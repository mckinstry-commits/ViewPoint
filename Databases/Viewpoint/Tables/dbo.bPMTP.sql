CREATE TABLE [dbo].[bPMTP]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Item] [dbo].[bContractItem] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[SICode] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMTP] ON [dbo].[bPMTP] ([PMCo], [Template], [PhaseGroup], [Phase]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMTP] WITH NOCHECK ADD
CONSTRAINT [FK_bPMTP_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
ALTER TABLE [dbo].[bPMTP] WITH NOCHECK ADD
CONSTRAINT [FK_bPMTP_bPMTH] FOREIGN KEY ([PMCo], [Template]) REFERENCES [dbo].[bPMTH] ([PMCo], [Template]) ON DELETE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTPd    Script Date: 8/28/99 9:38:17 AM ******/
CREATE trigger [dbo].[btPMTPd] on [dbo].[bPMTP] for DELETE as 
/*-------------------------------------------------------------- 
 * Delete trigger for PMTP
 * Created By:	GR 09/07/99
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/28/2012 Switch to using FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


------ delete PMTD - Template Phase Cost Types
--  This delete isn't put into a "...ON CASCADE DELETE..." Because we cannot create a unique matching index.
delete bPMTD
from bPMTD join deleted d on bPMTD.PMCo=d.PMCo and bPMTD.Template=d.Template and bPMTD.Phase=d.Phase


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMTP', ' Template: ' + isnull(d.Template,'') + ' Phase: ' + isnull(d.Phase,''), d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d join bPMCO c on c.PMCo = d.PMCo
where d.PMCo = c.PMCo and c.AuditPMTH = 'Y'


RETURN 
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[btPMTPi] on [dbo].[bPMTP] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMTP
 * Created By:   GR 10/04/1999
 * Modified By:  GF 08/29/2001 - Fix to not validate phase.
 *				 GF 05/17/2002 - More changes. If full phase not exist, check for valid portion
 *								 phase. If found add cost types for valid portion to bPMTD.
 *				 GF 12/13/2006 - 6.x HQMA
 *				 JayR 03/28/2012 TK-00000 Change to use FKs for validation.
 *
 *--------------------------------------------------------------*/
declare @numrows int, @rcode int, @errmsg varchar(255), @validcnt int, @pmco bCompany,
   		@template varchar(10), @phasegroup tinyint, @phase bPhase, @openct_cursor int,
   		@costtype bJCCType, @description bDesc, @validphasechars int, @pphase bPhase

if @@rowcount = 0 return
set nocount on


---- create pseudo cursor in inserted record to add bPMTD if needed
   select @pmco=min(PMCo) from inserted
   while @pmco is not null
   begin
   select @template=min(Template) from inserted where PMCo=@pmco
   while @template is not null
   begin
   select @phasegroup=min(PhaseGroup) from inserted where PMCo=@pmco and Template=@template
   while @phasegroup is not null
   begin
   select @phase=min(Phase) from inserted where PMCo=@pmco and Template=@template and PhaseGroup=@phasegroup
   while @phase is not null
   begin
   
   	-- see whether cost types already exisits
   	select @validcnt=Count(*) from bPMTD with (nolock)
   	where PMCo=@pmco and Template=@template and PhaseGroup=@phasegroup and Phase=@phase
   	if @validcnt <> 0 goto next_template_phase
   
   	-- check if cost types exist in bJCPC for full phase. If true, add these cost types to bPMTD
   	select @validcnt=count(*) from bJCPC with (nolock)
   	where PhaseGroup=@phasegroup and Phase=@phase
   	if @validcnt <> 0
   		begin
   			-- pseudo cursor for cost types
   			select @costtype=min(CostType) from bJCPC with (nolock)
   			where PhaseGroup=@phasegroup and Phase=@phase
   			while @costtype is not null
   			begin
   			
   				-- insert into bPMTD
   				insert into bPMTD (PMCo, Template, PhaseGroup, Phase, CostType, Description)
   				select @pmco, @template, @phasegroup, @phase, @costtype, b.Description
   				from bJCCT b where b.PhaseGroup=@phasegroup and b.CostType=@costtype
   
   			select @costtype=min(CostType) from bJCPC with (nolock)
   			where PhaseGroup=@phasegroup and Phase=@phase and CostType>@costtype
   			if @@rowcount = 0 select @costtype = null
   			end
   		
   		goto next_template_phase
   		end
   
   	-- get valid portion of phase code from bJCCO
   	select @validphasechars=ValidPhaseChars from bJCCO with (nolock) where JCCo=@pmco
   	if @@rowcount = 0 goto next_template_phase
   
   	-- check bJCPM using valid portion
   	if isnull(@validphasechars,0) > 0
   		begin
   		-- format valid portion of Phase
   		select @pphase = isnull(substring(@phase,1,@validphasechars),'') + '%'
   	
   		-- check valid portion of Phase in bJCPM
   		select Top 1 @pphase=Phase from bJCPM with (nolock)
   		where PhaseGroup=@phasegroup and Phase like @pphase
   		group by PhaseGroup, Phase
   		-- if valid portion phase found check bJCPC for cost types
   		if @@rowcount = 1
   			begin
   			select @validcnt=count(*) from bJCPC with (nolock)
   			where PhaseGroup=@phasegroup and Phase=@pphase
   			if @validcnt <> 0
   				begin
   					-- pseudo cursor for cost types
   					select @costtype=min(CostType) from bJCPC with (nolock)
   					where PhaseGroup=@phasegroup and Phase=@pphase
   					while @costtype is not null
   					begin
   			
   						-- insert into bPMTD
   						insert into bPMTD (PMCo, Template, PhaseGroup, Phase, CostType, Description)
   						select @pmco, @template, @phasegroup, @phase, @costtype, b.Description
   						from bJCCT b where b.PhaseGroup=@phasegroup and b.CostType=@costtype
   
   					select @costtype=min(CostType) from bJCPC with (nolock)
   					where PhaseGroup=@phasegroup and Phase=@pphase and CostType>@costtype
   					if @@rowcount = 0 select @costtype = null
   					end
   		
   				goto next_template_phase
   				end
   			end
   		end
   
   
   next_template_phase:
   select @phase=min(Phase) from inserted where PMCo=@pmco and Template=@template and PhaseGroup=@phasegroup and Phase>@phase
   if @@rowcount = 0 select @phase = null
   end
   select @phasegroup=min(PhaseGroup) from inserted where PMCo=@pmco and Template=@template and PhaseGroup>@phasegroup
   if @@rowcount = 0 select @phasegroup = null
   end
   select @template=min(Template) from inserted where PMCo=@pmco and Template>@template
   if @@rowcount = 0 select @template = null
   end
   select @pmco=min(PMCo) from inserted where PMCo>@pmco
   if @@rowcount = 0 select @pmco = null
   end



---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMTP', ' Template: ' + isnull(i.Template,'') + ' Phase: ' + isnull(i.Phase,''), i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMTH = 'Y'


RETURN 
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTPu    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMTPu] on [dbo].[bPMTP] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMTP
 * Created By:	GF 12/13/2006 - 6.x auditing
 * Modified By:  JayR 03/28/2012 Remove unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMTP', 'Template: ' + isnull(i.Template,'') + ' Phase: ' + isnull(i.Phase,''),
	i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Template=i.Template
	and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bPMCO c on c.PMCo=i.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMTH = 'Y'
if update(Item)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMTP', 'Template: ' + isnull(i.Template,'') + ' Phase: ' + isnull(i.Phase,''),
	i.PMCo, 'C', 'Item',  d.Item, i.Item, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Template=i.Template
	and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bPMCO c on c.PMCo=i.PMCo
	where isnull(d.Item,'') <> isnull(i.Item,'') and c.AuditPMTH = 'Y'
if update(SICode)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMTP', 'Template: ' + isnull(i.Template,'') + ' Phase: ' + isnull(i.Phase,''),
	i.PMCo, 'C', 'SICode',  d.SICode, i.SICode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Template=i.Template
	and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bPMCO c on c.PMCo=i.PMCo
	where isnull(d.SICode,'') <> isnull(i.SICode,'') and c.AuditPMTH = 'Y'



RETURN 
   
   
  
 






GO
