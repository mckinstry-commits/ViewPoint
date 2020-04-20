CREATE TABLE [dbo].[bGLDT]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[GLTrans] [dbo].[bTrans] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[SourceCo] [dbo].[bCompany] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[DatePosted] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[RevStatus] [tinyint] NOT NULL,
[Adjust] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLDTd    Script Date: 8/28/99 9:37:30 AM ******/
   CREATE  trigger [dbo].[btGLDTd] on [dbo].[bGLDT] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 5/14/98
    *			GP 05/14/09 - Issue 133435 Added insert to HQAT code
    *
    *	This trigger rejects deletion from bGLDT (Details) if any of
    *	the following error conditions exist:
    *
    *		Missing Account Summary
    *
    *	Adds HQ Master Audit entry if Audit = Y and Purge = N.
    *
    *	Note: Purge flag controls update to bGLAS. Normal
    *	deletes adjust balances while purges does not.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @glco bCompany, @mth bMonth, @glacct bGLAcct,
   @jrnl bJrnl, @glref bGLRef, @sourceco bCompany, @source bSource, @amt bDollar, @opencursor tinyint
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   select @opencursor = 0
   /* use a cursor to process each deleted row - must be backed out of Account Summary unless purge */
   declare bGLDT_delete cursor for select GLCo, Mth, GLAcct, Jrnl, GLRef,
   	SourceCo, Source, Amount
   from deleted
   where Purge = 'N'
   open bGLDT_delete
   select @opencursor = 1
   next_row:
   	fetch next from bGLDT_delete into @glco, @mth, @glacct, @jrnl, @glref,
   		@sourceco, @source, @amt
   	if @@fetch_status = -1 goto end_row
   	if @@fetch_status <> 0 goto next_row
   	update bGLAS
   	set NetAmt = NetAmt - @amt
   	where GLCo = @glco and GLAcct = @glacct and Mth = @mth and Jrnl = @jrnl
   		and GLRef = @glref and SourceCo = @sourceco and Source = @source
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Missing GL Account Summary'
   		goto error
   		end
   	goto next_row
   end_row:
   	close bGLDT_delete
   	deallocate bGLDT_delete
   	select @opencursor = 0
   /* Audit GL Detail deletions, skip purges */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLDT',
   		'Mth: ' + convert(varchar(12),d.Mth,1) + ' Trans#: ' + convert(varchar(8),d.GLTrans),
   		d.GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bGLCO c
   		where d.GLCo = c.GLCo and c.AuditDetail = 'Y' and d.Purge ='N'
   		
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
    where d.UniqueAttchID is not null  		
   		
   return
   error:
   	if @opencursor = 1
   		begin
   		close bGLDT_delete
   		deallocate bGLDT_delete
   		end
   	select @errmsg = @errmsg + ' - cannot delete GL Transaction detail entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   /****** Object:  Trigger dbo.btGLDTi    Script Date: 4/23/2002 1:57:35 PM ******/
  CREATE trigger [dbo].[btGLDTi] on [dbo].[bGLDT] for INSERT as
 
 /*-----------------------------------------------------------------
 * Created: ??
 * Modified:	GG 5/14/98
 *				GF 08/01/2003 - issue #21933 - speed improvements
 *				AR 2/4/2011  - #143291 - adding foreign keys and check constraints, removing trigger look ups
 *				JayR 07/17/2012 TK-16020 Backing out using a FK. 
 *	This trigger rejects insertion in bGLDT (GL Details) if any
 *	of the following error conditions exist:
 *
 *		Invalid GL Company #

 *		Not an open month
 *		Must first add Fiscal Year
 *		Adjustment entries must be made in a Fiscal Year ending	month
 *		Invalid GL Account
 *		Heading Account
 *		Inactive Account


 *		Invalid Journal
 *		Detail and Account Summary Adjustment flags must match
 *		Detail and GL Reference Adjustment flags must match
 *		Invalid Batch
 *		Purge flag must be 'N'
 *		In Use Batch Id must be null
 *
 *	Inserts or updates GL Account Summary.
 *	Adds HQ Master Audit entry.
 */----------------------------------------------------------------
   declare @acctsumadj bYN, @accttype char(1), @active bYN, @adj bYN, @amt bDollar,
   		@audit bYN, @batch bBatchID, @co bCompany, @date bDate, @errmsg varchar(255),
   		@errno int, @field char(30),@fy bMonth, @glacct  bGLAcct, @glco bCompany, @glref bGLRef,
   		@glrefadj bYN, @gltrans bTrans, @inusebatch bBatchID, @jrnl bJrnl, @key varchar(60), 
   		@lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint, @mth bMonth,@new varchar(30), 
   		@numrows int, @old varchar(30), @purge bYN, @rectype char(1), @source bSource,@tablename char(20), 
   		@user bVPUserName, @opencursor tinyint
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @opencursor = 0
   
   -- use a cursor to process each inserted row 
   declare bGLDT_insert cursor FAST_FORWARD
   for select GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, BatchId, Amount, Adjust,InUseBatchId, Purge
   from inserted
   
   open bGLDT_insert
   select @opencursor = 1
   
   next_row:
   fetch next from bGLDT_insert into @glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @batch, @amt, @adj, @inusebatch, @purge
   
   if @@fetch_status = -1 goto end_row
   if @@fetch_status <> 0 goto next_row
   
   -- validate GL Company and Month
   select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen, 
   	   @audit = AuditDetail 
   from bGLCO with (nolock) where GLCo = @glco
   --#142311 -	using a foreign key
   if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
    	begin
    	select @errmsg = 'Not an open month'
    	goto error
    	end
   
   -- validate Fiscal Year 
   select @fy = FYEMO from bGLFY with (nolock)
   where GLCo = @glco and @mth >= BeginMth and @mth <= FYEMO
   if @@rowcount = 0
    	begin
    	select @errmsg = 'Must first add Fiscal Year'
    	goto error
    	end
   
   if @adj = 'Y' and @mth <> @fy
    	begin
    	select @errmsg = 'Adjustment entries must be made in a Fiscal Year ending month'
    	goto error
    	end
   
   
   -- validate GL Account
   select @accttype = AcctType, @active = Active 
   from bGLAC with (nolock) where GLCo = @glco and GLAcct = @glacct
   -- JayR TK-16020 Backing out using a FK.  #142311 - using a foreign key
   if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid GL Account'
    	goto error
    	end
   if @accttype = 'H'
    	begin
    	select @errmsg = 'Heading Account'
    	goto error
    	end
   if @active = 'N'
    	begin
    	select @errmsg = 'Inactive Account'
    	goto error
    	end
   
   -- validate Journal
   exec @errno = bspGLJrnlVal @glco, @jrnl, @errmsg output
   if @errno <> 0 goto error
   
   -- validate GL Reference
   if @glref is null or @glref = ''
    	begin
    	select @errmsg = 'Missing GL Reference'
    	goto error
    	end
   
   -- if Account Summary exists validate adjustment flag
     select @acctsumadj = Adjust from bGLAS with (nolock)
   where GLCo = @glco and GLAcct = @glacct and Mth = @mth and Jrnl = @jrnl
   and GLRef = @glref and SourceCo = @co and	Source = @source
   if @@rowcount <> 0
    	begin
    	if @acctsumadj <> @adj
    		begin
    		select @errmsg = 'Detail and Account Summary Adjustment	flags must match'
    		goto error
    		end
    	end
   
   -- if GL Reference exists validate adjustment flag
   select @glrefadj = Adjust from bGLRF with (nolock)
   where GLCo = @glco and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
   if @@rowcount <> 0
    	begin
    	if @glrefadj <> @adj
    		begin
    		select @errmsg = 'Detail and GL Reference Adjustment flags must match'
    		goto error
    		end
    	end
   
   -- validate Batch 
   exec @errno = bspHQBatchIdVal @co, @mth, @batch, @errmsg output
   if @errno <> 0 goto error
   
   -- validate Purge flag
   if @purge <> 'N'
    	begin
    	select @errmsg = 'Purge flag must be N'
    	goto error
    	end
   
   -- make sure InUseBatch is null
   if @inusebatch is not null
    	begin
    	select @errmsg = 'In Use Batch Id must be null'
    	goto error
    	end
   
   -- insert or update GL Account Summary
   update bGLAS
   set NetAmt = NetAmt + @amt
   where GLCo = @glco and GLAcct = @glacct and Mth = @mth
   and Jrnl = @jrnl and GLRef = @glref and SourceCo = @co and Source = @source
   if @@rowcount = 0
    	begin
    	insert bGLAS (GLCo, GLAcct, Mth, Jrnl, GLRef, SourceCo, Source, NetAmt, Adjust, Purge)
    	values (@glco, @glacct, @mth, @jrnl, @glref, @co, @source, @amt, @adj, @purge)
    	end
   
   -- add HQ Master Audit entry
   if @audit = 'Y' and substring(@source,1,2) = 'GL' -- must be source GL
    	begin
    	select @tablename = 'bGLDT', @key = 'Mth: ' + convert(char(12),@mth,1) + ' Trans:' + convert(char(6),@gltrans),
   		   @co = @glco, @rectype = 'A', @field = null, @old = null, @new = null, @date = getdate(), @user = SUSER_SNAME()
    	exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field, @old, @new, @date, @user, @errmsg output
    	if @errno <> 0 goto error
    	end
   
   
   goto next_row
   
   
   
   end_row:
   	close bGLDT_insert
   	deallocate bGLDT_insert
   	select @opencursor = 0
   
   
   
   return
   
   
   
   
   error:
   	if @opencursor = 1
   		begin
   		close bGLDT_insert
   		deallocate bGLDT_insert
   		end
   
   	select @errmsg = @errmsg + ' - cannot insert GL Detail Transaction!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Trigger dbo.btGLDTu    Script Date: 8/28/99 9:38:22 AM ******/
   CREATE  trigger [dbo].[btGLDTu] on [dbo].[bGLDT] for UPDATE as
   

	/*-----------------------------------------------------------------
	* Created: ??
	* Modified: GG 5/14/98
	*           MH 8/25/99  See comments below.
	*			AR 2/7/2011  - #142311 - adding foreign keys and check constraints, removing trigger look ups
	*			JayR 07/17/2012 TK-16020 Backing out using a FK.
	*  
	*	This trigger rejects update in bGLDT (Details) if any
	*	of the following error conditions exist:
	*
	*		Cannot change GL Company
	*		Cannot change Month
	*		Cannot change GL Transaction #
	*		Cannot change Journal
	*		Cannot change GL Reference
	*		Cannot change Source Company
	*		Cannot change Source
	*		Must be a GL Source transaction
	*		Cannot change Adjustment flag
	*		Heading Account
	*		Inactive Accountvalidate Batch
	*		Invalid Batch
	* 		Invalid InUseBatch
	*		Missing Account Summary
	*
	*	Adds a record for each updated field to HQ Master Audit as
	*	necessary.
	*/----------------------------------------------------------------
   declare @accttype char(1), @active bYN, @audit bYN, @co bCompany, @date bDate,
   @errmsg varchar(255), @errno int, @field char(30), @glco bCompany, @gltrans bTrans,
   @key varchar(60), @mth bMonth,@new varchar(30), @newactdate bDate, @newadj bYN,
   @newamt bDollar, @newbatchid bBatchID, @newdateposted bDate, @newdesc bTransDesc,
   @newglacct bGLAcct, @newglref bGLRef, @newinusebatchid bBatchID, @newjrnl bJrnl, @newpurge bYN,
   @newrevstatus tinyint, @newsource bSource, @newsourceco bCompany, @numrows int, @old varchar(30),
   @oldactdate bDate, @oldadj bYN, @oldamt bDollar, @oldbatchid bBatchID, @olddateposted bDate,
   @olddesc bTransDesc, @oldglacct bGLAcct, @oldglref bGLRef, @oldinusebatchid bBatchID,
   @oldjrnl bJrnl, @oldrevstatus tinyint, @oldsource bSource, @oldsourceco bCompany,
   @opencursor tinyint, @rectype char(1), @tablename char(20), @user bVPUserName, @validcount int
   	
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @opencursor = 0	
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.Mth = i.Mth and d.GLTrans = i.GLTrans
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change GL Company, Month, or GL Transaction Number'
   	goto error
   	end
   
   /* use a cursor to process each updated row */
   declare bGLDT_update cursor for select i.GLCo, i.Mth, i.GLTrans, OldGLAcct = d.GLAcct, NewGLAcct = i.GLAcct,
   	OldJrnl = d.Jrnl, NewJrnl = i.Jrnl, OldGLRef = d.GLRef, NewGLRef = i.GLRef, OldSourceCo = d.SourceCo,
   	NewSourceCo = i.SourceCo, OldSource = d.Source, NewSource = i.Source, OldActDate = d.ActDate,
   	NewActDate = i.ActDate, OldDatePosted = d.DatePosted, NewDatePosted = i.DatePosted,
   
   	OldDescription = d.Description, NewDescription = i.Description, OldBatchId = d.BatchId,
   	NewBatchId = i.BatchId, OldAmount = d.Amount, NewAmount = i.Amount, OldRevStatus = d.RevStatus,
   	NewRevStatus = i.RevStatus, OldAdjust = d.Adjust, NewAdjust = i.Adjust, OldInUseBatchId = d.InUseBatchId,
   	NewInUseBatchId = i.InUseBatchId, NewPurge = i.Purge
   from deleted d, inserted i
   where d.GLCo = i.GLCo and d.Mth = i.Mth and d.GLTrans = i.GLTrans
   
   
   open bGLDT_update
   select @opencursor = 1
   
   next_row:
   	fetch next from bGLDT_update into @glco, @mth, @gltrans, @oldglacct, @newglacct, @oldjrnl, @newjrnl,
   		@oldglref, @newglref, @oldsourceco, @newsourceco, @oldsource, @newsource, @oldactdate,
   		@newactdate, @olddateposted, @newdateposted, @olddesc, @newdesc, @oldbatchid,
   		@newbatchid, @oldamt, @newamt, @oldrevstatus, @newrevstatus, @oldadj, @newadj,
   		@oldinusebatchid, @newinusebatchid, @newpurge
   		
   	if @@fetch_status = -1 goto end_row
   	if @@fetch_status <> 0 goto next_row
   	
   
   	/* check for Journal changes */
   	if @oldjrnl <> @newjrnl
   
   		begin
   		select @errmsg = 'Cannot change Journal'
   		goto error
   		end
   	/* check for GL Reference changes */
   	if @oldglref <> @newglref
   		begin
   		select @errmsg = 'Cannot change GL Reference'
   		goto error
   		end
   
   	/* check for Source Company changes */
   	if @oldsourceco <> @newsourceco
   		begin
   		select @errmsg = 'Cannot change Source Company'
   		goto error
   		end
   	/* check for Source changes */
   	if @oldsource <> @newsource
   		begin
   		select @errmsg = 'Cannot change Source'
   		goto error
   		end
   	/* validate Source - unless you are updating the purge flag to 'Y', you can
   		only change transactions with a 'GL' source */
   
   
   	if @newpurge = 'N' and substring(@newsource,1,2) <> 'GL'
   		begin
   		select @errmsg = 'Must be a GL Source transaction'
   		goto error
   		end
   	/* check for Adjustment flag changes */
   	if @oldadj <> @newadj
   		begin
   		select @errmsg = 'Cannot change Adjustment flag'
   		goto error
   		end
   	/* validate GL Account */
   	if @oldglacct <> @newglacct
   
   		begin
   		select @accttype = AcctType, @active = Active
   			from bGLAC
   			where GLCo = @glco and GLAcct = @newglacct
   		--JayR TK-16020 Backing out using the FK. --#142311 replacing with FK
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Invalid GL Account'
   			goto error
   			end
   		if @accttype = 'H'
   			begin
   			select @errmsg = 'Heading Account'
   			goto error
   			end
   		if @active = 'N'
   			begin
   			select @errmsg = 'Inactive Account'
   			goto error
   			end
   		end
   	/* validate Batch */
   	if @oldbatchid <> @newbatchid
   		begin
   		exec @errno = bspHQBatchIdVal @newsourceco, @mth, @newbatchid, @errmsg output
   		if @errno <> 0 goto error
   		end
   
   --Issue 4405, GLRevinit.  If the batch your using to reverse is not in the same month as the as the transaction
   --month you get 'Not Valid HQ Batch'.  MH 8/25/99
   --
   	/* validate InUseBatch */
   /*	if @oldinusebatchid <> @newinusebatchid and @newinusebatchid is not null
   		begin
   		exec @errno = bspHQBatchIdVal @newsourceco, @mth, @newinusebatchid, @errmsg output
   		if @errno <> 0 goto error
   		end
   */
   	/* update GL Account Summary */
   	if @oldglacct <> @newglacct or @oldamt <> @newamt
   		begin
   		/* back out old amount from Account Summary */
   		update bGLAS
   		set NetAmt = NetAmt - @oldamt
   		where GLCo = @glco and GLAcct = @oldglacct and
   			Mth = @mth and Jrnl = @newjrnl and
   			GLRef = @newglref and SourceCo = @newsourceco and Source = @newsource
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Missing Account Summary'
   			goto error
   
   			end
   		/* update new amount to Account Summary */
   		update bGLAS
   		set NetAmt = NetAmt + @newamt
   		where GLCo = @glco and GLAcct = @newglacct and
   			Mth = @mth and Jrnl = @newjrnl and
   			GLRef = @newglref and SourceCo = @newsourceco and Source = @newsource
   		if @@rowcount = 0
   			begin
   			insert bGLAS (GLCo, GLAcct, Mth, Jrnl, GLRef, SourceCo, Source, NetAmt, Adjust, Purge)
   			values (@glco, @newglacct, @mth, @newjrnl, @newglref, @newsourceco, @newsource, @newamt, @newadj, 'N')
   			end
   		end
   	/* check for HQ Master Audit */
   	select @audit = AuditDetail from bGLCO where GLCo = @glco
   	--#142311 replacing with FK
   	if @audit = 'Y' and substring(@newsource,1,2) = 'GL'
   		begin
   		select @tablename = 'bGLDT',
   			@key = ' Mth: ' + convert(char(12),@mth, 1) + ' Trans#: ' + convert(char(8),@gltrans),
   			@co = @glco, @rectype = 'C',
   			@date = getdate(), @user = SUSER_SNAME()
   		if @oldglacct <> @newglacct
   			begin
   			select @field = 'GL Account', @old = @oldglacct, @new = @newglacct
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @oldactdate <> @newactdate
   			begin
   			select @field = 'Actual Date', @old = convert(varchar(12), @oldactdate,1),
   				@new = convert(varchar(12), @newactdate,1)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @olddateposted <> @newdateposted
   			begin
   			select @field = 'Date Posted', @old = convert(varchar(12), @olddateposted,1),
   				@new = convert(varchar(12), @newdateposted,1)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @olddesc <> @newdesc
   			begin
   			select @field = 'Description', @old = @olddesc, @new = @newdesc
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @oldbatchid <> @newbatchid
   			begin
   			select @field = 'BatchId', @old = convert(varchar(8), @oldbatchid),
   				@new = convert(varchar(8), @newbatchid)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @oldamt <> @newamt
   			begin
   			select @field = 'Amount', @old = convert(varchar(20), @oldamt),
   				@new = convert(varchar(20), @newamt)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @oldrevstatus <> @newrevstatus
   
   			begin
   			select @field = 'Rev Status', @old = convert(varchar(1), @oldrevstatus),
   				@new = convert(varchar(1), @newrevstatus)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   
   			end
   		end
   	
   	goto next_row
   		
   end_row:
   	if @opencursor = 1
   		begin
   		close bGLDT_update
   		deallocate bGLDT_update
   		select @opencursor = 0
   		end
   	
   return
   
   error:
   	if @opencursor = 1
   		begin
   
   		close bGLDT_update
   
   		deallocate bGLDT_update
   		end
   	select @errmsg = @errmsg + ' - cannot update GL Transaction Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bGLDT] ADD CONSTRAINT [PK_bGLDT] PRIMARY KEY CLUSTERED  ([GLCo], [Mth], [GLTrans]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bGLDT_GLAcct] ON [dbo].[bGLDT] ([GLAcct]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bGLDT_Mth] ON [dbo].[bGLDT] ([Mth]) INCLUDE ([GLAcct], [GLCo]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bGLDT_GLAcctMth] ON [dbo].[bGLDT] ([Mth], [GLCo], [GLAcct]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biGLDTUniqueAttchID] ON [dbo].[bGLDT] ([UniqueAttchID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLDT].[Purge]'
GO
