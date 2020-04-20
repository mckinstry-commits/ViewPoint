CREATE TABLE [dbo].[bRQCO]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[AutoRQ] [dbo].[bYN] NOT NULL,
[LastRQ] [dbo].[bRQ] NOT NULL CONSTRAINT [DF_bRQCO_LastRQ] DEFAULT ((0)),
[QuoteReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[PurchaseReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[Threshold] [dbo].[bDollar] NULL,
[ThresholdReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bRQCO_AuditCoParams] DEFAULT ('Y'),
[AuditRQ] [dbo].[bYN] NOT NULL,
[AuditReview] [dbo].[bYN] NOT NULL,
[AuditQuote] [dbo].[bYN] NOT NULL,
[ApprforQuote] [dbo].[bYN] NOT NULL,
[ApprforPurchase] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bRQCO_AttachBatchReportsYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btRQCOd] on [dbo].[bRQCO] for DELETE as

/*-----------------------------------------------------------------
* Created: DC 02/12/04
* Modified: GG 04/20/07 - #30116 - data security review 
*
* Delete trigger for RQ Company; will rollback deletion if any of the 
* following conditions exist:
*	Requistion Headers exist
*	Quote Headers exist
*
* Add HQ Master Audit entry for deleted RQ compaines. 
* 
*/----------------------------------------------------------------
declare  @numrows int, @errmsg  varchar(255)
    
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on 
  
/* check RQ Header */
if exists(select top 1 0 from deleted d join dbo.bRQRH a (NOLOCK) on a.RQCo = d.RQCo)
	begin
	select @errmsg = 'RQ Requistions exist'
	goto error
	end
/* check RQ Quote */
if exists(select top 1 0 from deleted d join dbo.bRQQH a (NOLOCK) on a.RQCo = d.RQCo)
	begin
	select @errmsg = 'RQ Quotes exist'
	goto error
	end

/* Audit RQ Company deletions */
insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bRQCO', 'RQCo: ' + convert(varchar(3),RQCo), RQCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted
    
return

error:
	select @errmsg = @errmsg + ' - cannot delete RQ Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

    
    
    
    
    
    
    
    
    
    
   
   
   
   
  
 




GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
CREATE TRIGGER [dbo].[btRQCOi] ON [dbo].[bRQCO] FOR INSERT AS

/*-----------------------------------------------------------------
* Created: DC 02/13/2004
* Modified: GWC 06/29/2004
*			GG 04/20/07 - #30116 - data security review
*			  TRL 02/18/08 --#21452	
*
*Validates:	Company in HQ
*  			Last RQ must be a number
*			Threshold/Threshold Reviewer:
*				-If a threshold is entered, it must be a postive numeric
*				-If a threshold is entered, a Threshold reviewer must be entered
*		
*Adds HQ Master Audit entry.
*/----------------------------------------------------------------
    
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- validate MS Company
select @validcnt = count(0) from dbo.bHQCO c (NOLOCK) join inserted i on c.HQCo = i.RQCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid RQ Company, not setup in HQ!'
	goto error
	end
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

/* validate AuditCoParams */
select @validcnt = count(1) from inserted where AuditCoParams = 'Y'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Option to audit company parameters must be checked.'
	goto error
	end
    
-- add HQ Master Audit entry
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bRQCO', 'RQCo: ' + convert(char(3), RQCo), RQCo, 'A', null, null, null, getdate(),	SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bRQCO',  'RQ Co#: ' + convert(char(3), RQCo), RQCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bRQCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bRQCo', i.RQCo, i.RQCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bRQCo' and s.Qualifier = i.RQCo 
						and s.Instance = convert(char(30),i.RQCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = @errmsg + ' - cannot insert RQ Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

    
    
    
    
    
    
    
    
   
   
   
   
  
 




GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btRQCOu    Script Date: 10/6/2004 7:18:45 AM ******/
    
    
    
    
    /****** Object:  Trigger dbo.btRQCOu    Script Date: 2/12/2004 9:52:11 AM ******/
    CREATE               trigger [dbo].[btRQCOu] on [dbo].[bRQCO] for UPDATE as
    


/*-----------------------------------------------------------------
     *  Created: DC 02/12/04
     *  Modified: TRL 02/18/08 --#21452	
     *
     *  Validates:	Key field changes not allowed
     *		AuditCoParams must = 'Y'
     *		Last RQ must be numeric
     *		Threshold/Threshold Reviewer:
     *			-If a threshold is entered, it must be a postive numeric
     *			-If a threshold is entered, a Threshold reviewer must be entered
     *
     * 	HQ Master Audit entry.  
     *
     */----------------------------------------------------------------
    begin
      declare  @numrows int,
               @errmsg  varchar(255),
    	   @validcnt int
    
      select @numrows = @@rowcount
      if @numrows = 0 return
      set nocount on
    
    /* check for key changes */
    select @validcnt = count(1) from deleted d, inserted i
    	where d.RQCo = i.RQCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change RQ Company'
    	goto error
    	end
    
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
    
    /* HQMA audit posting */
       /* Insert records into HQMA for changes made to audited fields */
    IF exists(select top 1 0 from inserted i join bRQCO a on a.RQCo = i.RQCo where a.AuditCoParams = 'Y')
      BEGIN 
      IF update(AutoRQ)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Automatically Generate RQ#', d.AutoRQ, i.AutoRQ,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.AutoRQ,0) <> isnull(d.AutoRQ,0)
      IF update(LastRQ)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Last Used RQ#', d.LastRQ, i.LastRQ,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.LastRQ,0) <> isnull(d.LastRQ,0)
      IF update(ApprforQuote)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Approval Required Quote', d.ApprforQuote, i.ApprforQuote,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.ApprforQuote,0) <> isnull(d.ApprforQuote,0)
      IF update(ApprforPurchase)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Approval Required Purchase', d.ApprforPurchase, i.ApprforPurchase,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.ApprforPurchase,0) <> isnull(d.ApprforPurchase,0)
      IF Update(AuditRQ)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Audit Requisition', d.AuditRQ, i.AuditRQ,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.AuditRQ,0) <> isnull(d.AuditRQ,0)
      IF update(AuditReview)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Audit Review', d.AuditReview, i.AuditReview,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.AuditReview,0) <> isnull(d.AuditReview,0)
      IF update(AuditQuote)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQCO', 'RQCo: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
     	'Audit Quote', d.AuditQuote, i.AuditQuote,
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo
     	where isnull(i.AuditQuote,0) <> isnull(d.AuditQuote,0)
      END

--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bRQCO', 'RQ Co#: ' + convert(char(3),i.RQCo), i.RQCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.RQCo = d.RQCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end
      return
    error:
    	select @errmsg = @errmsg + ' - cannot Update RQ Company!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    end
    
    
    
    
    
    
    
    
    
   
   
   
   
  
 




GO
ALTER TABLE [dbo].[bRQCO] ADD CONSTRAINT [biRQCO] PRIMARY KEY CLUSTERED  ([RQCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bRQCO_KeyID] ON [dbo].[bRQCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
