CREATE TABLE [dbo].[bMSCO]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[APCo] [dbo].[bCompany] NOT NULL,
[ARCo] [dbo].[bCompany] NOT NULL,
[ARInterfaceLvl] [tinyint] NOT NULL,
[INInterfaceLvl] [tinyint] NOT NULL,
[INProdInterfaceLvl] [tinyint] NOT NULL,
[JCInterfaceLvl] [tinyint] NOT NULL,
[EMInterfaceLvl] [tinyint] NOT NULL,
[GLTicLvl] [tinyint] NOT NULL,
[GLTicSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLTicDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLInvLvl] [tinyint] NOT NULL,
[GLInvSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLInvDetailDesc] [varchar] (90) COLLATE Latin1_General_BIN NULL,
[AutoQuote] [dbo].[bYN] NOT NULL,
[LastQuote] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TicWarn] [tinyint] NOT NULL,
[LimitChk] [dbo].[bYN] NOT NULL,
[TaxOpt] [tinyint] NOT NULL,
[InvOpt] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[LastInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InvFormat] [dbo].[bReportTitle] NULL,
[DateSort] [dbo].[bYN] NOT NULL,
[LocSort] [dbo].[bYN] NOT NULL,
[InterCoInv] [dbo].[bYN] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditPayCodes] [dbo].[bYN] NOT NULL,
[AuditHaulCodes] [dbo].[bYN] NOT NULL,
[AuditTemplates] [dbo].[bYN] NOT NULL,
[AuditQuotes] [dbo].[bYN] NOT NULL,
[AuditTics] [dbo].[bYN] NOT NULL,
[AuditHaulers] [dbo].[bYN] NOT NULL,
[TicMatlVendor] [dbo].[bYN] NOT NULL,
[TicWeights] [dbo].[bYN] NOT NULL,
[TicEmployee] [dbo].[bYN] NOT NULL,
[TicDriver] [dbo].[bYN] NOT NULL,
[TicTimes] [dbo].[bYN] NOT NULL,
[TicLoads] [dbo].[bYN] NOT NULL,
[TicMiles] [dbo].[bYN] NOT NULL,
[TicHrs] [dbo].[bYN] NOT NULL,
[TicZone] [dbo].[bYN] NOT NULL,
[TicRev] [dbo].[bYN] NOT NULL,
[TicPay] [dbo].[bYN] NOT NULL,
[TicTax] [dbo].[bYN] NOT NULL,
[TicDisc] [dbo].[bYN] NOT NULL,
[HaulMatlVendor] [dbo].[bYN] NOT NULL,
[HaulTimes] [dbo].[bYN] NOT NULL,
[HaulLoads] [dbo].[bYN] NOT NULL,
[HaulMiles] [dbo].[bYN] NOT NULL,
[HaulHrs] [dbo].[bYN] NOT NULL,
[HaulZone] [dbo].[bYN] NOT NULL,
[HaulRev] [dbo].[bYN] NOT NULL,
[HaulPay] [dbo].[bYN] NOT NULL,
[HaulTax] [dbo].[bYN] NOT NULL,
[HaulDisc] [dbo].[bYN] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_AuditYN] DEFAULT ('Y'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[SaveDeleted] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_SaveDeleted] DEFAULT ('N'),
[TicReason] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_TicReason] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[AuditInvDetail] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_AuditInvDetail] DEFAULT ('N'),
[AutoApplyCash] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_AutoApplyCash] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[InvInitOrder] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_InvInitOrder] DEFAULT ('N'),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_AttachBatchReportsYN] DEFAULT ('N'),
[DfltSurchargeGroup] [smallint] NULL,
[AuditSurcharges] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSCO_AuditSurcharges] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
CREATE  trigger [dbo].[btMSCOd] on [dbo].[bMSCO] for DELETE as
/*-----------------------------------------------------------------
*  Created:  GF 03/06/2000
*  Modified: GG 04/23/07 - #30116 data security review, added validation
*
* Validates and inserts HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/** check a few MS tables to make sure we don't delete an active company **/
--check Haul Codes
if exists(select top 1 1 from dbo.bMSHC h (nolock) join deleted d on d.MSCo = h.MSCo)
    	begin
    	select @errmsg = 'MS Haul Codes exist'
    	goto error
    	end
--check Discount Templates
if exists(select top 1 1 from dbo.bMSDH h (nolock) join deleted d on d.MSCo = h.MSCo)
    	begin
    	select @errmsg = 'MS Discount Templates exist'
    	goto error
    	end
--check Quotes
if exists(select top 1 1 from dbo.bMSQH q (nolock) join deleted d on d.MSCo = q.MSCo)
    	begin
    	select @errmsg = 'MS Quotes exist'
    	goto error
    	end
--check Invoices
if exists(select top 1 1 from dbo.bMSIH h (nolock) join deleted d on d.MSCo = h.MSCo)
    	begin
    	select @errmsg = 'MS Invoices exist'
    	goto error
    	end
--check Tickets
if exists(select top 1 1 from dbo.bMSTD h (nolock) join deleted d on d.MSCo = h.MSCo)
    	begin
    	select @errmsg = 'MS Ticket Detail exists'
    	goto error
    	end

-- Audit MS Company deletions
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bMSCO', 'MS Co#: ' + convert(varchar(3),MSCo), MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted
if @@rowcount <> @numrows
	begin
	select @errmsg = 'Unable to update HQ Master Audit'
	goto error
	end

return

error:
	select @errmsg = @errmsg + ' - cannot delete MS Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE   trigger [dbo].[btMSCOi] on [dbo].[bMSCO] for INSERT as
/*-----------------------------------------------------------------
*  Created:  GF 03/06/2000
*  Modified: GG 09/05/00	-- Added INInterfaceLvl and INProdInterfaceLvl
*	         GG 10/24/00 - cleanup
*            GF 11/03/2000 - last quote validation incorrect.
*			 GG 04/20/07 - #30116 - data security review
*			 TRL 02/18/08 --#21452
*
* Validates critical column values
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------

declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount

if @numrows = 0 return
set nocount on
   
-- validate MS Company
select @validcnt = count(*) from dbo.bHQCO c (nolock) join inserted i on c.HQCo = i.MSCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid MS Company, not setup in HQ!'
	goto error
	end
if exists(select top 1 1 from inserted where ARInterfaceLvl not in (0,1,2,3))
	begin
	select @errmsg = 'Invalid AR Interface Level - must be 0, 1, 2, or 3'
	goto error
	end
if exists(select top 1 1 from inserted where INInterfaceLvl not in (0,1,2))
	begin
	select @errmsg = 'Invalid IN Interface Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where INProdInterfaceLvl not in (0,1,2))
	begin
	select @errmsg = 'Invalid IN Production Interface Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where JCInterfaceLvl not in (0,1,2))
	begin
	select @errmsg = 'Invalid JC Interface Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where EMInterfaceLvl not in (0,1,2))
	begin
	select @errmsg = 'Invalid EM Interface Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where GLTicLvl not in (0,1,2))
	begin
	select @errmsg = 'Invalid GL Ticket Interface Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where GLInvLvl not in (0,1,2))
	begin
	select @errmsg = 'Invalid GL Invoice Interface Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where TicWarn not in (0,1,2))
	begin
	select @errmsg = 'Invalid Ticket Warning Level - must be 0, 1, 2'
	goto error
	end
if exists(select top 1 1 from inserted where TaxOpt not in (0,1,2,3,4))
	begin
	select @errmsg = 'Invalid Tax option - must be 0, 1, 2, 3, or 4'
	goto error
	end
if exists(select top 1 1 from inserted where InvOpt not in ('MS','AR'))
	begin
	select @errmsg = 'Invalid Invoice option - must be (MS) or (AR) '
	goto error
	end
if exists(select top 1 1 from inserted where LastQuote is not null and isnumeric(LastQuote)=0)
	begin
	select @errmsg = 'Invalid Last Quote - must be numeric or null'
	goto error
	end

-- add HQ Master Audit entry
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bMSCO',  'MS Co#: ' + convert(char(3), MSCo), MSCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bMSCO',  'MS Co#: ' + convert(char(3), MSCo), MSCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bMSCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bMSCo', i.MSCo, i.MSCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bMSCo' and s.Qualifier = i.MSCo 
						and s.Instance = convert(char(30),i.MSCo) and s.SecurityGroup = @dfltsecgroup)
	end 
return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert MS Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************************************/
CREATE trigger [dbo].[btMSCOu] on [dbo].[bMSCO] for UPDATE as
/*-----------------------------------------------------------------
* Created By:  GF 03/06/2000
* Modified By: GG 09/05/00 - Added INInterfaceLvl and INProdInterfaceLvl
*				GG 09/27/00 - Added DateSort and LocSort columns
*				GG 10/24/00 - cleanup
*				RM 03/02/01 Added TicReason to update in audit table
*				GG 01/30/02 - #14176 - audit changes to AuditInvDetail
*				GG 01/31/02 - #14177 - audit changes to AutoApplyCash
*				GF 12/03/03 - issue # 23147 changes for ANSI nulls
*			    TRL 02/18/08 --#21452
*				GF 03/23/2010 - issue #129350 surcharges
*
*
* Validates and inserts HQ Master Audit entry.
*
* Cannot change Primary key - MS Company
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
   if update(MSCo)
   	begin
   	select @errmsg = 'Cannot change MS Company'
   	goto error
   	end
   if exists(select * from inserted where ARInterfaceLvl not in (0,1,2,3))
   	begin
   	select @errmsg = 'Invalid AR Interface Level - must be 0, 1, 2, or 3'
   	goto error
   	end
   if exists(select * from inserted where INInterfaceLvl not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid IN Interface Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where INProdInterfaceLvl not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid IN Production Interface Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where JCInterfaceLvl not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid JC Interface Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where EMInterfaceLvl not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid EM Interface Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where GLTicLvl not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid GL Ticket Interface Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where GLInvLvl not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid GL Invoice Interface Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where TicWarn not in (0,1,2))
   	begin
   	select @errmsg = 'Invalid Ticket Warning Level - must be 0, 1, 2'
   	goto error
   	end
   if exists(select * from inserted where TaxOpt not in (0,1,2,3,4))
   	begin
   	select @errmsg = 'Invalid Tax option - must be 0, 1, 2, 3, or 4'
   	goto error
   	end
   if exists(select * from inserted where InvOpt not in ('MS','AR'))
   	begin
   	select @errmsg = 'Invalid Invoice option - must be (MS) or (AR)'
   	goto error
   	end
   
   if exists(select * from inserted where LastQuote is not null and isnumeric(LastQuote)=0)
   	begin
       select @errmsg = 'Invalid Last Quote - must be numeric or null'
       goto error
       end
   
   -- Insert records into HQMA for changes made to audited fields
   IF UPDATE(Jrnl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C', 'GL Jrnl',
   		d.Jrnl, i.Jrnl, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.Jrnl,'') <> isnull(d.Jrnl,'')
   
   IF UPDATE(APCo)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C', 'AP Company',
   		convert(varchar(3),d.APCo), convert(varchar(3),i.APCo), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.APCo,'') <> isnull(d.APCo,'')
   
   IF UPDATE(ARCo)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C', 'AR Company',
   		convert(varchar(3),d.ARCo), convert(varchar(3),i.ARCo), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.ARCo,'') <> isnull(d.ARCo,'')
   
   IF UPDATE(ARInterfaceLvl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C', 'AR Interface Level',
   		convert(char(1),d.ARInterfaceLvl), convert(char(1),i.ARInterfaceLvl), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.ARInterfaceLvl,'') <> isnull(d.ARInterfaceLvl,'')
   
   IF UPDATE(INInterfaceLvl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','IN Interface Level',
   		convert(char(1),d.INInterfaceLvl), convert(char(1),i.INInterfaceLvl), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.INInterfaceLvl,'') <> isnull(d.INInterfaceLvl,'')
   
   IF UPDATE(INProdInterfaceLvl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C',
   	'IN Prod Interface Level', convert(char(1),d.INProdInterfaceLvl), convert(char(1),i.INProdInterfaceLvl),
   	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.INProdInterfaceLvl,'') <> isnull(d.INProdInterfaceLvl,'')
   
   IF UPDATE(JCInterfaceLvl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C', 'JC Interface Level',
   		convert(char(1),d.JCInterfaceLvl), convert(char(1),i.JCInterfaceLvl),	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.JCInterfaceLvl,'') <> isnull(d.JCInterfaceLvl,'')
   
   IF UPDATE(EMInterfaceLvl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','EM Interface Level',
   		convert(char(1),d.EMInterfaceLvl), convert(char(1),i.EMInterfaceLvl),	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.EMInterfaceLvl,'') <> isnull(d.EMInterfaceLvl,'')
   
   IF UPDATE(GLTicLvl)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','GL Ticket Interface Level',
   		convert(char(1),d.GLTicLvl), convert(char(1),i.GLTicLvl), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.GLTicLvl,'') <> isnull(d.GLTicLvl,'')
   
   IF UPDATE(GLInvLvl)
   	insert  bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','GL Invoice Interface Level',
   		convert(char(1),d.GLInvLvl), convert(char(1),i.GLInvLvl), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.GLInvLvl,'') <> isnull(d.GLInvLvl,'')
   
   IF UPDATE(GLTicSummaryDesc)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C',	'GL Ticket Summary Desc',
   		d.GLTicSummaryDesc, i.GLTicSummaryDesc,	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.GLTicSummaryDesc,'') <> isnull(d.GLTicSummaryDesc,'')
   
   IF UPDATE(GLInvSummaryDesc)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','GL Invoice Summary Desc',
   		d.GLInvSummaryDesc, i.GLInvSummaryDesc,	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.GLInvSummaryDesc,'') <> isnull(d.GLInvSummaryDesc,'')
   
   IF UPDATE(GLTicDetailDesc)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','GL Ticket Detail Desc',
   		d.GLTicDetailDesc, i.GLTicDetailDesc, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.GLTicDetailDesc,'') <> isnull(d.GLTicDetailDesc,'')
   
   IF UPDATE(GLInvDetailDesc)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','GL Invoice Detail Desc',
   		d.GLInvDetailDesc, i.GLInvDetailDesc, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.GLInvDetailDesc,'') <> isnull(d.GLInvDetailDesc,'')
   
   IF UPDATE(AutoQuote)
   	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(varchar(3),i.MSCo), i.MSCo, 'C','Auto Quote Option',
   		d.AutoQuote, i.AutoQuote, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where isnull(i.AutoQuote,'') <> isnull(d.AutoQuote,'')
   
   IF UPDATE(LastQuote)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C','Last Quote', 
   		d.LastQuote, i.LastQuote,	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.LastQuote,'') <> isnull(d.LastQuote,'') and i.AuditYN='Y'
   
   IF UPDATE(TicWarn)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C','Ticket Warning Option', 
   		convert(char(1),d.TicWarn), Convert(char(1),i.TicWarn), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and i.TicWarn <> d.TicWarn
   
   IF UPDATE(LimitChk)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C','Check customer credit limit', 
   		d.LimitChk, i.LimitChk, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.LimitChk,'') <> isnull(d.LimitChk,'')
   
   IF UPDATE(TaxOpt)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Tax Option', 
   		convert(char(1),d.TaxOpt), Convert(char(1),i.TaxOpt), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TaxOpt,'') <> isnull(d.TaxOpt,'')
   
   IF UPDATE(InvOpt)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Invoice Option', 
   		convert(char(1),d.InvOpt), Convert(char(1),i.InvOpt), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.InvOpt,'') <> isnull(d.InvOpt,'')
   
   IF UPDATE(LastInv)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Last used MS Invoice', 
   		d.LastInv, i.LastInv, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.LastInv,'') <> isnull(d.LastInv,'') and i.AuditYN='Y'
   
   IF UPDATE(InvFormat)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Invoice Format', 
   		convert(char(30),d.InvFormat), Convert(char(30),i.InvFormat), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.InvFormat,'') <> isnull(d.InvFormat,'')
   
   IF UPDATE(DateSort)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Date Sort', 
   		d.DateSort, i.DateSort, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.DateSort,'') <> isnull(d.DateSort,'')
   
   IF UPDATE(LocSort)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Location Sort', 
   		d.LocSort, i.LocSort, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.LocSort,'') <> isnull(d.LocSort,'')
   
   IF UPDATE(InterCoInv)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Intercompany Invoices', 
   	d.InterCoInv, i.InterCoInv, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.InterCoInv,'') <> isnull(d.InterCoInv,'')
   
   IF UPDATE(AuditCoParams)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Company Parameters', 
   		d.AuditCoParams, i.AuditCoParams, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditCoParams,'') <> isnull(d.AuditCoParams,'')
   
   IF UPDATE(AuditPayCodes)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Pay Codes', 
   		d.AuditPayCodes, i.AuditPayCodes, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditPayCodes,'') <> isnull(d.AuditPayCodes,'')
   
   IF UPDATE(AuditHaulCodes)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Haul Codes', 
   		d.AuditHaulCodes, i.AuditHaulCodes, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditHaulCodes,'') <> isnull(d.AuditHaulCodes,'')
   
   IF UPDATE(AuditTemplates)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Templates', 
   		d.AuditTemplates, i.AuditTemplates, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditTemplates,'') <> isnull(d.AuditTemplates,'')
   
   IF UPDATE(AuditQuotes)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Quotes', 
   		d.AuditQuotes, i.AuditQuotes, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditQuotes,'') <> isnull(d.AuditQuotes,'')
   
   IF UPDATE(AuditTics)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Tickets', 
   		d.AuditTics, i.AuditTics, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditTics,'') <> isnull(d.AuditTics,'')
   
   IF UPDATE(AuditHaulers)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Hauler Time Sheets', 
   		d.AuditHaulers, i.AuditHaulers, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditHaulers,'') <> isnull(d.AuditHaulers,'')
   
   IF UPDATE(TicMatlVendor)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Material Vendor', 
   		d.TicMatlVendor, i.TicMatlVendor, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicMatlVendor,'') <> isnull(d.TicMatlVendor,'')
   
   IF UPDATE(TicWeights)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Weights', 
   		d.TicWeights, i.TicWeights, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicWeights,'') <> isnull(d.TicWeights,'')
   
   IF UPDATE(TicEmployee)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Employee', 
   		d.TicEmployee, i.TicEmployee, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicEmployee,'') <> isnull(d.TicEmployee,'')
   
   IF UPDATE(TicDriver)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Driver', 
   		d.TicDriver, i.TicDriver, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicDriver,'') <> isnull(d.TicDriver,'')
   
   IF UPDATE(TicTimes)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Times', 
   		d.TicTimes, i.TicTimes, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicTimes,'') <> isnull(d.TicTimes,'')
   
   IF UPDATE(TicLoads)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Loads', 
   		d.TicLoads, i.TicLoads, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicLoads,'') <> isnull(d.TicLoads,'')
   
   IF UPDATE(TicMiles)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Miles', 
   	d.TicMiles, i.TicMiles, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicMiles,'') <> isnull(d.TicMiles,'')
   
   IF UPDATE(TicHrs)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Hrs', 
   		d.TicHrs, i.TicHrs, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicHrs,'') <> isnull(d.TicHrs,'')
   
   IF UPDATE(TicZone)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Zone', 
   		d.TicZone, i.TicZone, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicZone,'') <> isnull(d.TicZone,'')
   
   IF UPDATE(TicRev)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry EM Revenue Info', 
   		d.TicRev, i.TicRev, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicRev,'') <> isnull(d.TicRev,'')
   
   IF UPDATE(TicPay)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Vendor Pay Info', 
   		d.TicPay, i.TicPay, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicPay,'') <> isnull(d.TicPay,'')
   
   IF UPDATE(TicTax)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Tax Info', 
   		d.TicTax, i.TicTax, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicTax,'') <> isnull(d.TicTax,'')
   
   IF UPDATE(TicDisc)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Discount Info', 
   		d.TicDisc, i.TicDisc, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicDisc,'') <> isnull(d.TicDisc,'')
   
   IF UPDATE(TicReason)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Ticket Entry Discount Info', 
   		d.TicReason, i.TicReason, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.TicReason,'') <> isnull(d.TicReason,'')
   
   IF UPDATE(HaulMatlVendor)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Material Vendor', 
   		d.HaulMatlVendor, i.HaulMatlVendor, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulMatlVendor,'') <> isnull(d.HaulMatlVendor,'')
   
   IF UPDATE(HaulTimes)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Times', 
   		d.HaulTimes, i.HaulTimes, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulTimes,'') <> isnull(d.HaulTimes,'')
   
   IF UPDATE(HaulLoads)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Loads', 
   		d.HaulLoads, i.HaulLoads, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulLoads,'') <> isnull(d.HaulLoads,'')
   
   IF UPDATE(HaulMiles)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Miles', 
   		d.HaulMiles, i.HaulMiles, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulMiles,'') <> isnull(d.HaulMiles,'')
   
   IF UPDATE(HaulHrs)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Hours', 
   		d.HaulHrs, i.HaulHrs, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulHrs,'') <> isnull(d.HaulHrs,'')
   
   IF UPDATE(HaulZone)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Zone', 
   		d.HaulZone, i.HaulZone, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulZone,'') <> isnull(d.HaulZone,'')
   
   IF UPDATE(HaulRev)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet EM Revenue Info', 
   		d.HaulRev, i.HaulRev, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulRev,'') <> isnull(d.HaulRev,'')
   
   IF UPDATE(HaulPay)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Vendor Pay Info', 
   		d.HaulPay, i.HaulPay, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulPay,'') <> isnull(d.HaulPay,'')
   
   IF UPDATE(HaulTax)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Tax Info', 
   		d.HaulTax, i.HaulTax, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulTax,'') <> isnull(d.HaulTax,'')
   
   IF UPDATE(HaulDisc)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Haul Sheet Discount Info', 
   		d.HaulDisc, i.HaulDisc, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.HaulDisc,'') <> isnull(d.HaulDisc,'')
   
   IF UPDATE(AuditInvDetail)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Audit Invoice Detail', 
   		d.AuditInvDetail, i.AuditInvDetail, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditInvDetail,'') <> isnull(d.AuditInvDetail,'')
   
   IF UPDATE(AutoApplyCash)
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C', 'Auto Apply Cash', 
   		d.AutoApplyCash, i.AutoApplyCash, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.MSCo = d.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AutoApplyCash,'') <> isnull(d.AutoApplyCash,'')
   
--#21452
If update(AttachBatchReportsYN)
	begin
	insert into bHQMA select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.MSCo = d.MSCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
	end   

----#129350
If update(DfltSurchargeGroup)
	begin
	insert into bHQMA select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C',
   	'Default Surcharge Group', d.DfltSurchargeGroup, i.DfltSurchargeGroup,
   	getdate(), SUSER_SNAME()
   	from inserted i inner join deleted d on d.MSCo=i.MSCo
   	where i.MSCo = d.MSCo and isnull(i.DfltSurchargeGroup,'') <> isnull(d.DfltSurchargeGroup,'')
   	end 
If update(AuditSurcharges)
	begin
	insert into bHQMA select 'bMSCO', 'MS Co#: ' + convert(char(3),i.MSCo), i.MSCo, 'C',
   	'Audit Surcharges', d.AuditSurcharges, i.AuditSurcharges,
   	getdate(), SUSER_SNAME()
   	from inserted i inner join deleted d on d.MSCo=i.MSCo
   	where i.MSCo = d.MSCo and isnull(i.AuditSurcharges,'') <> isnull(d.AuditSurcharges,'')
	end 




return


error:
	select @errmsg = @errmsg + ' - cannot update MS Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSCO] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSCO] ON [dbo].[bMSCO] ([MSCo]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AutoQuote]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[LimitChk]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[DateSort]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[LocSort]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[InterCoInv]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditPayCodes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditHaulCodes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditTemplates]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditQuotes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditTics]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditHaulers]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicMatlVendor]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicWeights]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicEmployee]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicDriver]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicTimes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicLoads]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicMiles]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicHrs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicZone]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicRev]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicPay]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicTax]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicDisc]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulMatlVendor]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulTimes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulLoads]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulMiles]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulHrs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulZone]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulRev]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulPay]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulTax]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[HaulDisc]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[SaveDeleted]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[TicReason]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AuditInvDetail]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSCO].[AutoApplyCash]'
GO
