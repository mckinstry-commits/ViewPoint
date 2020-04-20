CREATE TABLE [dbo].[bJCJP]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[ProjMinPct] [dbo].[bPct] NULL,
[ActiveYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[InsCode] [dbo].[bInsCode] NULL,
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

/****** Object:  Trigger dbo.btJCJPd    Script Date: 8/28/99 9:37:45 AM ******/
CREATE trigger [dbo].[btJCJPd] on [dbo].[bJCJP] for DELETE as 
/*-------------------------------------------------------------- 
 * Delete trigger for JCJP
 * Created By:		Unknown
 * Modified By:	GF 01/22/2002 - Allows delete if in PM only. Signified by SourceStatus for JCCH records = (Y,N)
 *				GF 04/20/2007 - issue #124414 ADDED HQMA auditing
 *				GF 01/29/2010 - issue #135527 Job Phase Roles
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int,
		@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase,
		@costtype bJCCType

select @numrows = @@rowcount 
if @numrows = 0 return
set nocount on


---- pseudo cursor for deleted records by JCCo,Job,PhaseGroup,Phase
select @jcco = min(JCCo) from deleted
while @jcco is not null
begin
select @job = min(Job) from deleted where JCCo=@jcco
while @job is not null
begin
select @phasegroup = min(PhaseGroup) from deleted where JCCo=@jcco and Job=@job
while @phasegroup is not null
begin
select @phase = min(Phase) from deleted where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
while @phase is not null
begin

	---- pseudo cursor for JCCH records by deleted JCCo,Job,PhaseGroup,Phase
   	select @costtype = min(CostType) from bJCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
   	while @costtype is not null
   	begin
		---- delete JCCH record - all check are done in JCCH delete trigger
   		delete from bJCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
   		if @@Error <> 0 goto error
   		
   	select @costtype = min(CostType) from bJCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType>@costtype
   	if @@rowcount = 0 select @costtype = null
   	end

	---- delete job phase roles - #135527
	delete from dbo.vJCJPRoles where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
	
select @phase = min(Phase) from deleted where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase>@phase
if @@rowcount = 0 select @phase = null
end
select @phasegroup = min(PhaseGroup) from deleted where JCCo=@jcco and Job=@job and PhaseGroup>@phasegroup
if @@rowcount = 0 select @phasegroup = null
end
select @job = min(Job) from deleted where JCCo=@jcco and Job>@job
if @@rowcount = 0 select @job = null
end
select @jcco = min(JCCo) from deleted where JCCo>@jcco
if @@rowcount = 0 select @jcco = null
end



---- Auditing
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCJP','JCCo: ' + convert(varchar(3),deleted.JCCo) + ' Job: ' + deleted.Job + ' Phase: ' + deleted.Phase,
		deleted.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted join bJCCO ON deleted.JCCo=bJCCO.JCCo
where bJCCO.AuditPhases = 'Y'


return


error:
	select @errmsg = @errmsg + ' - cannot delete from JCJP'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
CREATE  trigger [dbo].[btJCJPi] on [dbo].[bJCJP] for INSERT as
/*-----------------------------------------------------------------
 * Created By:
 * Modified By:	JRE 12/01/2000 - Issue 11959 added check that the Contract number must be the same as in JCJM
 *				GF 08/08/2002 - Issue #17355 AutoAddItemYN flag from JCJM
 *				TV - 23061 added isnulls
 *				GF 02/07/2005 - issue #27007 use JCCM.StartMonth as JCCI.StartMonth default
 * 		 	    DANF 03/15/05 - #27294 - Remove scrollable cursor.
 *				GF 11/01/2006 - issue #122832 - when auto add contract item = 'Y' set bill descripiton also.
 *				GF 04/20/2007 - issue #124414 - added HQMA auditing
 *				EN 11/15/07 - issue #233649 - added job and phase info
 *				GF 06/04/2008 - issue #128547 only update PMPA when item is different
 *				GF 08/12/2008 - issue #129388 added check for override = 'O' which is from JCJP insert trigger.
 *				GF 02/11/2012 - TK-12470 issue #145758 description declared as 30 and S/B 60
 *
 *
 * This trigger rejects insertion in bJCJP  (JC Job Phases) if the
 * following error condition exists:
 *
 * Invalid Job Cost Company
 * Invalid Job
 * Invalid Phase according to Job/Phase validation rules
 * Invalide Contract
 *
 */----------------------------------------------------------------
declare @errmsg varchar(255), @rcode int, @numrows int, @validcnt int,
		@pp bPhase, @item bContractItem,
		@dept varchar(10), @contract bContract, @projminpct bPct,
		@co bCompany, @job bJob, @phase bPhase, @ct bJCCType, @PhaseGroup tinyint,
   		@vcontract bContract, @vitem bContractItem,@active char(1),@JCJPexists char(1),
   		@autoadditemyn bYN,
   		---- TK-12470
   		@desc VARCHAR(60), @description VARCHAR(60)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


if @numrows = 1
	select @co = JCCo, @job = Job, @phase = Phase, @PhaseGroup = PhaseGroup,
   		@contract = Contract, @item=Item, @projminpct=ProjMinPct, @active=ActiveYN,
   		@description = Description
	from inserted
else
   	begin
   	---- use a cursor to process each inserted row
   	declare bJCJP_insert cursor local fast_forward for select JCCo, Job, Phase, PhaseGroup, Contract,
   				Item, ProjMinPct, ActiveYN, Description
   	from inserted

   	open bJCJP_insert
   	fetch next from bJCJP_insert into @co, @job, @phase, @PhaseGroup, @contract,
   				@item, @projminpct, @active, @description
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end


insert_check:
---- validate standard phase
---- note bspJCVPHASE also validates bJCCO and bJCJM
exec @rcode=bspJCVPHASE @co,@job,@phase,@PhaseGroup,'O',@pp output, @desc output, @PhaseGroup output,
   					@vcontract output, @vitem output, @dept output, @projminpct output, @JCJPexists output, @errmsg output
if @rcode <> 0 goto error

---- validate Contract
if not exists (select * from bJCCM c JOIN bJCJM j on c.JCCo=j.JCCo and c.Contract=j.Contract
			where c.JCCo = @co and c.Contract = @contract and j.Job=@job and j.Contract=@contract)
	begin
	select @errmsg = isnull(@contract,'') + ' is an invalid Contract.'
	goto error
	end

---- validate Job's contract  issue 11959
if @contract <> (select Contract from bJCJM where JCCo = @co and Job=@job)
	begin
	select @errmsg = isnull(@item,'') + ' contract does not match the contract for the job.'
	goto error
	end

---- get AutoAddItemYN flag from bJCJM
select @autoadditemyn=AutoAddItemYN from bJCJM where JCCo=@co and Job=@job
if @@rowcount = 0 select @autoadditemyn='N'

---- Contract item must not be null
if isnull(@item,'') = ''
	begin
	select @errmsg = 'Missing contract item ' + @item + ' for job ' + @job + ' and phase ' + @phase + '.' --#233649 added job and phase info

	goto error
	end

---- validate contract item when AutoAddItemYN flag is 'N'
if @autoadditemyn = 'N'
	begin
	if not exists (select * from bJCCI c where c.JCCo = @co and c.Contract = @contract and c.Item=@item)
		begin
		select @errmsg = isnull(@item,'') + ' is an invalid Contract Item.'
		goto error
		end
	end

---- validate proj min %
if @projminpct < 0 or @projminpct > 1
	begin
	select @errmsg = Convert(varchar(14),@projminpct) + ' is not a valid percentage.'
	goto error
	end

---- validate ActiveYN
if @active<>'Y' and @active<>'N'
	begin
	select @errmsg = ' ActiveYN must be (Y) or (N)'
	goto error
	end

---- update contract item in bPMPA if different from bJCJP
if exists(select top 1 1 from bPMPA with (nolock) where PMCo=@co and Project=@job
			and Phase=@phase and Item is not null and Item <> @item)
	begin
	Update bPMPA set Item=@item
	where PMCo=@co and Project=@job and Phase=@phase
	end

---- when AutoAddItemYN is 'Y' create contract item in bJCCI when not exists
if @autoadditemyn = 'Y' and not exists(select JCCo from bJCCI where JCCo=@co 
					and Contract=@contract and Item=@item)
	begin
	---- now add contract Item 1 if there are no contract items
	insert into bJCCI(JCCo,Contract,Item,Description,Department,TaxGroup,TaxCode,UM,RetainPCT,BillType,StartMonth,BillDescription)
	select @co, @contract, @item, @description, c.Department, c.TaxGroup, c.TaxCode,
           		'LS', c.RetainagePCT, c.DefaultBillType, c.StartMonth, @description
	from bJCCM c where c.JCCo=@co and c.Contract=@contract
	end



---- fetch next row
if @numrows > 1
	begin
	fetch next from bJCJP_insert into @co, @job, @phase, @PhaseGroup, @contract, @item, @projminpct, @active, @description
	if @@fetch_status = 0
		begin
		goto insert_check
		end
	else
		begin
		close bJCJP_insert
		deallocate bJCJP_insert
		end
	end



---- Audit inserts
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bJCJP','JCCo: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase,
		i.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
from inserted i join bJCCO c on i.JCCo=c.JCCo
where c.AuditPhases = 'Y'



return


error:
	if @numrows > 1
		begin
   		close bJCJP_insert
   		deallocate bJCJP_insert
   		end
   
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Job Phase!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************/
CREATE trigger [dbo].[btJCJPu] on [dbo].[bJCJP] for update as
/*-----------------------------------------------------------------
 * This trigger rejects insertion in bJCJP  (JC Job Phases) if the
 * following error condition exists:
 * Created By:
 * Modified By:	GF 12/20/2002 - changed for auto-add contract item enhancement.
 *				TV - 23061 added isnulls
 *				GF 02/07/2005 - issue #27007 use JCCM.StartMonth as JCCI.StartMonth default
 *				gf 04/20/2007 - issue #124414 added HQMA auditing
 *				GF 11/18/2008 - issue #131??? use cursor if needed for performance.
  *				GF 04/20/2009 - issue #132326 JCCI start month cannot be null
  *				GF 03/02/2010 - issue #138332 need to set bill description to item description for JCCI insert
 *
 *
 *			
 *
 *		JCCO, Job, Phase, Contract has changed.
 *		Invalid Phase according to Job/Phase validation rules
 *		Invalid ProjMinPct
 *
 */----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @rcode int,
		@contract bContract, @item bContractItem, @projminpct real,
		@jcco bCompany, @job bJob, @phasegroup tinyint, @phase bPhase, 
		@activeyn char(1), @autoadditemyn bYN, @phasedesc bItemDesc,
		@origcost bDollar, @olditem bContractItem

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check if key values have changed
if update(JCCo)
	begin
	select @errmsg='Update to JC Company not allowed'
	goto error
	end

if update(Job)
	begin
	select @errmsg='Update to Job not allowed'
	goto error
	end

if update(Phase)
	begin
	select @errmsg='Update to Phase not allowed'
	goto error
	end

if update(Contract)
   	begin
   	if exists (select top 1 1 from bJCJM j with (nolock) join inserted i on j.JCCo=i.JCCo and j.Job=i.Job and j.Contract<>i.Contract)
       	begin
   		select @errmsg='Contract is not the same as on the Job Master'
   		goto error
       	end
   	end


------------------
-- CURSOR BEGIN --
------------------
if @numrows = 1
	begin
	select @jcco=i.JCCo, @job=i.Job, @phasegroup=i.PhaseGroup, @phase=i.Phase, @contract=i.Contract,
			@item=i.Item, @projminpct=i.ProjMinPct, @activeyn=i.ActiveYN, @phasedesc=i.Description,
			@olditem=d.Item
	from inserted i
	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	end
else
	begin
	declare bJCJP_update cursor LOCAL FAST_FORWARD
		for select i.JCCo, i.Job, i.PhaseGroup, i.Phase, i.Contract, i.Item,
				i.ProjMinPct, i.ActiveYN, i.Description, d.Item
	from inserted i
	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase

	open bJCJP_update

	fetch next from bJCJP_update into @jcco, @job, @phasegroup, @phase, @contract, @item,
				@projminpct, @activeyn, @phasedesc, @olditem

	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end

update_check:
---- validate proj min %
if @projminpct < 0 or @projminpct > 1
	begin
	select @errmsg = isnull(Convert(varchar(14),@projminpct),'') + ' is not a valid percentage'
	goto error
	end


---- if item has changed the auto-add item feature may apply
if isnull(@olditem,'') <> isnull(@item,'')
	begin
	---- get auto add item flag from JCJM
	select @autoadditemyn=AutoAddItemYN from bJCJM with (nolock) where JCCo=@jcco and Job=@job
	---- validate Contract Item - must exist if auto add feature off
	if isnull(@autoadditemyn,'N') = 'N'
		begin
		if not exists (select 1 from bJCCI c with (nolock) where c.JCCo=@jcco
					and c.Contract=@contract and c.Item=@item)
			begin
			select @errmsg = isnull(@item,'') + ' is not a valid Contract Item.'
			goto error
			end
		goto next_phase
		end
	else
		begin
		set @origcost = 0
		---- get estimated cost from bJCCH
		select @origcost = sum(h.OrigCost)
		from bJCCH h with (nolock)
		where h.JCCo=@jcco and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@phase
		if @@rowcount = 0 goto next_phase
		
		---- back out original cost from old item in bJCCI
		update bJCCI set OrigContractAmt = OrigContractAmt - @origcost
		where JCCo=@jcco and Contract=@contract and Item=@olditem
		
		---- check bJCCI to see if adding new item or changing item
		if not exists (select 1 from bJCCI c with (nolock) where c.JCCo=@jcco and c.Contract=@contract and c.Item=@item)
			begin
			---- now add contract Item
			---- #138332 - need to set bill description
			insert into bJCCI(JCCo, Contract, Item, Description, Department, TaxGroup, TaxCode, UM,
						RetainPCT, BillType, StartMonth, OrigContractAmt, BillDescription)
			select @jcco, @contract, @item, @phasedesc, c.Department, c.TaxGroup, c.TaxCode, 'LS',
						c.RetainagePCT, c.DefaultBillType, c.StartMonth, @origcost, @phasedesc
			from bJCCM c with (nolock) where c.JCCo=@jcco and c.Contract=@contract
			end
		else
			begin
			---- update item adding original cost from bJCCH
			update bJCCI set OrigContractAmt = OrigContractAmt + @origcost
			where JCCo=@jcco and Contract=@contract and Item=@item
			end
		end
	end



next_phase:
if @numrows > 1
	begin
	fetch next from bJCJP_update into @jcco, @job, @phasegroup, @phase, @contract, @item,
				@projminpct, @activeyn, @phasedesc, @olditem
	if @@fetch_status = 0
		begin
		goto update_check
		end
	else
		begin
		close bJCJP_update
		deallocate bJCJP_update
		end
	end


----------------
-- CURSOR END --
----------------


---- HQMA inserts
if not exists(select top 1 1 from inserted i join bJCCO c with (nolock) on i.JCCo=c.JCCo and c.AuditPhases='Y')
	begin
  	goto trigger_end
	end

---------- Audit inserts ----------
IF update(Description)
	begin
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJP','JCCo: ' + convert(varchar(3),i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase,
		i.JCCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bJCCO on i.JCCo=bJCCO.JCCo and bJCCO.AuditPhases = 'Y'
	where isnull(d.Description,'') <> isnull(i.Description,'')
	end
IF update(Contract)
	begin
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJP','JCCo: ' + convert(varchar(3),i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase,
		i.JCCo, 'C', 'Contract', d.Contract, i.Contract, getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bJCCO on i.JCCo=bJCCO.JCCo and bJCCO.AuditPhases = 'Y'
	where isnull(d.Contract,'') <> isnull(i.Contract,'')
	end
IF update(Item)
	begin
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJP','JCCo: ' + convert(varchar(3),i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase,
		i.JCCo, 'C', 'Item', d.Item, i.Item, getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bJCCO on i.JCCo=bJCCO.JCCo and bJCCO.AuditPhases = 'Y'
	where isnull(d.Item,'') <> isnull(i.Item,'')
	end
IF update(ActiveYN)
	begin
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJP','JCCo: ' + convert(varchar(3),i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase,
		i.JCCo, 'C', 'ActiveYN', d.ActiveYN, i.ActiveYN, getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bJCCO on i.JCCo=bJCCO.JCCo and bJCCO.AuditPhases = 'Y'
	where isnull(d.ActiveYN,'') <> isnull(i.ActiveYN,'')
	end
if update(ProjMinPct)
	begin
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJP','JCCo: ' + convert(varchar(3),i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase,
		i.JCCo, 'C', 'ProjMinPct', convert(varchar(16),d.ProjMinPct), convert(varchar(16),i.ProjMinPct),
		getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job and d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase
	join bJCCO on i.JCCo=bJCCO.JCCo and bJCCO.AuditPhases = 'Y'
	where isnull(convert(varchar(16),d.ProjMinPct),'') <> isnull(convert(varchar(16),i.ProjMinPct),'')
	end




trigger_end:
	return


error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update Job Phases!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE NONCLUSTERED INDEX [biJCJPContract] ON [dbo].[bJCJP] ([JCCo], [Contract], [Item], [Job]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCJP] ON [dbo].[bJCJP] ([JCCo], [Job], [PhaseGroup], [Phase]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCJP] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCJP].[ProjMinPct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJP].[ActiveYN]'
GO
EXEC sp_bindefault N'[dbo].[bdYes]', N'[dbo].[bJCJP].[ActiveYN]'
GO
