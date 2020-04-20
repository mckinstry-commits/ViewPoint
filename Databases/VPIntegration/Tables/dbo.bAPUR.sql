CREATE TABLE [dbo].[bAPUR]
(
[APCo] [dbo].[bCompany] NOT NULL,
[UIMth] [dbo].[bMonth] NOT NULL,
[UISeq] [smallint] NOT NULL,
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ApprvdYN] [dbo].[bYN] NOT NULL,
[Line] [int] NOT NULL CONSTRAINT [DF_bAPUR_Line] DEFAULT ((-1)),
[ApprovalSeq] [int] NOT NULL CONSTRAINT [DF_bAPUR_ApprovalSeq] DEFAULT ((1)),
[DateAssigned] [dbo].[bDate] NULL,
[DateApproved] [dbo].[bDate] NULL,
[AmountApproved] [dbo].[bDollar] NULL,
[Rejected] [dbo].[bYN] NULL CONSTRAINT [DF_bAPUR_Rejected] DEFAULT ('N'),
[RejReason] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[APTrans] [dbo].[bTrans] NULL,
[ExpMonth] [dbo].[bMonth] NULL,
[Memo] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[LoginName] [dbo].[bVPUserName] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[RejectDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   --ALTER  delete trigger
   CREATE          trigger [dbo].[btAPURd] on [dbo].[bAPUR] for delete as
     

/*-----------------------------------------------------------------
      *  Created: TV 01/17/02 Reviewer check
      *           TV 06/20/02 Redo Delete APUR
      *			MV 03//24/04 - #23833 audit deletes		
      * Deletes entries for line level
      */----------------------------------------------------------------
     
     declare @errmsg varchar(255), @validcnt int, @numrows int, @line int,
     @APCo bCompany, @UIMth bMonth, @UISeq int, @Reviewer varchar(3), @APTrans bTrans,
     @ExpMonth bMonth, @audit bYN
     
     SELECT @numrows = (Select Count(*) from deleted)
     IF @numrows = 0 return
     SET nocount on
     
   	select @audit = AuditUnappInv from APCO c with (nolock) join deleted d on c.APCo=d.APCo
     
     --------------------------------------------Reviewer check------------------------------
    
     declare bcLinecheck cursor 
     for 
     select Line,APCo, UIMth, UISeq, Reviewer, @APTrans ,
     ExpMonth from deleted
    
     open  bcLinecheck
    
     fetchnext:
     fetch next from bcLinecheck into @line,  @APCo, @UIMth, @UISeq, @Reviewer, 
     @APTrans, @ExpMonth 
     if @@fetch_Status <> 0 goto fetchend
    
     
         
     if (select @line)= -1
        begin
        exec bspAPURDeleteHeader @APCo, @UIMth, @UISeq, @Reviewer,@APTrans, @ExpMonth 
        end         
   
   /* Audit delete */
   if @audit = 'Y'
   	begin
   	insert into bHQMA select 'bAPUR', ' UIMth: ' + convert(char(8), UIMth,1) +
   	' UISeq: ' + convert(varchar(10), UISeq) +
   	case when Line > 0 then ' Line: ' + convert(varchar(10),Line) else ' Header' end +
   	' Reviewer: ' + Reviewer,
   	APCo, 'D',NULL, NULL, NULL, getdate(), SUSER_SNAME()
   	from deleted where APCo=@APCo and UIMth=@UIMth and UISeq=@UISeq and Reviewer=@Reviewer
    	end
    
     goto fetchnext
     fetchend:
     close bcLinecheck
     deallocate bcLinecheck
    
   
     return
     
     error:
         SELECT @errmsg = @errmsg +  ' - cannot delete AP Unapproved Invoice Reviewer!'
         RAISERROR(@errmsg, 11, -1);
         rollback transaction
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   --ALTER  insert trigger
   CREATE      trigger [dbo].[btAPURi] on [dbo].[bAPUR] for INSERT as
    

/*-----------------------------------------------------------------
 *  Created: EN 11/2/98
 *  Modified: EN 11/2/98
 *            TV 01/17/02 Reviewer check
 *            TV 06/20/02 Update reviewer insert
 *			GG 06/21/02 - cleanup, added validation
 *			MV 03/24/04 - #23833 audit inserts
 *			GF 10/25/2010 - issue #141031
 *				CHS 06/17/2011 - issue #143179 to undo issue #141031 
 *
 * Insert trigger for AP Unapproved Invoice Reviewer detail
 */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @validcnt int, @numrows int, @apco bCompany, @uimth bMonth, @uiseq int, @line int
    
    SELECT @numrows = @@rowcount,@validcnt=0
    IF @numrows = 0 return
    
    SET nocount on
    
	/* check Unapproved Invoice Header */
	SELECT @validcnt = count(*)
	FROM dbo.bAPUI h (nolock)
	JOIN inserted i ON h.APCo = i.APCo and h.UIMth = i.UIMth and h.UISeq = i.UISeq

	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Unapproved Invoice does not exist'
		GOTO error
	END

	/* validate Reviewer */
	SELECT @validcnt = count(*)
	FROM dbo.bHQRV r (nolock)
	JOIN inserted i ON r.Reviewer = i.Reviewer

	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid Reviewer' 
		GOTO error
	END

	if exists(select 1 from inserted where ApprvdYN = 'Y' or isnull(Rejected,'N') = 'Y')
	begin
		select @errmsg = 'Entries cannot be added already Approved or Rejected'
		goto error
	end
    
    if exists(select 1 from inserted where APTrans is not null or ExpMonth is not null)
	begin
		select @errmsg = 'Expense Month and AP Transaction # must be null'
		goto error
	end 
    
	-- if needed, update the Assigned Date
	if exists(select 1 from inserted where DateAssigned is null)
	BEGIN
		----#141031
		--update bAPUR set DateAssigned = dbo.vfDateOnly()
		--issue #143179
		update bAPUR set DateAssigned = getdate()
		from inserted i
		join dbo.bAPUR b (nolock) on b.APCo = i.APCo and b.UIMth = i.UIMth and b.UISeq = i.UISeq and b.Line = i.Line and
		b.Reviewer = i.Reviewer and b.ApprovalSeq = i.ApprovalSeq and b.APTrans is null and b.ExpMonth  is null
		where  isnull(b.DateAssigned, '') = ''
	end
    
    declare bcLineCheck cursor for 
    
    Select APCo, UIMth, UISeq, Line
    from inserted
    where Line <> -1
    open bcLineCheck
    
    fetchnext:
    Fetch next from bcLineCheck into @apco, @uimth, @uiseq, @line
    if @@fetch_status <> 0 goto fetchend
    
    if (select Count(*) from dbo.APUL (nolock) where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line) = 0
	begin
		select @errmsg = 'Invoice Line:' + convert(varchar(10),@line) + ' does not exist for this invoice.'
		goto error
	end
    
    goto fetchnext
    fetchend:
    
    close bcLineCheck
    deallocate bcLineCheck
    
   
    return
    
    error:
        SELECT @errmsg = @errmsg +  ' - cannot insert AP Unapproved Invoice Reviewer detail!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btAPURu    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE      trigger [dbo].[btAPURu] on [dbo].[bAPUR] for UPDATE as
/*-----------------------------------------------------------------
    *	Created :  11/2/98 EN
    *	Modified : 11/2/98 EN
    *             05/13/02 TV
    *             TV Redo approval
    *			   GG 06/21/02 - cleanup
    *             TV 09/10/02-Fix the update APUR when line = -1
    *			   GF 08/11/2003 - issue #22112 - performance improvements
    *			   MV 03/24/04 - #23833 - audit changes
    *			   MV 03/30/04 - #23833 - change how cursor works
    *				TV 01/10/05 25866 - New query for rejected unapproved invoices.
    *				MV 01/30/08 - #126702 AmountApproved - include tax for both tax types
	*								include discount only if NetAmtOpt is checked in bAPCO
	*				MV 09/08/08 - #128541 - allow Approval Seq change, update audit
	*				MV 03/25/09 - #132650 - set RejReason = null when Reject = 'N'
    *				MV 07/02/09 - #134511 - exclude use tax in amount approved.
    *				GF 10/25/2010 - issue #141031
    *
    *	This trigger rejects primary key changes.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @opencursor int, @auditYN bYN,
	@netamtoptyn bYN
      
   select @numrows = @@rowcount, @opencursor = 0
   if @numrows = 0 return
   set nocount on
      
   -- verify primary key not changed - except APTrans and ExpMonth
   if update(APCo) or update(UIMth) or update(UISeq)
   	begin
   	select @errmsg = 'Change to AP Co#, Unapproved Invoice Month, or Invoice Seq# not allowed'
   	goto error
   	end
   if update(Reviewer)
       	begin
       	select @errmsg = 'Change to Reviewer not allowed'
       	goto error
       	end
   if update(Line)
       	begin
       	select @errmsg = 'Change to Line# not allowed'
       	goto error
       	end
--   if update(ApprovalSeq)
--       	begin
--       	select @errmsg = 'Change to Approval Seq# not allowed.'
--       	goto error
--       	end
      
   if exists(select 1 from inserted where ApprvdYN = 'Y' and isnull(Rejected,'N') = 'Y')
      	begin
      	select @errmsg = 'Cannot be both Approved and Rejected'
      	goto error
      	end

   select @auditYN=AuditUnappInv, @netamtoptyn = NetAmtOpt from bAPCO c with (nolock) join inserted i on i.APCo=c.APCo 
     
   -- Approval updates	-- moved this code so updates where ApprvdYN isn't involved, get a cursor too.
   -- if update(ApprvdYN)
   -- 	begin
   	--populates needed fields on approval.
   declare @line int, @approve char(1), @reject char(1), @uimth bMonth, @uiseq int, 
   		@co bCompany, @reviewer Varchar(25), @approvedamount bDollar, @approvalseq int
   
   declare btcAPURLine cursor LOCAL FAST_FORWARD
   for select Line, ApprvdYN, Rejected, UIMth, UISeq, APCo,Reviewer, ApprovalSeq
   from inserted
           
   open btcAPURLine
   	select @opencursor = 1
   FetchNextAPURLine:
   fetch next from btcAPURLine into @line, @approve, @reject, @uimth, @uiseq, @co, @reviewer, @approvalseq
   
   if @@fetch_status <> 0 goto CloseAPURLine
   
   if update(ApprvdYN)
   	begin  
   		if @approve = 'Y'
   		  	begin
   	       	update bAPUR
   	       	----#141031
   	       	set DateApproved = dbo.vfDateOnly(),
			AmountApproved = l.GrossAmt + (case l.MiscYN when 'Y' then l.MiscAmt else 0 end) 
				+ case l.TaxType when 2 then 0 else l.TaxAmt end - (case @netamtoptyn when 'Y' then l.Discount else 0 end)/*l.GrossAmt - l.Discount + l.TaxAmt */
   	        from bAPUR r join bAPUL l on r.APCo = l.APCo and r.UIMth = l.UIMth and r.UISeq = l.UISeq and r.Line = l.Line
   	       	where r.APCo = @co and r.UIMth = @uimth and r.UISeq =@uiseq and r.Reviewer = @reviewer and 
   	             	r.Line = @line and r.APTrans is null and r.ExpMonth is null
   	       	end
   	   	else  
   	       	begin
   	       	update bAPUR
   	       	set DateApproved = null, AmountApproved =null
   	       	from bAPUR r join inserted i on r.APCo = i.APCo and r.UISeq = i.UISeq and r.UIMth = i.UIMth
   	       	where r.Line = @line and r.ApprvdYN = 'N'
   	               and r.Reviewer = @reviewer and r.ApprovalSeq = i.ApprovalSeq
   	       	end
   	 
   		if not exists (select 1 from bAPUR r with (nolock) where r.APCo = @co and r.UIMth = @uimth
   				and r.UISeq =@uiseq and r.Reviewer = @reviewer and r.Line = @line
   				and r.APTrans is null and r.ExpMonth is null and r.ApprvdYN = 'N' and r.Line <> -1)
   			and exists (select 1 from bAPUR r with (nolock) where r.APCo = @co and r.UIMth = @uimth
   				and r.UISeq =@uiseq and r.Reviewer = @reviewer and r.Line = -1
   				and r.APTrans is null and r.ExpMonth is null and r.ApprvdYN = 'N' ) 
   				-- and (select Line from Inserted i where i.APCo = @co and i.UIMth = @uimth
   				-- and i.UISeq =@uiseq and i.Reviewer = @reviewer and i.Line = @line ) <> -1
   			begin
   			update bAPUR set ApprvdYN = 'Y'
   			where APCo = @co and UIMth = @uimth and UISeq =@uiseq and Reviewer = @reviewer
   			and	Line = -1 and APTrans is null and ExpMonth is null
   			end
   		else
   			begin
   			update bAPUR set ApprvdYN = 'N'
   			where APCo = @co and UIMth = @uimth and UISeq =@uiseq and Reviewer = @reviewer
   			and	Line = -1 and APTrans is null and ExpMonth is null
   	   		 end
   		
   	end
   
    
    
   if update(Rejected) 
   	begin
   	--update header if all lines are rejected
   	if not exists (select 1 from bAPUR r with (nolock) where r.APCo = @co and r.UIMth = @uimth
   			and r.UISeq =@uiseq and r.Reviewer = @reviewer and r.Line = @line
   			and r.APTrans is null and r.ExpMonth is null and Rejected = 'N' and r.Line <> -1)
   		and exists (select 1 from bAPUR r with (nolock) where r.APCo = @co and r.UIMth = @uimth 
   			and r.UISeq =@uiseq and r.Reviewer = @reviewer and r.Line = -1
   			and r.APTrans is null and r.ExpMonth is null and r.Rejected = 'N' )
   		begin
   		update bAPUR set Rejected = 'Y'
   		from bAPUL l with (nolock) join bAPUR r on r.APCo = l.APCo and r.UISeq = l.UISeq
                           and r.UIMth = l.UIMth and r.Line = l.Line 
   		where r.APCo = @co and r.UIMth = @uimth and r.UISeq =@uiseq and r.Reviewer = @reviewer
   		and r.Line = -1 and r.APTrans is null and r.ExpMonth is null
   		end
   	-- TV 01/10/05 25866 - New query for rejected unapproved invoices.
   	----#141031
   	update bAPUR  set RejectDate = case when Rejected = 'Y' then dbo.vfDateOnly() else null end
   	where bAPUR.APCo = @co and bAPUR.UIMth = @uimth and bAPUR.UISeq =@uiseq and bAPUR.Reviewer = @reviewer
   			and bAPUR.Line = @line
   	end

	--Clear RejReason - #132650
	if (@approve = 'Y' and @reject = 'N') or (@approve = 'N' and @reject = 'N')
		begin
		update bAPUR set RejReason = null where APCo = @co and UIMth = @uimth and UISeq =@uiseq and Reviewer = @reviewer
   			and	Line = @line and APTrans is null and ExpMonth is null
		end

  
   
   -- Check bAPCO to see if auditing changes. 
   if isnull(@auditYN,'N') = 'Y'
   	begin
   	-- Insert records into HQMA for changes made to audited fields
   	if update(ApprvdYN)
   		insert into bHQMA select 'bAPUR',
   		' UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		case when i.Line > 0 then ' Line: ' + convert (varchar(10), i.Line)else 'Header 'end +
   		' Reviewer: ' + i.Reviewer, i.APCo, 'C',
   	 	'Approved ', d.ApprvdYN, i.ApprvdYN, getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line and d.Reviewer=i.Reviewer
   	    where isnull(d.ApprvdYN,'') <> isnull(i.ApprvdYN,'') 
   	if update(Rejected)
   		insert into bHQMA select 'bAPUR',
   		' UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		case when i.Line > 0 then ' Line: ' + convert (varchar(10), i.Line)else 'Header 'end +
   		' Reviewer: ' + i.Reviewer, i.APCo, 'C',
   	 	'Rejected ', d.Rejected, i.Rejected, getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line and d.Reviewer=i.Reviewer
   	    where isnull(d.Rejected,'') <> isnull(i.Rejected,'')
   	if update(RejReason)
   		insert into bHQMA select 'bAPUR',
   		' UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		case when i.Line > 0 then ' Line: ' + convert (varchar(10), i.Line)else 'Header 'end +
   		' Reviewer: ' + i.Reviewer, i.APCo, 'C',
   	 	'Reject Reason ', d.RejReason, i.RejReason, getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line and d.Reviewer=i.Reviewer
   	    where isnull(d.RejReason,'') <> isnull(i.RejReason,'')
	if update(ApprovalSeq)
   		insert into bHQMA select 'bAPUR',
   		' UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		case when i.Line > 0 then ' Line: ' + convert (varchar(10), i.Line)else 'Header 'end +
   		' Reviewer: ' + i.Reviewer, i.APCo, 'C',
   	 	'Approval Seq ', convert(varchar(3),d.ApprovalSeq), convert(varchar(3),i.ApprovalSeq), getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line and d.Reviewer=i.Reviewer
   	    where d.ApprovalSeq <> i.ApprovalSeq
   	End
   
   goto FetchNextAPURLine
      
   CloseAPURLine:
   	if @opencursor = 1
   	begin
   		close btcAPURLine
   		deallocate btcAPURLine
   	end
   	   
      
      
   return
      
   
   
   error:
   	if @opencursor = 1
   	begin
   		close btcAPURLine
   		deallocate btcAPURLine
   	end
   	select @errmsg = @errmsg + ' - cannot update AP Unapproved Invoice Reviewer!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
CREATE NONCLUSTERED INDEX [IX_bAPUR_APCoReviewerLine] ON [dbo].[bAPUR] ([APCo], [Reviewer], [Line]) INCLUDE ([KeyID], [UIMth], [UISeq]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biAPUR] ON [dbo].[bAPUR] ([APCo], [UIMth], [UISeq], [Reviewer], [Line]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPUR] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPUR].[ApprvdYN]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bAPUR].[ApprvdYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPUR].[Rejected]'
GO
