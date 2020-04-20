CREATE TABLE [dbo].[bARBH]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[TransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[Source] [dbo].[bSource] NOT NULL,
[ARTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[RecType] [tinyint] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Contract] [dbo].[bContract] NULL,
[CustRef] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Invoice] [char] (10) COLLATE Latin1_General_BIN NULL,
[CheckNo] [char] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[MSCo] [dbo].[bCompany] NULL,
[TransDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[DiscDate] [dbo].[bDate] NULL,
[CheckDate] [dbo].[bDate] NULL,
[AppliedMth] [dbo].[bMonth] NULL,
[AppliedTrans] [dbo].[bTrans] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[CMDeposit] [dbo].[bCMRef] NULL,
[CreditAmt] [dbo].[bDollar] NULL CONSTRAINT [DF_bARBH_CreditAmt] DEFAULT ((0)),
[PayTerms] [dbo].[bPayTerms] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[oldCustRef] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[oldCustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[oldInvoice] [char] (10) COLLATE Latin1_General_BIN NULL,
[oldCheckNo] [char] (10) COLLATE Latin1_General_BIN NULL,
[oldDescription] [dbo].[bDesc] NULL,
[oldMSCo] [dbo].[bCompany] NULL,
[oldTransDate] [dbo].[bDate] NULL,
[oldDueDate] [dbo].[bDate] NULL,
[oldDiscDate] [dbo].[bDate] NULL,
[oldCheckDate] [dbo].[bDate] NULL,
[oldCMCo] [dbo].[bCompany] NULL,
[oldCMAcct] [dbo].[bCMAcct] NULL,
[oldCMDeposit] [dbo].[bCMRef] NULL,
[oldCreditAmt] [dbo].[bDollar] NULL,
[oldPayTerms] [dbo].[bPayTerms] NULL,
[ReasonCode] [dbo].[bReasonCode] NULL,
[oldReasonCode] [dbo].[bReasonCode] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[oldRecType] [tinyint] NULL,
[oldJCCo] [dbo].[bCompany] NULL,
[oldContract] [dbo].[bContract] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btARBHd    Script Date: 8/28/99 9:37:01 AM ******/
   
CREATE  trigger [dbo].[btARBHd] ON [dbo].[bARBH] for DELETE as

declare @errmsg varchar(255), @validcnt int , @validcnt2 int
/*-----------------------------------------------------------------
 *	This trigger rejects delete in bARBH (AR Batch Header)
 *	 IF the following error condition EXISTS:
 *
 *		entries exist in ARBL - except for cash receipt
 *
 *    CJW 5/23/97
 *  Mod: JRE 2/2/99 - added bARBL.BatchId = deleted.BatchId in join
 *  Mod: JRE 4/28/98 - delete payment lines when payment header is deleted.
 *  Mod: DH 8/13/98 - Mth missing from 'lines exist' check
 *  Mod: bc 8/21/98 - Need type 'M' and 'R' in here
 *  Mod: TV 03/21/02 - Delete HQAT record...
 *  General Modification:  bc 01/27/99
 *	TJL 09/07/06 - Issue #122416, Fix Batch Clear taking too long on Large Batches
 *	TJL 05/14/09 - Issue #133432, Latest Attachment Delete process.
 *
 *----------------------------------------------------------------*/
declare  @errno   int, @numrows int
SELECT @numrows = @@rowcount
IF @numrows = 0 return
set nocount on
   
begin
/*--------------------------------------*/
/* check ARBL							*/
/*--------------------------------------*/

/* if a payment, misc cash receipt or retainage type header then delete the the lines */
DELETE FROM bARBL
from bARBL l, deleted d
where l.Co = d.Co and l.Mth = d.Mth and l.BatchId = d.BatchId and l.BatchSeq = d.BatchSeq and
   (d.ARTransType='P' or d.ARTransType = 'M' or d.ARTransType = 'R')
   
   
IF EXISTS (SELECT * FROM deleted
	JOIN bARBL ON bARBL.Co = deleted.Co and bARBL.Mth = deleted.Mth and bARBL.BatchId = deleted.BatchId
		and bARBL.BatchSeq = deleted.BatchSeq
	where deleted.TransType = 'A')
		BEGIN
		SELECT @errmsg = 'Lines exist'
		goto error
		END
   
/*--------------------------------------*/
/* check ARBM							*/
/*--------------------------------------*/
IF EXISTS (SELECT * FROM deleted
	JOIN bARBM ON bARBM.Co = deleted.Co and bARBM.Mth = deleted.Mth
		and bARBM.BatchId=deleted.BatchId and bARBM.BatchSeq = deleted.BatchSeq
	where deleted.TransType = 'A')
		Begin
		select @errmsg = 'Miscellaneous Distributions exists'
		goto error
		END
   
select @validcnt2 = count(*)
from deleted d, bARTH h
where d.Co=h.ARCo and d.Mth = h.Mth and d.ARTrans=h.ARTrans
   
update bARTH
set InUseBatchID=null from bARTH h, deleted d
where d.Co=h.ARCo and d.Mth = h.Mth and d.ARTrans=h.ARTrans
   
if @@rowcount<>@validcnt2
	begin
	select @errmsg = 'Unable to remove InUse Flag from AR Header.'
	goto error
	end

/*select @errmsg = convert(varchar(25),@@rowcount)goto error*/
/*select @validcnt = count(*) from deleted where TransType <> 'C'*/
   
-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h 
join deleted d on h.UniqueAttchID = d.UniqueAttchID
where h.UniqueAttchID not in(select t.UniqueAttchID 
	from bARTH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and d.UniqueAttchID is not null     
  
return
   
error:
   
SELECT @errmsg = @errmsg + ' - cannot delete AR Transaction!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
end
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btARBHi    Script Date: 8/28/99 9:37:01 AM ******/
CREATE trigger [dbo].[btARBHi] on [dbo].[bARBH] for INSERT as

/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255),
	@validcnt int, @validcnt2 int
   
/*--------------------------------------------------------------
*
*  Update trigger for ARBH
*  Created By:  CJW	 05/26/97
*  Modified:  
*
*
*--------------------------------------------------------------*/

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* validate batch */
select @validcnt = count(*) 
from bHQBC r
join inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
if @validcnt<>@numrows
	begin
	select @errmsg = 'Invalid Batch ID#'
	goto error
	end

select @validcnt = count(*) 
from bHQBC r
join inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and not r.BatchId is null
if @validcnt<>@numrows
	begin
	select @errmsg = 'Batch In Use, name must first be updated.'
	goto error
	end
   
select @validcnt = count(*) 
from bHQBC r
join inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and r.Status=0
if @validcnt<>@numrows
	begin
	select @errmsg = 'Must be an open batch.'
	goto error
	end
   
select @validcnt = count(*) 
from inserted 
where TransType<> 'A'
   
update bARTH
set InUseBatchID=i.BatchId 
from bARTH r, inserted i
where i.Co=r.ARCo and i.Mth = r.Mth and i.ARTrans=r.ARTrans and TransType<>'A'
select @validcnt2 = @@rowcount
if @validcnt2 <> @validcnt
	begin
	select @errmsg = 'Unable to flag AR Trans as *In Use*.'
	goto error
	end

/* Let Trigger on ARBL=set inuse flag on ARTL */
   
return
   
error:
	select @errmsg = @errmsg + ' - cannot insert ARBH'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
  
 




GO
ALTER TABLE [dbo].[bARBH] WITH NOCHECK ADD CONSTRAINT [CK_bARBH_ARTransType] CHECK (([ARTransType]='A' OR [ARTransType]='C' OR [ARTransType]='F' OR [ARTransType]='I' OR [ARTransType]='M' OR [ARTransType]='P' OR [ARTransType]='R' OR [ARTransType]='V' OR [ARTransType]='W'))
GO
ALTER TABLE [dbo].[bARBH] WITH NOCHECK ADD CONSTRAINT [CK_bARBH_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000) OR [CMAcct] IS NULL))
GO
ALTER TABLE [dbo].[bARBH] WITH NOCHECK ADD CONSTRAINT [CK_bARBH_oldCMAcct] CHECK (([oldCMAcct]>(0) AND [oldCMAcct]<(10000) OR [oldCMAcct] IS NULL))
GO
CREATE NONCLUSTERED INDEX [biARBHCustomer] ON [dbo].[bARBH] ([Co], [CustGroup], [Customer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARBHInvoice] ON [dbo].[bARBH] ([Co], [Invoice]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBH] ON [dbo].[bARBH] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARBH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
