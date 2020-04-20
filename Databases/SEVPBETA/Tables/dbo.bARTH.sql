CREATE TABLE [dbo].[bARTH]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ARTrans] [dbo].[bTrans] NOT NULL,
[ARTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustRef] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RecType] [tinyint] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Contract] [dbo].[bContract] NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CheckNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Source] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[MSCo] [dbo].[bCompany] NULL,
[TransDate] [dbo].[bDate] NOT NULL,
[DueDate] [dbo].[bDate] NULL,
[DiscDate] [dbo].[bDate] NULL,
[CheckDate] [dbo].[bDate] NULL,
[Description] [dbo].[bDesc] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[CMDeposit] [dbo].[bCMRef] NULL,
[CreditAmt] [dbo].[bDollar] NOT NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[AppliedMth] [dbo].[bMonth] NULL,
[AppliedTrans] [dbo].[bTrans] NULL,
[Invoiced] [dbo].[bDollar] NOT NULL,
[Paid] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[AmountDue] [dbo].[bDollar] NOT NULL,
[PayFullDate] [dbo].[bDate] NULL,
[PurgeFlag] [dbo].[bYN] NOT NULL,
[EditTrans] [dbo].[bYN] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[InUseBatchID] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReasonCode] [dbo].[bReasonCode] NULL,
[ExcludeFC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARTH_ExcludeFC] DEFAULT ('N'),
[FinanceChg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARTH_FinanceChg] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udARTOPCID] [bigint] NULL,
[udPAYARTOPCID] [bigint] NULL,
[udPAYARTOPDID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[udCheckNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[udCMSContract] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[udMiscPayYN] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udRetgClearYN] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCVStoredProc] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[udRetgHistYN] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udHistYN] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udPaidMth] [smalldatetime] NULL,
[udPaidDate] [smalldatetime] NULL,
[udCashRcptsDate] [smalldatetime] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btARTHd    Script Date: 8/28/99 9:37:03 AM ******/
CREATE trigger [dbo].[btARTHd] on [dbo].[bARTH] for DELETE as

/*-----------------------------------------------------------------
*  Created:    JM 6/16/99
*  Modified:   JM 6/22/99 - Added HQMA insert.  Ref Issue 3852.
*		TJL 09/18/01 - Issue 14588, HQMA not being updated upon delete. Fixed.
*		TJL 09/27/01 - Issue 13931, Use ApplyMth and ApplyTrans to check for Existing Lines
*		TJL 05/14/09 - Issue #133432, Latest Attachment Delete process.
*
*  This trigger restricts deletion of any ARTH records if lines exist in ARTL.
*
*  Adds entry to HQ Master Audit table bHQMA if ARCO.AuditTrans = 'Y'
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

if exists(select * from bARTL a, deleted d
   	where a.ARCo = d.ARCo and a.ApplyMth=d.Mth and a.ApplyTrans=d.ARTrans)
   	begin
   	select @errmsg='Lines exist for this transaction'
   	goto error
   	end

-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h
join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
where d.UniqueAttchID is not null                               

/* Audit AR Transaction Header deletions only when PurgeFlag = 'N' */
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bARTH', 'ARCo: ' + isnull(convert(varchar(3),d.ARCo),'')
	+  ' Mth: ' + isnull(convert(varchar(8),d.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),d.ARTrans),''),
	d.ARCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
       FROM deleted d
join bARCO c ON d.ARCo = c.ARCo
where c.AuditTrans = 'Y' and d.PurgeFlag = 'N'
   
return
   
error:
select @errmsg = @errmsg + ' - cannot delete AR Transaction Header!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  
   CREATE trigger [dbo].[btARTHi] on [dbo].[bARTH] for INSERT as
   

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   /*--------------------------------------------------------------
   *
   *  Insert trigger for ARTH
   *  Created By: 	JRE
   *  Date:       	05/13/97
   *  Modified: 	JM 6/22/99 - Added HQMA insert.  Ref Issue 3852.
   *              	bc 09/12/00 changed JB source
   *		GG 11/30/00 - added MS source
   *		TJL 07/23/01 - Validate RecType
   *		TJL 09/18/01 - Issue #14382, Change Audit Type (RecType) from 'C' to 'A'
   *		TJL 11/29/01 - Issue #14449, Validate DueDate for original invoice transactions.  May not be null.
   *		TJL 04/30/03 - Issue #20936, Reverse Release Retainage
   *		GF 07/14/2003 - issue #21828 - speed improvements. Added with nolock
   *
   *--------------------------------------------------------------*/
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- Validate ARTransType
   select @validcnt = count(*) from inserted i
   where i.ARTransType in ('I','C','W','A','P','M','F','R','V')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Transaction Type must be one of: I,C,W,A,P,M,F,R,V'
   	goto error
   	end
   
   -- Validate Customer
   select @validcnt = count(*) from inserted i
   JOIN bARCM r with (nolock) ON i.CustGroup = r.CustGroup  and i.Customer = r.Customer
   select @nullcnt  = count(*) from inserted i where i.Customer is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Customer is Invalid'
   	goto error
   	end
   
   -- Validate Source
   select @validcnt = count(*) from inserted i
   where i.Source in ('AR Invoice','AR Receipt','ARFinanceC','SM Invoice', 'ARRelease', 'JB', 'MS')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Source '
   	goto error
   	end
   
   
   -- Validate AppliedTrans
   select @validcnt = count(*) from inserted i
   JOIN bARTH r with (nolock) ON i.ARCo = r.ARCo  and i.AppliedMth = r.Mth and i.AppliedTrans = r.ARTrans
   select @nullcnt = count(*) from inserted i where i.AppliedTrans is null
   if @validcnt+@nullcnt <> @numrows
   	begin
   	select @errmsg = 'AppliedTrans is Invalid '
   	goto error
   	end
   
   -- Validate Contract
   select @validcnt = count(*) from inserted i
   JOIN bJCCM r with (nolock) ON i.JCCo = r.JCCo and i.Contract = r.Contract
   select @nullcnt = count(*) from  inserted i where i.Contract is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Contract is Invalid '
   	goto error
   	end
   
   -- Validate CMAcct
   select @validcnt = count(*) from inserted i
   JOIN bCMAC r with (nolock) ON i.CMCo = r.CMCo and i.CMAcct = r.CMAcct
   select @nullcnt = count(*) from  inserted i where i.CMAcct is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'CMAcct is Invalid '
   	goto error
   	end
   
   -- Validate CM Reference
   select @validcnt = count(*) from inserted i
   JOIN bCMDT r with (nolock) ON i.CMCo = r.CMCo and i.CMAcct = r.CMAcct and i.CMDeposit=r.CMRef and r.CMTransType = 2
   WHERE StmtDate is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'CM Reference is invalid, statement has been cleared'
   	goto error
   	end
   
   -- Validate RecType
   select @validcnt = count(*) from inserted i
   JOIN bARRT t with (nolock) ON i.ARCo = t.ARCo and  i.RecType = t.RecType
   select @nullcnt = count(*) from  inserted i where i.RecType is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'RecType is Invalid '
   	goto error
   	end
   
   -- Validate Payment terms
   select @validcnt = count(*)from inserted i
   JOIN bHQPT r with (nolock) ON i.PayTerms = r.PayTerms
   select @nullcnt = count(*) from  inserted i where i.PayTerms is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Payment terms is Invalid '
   	goto error
   	end
   
   --  Validate DueDate. Cannot be null on original invoices 
   select @nullcnt = count(*) from inserted i 
   where i.ARTransType in ('I', 'F', 'R') and i.AppliedMth = i.Mth and i.AppliedTrans = i.ARTrans and i.DueDate is null
   if @nullcnt <> 0
   	begin
   	select @errmsg = 'DueDate may not be NULL on original invoice transactions!'
   	goto error
   	end
   
   -- Audit inserts
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bARTH','ARCo: ' + isnull(convert(varchar(3),i.ARCo),'') + ' Mth: ' + isnull(convert(varchar(8), i.Mth,1),'')
   		 + ' ARTrans: ' + isnull(convert(varchar(6), i.ARTrans),''), i.ARCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bARCO c with (nolock) on c.ARCo = i.ARCo
   where i.ARCo = c.ARCo and c.AuditTrans = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert into ARTH'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  
   CREATE trigger [dbo].[btARTHu] on [dbo].[bARTH] for UPDATE as
   

/*--------------------------------------------------------------
   *
   *  UPDATE trigger for ARTH
   *  Created By: 	JRE  05/13/97
   *  Modified: 	JRE  05/07/99  added update checks so we can change the InUseFlag
   *  	      	JM 6/22/99 - Added HQMA insert.  Ref Issue 3852.
   *            	GH 07/7/99 Changed CMRef check, was checking CMRef when not needed.
   *            	bc 09/12/00 changed JB source name
   *		GG 11/30/00 - Added MS source
   *		TJL 07/23/01 - Validate RecType
   *		TJL 09/18/01 - Issue #14589, Modify HQMA Audit to utilize PurgeFlag consistent with bARTL update trigger
   *           			Modify HQMA Audit to 'distinct', insert single entry rather than duplicate entries
   *		TJL 11/29/01 - Issue #14449, Validate DueDate for original invoice transactions.  May not be null.
   *		TJL 04/30/03 - Issue #20936, Reverse Release Retainage
   *		TJL 05/05/03 - Issue #21203, Arithmetic errors when inserting large dollar values into HQMA
   *		GF 07/14/2003 - issue #21828 - speed improvements. nolocks, check updates for auditing, remmed out auditing
   *									   BatchId, InUseBatchId.
   *		TJL 12/29/04 - Issue #26488, Not auditing some fields going from NULL to Something or Something to NULL
   *		TJL 10/06/05 - Issue #29571, No HQMA auditing for Invoiced, Paid, Retainage, DiscTaken, AmountDue, PayFullDate
   *		JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
   *
   *--------------------------------------------------------------*/
   
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
   	@errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   
   set nocount on
      
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bARTH', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
   -- Change to ARCo, Mth, ARTrans, CustGroup, Customer, Source, CMCo, CMAcct, CMRef, Applied Trans
   
   if Update(ARCo)
   	begin
   	select @errmsg = 'ARCo may not be updated'
   	goto error
   	end
   if Update(Mth)
   	begin
   	select @errmsg = 'Transaction Month may not be updated'
   	goto error
   	end
   if Update(ARTrans)
   	begin
   	select @errmsg = 'Transaction # may not be updated'
   	goto error
   	end
   if Update(ARTransType)
   	begin
   	select @errmsg = 'Transaction Type may not be updated'
   	goto error
   	end
   
   -- Validate Contract
   if Update(JCCo) or Update(Contract)
   	begin  -- cant update if detail lines exist
   	select @validcnt=count(*) from bARTL a with (nolock) 
   	join inserted i on i.ARCo=a.ARCo and i.Mth=a.Mth and i.ARTrans=a.ARTrans
   	join deleted d on d.ARCo=a.ARCo and d.Mth=a.Mth and d.ARTrans=a.ARTrans
   	where (i.JCCo<>d.JCCo or i.Contract<>d.Contract)
   	if @validcnt <>0
   		begin
   		select @errmsg = 'Contract # may not be updated'
   		goto error
   		end
   	end
   
   -- can't change customer if not an original transaction or any other transaction applies to this one
   
   if Update(CustGroup) or Update(Customer)
   	begin -- cant update if detail lines exist
   	select @validcnt=count(*) from bARTL a with (nolock) 
   	join inserted i on i.ARCo=a.ARCo and i.Mth=a.Mth and i.ARTrans=a.ARTrans
   	join deleted d on d.ARCo=a.ARCo and d.Mth=a.Mth and d.ARTrans=a.ARTrans
   	where (i.CustGroup<>d.CustGroup or i.Customer<>d.Customer)
   	if @validcnt <>0
   		begin
   		select @errmsg = 'Customer # may not be updated'
   		goto error
   		end
   	end
   
   -- Validate ARTransType
   if update(ARTransType)
   	begin
   	select @validcnt = count(*) from inserted i
   	where i.ARTransType in ('I','C','W','A','P','M','F','R','V')
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Transaction Type must be one of: I,C,W,A,P,M,F,R,V'
   		goto error
   		end
   	end
   
   -- Validate Customer
   if update(CustGroup) or Update(Customer)
   	begin
   	select @validcnt = count(*) from inserted i
   	JOIN bARCM r with (nolock) ON i.CustGroup = r.CustGroup  and i.Customer = r.Customer
   	select @nullcnt  = count(*) from inserted i  where i.Customer is null
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Customer is Invalid'
   		goto error
   		end
   	end
   
   -- Validate Source
   if update(Source)
   	begin
   	select @validcnt = count(*) from inserted i
   	where i.Source in ('AR Invoice','AR Receipt','ARFinanceC','ARRelease','SM Invoice','JB', 'MS')
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Source'
   		goto error
   		end
   	end
   
   
   -- Validate AppliedTrans
   if update(AppliedMth) or update(AppliedTrans)
   	begin
   	select @validcnt = count(*) from inserted i
   	JOIN bARTH r with (nolock) ON i.ARCo = r.ARCo  and i.AppliedMth = r.Mth and i.AppliedTrans = r.ARTrans
     	select @nullcnt = count(*) from inserted i where i.AppliedTrans is null
     	if @validcnt+@nullcnt <> @numrows
     		begin
   		select @errmsg = 'AppliedTrans is Invalid '
        	goto error
        	end
     	end
   
   
   -- Validate CMAcct
   if update(CMCo) or update(CMAcct) or update(CMDeposit)
   	begin
   	select @validcnt = count(*) from inserted i
    	JOIN bCMAC r with (nolock) ON i.CMCo = r.CMCo and i.CMAcct = r.CMAcct
   	select @nullcnt = count(*) from  inserted i where i.CMAcct is null
     	if @validcnt + @nullcnt <> @numrows
        	begin
        	select @errmsg = 'CMAcct is Invalid '
        	goto error
        	end
     	end
   
   
   -- Validate CM Reference
   if update(CheckNo) or update(CMCo) or update(CMAcct) or update(CreditAmt)
   	begin
     	select @validcnt = count(*) from deleted d, inserted i
     	JOIN bCMDT r with (nolock) ON i.CMCo = r.CMCo and i.CMAcct = r.CMAcct and i.CMDeposit=r.CMRef and r.CMTransType = 2
    	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     		and i.CreditAmt <> d.CreditAmt and StmtDate is not null
     	if @validcnt <> 0
        	begin
        	select @errmsg = 'CM Reference is invalid, statement has been cleared'
        	goto error
        	end
     	end
   
   -- Validate RecType
   if update(RecType)
   	begin
   	select @validcnt = count(*) from inserted i
   	JOIN bARRT t with (nolock) ON i.ARCo = t.ARCo and  i.RecType = t.RecType
   	select @nullcnt = count(*) from  inserted i where i.RecType is null
    	if @validcnt + @nullcnt <> @numrows
       	begin
       	select @errmsg = 'RecType is Invalid '
       	goto error
       	end
    	end
   
   -- Validate Payment terms
   if update(PayTerms)
   	begin
     	select @validcnt = count(*) from inserted i
    	JOIN bHQPT r with (nolock) ON i.PayTerms = r.PayTerms
     	select @nullcnt = count(*) from  inserted i where i.PayTerms is null
     	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Payment terms is Invalid '
   		goto error
   		end
     	end
   
   --  Validate DueDate. Cannot be null on original invoices
   if update(DueDate)
   	begin
    	select @nullcnt = count(*) from inserted i where i.ARTransType in ('I', 'F', 'R') and i.AppliedMth = i.Mth
   	and i.AppliedTrans = i.ARTrans and i.DueDate is null
    	if @nullcnt <> 0
   	    begin
   	    select @errmsg = 'DueDate may not be NULL on original invoice transactions!'
   	    goto error
   	    end
   	end
   
   
   -- HQMA Inserts
   -- skip if auditing turned off or purging records
   if not exists (select * from inserted i join bARCO a with (nolock) on i.ARCo=a.ARCo where i.ARCo=a.ARCo 
   			and a.AuditTrans = 'Y' and i.PurgeFlag = 'N')
      	return
   
   if update(ARTransType)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'ARTransType', d.ARTransType, i.ARTransType, 	getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.ARTransType, '') <> isnull(d.ARTransType,'') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CustGroup)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CustGroup', convert(varchar(6),d.CustGroup), convert(varchar(6),i.CustGroup), getdate(), SUSER_SNAME()
     	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CustGroup, 0) <> isnull(d.CustGroup, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Customer)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'Customer', convert(varchar(6),d.Customer), convert(varchar(6),i.Customer), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.Customer, 0) <> isnull(d.Customer, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CustRef)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CustRef', d.CustRef, i.CustRef, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CustRef, '') <> isnull(d.CustRef, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(RecType)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'RecType', convert(varchar(6),d.RecType), convert(varchar(6),i.RecType), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.RecType, 0) <> isnull(d.RecType, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(JCCo)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'JCCo', convert(varchar(6),d.JCCo), convert(varchar(6),i.JCCo), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.JCCo, 0) <> isnull(d.JCCo, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Contract)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'Contract', d.Contract, i.Contract, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.Contract, '') <> isnull(d.Contract, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Invoice)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'Invoice', d.Invoice, i.Invoice, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.Invoice, '') <> isnull(d.Invoice, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CheckNo)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CheckNo', d.CheckNo, i.CheckNo, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CheckNo, '') <> isnull(d.CheckNo, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Source)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'Source', d.Source, i.Source, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.Source, '') <> isnull(d.Source, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(TransDate)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'TransDate', convert(varchar(12),d.TransDate), convert(varchar(12),i.TransDate), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.TransDate, '') <> isnull(d.TransDate, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(DueDate)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'DueDate', convert(varchar(12),d.DueDate), convert(varchar(12),i.DueDate), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.DueDate, '') <> isnull(d.DueDate, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(DiscDate)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'DiscDate', convert(varchar(12),d.DiscDate), convert(varchar(12),i.DiscDate), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.DiscDate, '') <> isnull(d.DiscDate, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CheckDate)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CheckDate', convert(varchar(12),d.CheckDate), convert(varchar(12),i.CheckDate), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CheckDate, '') <> isnull(d.CheckDate, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(Description)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.Description, '') <> isnull(d.Description, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CMCo)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CMCo', convert(varchar(6),d.CMCo), convert(varchar(6),i.CMCo), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CMCo, 0) <> isnull(d.CMCo, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CMAcct)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CMAcct', convert(varchar(12),d.CMAcct), convert(varchar(12),i.CMAcct), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CMAcct, '') <> isnull(d.CMAcct, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CMDeposit)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CMDeposit', convert(varchar(12),d.CMDeposit), convert(varchar(12),i.CMDeposit), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.CMDeposit, '') <> isnull(d.CMDeposit, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(CreditAmt)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'CreditAmt', convert(varchar(16),d.CreditAmt), convert(varchar(16),i.CreditAmt), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and i.CreditAmt <> d.CreditAmt and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(PayTerms)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'PayTerms', d.PayTerms, i.PayTerms, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.PayTerms, '') <> isnull(d.PayTerms,'') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(AppliedMth)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'AppliedMth', convert(varchar(12),d.AppliedMth), convert(varchar(12),i.AppliedMth), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.AppliedMth, '') <> isnull(d.AppliedMth, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(AppliedTrans)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'AppliedTrans', convert(varchar(12),d.AppliedTrans), convert(varchar(12),i.AppliedTrans), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.AppliedTrans, 0) <> isnull(d.AppliedTrans, 0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
  --  if update(Invoiced)
  --  BEGIN
  --  	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
  --    	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
  --    	'C', 'Invoiced', convert(varchar(16),d.Invoiced), convert(varchar(16),i.Invoiced), getdate(), SUSER_SNAME()
  --     	from inserted i, deleted d, ARCO a with (nolock) 
  --     	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
  --    	and i.Invoiced <> d.Invoiced and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
  --  END
   
  --  if update(Paid)
  --  BEGIN
  --  	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
  --    	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
  --    	'C', 'Paid', convert(varchar(16),d.Paid), convert(varchar(16),i.Paid), getdate(), SUSER_SNAME()
  --     	from inserted i, deleted d, ARCO a with (nolock) 
  --     	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
  --    	and i.Paid <> d.Paid and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
  --  END
   
  --  if update(Retainage)
  --  BEGIN
  --  	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
  --    	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
  --    	'C', 'Retainage', convert(varchar(16),d.Retainage), convert(varchar(16),i.Retainage), getdate(), SUSER_SNAME()
  --     	from inserted i, deleted d, ARCO a with (nolock) 
  --     	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
  --    	and i.Retainage <> d.Retainage and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
  --  END
   
  --  if update(DiscTaken)
  --  BEGIN
  --  	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
  --    	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
  --    	'C', 'DiscTaken', convert(varchar(16),d.DiscTaken), convert(varchar(16),i.DiscTaken), getdate(), SUSER_SNAME()
  --     	from inserted i, deleted d, ARCO a with (nolock) 
  --     	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
  --    	and i.DiscTaken <> d.DiscTaken and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
  --  END
   
  --  if update(AmountDue)
  --  BEGIN
  --  	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
  --    	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
  --    	'C', 'AmountDue', convert(varchar(16),d.AmountDue), convert(varchar(16),i.AmountDue), getdate(), SUSER_SNAME()
  --     	from inserted i, deleted d, ARCO a with (nolock) 
  --     	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
  --    	and i.AmountDue <> d.AmountDue and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
  --  END
   
  --  if update(PayFullDate)
  --  BEGIN
  --  	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
  --    	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
  --    	'C', 'PayFullDate', convert(varchar(12),d.PayFullDate), convert(varchar(12),i.PayFullDate), getdate(), SUSER_SNAME()
  --     	from inserted i, deleted d, ARCO a with (nolock) 
  --     	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
  --    	and isnull(i.PayFullDate, '') <> isnull(d.PayFullDate, '') and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
  --  END
   
   if update(PurgeFlag)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'PurgeFlag', d.PurgeFlag, i.PurgeFlag, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and i.PurgeFlag <> d.PurgeFlag and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   IF update(EditTrans)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + isnull(convert(char(3),i.ARCo),'') + ' Mth: ' +
     	isnull(convert(varchar(8),i.Mth,1),'') + ' ARTrans: ' + isnull(convert(varchar(6),i.ARTrans),''), i.ARCo,
     	'C', 'EditTrans', d.EditTrans, i.EditTrans, getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and i.EditTrans <> d.EditTrans and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   /*
   -- we don't audit the BatchId and InUseBatchID, considered a system function - GF
   if update(BatchId)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + convert(char(3),i.ARCo) + ' Mth: ' +
     	convert(varchar(8),i.Mth,1) + ' ARTrans: ' + convert(varchar(6),i.ARTrans), i.ARCo,
     	'C', 'BatchId', convert(varchar(12),d.BatchId), convert(varchar(12),i.BatchId), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and i.BatchId <> d.BatchId and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   
   if update(InUseBatchID)
   BEGIN
   	insert into bHQMA select distinct 'bARTH', 'ARCo: ' + convert(char(3),i.ARCo) + ' Mth: ' +
     	convert(varchar(8),i.Mth,1) + ' ARTrans: ' + convert(varchar(6),i.ARTrans), i.ARCo,
     	'C', 'InUseBatchID', convert(varchar(12),d.InUseBatchID), convert(varchar(12),i.InUseBatchID), getdate(), SUSER_SNAME()
      	from inserted i, deleted d, ARCO a with (nolock) 
      	where i.ARCo = d.ARCo and i.Mth = d.Mth and i.ARTrans = d.ARTrans
     	and isnull(i.InUseBatchID,0) <> isnull(d.InUseBatchID,0) and a.AuditTrans = 'Y' and i.PurgeFlag = 'N'
   END
   */
   
Trigger_Skip:
   
   return
   
   error:
        select @errmsg = @errmsg + ' - cannot update AR Transaction Header'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
  
  
 



GO
CREATE NONCLUSTERED INDEX [biARTHApplied] ON [dbo].[bARTH] ([ARCo], [AppliedMth], [AppliedTrans]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARTHTrans] ON [dbo].[bARTH] ([ARCo], [ARTrans]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARTHCustomer] ON [dbo].[bARTH] ([ARCo], [CustGroup], [Customer]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARTHInvoice] ON [dbo].[bARTH] ([ARCo], [Invoice]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARTH] ON [dbo].[bARTH] ([ARCo], [Mth], [ARTrans]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARTH] ([KeyID]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARTHudARTOPCID] ON [dbo].[bARTH] ([udARTOPCID]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biARTHudPAYARTOPCID] ON [dbo].[bARTH] ([udPAYARTOPCID]) WITH (FILLFACTOR=90, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brARTransType]', N'[dbo].[bARTH].[ARTransType]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bARTH].[CMAcct]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARTH].[CreditAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARTH].[Invoiced]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARTH].[Paid]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARTH].[Retainage]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARTH].[DiscTaken]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARTH].[AmountDue]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARTH].[PurgeFlag]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bARTH].[PurgeFlag]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARTH].[EditTrans]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARTH].[ExcludeFC]'
GO
