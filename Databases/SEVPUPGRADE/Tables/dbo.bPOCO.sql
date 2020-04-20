CREATE TABLE [dbo].[bPOCO]
(
[POCo] [dbo].[bCompany] NOT NULL,
[AutoPO] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AutoPO] DEFAULT ('N'),
[LastPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CmtdDetailToJC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_CmtdDetailToJC] DEFAULT ('Y'),
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditPOs] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReceiptUpdate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_ReceiptUpdate] DEFAULT ('N'),
[GLAccrualAcct] [dbo].[bGLAcct] NULL,
[GLRecExpInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPOCO_GLRecExpInterfacelvl] DEFAULT ((0)),
[GLRecExpSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLRecExpDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RecJCInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPOCO_RecJCInterfacelvl] DEFAULT ((0)),
[RecEMInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPOCO_RecEMInterfacelvl] DEFAULT ((0)),
[RecINInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPOCO_RecINInterfacelvl] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[AuditPOCompliance] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AuditPOCompliance] DEFAULT ('N'),
[PayTypeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_PayTypeYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AuditPOReceipts] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AuditPOReceipts] DEFAULT ('N'),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AttachBatchReportsYN] DEFAULT ('N'),
[QuoteReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[PurchaseReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[Threshold] [dbo].[bDollar] NULL,
[ThresholdReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[AutoRQ] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AutoRQ] DEFAULT ('N'),
[LastRQ] [dbo].[bRQ] NOT NULL CONSTRAINT [DF_bPOCO_LastRQ] DEFAULT ('N'),
[ApprforQuote] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_ApprforQuote] DEFAULT ('N'),
[ApprforPurchase] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_ApprforPurchase] DEFAULT ('N'),
[AuditRQ] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AuditRQ] DEFAULT ('N'),
[AuditReview] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AuditReview] DEFAULT ('N'),
[AuditQuote] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_AuditQuote] DEFAULT ('N'),
[ByPassTriggers] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCO_ByPassTriggers] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 CREATE  trigger [dbo].[btPOCOd] on [dbo].[bPOCO] for DELETE as
/*----------------------------------------------------------
* Created: ??
* Modified:		DC 12/03/08 #130129  -Combine RQ and PO into a single module
*
*	This trigger rejects delete of bPOCO (Companies) if a
*	dependent record is found in:
*
*		POHD PO Header
*
*	Adds HQ Master Audit entry.
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check PO Header */
if exists(select top 1 1 from dbo.bPOHD s (nolock) join deleted d on s.POCo = d.POCo)
	begin
	select @errmsg = 'Purchase Orders exist'
	goto error
	end
	
--DC #130129
/* check RQ Header */
if exists(select top 1 1 from deleted d join dbo.bPOHD a (NOLOCK) on a.POCo = d.POCo)
	begin
	select @errmsg = 'RQ Requistions exist'
	goto error
	end
/* check RQ Quote */
if exists(select top 1 1 from deleted d join dbo.bPOHD a (NOLOCK) on a.POCo = d.POCo)
	begin
	select @errmsg = 'RQ Quotes exist'
	goto error
	end

/* Audit PO Company deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPOCO', 'PO Co#: ' + convert(varchar(3),POCo), POCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted
   
return

error:
	select @errmsg = @errmsg + ' - cannot delete PO Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btPOCOi] on [dbo].[bPOCO] for INSERT as
/*-----------------------------------------------------------------
* Created: ??
* Modifed: GG 04/20/07 - #30116 - data security review
*			  TRL 02/18/08 --#21452	
*				DC 12/03/08 #130129 - Combine RQ and PO into a single module
*
*	This trigger rejects insertion in bPOCO (Companies) if the
*	following error condition exists:
*
*		Invalid HQ Company number
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate HQ Company */
select @validcnt = count(*) from dbo.bHQCO c (nolock) join inserted i on c.HQCo = i.POCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid PO Company#, must be setup in HQ first'
	goto error
	end
	
--DC #130129	
if exists(select top 1 0 from inserted where LastRQ is not null and isnumeric(LastRQ)=0)
	begin
	select @errmsg = 'Invalid Last RQ - must be numeric or null'
	goto error
	end
--Validate positive numeric threshold value was entered
if exists(select top 1 0 from inserted where Threshold is not null and (isnumeric(Threshold)=0 or Threshold < 0))
	begin
	select @errmsg = 'Invalid Threshold - must be a positive numeric or null.'
	goto error
	end
--if a threshold is being inserted, verify a Threshold reviewer has been setup as well
if exists(select top 1 0 from inserted where Threshold is not null and ThresholdReviewer is null)
	begin
	select @errmsg = 'Threshold Reviewer must be entered when Threshold has been set.'
	goto error
	end

/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPOCO',  'PO Co#: ' + convert(char(3), POCo), POCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPOCO',  'PO Co#: ' + convert(char(3), POCo), POCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bPOCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bPOCo', i.POCo, i.POCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bPOCo' and s.Qualifier = i.POCo 
						and s.Instance = convert(char(30),i.POCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = @errmsg + ' - cannot insert PO Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPOCOu    Script Date: 8/28/99 9:38:06 AM ******/
   CREATE    trigger [dbo].[btPOCOu] on [dbo].[bPOCO] for UPDATE as
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bPOCO (PO Companies) if the
    *	following error condition exists: Cannot change PO Company
    *  Modified 11/28/01 DANF - Updated Aduti for addtional columns in POCO table.
    *			 MV - 05/16/03 - #18763 audit for PayTypeYN
    *			 MV - 01/27/05 - #26879 - audit change to 'Audit PO Compliance' flag	
	*			  TRL 02/18/08 --#21452	
	*			DC 10/21/08 --#128052  - Remove CmtdDetailToJC reference
	*			DC 12/3/08 #130129 - Combine RQ and PO into a single module
	*			DC 05/19/09 - #133612 - Permission error on bPOCO when app role security is turned on
	*			GF 03/19/2012 TK-13469 #146094 need to set @numrows first
	*
    *
    *	Adds record to HQ Master Audit.
    */----------------------------------------------------------------
	declare @errmsg varchar(255), @numrows int, @validcount int, @validcount2 int
	
	----TK-13469 #146094
	select @numrows = @@rowcount
	if @numrows = 0 return
	set nocount ON
	
	--DC #133612
	if (select ByPassTriggers from deleted) = 'Y' return

	/* check for key changes */
	select @validcount = count(*) from deleted d, inserted i
	where d.POCo = i.POCo
	if @validcount <> @numrows
		begin
		select @errmsg = 'Cannot change PO Company'
		goto error
		end

	--DC #130129		
    /* Validate Last RQ */
    if exists(select top 1 0 from inserted where LastRQ is not null and isnumeric(LastRQ)=0)
    	begin
    	select @errmsg = 'Invalid Last RQ - must be numeric or null'
    	goto error
    	end    
    --Validate positive numeric threshold value was entered
    if exists(select top 1 0 from inserted where Threshold is not null and (isnumeric(Threshold)=0 or Threshold < 0))
    	begin
    	select @errmsg = 'Invalid Threshold - must be a positive numeric or null.'
    	goto error
    	end    
    --If a threshold is being inserted, verify a Threshold reviewer has been setup as well
    if exists(select top 1 0 from inserted where Threshold is not null and ThresholdReviewer is null)
    	begin
    	select @errmsg = 'Threshold Reviewer must be entered when Threshold has been set.'
    	goto error
    	end	
		
	/* validate AuditCoParams */
	select @validcount = count(*) from inserted where AuditCoParams = 'Y'
	if @validcount <> @numrows
		begin
		select @errmsg = 'Option to audit company parameters must be checked.'
		goto error
		end
   	   	
   /* HQMA audit posting */   
   IF UPDATE(AutoPO)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Auto PO', d.AutoPO, i.AutoPO,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.AutoPO <> d.AutoPO
   end
   
	--DC #130129
	IF UPDATE(LastPO)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Last PO',d.LastPO,i.LastPO,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.LastPO,0) <> isnull(d.LastPO,0)
    END    
      
   IF UPDATE(AuditPOs)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Audit POs', d.AuditPOs, i.AuditPOs,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.AuditPOs <> d.AuditPOs
   end
   
   /*--DC #128052
   IF UPDATE(CmtdDetailToJC)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Committed Detail to JC', d.CmtdDetailToJC, i.CmtdDetailToJC,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.CmtdDetailToJC <> d.CmtdDetailToJC
   end
   */
   
   IF UPDATE(ReceiptUpdate)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Receipt Update', d.ReceiptUpdate, i.ReceiptUpdate,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.ReceiptUpdate <> d.ReceiptUpdate
   end
   
   IF UPDATE(GLAccrualAcct)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'GL Accrual Acct', d.GLAccrualAcct, i.GLAccrualAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.GLAccrualAcct <> d.GLAccrualAcct
   end
   
   IF UPDATE(GLRecExpInterfacelvl)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'GL Rec Exp Interface lvl', convert(char(1),d.GLRecExpInterfacelvl), convert(char(1),i.GLRecExpInterfacelvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.GLRecExpInterfacelvl <> d.GLRecExpInterfacelvl
   end
   
   IF UPDATE(GLRecExpSummaryDesc)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'GL Rec Exp Summary Desc', d.GLRecExpSummaryDesc, i.GLRecExpSummaryDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.GLRecExpSummaryDesc <> d.GLRecExpSummaryDesc
   end
   
   IF UPDATE(GLRecExpDetailDesc)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'GL Rec Exp Detail Desc', d.GLRecExpDetailDesc, i.GLRecExpDetailDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.GLRecExpDetailDesc <> d.GLRecExpDetailDesc
   end
   
   IF UPDATE(RecINInterfacelvl)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Rec IN Interface lvl', convert(char(1),d.RecINInterfacelvl), convert(char(1),i.RecINInterfacelvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.RecINInterfacelvl <> d.RecINInterfacelvl
   end
   
   IF UPDATE(RecJCInterfacelvl)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Rec JC Interface lvl', convert(char(1),d.RecJCInterfacelvl), convert(char(1),i.RecJCInterfacelvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.RecJCInterfacelvl <> d.RecJCInterfacelvl
   end
   
   IF UPDATE(RecEMInterfacelvl)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Rec EM Interface lvl', convert(char(1),d.RecEMInterfacelvl), convert(char(1),i.RecEMInterfacelvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.RecEMInterfacelvl <> d.RecEMInterfacelvl
   end
   
   IF UPDATE(PayTypeYN)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Specify Pay Type in PO Entry',d.PayTypeYN,i.PayTypeYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.PayTypeYN <> d.PayTypeYN
   end
   
   IF UPDATE(AuditPOCompliance)
   begin
   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Audit PO Compliance', d.AuditPOCompliance,i.AuditPOCompliance,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.AuditPOCompliance <> d.AuditPOCompliance
   end

--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.POCo = d.POCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end

	--DC #130129
	IF update(AutoRQ)
    BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Automatically Generate RQ#',d.AutoRQ,i.AutoRQ,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.AutoRQ,0) <> isnull(d.AutoRQ,0)
    END        
	IF update(LastRQ)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Last Used RQ#',d.LastRQ,i.LastRQ,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.LastRQ,0) <> isnull(d.LastRQ,0)
    END        
	IF update(ApprforQuote)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Approval Required for Quote',d.ApprforQuote,i.ApprforQuote,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.ApprforQuote,0) <> isnull(d.ApprforQuote,0)
    END    
	IF update(ApprforPurchase)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Approval Required for Purchase',d.ApprforPurchase,i.ApprforPurchase,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.ApprforPurchase,0) <> isnull(d.ApprforPurchase,0)		
    END
	IF update(QuoteReviewer)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Quote Reviewer',d.QuoteReviewer,i.QuoteReviewer,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.QuoteReviewer,0) <> isnull(d.QuoteReviewer,0)		
    END
	IF update(PurchaseReviewer)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Purchase Reviewer',d.PurchaseReviewer,i.PurchaseReviewer,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.PurchaseReviewer,0) <> isnull(d.PurchaseReviewer,0)		
    END
	IF update(Threshold)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Threshold Amount',d.Threshold,i.Threshold,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.Threshold,0) <> isnull(d.Threshold,0)		
    END
    IF update(ThresholdReviewer)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Threshold Reviewer',d.ThresholdReviewer,i.ThresholdReviewer,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.ThresholdReviewer,0) <> isnull(d.ThresholdReviewer,0)		
    END
    IF update(AuditRQ)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Audit Requisition',d.AuditRQ,i.AuditRQ,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.AuditRQ,0) <> isnull(d.AuditRQ,0)		
    END
    IF update(AuditReview)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Audit Review',d.AuditReview,i.AuditReview,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.AuditReview,0) <> isnull(d.AuditReview,0)		
    END
    IF update(AuditQuote)
	BEGIN
	   insert into bHQMA select 'bPOCO', 'PO Co#: ' + convert(char(3),i.POCo), i.POCo, 'C',
   		'Audit Quote',d.AuditQuote,i.AuditQuote,
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.POCo = d.POCo
   		where isnull(i.AuditQuote,0) <> isnull(d.AuditQuote,0)		
    END
    

   return
   error:
   	select @errmsg = @errmsg + ' - cannot update PO Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOCO] ON [dbo].[bPOCO] ([POCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[AutoPO]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[CmtdDetailToJC]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[AuditPOs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[ReceiptUpdate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[AuditPOCompliance]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCO].[PayTypeYN]'
GO
