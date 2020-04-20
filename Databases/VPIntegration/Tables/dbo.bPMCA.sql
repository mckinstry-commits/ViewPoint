CREATE TABLE [dbo].[bPMCA]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Addon] [int] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Pct] [numeric] (12, 6) NULL,
[Amount] [dbo].[bDollar] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[Item] [dbo].[bContractItem] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[TotalType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCA_TotalType] DEFAULT ('N'),
[Include] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCA_Include] DEFAULT ('N'),
[NetCalcLevel] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCA_NetCalcLevel] DEFAULT ('T'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BasisCostType] [dbo].[bJCCType] NULL,
[RevRedirect] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCA_RevRedirect] DEFAULT ('N'),
[RevItem] [dbo].[bContractItem] NULL,
[RevStartAtItem] [int] NULL CONSTRAINT [DF_bPMCA_RevStartAtItem] DEFAULT ((0)),
[RevFixedACOItem] [dbo].[bACOItem] NULL,
[RevUseItem] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCA_RevUseItem] DEFAULT ('U'),
[Standard] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCA_Standard] DEFAULT ('Y'),
[RoundAmount] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCA_RoundAmount] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btPMCAd] on [dbo].[bPMCA] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMCA
 * Created By:	GF 12/05/2006 - 6.x added HQMA auditing
 * Modified By: JayR 03/20/2012  Remove unused code.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMCA','PM Co#: ' + isnull(convert(char(3),d.PMCo), '') + 'Add-On: ' + isnull(convert(varchar(6),d.Addon),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMCA = 'Y'

RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMCAi    Script Date: 8/28/99 9:37:49 AM ******/
CREATE trigger [dbo].[btPMCAi] on [dbo].[bPMCA] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMCA
* Created By:	LM 1/7/97
* Modified By:	JE 5/11/98 - Took out Contract Validation
*				GF 02/12/2008 - issue #127210 validate basis cost type
*				GF 01/29/2009 - issue #129669 add-on cost distribution enhancement
*				JayR 03/20/2012  Change to use FK constraints.  
*
*		
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMCA', ' Key: ' + convert(char(3), i.PMCo) + '/' + convert(varchar(6),i.Addon),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMCA = 'Y'

RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMCAu    Script Date: 8/28/99 9:37:49 AM ******/
CREATE trigger [dbo].[btPMCAu] on [dbo].[bPMCA] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMCA
* Created By:	LM 1/7/97
* Modified By:	JE 5/8/98 - took out contract validation
*				GF 12/05/2006 - 6.x added HQMA auditing
*				GF 02/12/2008 - #127210 added BasisCostType validation
*				GF 04/27/2008 - issue #22100 redirect addon revenue
*				GF 01/29/2009 - issue #129669 add-on cost distribution enhancement
*				GF 08/03/2010 - issue #134354 standard and round amount flags
*				JayR 03/20/2012 Change to us FK constraints.
*
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
	BEGIN
		RAISERROR('Cannot change PM Company - cannot update PMCA', 11, -1)
		rollback transaction
		RETURN
	END 

---- check for changes to Add On
if update(Addon)
      begin
		RAISERROR('Cannot change Add On - cannot update PMCA', 11, -1)
		rollback transaction
		RETURN
      end

---- HQMA inserts
if not exists(select 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMCA='Y')
	begin
  		RETURN
	end

if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.Description,'') <> isnull(i.Description,'')
if update(Basis)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Basis',  d.Basis, i.Basis, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.Basis,'') <> isnull(i.Basis,'')
if update(Phase)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Phase',  d.Phase, i.Phase, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.Phase,'') <> isnull(i.Phase,'')
if update(Item)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Item',  d.Item, i.Item, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.Item,'') <> isnull(i.Item,'')
if update(TotalType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'TotalType',  d.TotalType, i.TotalType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.TotalType,'') <> isnull(i.TotalType,'')
if update(Include)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Include',  d.Include, i.Include, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.Include,'') <> isnull(i.Include,'')
if update(Amount)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Amount', convert(varchar(16),d.Amount), convert(varchar(16),i.Amount), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(convert(varchar(16),d.Amount),'') <> isnull(convert(varchar(16),i.Amount),'')
if update(Pct)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'Pct', convert(varchar(20),d.Pct), convert(varchar(20),i.Pct), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(convert(varchar(20),d.Pct),'') <> isnull(convert(varchar(20),i.Pct),'')
if update(CostType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'CostType', convert(varchar(3),d.CostType), convert(varchar(3),i.CostType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(convert(varchar(3),d.CostType),'') <> isnull(convert(varchar(3),i.CostType),'')
if update(NetCalcLevel)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'NetCalcLevel', d.NetCalcLevel, i.NetCalcLevel, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(d.NetCalcLevel,'') <> isnull(i.NetCalcLevel,'')
if update(BasisCostType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + convert(varchar(6),i.Addon),
		i.PMCo, 'C', 'BasisCostType', convert(varchar(3),d.BasisCostType), convert(varchar(3),i.BasisCostType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Addon=i.Addon
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMCA='Y'
	where isnull(convert(varchar(3),d.BasisCostType),'') <> isnull(convert(varchar(3),i.BasisCostType),'')
if update(RevRedirect)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Addon: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'Reveune Redirect', d.RevRedirect, i.RevRedirect, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevRedirect,'') <> isnull(i.RevRedirect,'') and c.AuditPMCA = 'Y'
if update(RevItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' AddOn: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'Revenue Item', d.RevItem, i.RevItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevItem,'') <> isnull(i.RevItem,'') and c.AuditPMCA = 'Y'
if update(RevUseItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' AddOn: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'Revenue Use Item', d.RevUseItem, i.RevUseItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevUseItem,'') <> isnull(i.RevUseItem,'') and c.AuditPMCA = 'Y'
if update(RevStartAtItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' AddOn: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'Revenue Start At Item', isnull(convert(varchar(10),d.RevStartAtItem),''), isnull(convert(varchar(10),i.RevStartAtItem),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevStartAtItem,'') <> isnull(i.RevStartAtItem,'') and c.AuditPMCA = 'Y'
if update(RevFixedACOItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' AddOn: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'Revenue Fixed ACO Item', d.RevFixedACOItem, i.RevFixedACOItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevFixedACOItem,'') <> isnull(i.RevFixedACOItem,'') and c.AuditPMCA = 'Y'
----#134354 
if update(Standard)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' AddOn: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'Standard', d.Standard, i.Standard, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Standard,'') <> isnull(i.Standard,'') and c.AuditPMCA = 'Y'
if update(RoundAmount)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' AddOn: ' + isnull(convert(varchar(6),i.Addon),''),
		i.PMCo, 'C', 'RoundAmount', d.RoundAmount, i.RoundAmount, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Addon=i.Addon
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RoundAmount,'') <> isnull(i.RoundAmount,'') and c.AuditPMCA = 'Y'
----#134354 
	

RETURN


GO
ALTER TABLE [dbo].[bPMCA] ADD CONSTRAINT [CK_bPMCA_RoundAmount] CHECK (([RoundAmount]='Y' OR [RoundAmount]='N'))
GO
ALTER TABLE [dbo].[bPMCA] ADD CONSTRAINT [CK_bPMCA_Standard] CHECK (([Standard]='Y' OR [Standard]='N'))
GO
ALTER TABLE [dbo].[bPMCA] ADD CONSTRAINT [PK_bPMCA] PRIMARY KEY CLUSTERED  ([PMCo], [Addon]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMCA] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMCA] WITH NOCHECK ADD CONSTRAINT [FK_bPMCA_bJCCT_BasisCostType] FOREIGN KEY ([PhaseGroup], [BasisCostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMCA] WITH NOCHECK ADD CONSTRAINT [FK_bPMCA_bJCCT_CostType] FOREIGN KEY ([PhaseGroup], [CostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMCA] WITH NOCHECK ADD CONSTRAINT [FK_bPMCA_bJCPM] FOREIGN KEY ([PhaseGroup], [Phase]) REFERENCES [dbo].[bJCPM] ([PhaseGroup], [Phase])
GO
ALTER TABLE [dbo].[bPMCA] WITH NOCHECK ADD CONSTRAINT [FK_bPMCA_bPMCo] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo]) ON DELETE CASCADE
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMCA].[Include]'
GO
