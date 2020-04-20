CREATE TABLE [dbo].[bPMPA]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[AddOn] [int] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Pct] [numeric] (12, 6) NULL,
[Amount] [dbo].[bDollar] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[Contract] [dbo].[bContract] NULL,
[Item] [dbo].[bContractItem] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[TotalType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPA_TotalType] DEFAULT ('N'),
[Include] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMPA_Include] DEFAULT ('N'),
[NetCalcLevel] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPA_NetCalcLevel] DEFAULT ('T'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BasisCostType] [dbo].[bJCCType] NULL,
[RevRedirect] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMPA_RevRedirect] DEFAULT ('N'),
[RevItem] [dbo].[bContractItem] NULL,
[RevStartAtItem] [int] NULL CONSTRAINT [DF_bPMPA_RevStartAtItem] DEFAULT ((0)),
[RevFixedACOItem] [dbo].[bACOItem] NULL,
[RevUseItem] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPA_RevUseItem] DEFAULT ('U'),
[Standard] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPA_Standard] DEFAULT ('Y'),
[RoundAmount] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPA_RoundAmount] DEFAULT ('N'),
[udConv] [char] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger [dbo].[btPMPAd]    Script Date: 12/13/2006 12:22:59 ******/
CREATE trigger [dbo].[btPMPAd] on [dbo].[bPMPA] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPA
 * Created By:	GF 12/13/2006 - 6.x HQMA
 * Modified By:  JayR 03/23/2012 TK-00000 Remove unused variables
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on



---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPA','PMCo: ' + isnull(convert(varchar(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),d.AddOn),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMPA = 'Y'


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPAi    Script Date: 8/28/99 9:37:57 AM ******/
CREATE   trigger [dbo].[btPMPAi] on [dbo].[bPMPA] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMPA
 * Created By:  LM	1/7/98
 * Modified By: Danf 09/06/02 - 17738 Added Phase group bspJCADDCOSTTYPE
 *				GF 11/20/2003 - issue #22966 - override flag is 'P' for bspJCADDCOSTTYPE
 *				GF 01/12/2004 - issue #23450 - remmed out phase validation, problem with job security
 *				GF 12/13/2006 - 6.x HQMA
 *				GF 12/19/2006 - issue #123360 - net calculation level
 *				GF 02/26/2008 - issue #127210 validate basis cost type
 *				JayR 03/23/2012 - TK-00000 Switch to using FKs for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- update contract equal JCJM.Contract if null
if exists(select 1 from bPMPA where Contract is null)
	begin
	update bPMPA set Contract=j.Contract
	from bPMPA join bJCJM j on j.JCCo=bPMPA.PMCo and j.Job=bPMPA.Project
	where j.Contract is not null and bPMPA.Contract is null
	end


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPA', 'PMCo: ' + isnull(convert(varchar(3),i.PMCo),'') + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
	i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo=c.PMCo and c.AuditPMPA = 'Y'

RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPAu Script Date: 8/28/99 9:37:57 AM ******/
CREATE   trigger [dbo].[btPMPAu] on [dbo].[bPMPA] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMPA
 * Created By:	LM 01/07/97
 * Modified By: DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
 *				GF 11/19/2002 - enhancement for TotalType flag, update PMOA if changed.
 *				GF 10/28/2003 - issue #22827 - when total flag changes, besides updating PMOA.
 *								  Need to recalculate addons for pending CO items.
 *				GF 11/20/2003 - issue #22966 - override flag is 'P' for bspJCADDCOSTTYPE
 *				GF 01/12/2004 - issue #23450 - remmed out phase validation
 *				GF 12/13/2006 - 6.x HQMA
 *				GF 12/19/2006 - exclude net addons flag
 *				GF 02/14/2008 - issue #127195, #127210 - validate basis cost type and new calculation SP
 *				GF 04/29/2008 - issue #22100 redirect addon reveune columns
 *				GF 06/04/2008 - issue #128547 do not try to add phase cost type to JCCH here. breaks copy
 *				GF 08/01/2010 - issue #134354 standard and round amount flags to audit
 *				JayR 03/23/2012  - TK-00000 Switch to using FKs for validation.
 *				GP 09/05/2012 - TK-17612 Removed check for updating Project and changed cursor where to use KeyID
 *
 *--------------------------------------------------------------*/
declare @numrows int, @validcnt int, @rcode int, @errmsg varchar(255), @opencursor int,
   		@pmco bCompany, @project bJob, @phasegroup bGroup, @phase bPhase, 
   		@costtype bJCCType, @addon int, @totaltype char(1), @oldphase bPhase,
   		@oldcosttype bJCCType, @oldtotaltype char(1), @openpmoi int, @pcotype bDocType,
   		@pco bPCO, @pcoitem bPCOItem, @include bYN, @oldinclude bYN, @netcalclevel varchar(1),
		@oldnetcalclevel varchar(1), @oldbasiscosttype bJCCType, @basiscosttype bJCCType,
		@validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @opencursor = 0, @openpmoi = 0

---- check for changes to PMCo
if exists (select 1 from inserted i join deleted d on i.KeyID = d.KeyID and i.PMCo <> d.PMCo)
      begin
      select @errmsg = 'Cannot change PMCo'
      goto error
      end

---- check for changes to Addon
if update(AddOn)
      begin
      select @errmsg = 'Cannot change Add On'
      goto error
      end

---- update contract equal JCJM.Contract if null
if exists(select 1 from bPMPA where Contract is null)
	begin
	update bPMPA set Contract=j.Contract
	from bPMPA join bJCJM j on j.JCCo=bPMPA.PMCo and j.Job=bPMPA.Project
	where j.Contract is not null and bPMPA.Contract is null
	end

---- cursor only needed if more than a single row updated
if @numrows = 1
	begin
	select @pmco=i.PMCo, @project=i.Project, @addon=i.AddOn, @phasegroup=i.PhaseGroup, @phase=i.Phase, 
			@costtype=i.CostType, @totaltype=i.TotalType, @oldtotaltype=d.TotalType, @include=i.Include,
			@oldinclude=d.Include, @netcalclevel=i.NetCalcLevel, @oldnetcalclevel=d.NetCalcLevel,
			@basiscosttype=i.BasisCostType, @oldbasiscosttype=d.BasisCostType
	from inserted i
   	JOIN deleted d ON i.PMCo=d.PMCo and i.Project=d.Project and i.AddOn=d.AddOn
	end
else
	begin
   	---- use a cursor to process each updated row
   	declare bPMPA_update cursor LOCAL FAST_FORWARD
   	for select i.PMCo, i.Project, i.AddOn, i.PhaseGroup, i.Phase, i.CostType, i.TotalType, d.TotalType,
				i.Include, d.Include, i.NetCalcLevel, d.NetCalcLevel, i.BasisCostType, d.BasisCostType
	from inserted i
   	JOIN deleted d ON i.KeyID=d.KeyID
   
   	open bPMPA_update
	select @opencursor = 1
   
   	fetch next from bPMPA_update into @pmco, @project, @addon, @phasegroup, @phase, @costtype,
			@totaltype, @oldtotaltype, @include, @oldinclude, @netcalclevel, @oldnetcalclevel,
			@basiscosttype, @oldbasiscosttype
   	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end



update_check:
---- validate phase
----if isnull(@phase,'') <> ''
----   	begin
----   	---- validate standard phase - if it doesnt exist in JCJP try to add it
----   	exec @rcode = bspJCADDPHASE @pmco, @project, @phasegroup, @phase, 'Y', null, @errmsg output
----   	-- if @rcode <> 0 goto error
----   
----   	---- validate Cost Type - if JCCH doesnt exist try to add it
----   	exec @rcode = bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, @phase=@phase,
----   	                @costtype=@costtype, @override= 'P', @msg=@errmsg output
----   	---- if @rcode<>0 goto error
----   	end

---- update TotalType flag in PMOA if changed
if @oldtotaltype <> @totaltype or @oldinclude <> @include or @oldnetcalclevel <> @netcalclevel
   	begin
   	update bPMOA set TotalType = @totaltype, Include = @include, NetCalcLevel = @netcalclevel
   	where PMCo=@pmco and Project=@project and AddOn=@addon
   
   	---- declare cursor on PMOI for pending items not yet assigned to ACO
   	declare bcPMOI cursor LOCAL FAST_FORWARD for select PCOType, PCO, PCOItem
   	from bPMOI where PMCo=@pmco and Project=@project and isnull(ACO,'') = ''
   
   	---- open bcPMOI
   	open bcPMOI
   	select @openpmoi = 1
      
   	---- process through all PCO items
   	PMOI_loop:
   	fetch next from bcPMOI into @pcotype, @pco, @pcoitem
   	if @@fetch_status = -1 goto PMOI_end
   	if @@fetch_status <> 0 goto PMOI_loop
   	exec @rcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem
   	goto PMOI_loop
   
   	PMOI_end:
		if @openpmoi = 1
		begin
		close bcPMOI
		deallocate bcPMOI
		set @openpmoi = 0
		end
	end




if @numrows > 1
	begin
	fetch next from bPMPA_update into @pmco, @project, @addon, @phasegroup, @phase, @costtype,
				@totaltype, @oldtotaltype, @include, @oldinclude, @netcalclevel, @oldnetcalclevel,
				@basiscosttype, @oldbasiscosttype
	if @@fetch_status = 0
		begin
		goto update_check
		end
	else
		begin
		close bPMPA_update
		deallocate bPMPA_update
		select @opencursor = 0
		end
	end



---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMPA='Y')
	begin
  	goto trigger_end
	end

if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMPA = 'Y'
if update(Basis)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Basis', d.Basis, i.Basis, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Basis,'') <> isnull(i.Basis,'') and c.AuditPMPA = 'Y'
if update(Pct)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Pct', isnull(convert(varchar(20),d.Pct),''), isnull(convert(varchar(20),i.Pct),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Pct,'') <> isnull(i.Pct,'') and c.AuditPMPA = 'Y'
if update(Amount)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Amount', isnull(convert(varchar(16),d.Amount),''), isnull(convert(varchar(16),i.Amount),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Amount,'') <> isnull(i.Amount,'') and c.AuditPMPA = 'Y'
if update(Phase)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Phase,'') <> isnull(i.Phase,'') and c.AuditPMPA = 'Y'
if update(CostType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'CostType', isnull(convert(varchar(3),d.CostType),''), isnull(convert(varchar(3),i.CostType),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.CostType,'') <> isnull(i.CostType,'') and c.AuditPMPA = 'Y'
if update(Item)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Item', d.Item, i.Item, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Item,'') <> isnull(i.Item,'') and c.AuditPMPA = 'Y'
if update(TotalType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'TotalType', d.TotalType, i.TotalType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.TotalType,'') <> isnull(i.TotalType,'') and c.AuditPMPA = 'Y'
if update(Include)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Include', d.Include, i.Include, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Include,'') <> isnull(i.Include,'') and c.AuditPMPA = 'Y'
if update(NetCalcLevel)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'NetCalcLevel', d.NetCalcLevel, i.NetCalcLevel, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.NetCalcLevel,'') <> isnull(i.NetCalcLevel,'') and c.AuditPMPA = 'Y'
if update(BasisCostType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'BasisCostType', isnull(convert(varchar(3),d.BasisCostType),''), isnull(convert(varchar(3),i.BasisCostType),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.BasisCostType,'') <> isnull(i.BasisCostType,'') and c.AuditPMPA = 'Y'
if update(RevRedirect)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Reveune Redirect', d.RevRedirect, i.RevRedirect, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevRedirect,'') <> isnull(i.RevRedirect,'') and c.AuditPMPA = 'Y'
if update(RevItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Revenue Item', d.RevItem, i.RevItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevItem,'') <> isnull(i.RevItem,'') and c.AuditPMPA = 'Y'
if update(RevUseItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Revenue Use Item', d.RevUseItem, i.RevUseItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevUseItem,'') <> isnull(i.RevUseItem,'') and c.AuditPMPA = 'Y'
if update(RevStartAtItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Revenue Start At Item', isnull(convert(varchar(10),d.RevStartAtItem),''), isnull(convert(varchar(10),i.RevStartAtItem),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevStartAtItem,'') <> isnull(i.RevStartAtItem,'') and c.AuditPMPA = 'Y'
if update(RevFixedACOItem)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Revenue Fixed ACO Item', d.RevFixedACOItem, i.RevFixedACOItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevFixedACOItem,'') <> isnull(i.RevFixedACOItem,'') and c.AuditPMPA = 'Y'
----#134354
if update(Standard)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'Standard', d.Standard, i.Standard, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Standard,'') <> isnull(i.Standard,'') and c.AuditPMPA = 'Y'
if update(RoundAmount)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPA', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' AddOn: ' + isnull(convert(varchar(6),i.AddOn),''),
		i.PMCo, 'C', 'RoundAmount', d.RoundAmount, i.RoundAmount, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.AddOn=i.AddOn
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RoundAmount,'') <> isnull(i.RoundAmount,'') and c.AuditPMPA = 'Y'
----#134354

trigger_end:
	return


error:
	select @errmsg = @errmsg + ' - cannot update PMPA'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
ALTER TABLE [dbo].[bPMPA] WITH NOCHECK ADD CONSTRAINT [CK_bPMPA_BasisCostType] CHECK (([BasisCostType] IS NULL OR [PhaseGroup] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMPA] WITH NOCHECK ADD CONSTRAINT [CK_bPMPA_Include] CHECK (([Include]='Y' OR [Include]='N'))
GO
ALTER TABLE [dbo].[bPMPA] WITH NOCHECK ADD CONSTRAINT [CK_bPMPA_RoundAmount] CHECK (([RoundAmount]='Y' OR [RoundAmount]='N'))
GO
ALTER TABLE [dbo].[bPMPA] WITH NOCHECK ADD CONSTRAINT [CK_bPMPA_Standard] CHECK (([Standard]='Y' OR [Standard]='N'))
GO
ALTER TABLE [dbo].[bPMPA] ADD CONSTRAINT [PK_bPMPA] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [AddOn]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMPA] WITH NOCHECK ADD CONSTRAINT [FK_bPMPA_bJCCT] FOREIGN KEY ([PhaseGroup], [BasisCostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMPA] WITH NOCHECK ADD CONSTRAINT [FK_bPMPA_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bPMPA] NOCHECK CONSTRAINT [FK_bPMPA_bJCCT]
GO
ALTER TABLE [dbo].[bPMPA] NOCHECK CONSTRAINT [FK_bPMPA_bJCJM]
GO
