CREATE TABLE [dbo].[bPMED]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[BudgetNo] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[CostLevel] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMED_CostLevel] DEFAULT ('D'),
[GroupNo] [int] NOT NULL CONSTRAINT [DF_bPMED_GroupNo] DEFAULT ((0)),
[Line] [int] NOT NULL CONSTRAINT [DF_bPMED_Line] DEFAULT ((0)),
[BudgetCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[Units] [dbo].[bUnits] NULL CONSTRAINT [DF_bPMED_Units] DEFAULT ((0)),
[UM] [dbo].[bUM] NULL,
[HrsPerUnit] [numeric] (15, 4) NULL CONSTRAINT [DF_bPMED_HrsPerUnit] DEFAULT ((0)),
[Hours] [dbo].[bHrs] NULL CONSTRAINT [DF_bPMED_Hours] DEFAULT ((0)),
[HourCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bPMED_HourCost] DEFAULT ((0)),
[UnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bPMED_UnitCost] DEFAULT ((0)),
[Markup] [dbo].[bPct] NULL CONSTRAINT [DF_bPMED_Markup] DEFAULT ((0)),
[Amount] [dbo].[bDollar] NULL CONSTRAINT [DF_bPMED_Amount] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMED] ADD 
CONSTRAINT [PK_bPMED] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [BudgetNo], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMED] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMED] WITH NOCHECK ADD
CONSTRAINT [FK_bPMED_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMED] WITH NOCHECK ADD
CONSTRAINT [FK_bPMED_bPMEH] FOREIGN KEY ([PMCo], [Project], [BudgetNo]) REFERENCES [dbo].[bPMEH] ([PMCo], [Project], [BudgetNo]) ON DELETE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMEDd] on [dbo].[bPMED] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMED
 * Created By:	GF 05/24/2007
 *
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int,
		@opencursor int, @rcode int, @pmco bCompany, @project bJob, 
		@budgetno varchar(10), @msg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @opencursor = 0, @rcode = 0



if @numrows = 1
	begin
  	select @pmco=PMCo, @project=Project, @budgetno=BudgetNo
	from deleted
	end
else
	begin
	declare bPMED_delete cursor LOCAL FAST_FORWARD
  	for select PMCo, Project, BudgetNo
  	from deleted
	group by PMCo, Project, BudgetNo
  
  	open bPMED_delete
	select @opencursor = 1

	fetch next from bPMED_delete into @pmco, @project, @budgetno 
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
  		end
	end


insert_check:
---- execute estimate cost re-calculation SP
exec @rcode = dbo.vspPMEDRecalculate @pmco, @project, @budgetno, @msg=@errmsg output



if @numrows > 1
  	begin
  	fetch next from bPMED_delete into @pmco, @project, @budgetno
  	if @@fetch_status = 0
  		goto insert_check
  	else
  		begin
  		close bPMED_delete
  		deallocate bPMED_delete
		select @opencursor = 0
  		end
  	end




---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMED','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' BudgetNo: ' + isnull(d.BudgetNo,'') + ' Seq: ' + convert(varchar(10),d.Seq),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMEH = 'Y'





return



error:
	select @errmsg = isnull(@errmsg, '') + ' - cannot delete from PMED'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMEDi] on [dbo].[bPMED] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMED
 * Created By:	GF 05/24/2007
 * Modified By:
 *
 *		
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int,
		@opencursor int, @rcode int, @pmco bCompany, @project bJob, 
		@budgetno varchar(10), @msg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @opencursor = 0, @rcode = 0

if @numrows = 1
	begin
  	select @pmco=PMCo, @project=Project, @budgetno=BudgetNo
	from inserted
	end
else
	begin
	declare bPMED_insert cursor LOCAL FAST_FORWARD
  	for select PMCo, Project, BudgetNo
  	from inserted
	group by PMCo, Project, BudgetNo
  
  	open bPMED_insert
	select @opencursor = 1

	fetch next from bPMED_insert into @pmco, @project, @budgetno 
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
  		end
	end


insert_check:
---- execute estimate cost re-calculation SP
exec @rcode = dbo.vspPMEDRecalculate @pmco, @project, @budgetno, @msg=@errmsg output



if @numrows > 1
  	begin
  	fetch next from bPMED_insert into @pmco, @project, @budgetno
  	if @@fetch_status = 0
  		goto insert_check
  	else
  		begin
  		close bPMED_insert
  		deallocate bPMED_insert
		select @opencursor = 0
  		end
  	end



---- Audit inserts
HQMA_inserts:
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMED', ' Key: ' + convert(char(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMEH = 'Y'



return


error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMED'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMEDu] on [dbo].[bPMED] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMED
 * Created By:	GF 05/24/2007
 * Modified By:
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int,
		@opencursor int, @rcode int, @pmco bCompany, @project bJob, 
		@budgetno varchar(10), @msg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @opencursor = 0, @rcode = 0

-- check for changes to PMCo
if update(PMCo)
	begin
	select @errmsg = 'Cannot change PM Company'
	goto error
	end

-- check for changes to Project
if update(Project)
	begin
	select @errmsg = 'Cannot change Project'
	goto error
	end

-- check for changes to BudgetNo
if update(BudgetNo)
	begin
	select @errmsg = 'Cannot change BudgetNo'
	goto error
	end


if @numrows = 1
	begin
  	select @pmco=PMCo, @project=Project, @budgetno=BudgetNo
	from inserted
	end
else
	begin
	declare bPMED_update cursor LOCAL FAST_FORWARD
  	for select PMCo, Project, BudgetNo
  	from inserted
	group by PMCo, Project, BudgetNo
  
  	open bPMED_update
	select @opencursor = 1

	fetch next from bPMED_update into @pmco, @project, @budgetno 
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
  		end
	end


insert_check:
---- execute BudgetNo cost re-calculation SP
exec @rcode = dbo.vspPMEDRecalculate @pmco, @project, @budgetno, @msg=@errmsg output



if @numrows > 1
  	begin
  	fetch next from bPMED_update into @pmco, @project, @budgetno
  	if @@fetch_status = 0
  		goto insert_check
  	else
  		begin
  		close bPMED_update
  		deallocate bPMED_update
		select @opencursor = 0
  		end
  	end




---- HQMA inserts
if update(GroupNo)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'GroupNo', convert(varchar(10),d.GroupNo), convert(varchar(10),i.GroupNo), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(10),d.GroupNo),'') <> isnull(convert(varchar(10),i.GroupNo),'')
if update(Line)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Line', convert(varchar(10),d.Line), convert(varchar(10),i.Line), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(10),d.Line),'') <> isnull(convert(varchar(10),i.Line),'')
if update(CostLevel)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'CostLevel',  d.CostLevel, i.CostLevel, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(d.CostLevel,'') <> isnull(i.CostLevel,'')
if update(BudgetCode)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'BudgetCode',  d.BudgetCode, i.BudgetCode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(d.BudgetCode,'') <> isnull(i.BudgetCode,'')
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(d.Description,'') <> isnull(i.Description,'')
if update(Phase)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Phase',  d.Phase, i.Phase, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(d.Phase,'') <> isnull(i.Phase,'')
if update(UM)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'UM',  d.UM, i.UM, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(d.UM,'') <> isnull(i.UM,'')
if update(CostType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'CostType', convert(varchar(3),d.CostType), convert(varchar(3),i.CostType), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(3),d.CostType),'') <> isnull(convert(varchar(3),i.CostType),'')
if update(Markup)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Markup', convert(varchar(16),d.Markup), convert(varchar(16),i.Markup), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(16),d.Markup),'') <> isnull(convert(varchar(16),i.Markup),'')
if update(Units)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Units', convert(varchar(20),d.Units), convert(varchar(20),i.Units), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(20),d.Units),'') <> isnull(convert(varchar(20),i.Units),'')
if update(HrsPerUnit)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'HrsPerUnit', convert(varchar(20),d.HrsPerUnit), convert(varchar(20),i.HrsPerUnit), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(20),d.HrsPerUnit),'') <> isnull(convert(varchar(20),i.HrsPerUnit),'')
if update(Hours)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Hours', convert(varchar(20),d.Hours), convert(varchar(20),i.Hours), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(20),d.Hours),'') <> isnull(convert(varchar(20),i.Hours),'')
if update(HourCost)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'HourCost', convert(varchar(20),d.HourCost), convert(varchar(20),i.HourCost), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(20),d.HourCost),'') <> isnull(convert(varchar(20),i.HourCost),'')
if update(UnitCost)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'UnitCost', convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(20),d.UnitCost),'') <> isnull(convert(varchar(20),i.UnitCost),'')
if update(Amount)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMED', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,'') + ' Seq: ' + convert(varchar(10),i.Seq),
		i.PMCo, 'C', 'Amount', convert(varchar(20),d.Amount), convert(varchar(20),i.Amount), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.BudgetNo=i.BudgetNo and d.Seq=i.Seq
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(convert(varchar(20),d.Amount),'') <> isnull(convert(varchar(20),i.Amount),'')


return



error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update PMED'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
