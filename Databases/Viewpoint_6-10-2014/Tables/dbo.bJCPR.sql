CREATE TABLE [dbo].[bJCPR]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ResTrans] [dbo].[bTrans] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[BudgetCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Employee] [dbo].[bEmployee] NULL,
[Description] [dbo].[bItemDesc] NULL,
[DetMth] [dbo].[bMonth] NULL,
[FromDate] [dbo].[bDate] NULL,
[ToDate] [dbo].[bDate] NULL,
[Quantity] [dbo].[bUnits] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NULL,
[UnitHours] [dbo].[bHrs] NULL,
[Hours] [dbo].[bHrs] NULL,
[Rate] [dbo].[bUnitCost] NULL,
[UnitCost] [dbo].[bUnitCost] NULL,
[Amount] [dbo].[bDollar] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btJCPRd  ******/
CREATE trigger [dbo].[btJCPRd] on [dbo].[bJCPR] for DELETE as
/*-----------------------------------------------------------------
* Created By:	GF 03/28/2009 - issue #129898
* Modified By:	JonathanP 05/29/2009 - #133437 - Added code to clean up attachments.
*
*
*
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- Audit deletes
----insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
----select 'bJCPR', 'JCCo: ' + convert(char(3), d.JCCo) + ' Month: ' + convert(varchar(30), d.Mth) + ' ResTrans: ' + convert(varchar(10),d.ResTrans),
----d.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
----from deleted d

-- issue #133437
-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		  select AttachmentID, suser_name(), 'Y' 
			  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
			  where d.UniqueAttchID is not null


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete JC Projection Detail Record!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btJCPRi ******/
CREATE  trigger [dbo].[btJCPRi] on [dbo].[bJCPR] for insert as
/**************************************************************
* Created By:	GF 03/29/2009 - issue #129898
* Modified By:	CHS	08/20/2009	- issue #135183
*
*
*
*
* This trigger rejects insert in bJCPR (JC Projection Resource Detail)
* if the following error condition exists:
*
* invalid Phase or CostType
* TransType not in 'OE' or '- currently only insert are allowed
* Still needs check for valid BatchId, inuseBatchId, reversal status, ECM,
* postedum, ACO, ACOItem
*
*      note
*      (Future checks AP, PM, PR, MS, EM, PO, ???)
*  This trigger does not use a cursor, rather it iterates througt the inserted
*      table using @KeyCo, @KeyMonth & @Trans
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
		@rcode int, @retmsg varchar(255), @ctstring varchar(5),

		@jcco bCompany, @mth bMonth, @restrans bTrans, @job bJob, @phasegroup tinyint, 
		@phase bPhase, @costtype bJCCType, @jctranstype varchar(2), @source bSource, 
		@posteddate bDate, @actualdate bDate, @budgetcode varchar(10), @emco bCompany,
		@equipment bEquip, @prco bCompany, @craft bCraft, @class bClass, @description bItemDesc,
		@fromdate bDate, @todate bDate, @um bUM, @units bUnits, @unithours bHrs, @hours bHrs,
		@rate bUnitCost, @unitcost bUnitCost, @amount bDollar, @employee bEmployee,
		@quantity bUnits, @detmth bMonth


select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


if @numrows = 1
	select @jcco = JCCo, @mth = Mth, @restrans = ResTrans, @job = Job, @phasegroup = PhaseGroup, 
		@phase = Phase, @costtype = CostType, @jctranstype = JCTransType, @source = Source,
		@posteddate = PostedDate, @actualdate = ActualDate, @budgetcode = BudgetCode,
		@emco = EMCo, @equipment = Equipment, @prco = PRCo, @craft = Craft, @class = Class,
		@description = Description, @fromdate = FromDate, @todate = ToDate, @um = UM,
		@units = Units, @unithours = UnitHours, @hours = Hours, @rate = Rate, @unitcost = UnitCost,
		@amount = Amount, @employee = Employee, @detmth = DetMth, @quantity = Quantity
    from inserted
else
    begin
	-- use a cursor to process each inserted row
	declare bJCPR_insert cursor LOCAL FAST_FORWARD
	for select JCCo, Mth, ResTrans, Job, PhaseGroup, Phase, CostType, JCTransType, Source, 
		PostedDate, ActualDate, BudgetCode, EMCo, Equipment, PRCo, Craft, Class, Description,
		FromDate, ToDate, UM, Units, UnitHours, Hours, Rate, UnitCost, Amount,
		Employee, DetMth, Quantity
	from inserted

	open bJCPR_insert

    fetch next from bJCPR_insert into @jcco, @mth, @restrans, @job, @phasegroup, 
		@phase, @costtype, @jctranstype, @source, @posteddate, @actualdate, @budgetcode,
		@emco, @equipment, @prco, @craft, @class, @description, @fromdate, @todate, @um,
		@units, @unithours, @hours, @rate, @unitcost, @amount, @employee, @detmth, @quantity

    if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
    end

insert_check:
    
---- Validate JC Trans Type
if @jctranstype <> 'PF'
	begin
	select @errmsg = 'Invalid Trans Type.'
	goto error
	End
   
---- validate Source
if @source <> 'JC Projctn'
	begin
	select @errmsg = 'Invalid Source.'
	goto error
	End

---- validate job
if not exists (select 1 from bJCJM with (nolock) where JCCo = @jcco and Job = @job)
	begin
	select @errmsg = 'Job is invalid.'
	goto error
	end

---- validate PhaseGroup
if not exists (select 1 from bHQGP with (nolock) where Grp=@phasegroup)
	begin
	select @errmsg = 'Phase Group ' + isnull(convert(varchar(3),@phasegroup),'') + ' - is invalid.'
	goto error
	end


---- validate phase
exec @rcode = bspJCVPHASEForJCJP @jcco, @job, @phase, 'N', @errmsg output 
if @rcode <> 0 goto error

---- validate CostType
----select @ctstring=convert(varchar(5),@costtype)
----exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @ctstring, 'P', @errmsg output
----if @rcode <> 0 goto error

---- validate UM
if isnull(@um,'') = ''
	begin
	select @errmsg = 'UM cannot be null.'
	goto error
	end
if not exists (select 1 from bHQUM with (nolock) where UM=@um)
	begin
	select @errmsg = 'UM is invalid.'
	goto error
	end

---- from and to date validation
if isnull(@fromdate,'') = '' and isnull(@todate,'') <> ''
	begin
	select @errmsg = 'Must have a from date when a to date is entered.'
	goto error
	end

if isnull(@fromdate,'') <> '' and isnull(@todate,'') = ''
	begin
	select @errmsg = 'Must have a to date when a from date is entered.'
	goto error
	end

---- check from and to date range, to date cannot be less than from date
if isnull(@fromdate,'') <> '' and isnull(@todate,'') <> ''
	begin
	if @todate < @fromdate
		begin
		select @errmsg = 'The to date cannot be earlier than the from date.'
		goto error
		end
	end

---- validate budget code
if isnull(@budgetcode,'') <> ''
	begin
	if not exists (select 1 from bPMEC with (nolock) where PMCo = @jcco and BudgetCode = @budgetcode)
		begin
		select @errmsg = 'Budget code is invalid.'
		goto error
		end
	end

---- validate EM Company and Equipment
if isnull(@emco,'') <> ''
	begin
	if not exists (select 1 from bEMCO with (nolock) where EMCo = @emco)
		begin
		select @errmsg = 'EM Company is invalid.'
		goto error
		end

	---- validate equipment
	if isnull(@equipment,'') <> ''
		begin
		if not exists (select 1 from bEMEM with (nolock) where EMCo = @emco and Equipment=@equipment)
			begin
			select @errmsg = 'EM Equipment is invalid.'
			goto error
			end
		end
	end

---- validate PR Company, Craft, Class
if isnull(@prco,'') <> ''
	begin
	if not exists (select 1 from bPRCO with (nolock) where PRCo = @prco)
		begin
		select @errmsg = 'PR Company is invalid.'
		goto error
		end

	---- validate employee
	if isnull(@employee,'') <> ''
		begin
--		if not exists(select 1 from bPREM with (nolock) where PRCo=@prco and Employee=@employee) #135183
		if not exists(select 1 from bPREH with (nolock) where PRCo=@prco and Employee=@employee)
			begin
			select @errmsg = 'PR Employee is invalid.'
			goto error
			end
		end

	---- validate craft
	if isnull(@craft,'') <> ''
		begin
		if not exists(select 1 from bPRCM with (nolock) where PRCo=@prco and Craft=@craft)
			begin
			select @errmsg = 'PR Craft is invalid.'
			goto error
			end

		if isnull(@class,'') <> ''
			begin
			if not exists(select 1 from bPRCC with (nolock) where PRCo=@prco and Craft=@craft and Class=@class)
				begin
				select @errmsg = 'PR Craft/Class is invalid'
				goto error
				end
			end
		end

	if isnull(@craft,'') = '' and isnull(@class,'') <> ''
		begin
		select @errmsg = 'PR Craft must be specified if Class is entered'
		end

	if isnull(@craft,'') <> '' and isnull(@class,'') = ''
		begin
		select @errmsg = 'PR Class is missing'
		goto error
		end
	end







if @numrows > 1
	begin
	fetch next from bJCPR_insert into @jcco, @mth, @restrans, @job, @phasegroup, 
		@phase, @costtype, @jctranstype, @source, @posteddate, @actualdate, @budgetcode,
		@emco, @equipment, @prco, @craft, @class, @description, @fromdate, @todate, @um,
		@units, @unithours, @hours, @rate, @unitcost, @amount, @employee, @detmth, @quantity

	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close bJCPR_insert
		deallocate bJCPR_insert
		end
	end



---- Audit inserts
----insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
----select 'bJCPR', 'JCCo: ' + convert(varchar(3), i.JCCo) + ' Mth: ' + convert(varchar(30),i.Mth,1) + ' ResTrans: ' + convert(varchar(10),i.ResTrans),
----i.JCCo, 'A', null, null, null, getdate(), suser_sname()
----from inserted i



Return


error:
	select @errmsg = @errmsg + ' - cannot insert Projection Detail Trans: ' + convert(varchar(8),isnull(@restrans,0)) + ' Phase: ' + isnull(@phase,'') + ' CostType: ' + convert(varchar(3),isnull(@costtype,0))
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btJCPRu   ******/
CREATE trigger [dbo].[btJCPRu] on [dbo].[bJCPR] for update as
/**************************************************************
* Created By:	GF 03/29/2009 - issue #129898
* Modified By:

*
*
* invalid Phase or CostType
* TransType not in 'PF' or '- currently only insert are allowed
* Still needs check for valid BatchId, inuseBatchId
*
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @numrows int,
		@override char(1), @rcode int, @retmsg varchar(255), @ctstring varchar(5),

		@jcco bCompany, @mth bMonth, @restrans bTrans, @job bJob, @phasegroup tinyint, 
		@phase bPhase, @costtype bJCCType, @jctranstype varchar(2), @source bSource, 
		@posteddate bDate, @actualdate bDate, @budgetcode varchar(10), @emco bCompany,
		@equipment bEquip, @prco bCompany, @craft bCraft, @class bClass, @description bItemDesc,
		@fromdate bDate, @todate bDate, @um bUM, @units bUnits, @unithours bHrs, @hours bHrs,
		@rate bUnitCost, @unitcost bUnitCost, @amount bDollar, @employee bEmployee,
		@quantity bUnits, @detmth bMonth

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


----If the only column that changed was UniqueAttachID, then skip validation.        
IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bJCCD', 'UniqueAttchID') = 1
	BEGIN 
	goto Trigger_Skip
	END    

---- see if any fields have changed that is not allowed
if update(JCCo) or Update(Mth) or Update(ResTrans)
   	begin
   	select @validcnt = count(*) from inserted i
   	JOIN deleted d ON d.JCCo = i.JCCo and d.Mth=i.Mth and d.ResTrans=i.ResTrans
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Primary key fields may not be changed'
   		GoTo error
   		End
   	End

---- if we are pulling a transaction into batch and updating InUseBatchId
---- with a batch id then skip trigger validation.
if Update(InUseBatchId) 
	begin
	select @validcnt = count(*) from inserted i where InUseBatchId is not null
   	select @validcnt2 = count(*) from deleted d where InUseBatchId is null
   	if @validcnt = @validcnt2 and @validcnt = @numrows goto Trigger_Skip
	End


if @numrows = 1
	begin
	select @jcco = JCCo, @mth = Mth, @restrans = ResTrans, @job = Job, @phasegroup = PhaseGroup, 
			@phase = Phase, @costtype = CostType, @jctranstype = JCTransType, @source = Source,
			@posteddate = PostedDate, @actualdate = ActualDate, @budgetcode = BudgetCode,
			@emco = EMCo, @equipment = Equipment, @prco = PRCo, @craft = Craft, @class = Class,
			@description = Description, @fromdate = FromDate, @todate = ToDate, @um = UM,
			@units = Units, @unithours = UnitHours, @hours = Hours, @rate = Rate, @unitcost = UnitCost,
			@amount = Amount, @employee = Employee, @detmth = DetMth, @quantity = Quantity
	from inserted
	end
else
	begin
	-- use a cursor to process each inserted row
	declare bJCPR_update cursor LOCAL FAST_FORWARD
	for select JCCo, Mth, ResTrans, Job, PhaseGroup, Phase, CostType, JCTransType, Source, 
		PostedDate, ActualDate, BudgetCode, EMCo, Equipment, PRCo, Craft, Class, Description,
		FromDate, ToDate, UM, Units, UnitHours, Hours, Rate, UnitCost, Amount,
		Employee, DetMth, Quantity
	from inserted

	open bJCPR_update

    fetch next from bJCPR_update into @jcco, @mth, @restrans, @job, @phasegroup, 
		@phase, @costtype, @jctranstype, @source, @posteddate, @actualdate, @budgetcode,
		@emco, @equipment, @prco, @craft, @class, @description, @fromdate, @todate, @um,
		@units, @unithours, @hours, @rate, @unitcost, @amount, @employee, @detmth, @quantity

	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end



update_check:
---- Validate JC Trans Type
if update(JCTransType)
   	begin
   	if @jctranstype <> 'PF'
   		begin
   		select @errmsg = 'TransType ' + isnull(@jctranstype,'') + ' is invalid.'
   		GoTo error
   		end
   	end

---- validate Source
if update(Source)
   	Begin
   	if @source <> 'JC Projctn'
   		begin
   		select @errmsg = 'Source ' + isnull(@source,'') + ' is invalid.'
		GoTo error
   		End
   	End

---- validate UM
if update(UM)
   	begin
	if isnull(@um,'') = ''
		begin
		select @errmsg = 'UM cannot be null.'
		goto error
		end
	if not exists (select 1 from bHQUM with (nolock) where UM=@um)
		begin
		select @errmsg = 'UM is invalid.'
		goto error
		end
	end

set @override='N'

---- validate standard phase - if it doesnt exist in JCJP try to add it
if update(Job) or update(Phase)
   	begin
   	exec @rcode = dbo.bspJCADDPHASE @jcco, @job, @phasegroup, @phase, @override, null, @errmsg output
   	if @rcode<>0 goto error
   	end

---- if source is JC Projection, the @override must be P
set @override = 'P'

---- validate cost type - if JCCH does not exist try to add it
if update(Job) or update(Phase) or update(CostType)
   	begin
   	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@jcco, @job=@job, @phasegroup=@phasegroup, @phase=@phase,
   						@costtype=@costtype, @override= @override, @msg=@errmsg output
   	if @rcode<>0 goto error
   	end


---- from and to date validation
if update(FromDate) or update (ToDate)
	begin
	if isnull(@fromdate,'') = '' and isnull(@todate,'') <> ''
		begin
		select @errmsg = 'Must have a from date when a to date is entered.'
		goto error
		end

	if isnull(@fromdate,'') <> '' and isnull(@todate,'') = ''
		begin
		select @errmsg = 'Must have a to date when a from date is entered.'
		goto error
		end

	---- check from and to date range, to date cannot be less than from date
	if isnull(@fromdate,'') <> '' and isnull(@todate,'') <> ''
		begin
		if @todate < @fromdate
			begin
			select @errmsg = 'The to date cannot be earlier than the from date.'
			goto error
			end
		end
	end

---- validate budget code
if update(BudgetCode)
	begin
	if isnull(@budgetcode,'') <> ''
		begin
		if not exists (select 1 from bPMEC with (nolock) where PMCo = @jcco and BudgetCode = @budgetcode)
			begin
			select @errmsg = 'Budget code is invalid.'
			goto error
			end
		end
	end

---- validate EM Company and Equipment
if update(EMCo) or update(Equipment)
	begin
	if isnull(@emco,'') <> ''
		begin
		if not exists (select 1 from bEMCO with (nolock) where EMCo = @emco)
			begin
			select @errmsg = 'EM Company is invalid.'
			goto error
			end

		---- validate equipment
		if isnull(@equipment,'') <> ''
			begin
			if not exists (select 1 from bEMEM with (nolock) where EMCo = @emco and Equipment=@equipment)
				begin
				select @errmsg = 'EM Equipment is invalid.'
				goto error
				end
			end
		end
	end

---- validate PR Company, Craft, Class
if update(PRCo) or update(Craft) or update(Class)
	begin
	if isnull(@prco,'') <> ''
		begin
		if not exists (select 1 from bPRCO with (nolock) where PRCo = @prco)
			begin
			select @errmsg = 'PR Company is invalid.'
			goto error
			end

		---- validate employee
		if isnull(@employee,'') <> ''
			begin
			if not exists(select 1 from bPREM with (nolock) where PRCo=@prco and Employee=@employee)
				begin
				select @errmsg = 'PR Employee is invalid.'
				goto error
				end
			end

		---- validate craft
		if isnull(@craft,'') <> ''
			begin
			if not exists(select 1 from bPRCM with (nolock) where PRCo=@prco and Craft=@craft)
				begin
				select @errmsg = 'PR Craft is invalid.'
				goto error
				end

			if isnull(@class,'') <> ''
				begin
				if not exists(select 1 from bPRCC with (nolock) where PRCo=@prco and Craft=@craft and Class=@class)
					begin
					select @errmsg = 'PR Craft/Class is invalid'
					goto error
					end
				end
			end

		if isnull(@craft,'') = '' and isnull(@class,'') <> ''
			begin
			select @errmsg = 'PR Craft must be specified if Class is entered'
			end

		if isnull(@craft,'') <> '' and isnull(@class,'') = ''
			begin
			select @errmsg = 'PR Class is missing'
			goto error
			end
		end
	end



if @numrows > 1
	begin
   	fetch next from bJCPR_update into @jcco, @mth, @restrans, @job, @phasegroup, 
			@phase, @costtype, @jctranstype, @source, @posteddate, @actualdate, @budgetcode,
			@emco, @equipment, @prco, @craft, @class, @description, @fromdate, @todate, @um,
			@units, @unithours, @hours, @rate, @unitcost, @amount, @employee, @detmth, @quantity

    if @@fetch_status = 0 goto update_check

    close bJCPR_update
    deallocate bJCPR_update
    end




Trigger_Skip:
	Return


error:
   	select @errmsg = @errmsg + ' - cannot update Projection Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
ALTER TABLE [dbo].[bJCPR] ADD CONSTRAINT [PK_bJCPR] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCPRTrans] ON [dbo].[bJCPR] ([JCCo], [Mth], [ResTrans]) ON [PRIMARY]
GO
