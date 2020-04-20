CREATE TABLE [dbo].[bAPHB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[APTrans] [dbo].[bTrans] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[DiscDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[InvTotal] [dbo].[bDollar] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[PrePaidYN] [dbo].[bYN] NOT NULL,
[PrePaidMth] [dbo].[bMonth] NULL,
[PrePaidDate] [dbo].[bDate] NULL,
[PrePaidChk] [dbo].[bCMRef] NULL,
[PrePaidSeq] [tinyint] NULL,
[PrePaidProcYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPHB_PrePaidProcYN] DEFAULT ('N'),
[V1099YN] [dbo].[bYN] NOT NULL,
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[V1099Box] [tinyint] NULL,
[PayOverrideYN] [dbo].[bYN] NOT NULL,
[PayName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PayState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PayZip] [dbo].[bZip] NULL,
[InvId] [char] (10) COLLATE Latin1_General_BIN NULL,
[UIMth] [dbo].[bMonth] NULL,
[UISeq] [smallint] NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldVendor] [dbo].[bVendor] NULL,
[OldAPRef] [dbo].[bAPReference] NULL,
[OldDesc] [dbo].[bDesc] NULL,
[OldInvDate] [dbo].[bDate] NULL,
[OldDiscDate] [dbo].[bDate] NULL,
[OldDueDate] [dbo].[bDate] NULL,
[OldInvTotal] [dbo].[bDollar] NULL,
[OldHoldCode] [dbo].[bHoldCode] NULL,
[OldPayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldPayMethod] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldCMCo] [dbo].[bCompany] NULL,
[OldCMAcct] [dbo].[bCMAcct] NULL,
[OldPrePaidYN] [dbo].[bYN] NULL,
[OldPrePaidMth] [dbo].[bMonth] NULL,
[OldPrePaidDate] [dbo].[bDate] NULL,
[OldPrePaidChk] [dbo].[bCMRef] NULL,
[OldPrePaidSeq] [tinyint] NULL,
[OldPrePaidProcYN] [dbo].[bYN] NULL,
[Old1099YN] [dbo].[bYN] NULL,
[Old1099Type] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Old1099Box] [tinyint] NULL,
[OldPayOverrideYN] [dbo].[bYN] NULL,
[OldPayName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldPayAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldPayCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldPayState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldPayZip] [dbo].[bZip] NULL,
[PayAddInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldPayAddInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[DocName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[OldDocName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[MSCo] [dbo].[bCompany] NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[AddendaTypeId] [tinyint] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[DLcode] [dbo].[bEDLCode] NULL,
[TaxFormCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TaxPeriodEndDate] [dbo].[bDate] NULL,
[AmountType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NULL,
[AmtType2] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Amount2] [dbo].[bDollar] NULL,
[AmtType3] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Amount3] [dbo].[bDollar] NULL,
[OldAddendaTypeId] [tinyint] NULL,
[OldPRCo] [dbo].[bCompany] NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldDLcode] [dbo].[bEDLCode] NULL,
[OldTaxFormCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldTaxPeriodEndDate] [dbo].[bDate] NULL,
[OldAmountType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldAmount] [dbo].[bDollar] NULL,
[OldAmtType2] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldAmount2] [dbo].[bDollar] NULL,
[OldAmtType3] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldAmount3] [dbo].[bDollar] NULL,
[SeparatePayYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPHB_SeparatePayYN] DEFAULT ('N'),
[OldSeparatePayYN] [dbo].[bYN] NULL,
[ChkRev] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPHB_ChkRev] DEFAULT ('N'),
[PaidYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPHB_PaidYN] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AddressSeq] [tinyint] NULL,
[OldAddressSeq] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SLKeyID] [bigint] NULL,
[PayCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[OldPayCountry] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPHB] ON [dbo].[bAPHB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPHB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bAPHB_SLKeyID] ON [dbo].[bAPHB] ([SLKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPHBVendor] ON [dbo].[bAPHB] ([Vendor]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   /****** Object:  Trigger dbo.btAPHBd    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE        trigger [dbo].[btAPHBd] on [dbo].[bAPHB] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created : 9/2/97 kf
     *	Modified: 04/22/99 GG    (SQL 7.0)
     *				GG 08/14/01 - #14237 - MS Intercompany Invoices, cleanup
     *				TV 10/02/01 Was unlocking all of the APUI entries associated with the batchID
     *              TV 03/21/02 Delete HQAT entries..
     *              bc 4/30/2 - issue #17162
     *              TV 06/20/02 - Reset APTrans/ExpMonth to null 
     *              TV 07/12/02 - Change the table name in HQAT if deleted record was from APUI
     *              TV 09/26/02 - remove the previouse reset to APTrans and ExpMonth 18716
     *				GF 08/12/2003 - issue #22112 - performance
     *				MV 01/16/04 - #23513 - not deleting from bHQAT correctly
	 *				MV 05/05/08 - #128136 added cursor to bHQAT delete 
     *			    MV 07/21/08 - #128136 added cursor to bHQAT delete
     *              MV 07/22/08 - #128955 - check bAPRH before bHAQT delete
	 *				MV 06/01/09 - #133431 - delete attachments per issue #127603
     *				JonathanP 06/03/09 - #133431 - converted attachment deletion code to one statement.
	 *				GF 11/15/2012 TK-19414 SL Claim update claim header to pending status
     *
     *	Delete trigger for AP Transaction Batch Header Batch
     *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int, @co bCompany,@mth bMonth,
   	@batchid int, @seq int, @deleteflag int, @opencursor int
   	 
    
    select @numrows = @@rowcount, @deleteflag = 0, @opencursor = 0
    if @numrows = 0 return
    set nocount on
    
    --check for existing Batch Lines
    select @validcnt = count(*) from bAPLB l with (nolock)
    join deleted d on l.Co=d.Co and l.Mth=d.Mth and l.BatchId=d.BatchId and l.BatchSeq=d.BatchSeq
    if @validcnt > 0
    	begin
    	select @errmsg = 'Batch lines exist'
    	goto error
    	end   
    
    -- #133431 Delete attachments only if the unique attachment IDs do not exist in APTH, APUI, and APRH.
    insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		select h.AttachmentID, suser_name(), 'Y' 
		from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
		where d.UniqueAttchID not in(select t.UniqueAttchID from bAPTH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and
			  d.UniqueAttchID not in(select t.UniqueAttchID from bAPUI t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and
			  d.UniqueAttchID not in(select t.UniqueAttchID from bAPRH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)	and	
			  d.UniqueAttchID is not null        
   
    -- unlock existing AP trans - if they still exist
    update bAPTH
    set InUseMth = null, InUseBatchId = null
    from bAPTH h with (nolock) 
    join deleted d on d.Co = h.APCo and d.Mth = h.Mth and d.APTrans = h.APTrans
    
---- TK-19414 update claim header set back to pending
---- only care if the APHB action is 'A' - add and approval required
---- if from APUI then we do not want to reset claim status and certified
UPDATE dbo.vSLClaimHeader
		SET ClaimStatus = 10, CertifiedBy = NULL, CertifyDate = NULL
FROM dbo.vSLClaimHeader h
INNER JOIN dbo.bSLHD s ON s.SLCo = h.SLCo AND s.SL = h.SL
JOIN deleted d ON d.SLKeyID = h.KeyID
WHERE d.BatchTransType = 'A'
	AND s.ApprovalRequired = 'Y'
	AND NOT EXISTS(SELECT 1 FROM dbo.bAPUI i WHERE d.Co = i.APCo
				AND d.Mth = i.InUseMth AND d.BatchId = i.InUseBatchId
				AND i.UISeq = d.UISeq)



    -- unlock Unapproved Invoices - if they still exist
    update bAPUI
    set InUseMth = null, InUseBatchId = null
    from bAPUI i with (nolock) 
    join deleted d on d.Co = i.APCo and d.Mth = i.InUseMth and d.BatchId = i.InUseBatchId and i.UISeq = d.UISeq
     
    -- unlock Intercompany Invoices - if they still exist
    update bMSII
    set InUseAPCo = null, InUseBatchId = null
    from bMSII i with (nolock) 
    join deleted d on d.Co = i.InUseAPCo and d.Mth = i.Mth and d.BatchId = i.InUseBatchId     
   










   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Batch Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btAPHBi] on [dbo].[bAPHB] for INSERT as
/*--------------------------------------------------------------
* Created: SE 08/17/97
* Modified: KB 01/04/99
*			GG 08/14/01 - #14237 - added columns for MS Interco Invoices, cleanup
*			MV - 18878 Quoted identifier cleanup.
* 		 	DANF 03/15/05 - #27294 - Remove scrollable cursor.
*			GG 07/25/07 - #120561 - remove bHQCC insert, cleanup
*			MV 03/11/08 - #127347 International addresses
*			GG 06/06/08 - #128324 - removed State/Country validation
*
*	Insert trigger for AP Header Batch entries
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @co bCompany, @mth bMonth,
   	@batchid bBatchID, @trans bTrans, @uimth bMonth, @uiseq smallint,
   	@batchtranstype char(1), @rcode tinyint, @errtext varchar(60), @status tinyint,
   	@msco bCompany, @msinv varchar(10),@validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

if @numrows = 1
	select @co = Co, @mth = Mth, @batchid = BatchId, @trans = APTrans,
	@uimth = UIMth, @uiseq = UISeq, @batchtranstype = BatchTransType,
	@msco = MSCo, @msinv = MSInv
	from inserted
else
	begin
	-- use a cursor to process each inserted row
	declare bAPHB_insert cursor local fast_forward for
	select Co, Mth, BatchId, APTrans, UIMth, UISeq, BatchTransType, MSCo, MSInv
	from inserted

	open bAPHB_insert
	fetch next from bAPHB_insert into @co, @mth, @batchid, @trans, @uimth, @uiseq,
		@batchtranstype, @msco, @msinv

	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end
   
insert_check:
	--validate HQ Batch
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Entry', 'APHB', @errtext output, @status output
	if @rcode <> 0
		begin
		select @errmsg = @errtext, @rcode = 1
		goto error
  		end
	if @status <> 0
		begin
		select @errmsg = 'Must be an open batch'
		goto error
		end
	--validate Batch Trans Type
	if @batchtranstype not in ('A','C','D')
		begin
		select @errmsg = 'Transaction type must be ''A'',''C'', or ''D'' '
		goto error
		end
	if @batchtranstype = 'A' and @trans is not null
		begin
		select @errmsg = 'Transaction must be null with all ''add'' entries'
		goto error
		end
	if @batchtranstype in ('C','D') and @trans is null
		begin
		select @errmsg = 'Transaction cannot be null on ''change'' or ''delete'' entries'
		goto error
		end
		

--lock existing AP Trans pulled into batch for editing
update bAPTH
set InUseBatchId = @batchid, InUseMth = @mth
where APCo = @co and Mth = @mth and APTrans = @trans and @batchtranstype <> 'A'
and InUseBatchId is null and InUseMth is null
if @@rowcount = 0 and @batchtranstype <> 'A'
	begin
	select @errmsg = 'Unable to flag AP transaction as ''In Use''.'
	goto error
	end
--lock Unapproved Invoices added to batch for posting
update bAPUI
set InUseBatchId = @batchid, InUseMth = @mth
where APCo = @co and UIMth = @uimth and UISeq = @uiseq
and InUseBatchId is null and InUseMth is null
if @@rowcount = 0 and @uiseq is not null and @uimth is not null
	begin
	select @errmsg = 'Unable to flag AP Unapproved Invoice as ''In Use''.'
	goto error
	end
--lock MS Intercompany Invoices added to batch for posting
update bMSII
set InUseAPCo = @co, InUseBatchId = @batchid
where MSCo = @msco and MSInv = @msinv
and InUseAPCo is null and InUseBatchId is null and Mth = @mth
if @@rowcount = 0 and @msco is not null and @msinv is not null
	begin
	select @errmsg = 'Unable to flag MS Intercompany Invoice as ''In Use''.'
	goto error
	end
   
if @numrows > 1
	begin
	fetch next from bAPHB_insert into @co, @mth, @batchid, @trans, @uimth, @uiseq,
	@batchtranstype, @msco, @msinv

	if @@fetch_status = 0
		goto insert_check
	 else
		begin
		close bAPHB_insert
		deallocate bAPHB_insert
		end
	end

return

error:
	if @numrows > 1
		begin
		close bAPHB_insert
		deallocate bAPHB_insert
		end
   
	select @errmsg = @errmsg + ' - cannot insert AP Batch Header'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btAPHBu] on [dbo].[bAPHB] for UPDATE as
   

/*-----------------------------------------------------------------
*	Created : 8/26/98 EN
*	Modified : 8/26/98 EN
*				GG 08/14/01 - cleanup
*				MV 03/11/08	- #127347 International addresses
*				GG 06/06/08 - #128324 - removed State/Country validation
*
*	Update trigger for AP Header Batch entries
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int,@validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
--restrict primary key changes
select @validcnt = count(*)
from deleted d
join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
if @numrows <> @validcnt
	begin
	select @errmsg = 'Cannot change AP Co#, Month, Batch#, or Batch Seq#'
	goto error
	end

   --verify BatchTransType
   if update (BatchTransType)
   	begin
   	select @validcnt = count(*) from inserted where BatchTransType not in ('A','C','D')
   	if @validcnt > 0
   		begin
   		select @errmsg = 'Transaction type must be ''A'', ''C'', or ''D'''
   		goto error
   		end
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	where (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   		or (d.BatchTransType in ('C','D') and i.BatchTransType = 'A')
   	if @validcnt > 0
   		begin
   		select @errmsg = 'Cannot change Batch Transaction Type from ''C'' or ''D'' to ''A'', or ''A'' to ''C'' or ''D'''
   		goto error
   		end
   	end
	
return
   
error:
   	select @errmsg = @errmsg + ' - cannot update AP Batch Header!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
  
 



GO

GO

GO

GO

GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPHB].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[PrePaidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[PrePaidProcYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[V1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[PayOverrideYN]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPHB].[OldCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[OldPrePaidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[OldPrePaidProcYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[Old1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[OldPayOverrideYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[SeparatePayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[OldSeparatePayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[ChkRev]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPHB].[PaidYN]'
GO
