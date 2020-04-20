CREATE TABLE [dbo].[bAPPB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NULL,
[CMRefSeq] [tinyint] NULL,
[EFTSeq] [smallint] NULL,
[ChkType] [char] (1) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[PaidDate] [dbo].[bDate] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[Supplier] [dbo].[bVendor] NULL,
[VoidYN] [dbo].[bYN] NOT NULL,
[VoidMemo] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ReuseYN] [dbo].[bYN] NULL,
[Overflow] [dbo].[bYN] NOT NULL,
[AddnlInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AddendaTypeId] [tinyint] NULL,
[TaxFormCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Employee] [int] NULL,
[SeparatePayYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPPB_SeparatePayYN] DEFAULT ('N'),
[SeparatePayMth] [dbo].[bMonth] NULL,
[SeparatePayTrans] [dbo].[bTrans] NULL,
[Job] [dbo].[bJob] NULL,
[JCCo] [dbo].[bCompany] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PayOverrideYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPPB_PayOverrideYN] DEFAULT ('N'),
[AddressSeq] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   /****** Object:  Trigger dbo.btAPPBd    Script Date: 8/28/99 9:36:55 AM ******/
   CREATE  trigger [dbo].[btAPPBd] on [dbo].[bAPPB] for DELETE as
   

/*--------------------------------------------------------------
    *	Created:  EN 9/8/98
    *	Modified: EN 9/8/98
    *            GG 07/20/01 - unlock AP Payment Headers
    *            TV 03/21/02 - Delete HQAT enties when needed
	*			 MV 06/01/09 - #133431 delete HQAT per issue #127603 
	*			 JonathanP 06/03/09 - 133431 - Cleaned up attachment code.
	*			 MV 12/21/09 - #137151 - audit deleting payment header
    *  Delete trigger on AP Payment Batch Header
    *
    *	Reject if bAPTB entries exist.
    *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check AP Payment Transaction Batch */
   if exists(select * from bAPTB b, deleted d where b.Co = d.Co and b.Mth = d.Mth
   	  and b.BatchId = d.BatchId and b.BatchSeq = d.BatchSeq)
       begin
   	select @errmsg = 'Entries exist in AP Payment Transaction Batch for this entry'
   	goto error
   	end
   
   -- unlock any AP Payment Headers pulled into batch to void
   update bAPPH
   set InUseMth = null, InUseBatchId = null
   from bAPPH h
   join deleted d on h.APCo = d.Co and h.CMCo = d.CMCo and h.CMAcct = d.CMAcct
       and h.PayMethod = d.PayMethod and h.CMRef = d.CMRef and h.CMRefSeq = isnull(d.CMRefSeq,0)
       and h.EFTSeq = isnull(d.EFTSeq,0) and h.InUseMth = d.Mth and h.InUseBatchId = d.BatchId

	-- 133431 Delete attachment if they do not exist in the posted table.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		select AttachmentID, suser_name(), 'Y' 
		from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
		where h.UniqueAttchID not in (select t.UniqueAttchID from bAPPH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
			  and d.UniqueAttchID is not null   

	 /* Audit AP Payement Header deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bAPPB',' Key:'
		 + ' Mth ' + convert(varchar(2),datepart(mm, d.Mth)) + '/' + substring(convert(varchar(4),datepart(yy, d.Mth)),3,2)
		 + ' BatchId ' + convert (varchar(10),d.BatchId)
         + ' BatchSeq ' + convert (varchar(10),d.BatchSeq)
		 + ' CMCo ' + isnull(convert(varchar(3), d.CMCo),'')
   		 + ' CMAcct ' + isnull(convert(varchar(4), d.CMAcct),'')
   		 + ' PayMethod ' + isnull(convert(varchar(1),d.PayMethod),'')
   		 + ' CMRef ' + isnull(convert(varchar(10),d.CMRef),'')
   		 + ' CMRefSeq ' + isnull(convert(varchar(1),d.CMRefSeq),'')
   		 + ' EFTSeq ' + isnull(convert(varchar(4),d.EFTSeq),'')
		 + ' Vendor ' + isnull(convert(varchar(10),d.Vendor),''),
--		 + ' Amount ' + isnull(convert(varchar(20), d.Amount),''),
             d.Co, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
     FROM deleted d

   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete Payment Batch Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btAPPBi] on [dbo].[bAPPB] for INSERT as
/*--------------------------------------------------------------
* CREATED: KB 10/01/97
* MODIFIED: KB 01/04/99
*           GG 07/20/01 - lock AP Payment Headers pulled into batch for void
*			GG 07/25/07 - #120561 - remove bHQCC insert for AP GL Co#, cleanup
*			MV 03/11/08 - #127347 International addresses
*			GG 06/06/08 - #128324 - removed State/Country validation
*			MV 04/03/09 - #133073 - (nolock)
*
* Insert trigger for AP Payment Batch
*
*--------------------------------------------------------------*/
   
declare @numrows int, @errmsg varchar(255), @rcode tinyint, @co bCompany, @mth bMonth,
   @batchid bBatchID, @cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @cmref bCMRef,
   @cmrefseq tinyint, @eftseq smallint, @errtext varchar(60), @cmglco bCompany, @glco bCompany,
   @status tinyint,@validcnt int, @validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

if @numrows = 1
   	select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @cmco = i.CMCo, @cmacct = i.CMAcct,
           @paymethod = i.PayMethod, @cmref = i.CMRef, @cmrefseq = i.CMRefSeq, @eftseq = i.EFTSeq,
           @cmglco = c.GLCo, @glco = a.GLCo
	from inserted i
    join bAPCO a (nolock) on a.APCo = i.Co
    join bCMAC c (nolock) on c.CMCo = i.CMCo
else
    begin
	-- use a cursor to process each inserted row
	declare bcAPPB_insert cursor for
	select i.Co, i.Mth, i.BatchId, i.CMCo, i.CMAcct, i.PayMethod, i.CMRef, i.CMRefSeq,
       i.EFTSeq, c.GLCo, a.GLCo
	from inserted i
	join bAPCO a on a.APCo = i.Co
	join bCMAC c on c.CMCo = i.CMCo
   
    open bcAPPB_insert
   
    fetch next from bcAPPB_insert into @co, @mth, @batchid, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq,
           @eftseq, @cmglco, @glco
    if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end
   
insert_check:
	/* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Payment', 'APPB', @errtext output, @status output
    if @rcode <> 0
		begin
        select @errmsg = @errtext, @rcode = 1
		goto error
        end
    if @status <> 0
        begin
   	    select @errmsg = 'Must be an open batch.'
   	    goto error
   	    end
   
	/* add entry to HQ Close Control for the CM GL Co# */
    if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @cmglco)
   	   begin
   	   insert bHQCC (Co, Mth, BatchId, GLCo)
   	   values (@co, @mth, @batchid, @cmglco)
   	   end
   
    -- lock Payment Header entries pulled into batch for void (not all voids will have bAPPH entries)
    update bAPPH
    set InUseMth = @mth, InUseBatchId = @batchid
    where APCo = @co and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
		and CMRef = @cmref and isnull(CMRefSeq,0) = isnull(@cmrefseq,0) and isnull(EFTSeq,0) = isnull(@eftseq,0)
   
    if @numrows > 1
        begin
        fetch next from bcAPPB_insert into @co, @mth, @batchid, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq,
			@eftseq, @cmglco, @glco
        if @@fetch_status = 0
   			goto insert_check
        else
   		   begin
   		   close bcAPPB_insert
   		   deallocate bcAPPB_insert
   		   end
       end
   
return
   
error:
	if @numrows > 1
   	   begin
   	   close bcAPPB_insert
   	   deallocate bcAPPB_insert
   	   end
   
	select @errmsg = @errmsg + ' - cannot insert Payment Batch Header'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[btAPPBu] on [dbo].[bAPPB] for UPDATE as
/*-----------------------------------------------------------------
* Created : 9/8/98 EN
* Modified : 04/22/99 GG   (SQL 7.0)
*			kb 7/30/2 - issue #18112 - do manual check processing
*			MV 10/04/04 - #23827 redid manual check process, real cursor 
*			MV 09/26/07 - #125590 -  manual process check causing doubled discount in APTB in 6X
*			MV 03/11/08 - #127347 - International addresses
*			GG 06/06/08 - #128324 - removed State/Country validation
*			MV 07/23/08 - #129076 - fix cursor name in close and deallocate
*			MV 09/02/09 - #130949 - do manual check process for ChkType 'I' - Import
*			MV 12/21/09 - #137151 - audit changes to CMRef - printing or clearing/voiding checks
*
*	This trigger rejects update in bAPPB (Payment Batch Header)
*	if any of the following error conditions exist:
*
*		Cannot change Co
*		Cannot change Mth
*		Cannot change BatchId
*		Cannot change BatchSeq
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int,
	@co bCompany, @mth bMonth, @batchid bBatchID, @cmglco bCompany,
	@batchseq int, @rcode int, @chktype varchar(1),@cmref bCMRef,
	@openAPPB int, @msg varchar(255)

select @numrows = @@rowcount, @openAPPB = 0, @rcode = 0
if @numrows = 0 return

set nocount on

/* verify primary key not changed */
if update (Co) or update(Mth) or update(BatchId) or update(BatchSeq)
	begin
	select @errmsg = 'Cannot change Primary Key'
	goto error
	end
	   
-- update AP Trans Header with changes to PrePaid check#s    
if update(CMRef)
   	update bAPTH set PrePaidChk = i.CMRef
   	from inserted i
   	join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId 
   		and i.BatchSeq = d.BatchSeq
   	join bAPTH h (nolock) on h.APCo = i.Co and h.PrePaidMth = i.Mth and h.PrePaidChk = d.CMRef and
   		h.InUseMth = i.Mth and h.InUseBatchId = i.BatchId
   
-- if multiple rows updated use a cursor
if @numrows = 1
	begin
   	select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @batchseq = i.BatchSeq,
   			@chktype = i.ChkType, @cmref = i.CMRef, @cmglco = c.GLCo
	from inserted i
    join bCMCO c (nolock) on c.CMCo = i.CMCo
    if @@rowcount = 0 
		begin
		select @errmsg = 'Invalid CM Co#'
		goto error
		end
	end
else
    begin
	-- use a cursor to process each updated row
	declare bcAPPB_update cursor for
	select i.Co, i.Mth, i.BatchId, i.BatchSeq, i.ChkType, i.CMRef, c.GLCo
	from inserted i
	join bCMCO c (nolock) on c.CMCo = i.CMCo
   
    open bcAPPB_update
	select @openAPPB = 1
   
    fetch next from bcAPPB_update into @co, @mth, @batchid, @batchseq, @chktype, @cmref, @cmglco
    if @@fetch_status <> 0 goto bspexit
 	end
   
update_check:
	/* add entry to HQ Close Control for the CM GL Co# */
    if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @cmglco)
   	   begin
   	   insert bHQCC (Co, Mth, BatchId, GLCo)
   	   values (@co, @mth, @batchid, @cmglco)
   	   end

	-- Manual check process
	if @chktype in ('M','I') and isnull(@cmref,'') <> ''
--	if @chktype='M' and isnull(@cmref,'') <> '' 
		begin
		exec @rcode = bspAPManualCheckProcess @co, @mth, @batchid, @batchseq, @msg output
		if @rcode <> 0 goto error
		end

	 /* Audit AP Payement Header changes to CMRef when printing checks or clearing/voiding check number */
	   INSERT INTO bHQMA
		   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		SELECT 'bAPPB',' Key:'
			 + ' Mth ' + convert(varchar(2),datepart(mm, i.Mth)) + '/' + substring(convert(varchar(4),datepart(yy, d.Mth)),3,2)
			 + ' BatchId ' + convert (varchar(10),d.BatchId)
             + ' BatchSeq ' + convert (varchar(10),d.BatchSeq)
			 + ' CMCo ' + isnull(convert(varchar(3), d.CMCo),'')
   			 + ' CMAcct ' + isnull(convert(varchar(4), d.CMAcct),'')
   			 + ' PayMethod ' + isnull(convert(varchar(1),d.PayMethod),'')
   			 + ' CMRef ' + isnull(d.CMRef,isnull(i.CMRef,''))
   			 + ' CMRefSeq ' + isnull(convert(varchar(1),d.CMRefSeq),isnull(convert(varchar(1),i.CMRefSeq),''))
   			 + ' EFTSeq ' + isnull(convert(varchar(4),d.EFTSeq),'')
			 + ' Vendor ' + isnull(convert(varchar(10),d.Vendor),'')
			 + ' Amount ' + isnull(convert(varchar(20), d.Amount),''),
				  i.Co,'C','CMRef',isnull(d.CMRef,''), isnull(i.CMRef,''),getdate(),SUSER_SNAME()
		 FROM deleted d
		 JOIN inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId 
   			and i.BatchSeq = d.BatchSeq
		 WHERE (d.CMRef is not null and i.CMRef is null) or (d.CMRef is null and i.CMRef is not null) 

	if @numrows > 1
		begin
		fetch next from bcAPPB_update into @co, @mth, @batchid, @batchseq, @chktype, @cmref, @cmglco
		if @@fetch_status <> 0 goto bspexit
		goto update_check
		end
  
bspexit:
	if @openAPPB = 1
		begin
        close bcAPPB_update
		deallocate bcAPPB_update
		end
   
	return
   
error:
   	if @openAPPB = 1
           begin
           close bcAPPB_update
           deallocate bcAPPB_update
           end
   	select @errmsg = @errmsg + ' - cannot update Payment Batch Header!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
  
 





GO
CREATE NONCLUSTERED INDEX [biAPPBCMRef] ON [dbo].[bAPPB] ([CMRef]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biAPPB] ON [dbo].[bAPPB] ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPPB] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPPBVendor] ON [dbo].[bAPPB] ([Vendor]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPPB].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPPB].[VoidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPPB].[ReuseYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPPB].[Overflow]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bAPPB].[Overflow]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPPB].[SeparatePayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPPB].[PayOverrideYN]'
GO
