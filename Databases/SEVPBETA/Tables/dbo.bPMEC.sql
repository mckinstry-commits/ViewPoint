CREATE TABLE [dbo].[bPMEC]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[BudgetCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMEC_Active] DEFAULT ('Y'),
[CostLevel] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMEC_CostLevel] DEFAULT ('D'),
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[UM] [dbo].[bUM] NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPMEC_UnitCost] DEFAULT ((0)),
[HrsPerUnit] [numeric] (15, 4) NOT NULL CONSTRAINT [DF_bPMEC_HrsPerUnit] DEFAULT ((0)),
[Percentage] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bPMEC_Percentage] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMEC_Basis] DEFAULT ('U'),
[TimeUM] [dbo].[bUM] NULL,
[Rate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPMEC_Rate] DEFAULT ((0)),
[ExcludeFromLookups] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMEC_ExcludeFromLookups] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMECd] on [dbo].[bPMEC] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMEC
 * Created By:	GF 05/24/2007
 * Modified By:  JayR 03/21/2012 TK-00000 Remove unused code gotos
 *
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMEC','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' BudgetCode: ' + isnull(d.BudgetCode,''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMEC = 'Y'

RETURN 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMECi] on [dbo].[bPMEC] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMEC
 * Created By:	GF 05/24/2007
 * Modified By:  JayR  03/21/2012 TK-00000 Change to use FK for validation
 *
 *		
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMEC', ' Key: ' + convert(char(3), i.PMCo) + ' Budget: ' + isnull(i.BudgetCode,''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMEC = 'Y'


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMECu] on [dbo].[bPMEC] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMEC
 * Created By:	GF 05/24/2007
 * Modified By:	GF 03/24/2009 - issue #129898
 *				JayR 03/21/2012 - TK-00000 Remove gotos and unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

-- check for changes to PMCo
if update(PMCo)
	begin
	RAISERROR('Cannot change PM Company - cannot update PMEC', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

-- check for changes to BudgetCode
if update(BudgetCode)
	begin
	RAISERROR('Cannot change Budget Code - cannot update PMEC', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.Description,'') <> isnull(i.Description,'')
if update(Active)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Active',  d.Active, i.Active, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.Active,'') <> isnull(i.Active,'')
if update(CostLevel)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'CostLevel',  d.CostLevel, i.CostLevel, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.CostLevel,'') <> isnull(i.CostLevel,'')
if update(Phase)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Phase',  d.Phase, i.Phase, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.Phase,'') <> isnull(i.Phase,'')
if update(UM)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'UM',  d.UM, i.UM, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.UM,'') <> isnull(i.UM,'')
if update(CostType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'CostType', convert(varchar(3),d.CostType), convert(varchar(3),i.CostType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(convert(varchar(3),d.CostType),'') <> isnull(convert(varchar(3),i.CostType),'')
if update(Percentage)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Percentage', convert(varchar(16),d.Percentage), convert(varchar(16),i.Percentage), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(convert(varchar(16),d.Percentage),'') <> isnull(convert(varchar(16),i.Percentage),'')
if update(HrsPerUnit)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'HrsPerUnit', convert(varchar(20),d.HrsPerUnit), convert(varchar(20),i.HrsPerUnit), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(convert(varchar(20),d.HrsPerUnit),'') <> isnull(convert(varchar(20),i.HrsPerUnit),'')
if update(UnitCost)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'UnitCost', convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(convert(varchar(20),d.UnitCost),'') <> isnull(convert(varchar(20),i.UnitCost),'')
if update(TimeUM)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Time UM',  d.TimeUM, i.TimeUM, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.TimeUM,'') <> isnull(i.TimeUM,'')
if update(Basis)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Basis',  d.Basis, i.Basis, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.Basis,'') <> isnull(i.Basis,'')
if update(Rate)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'Rate',  convert(varchar(20),d.Rate), convert(varchar(20),i.Rate), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(convert(varchar(20),d.Rate),'') <> isnull(convert(varchar(20),i.Rate),'')
if update(ExcludeFromLookups)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEC', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' BudgetCode: ' + isnull(i.BudgetCode,''),
		i.PMCo, 'C', 'ExcludeFromLookups',  d.ExcludeFromLookups, i.ExcludeFromLookups, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.BudgetCode=i.BudgetCode
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEC='Y'
	where isnull(d.ExcludeFromLookups,'') <> isnull(i.ExcludeFromLookups,'')


RETURN 

GO
ALTER TABLE [dbo].[bPMEC] ADD CONSTRAINT [CK_bPMEC_Basis] CHECK (([Basis]='U' OR [Basis]='H'))
GO
ALTER TABLE [dbo].[bPMEC] ADD CONSTRAINT [PK_bPMEC] PRIMARY KEY CLUSTERED  ([PMCo], [BudgetCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMEC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMEC] WITH NOCHECK ADD CONSTRAINT [FK_bPMEC_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
GO
