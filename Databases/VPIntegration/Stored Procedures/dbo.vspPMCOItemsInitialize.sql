SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE proc [dbo].[vspPMCOItemsInitialize]
/***********************************************************
 * Created By:	GF 02/20/2006 6.x
 * Modified By: GF 03/26/2007 - issue #124177 check for at least one status code
 *				GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
 *				GF 03/05/2009 - issue #132046 - PCO internal add-on initialize
 *				GF 08/03/2010 - issue #134354 use standard flag when inserting change order addons.
 *				GF 08/03/2010 - issue #140860 format approved date without time
 *				GF 09/03/2010 - issue #141031 change to use date only function
 *
 *
 * USAGE:
 * Validates PM Pending Change Order Item or Approved Change
 * Order Item. Used in PMChgOrderInit to verify uniqueness.
 *
 * INPUT PARAMETERS
 *	PMCO - JC Company
 *  PROJECT - Project
 *  PCOType - PCO type
 *  PCO - Pending Change Order
 *  PCOItem - PCO Item
 *	ACO		- Approved Change Order
 *	ACOItem	- ACO Item
 *
 * OUTPUT PARAMETERS
 *   @msg - error message if error occurs
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @contract bContract = null, @pcotype bDocType = null,
 @pco bPCO = null, @aco bACO = null, @approvedby bVPUserName = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @validcnt int, @beginstatus bStatus, @finalstatus bStatus, 
   		@phasegroup bGroup, @approveddate bDate, @errmsg varchar(255),
		@opencursor int, @contractitem bContractItem, @coitem bPCOItem, @codesc bItemDesc,
		@coum bUM, @counits bUnits, @coitemuc bUnitCost, @coamount bDollar,
		@fixedyn bYN, @generateyn bYN, @coitem_count int

select @rcode = 0, @retcode = 0, @opencursor = 0, @coitem_count = 0, @validcnt = 0

---- set approval date
----#141031
set @approveddate = dbo.vfDateOnly()

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @contract is null
   	begin
   	select @msg = 'Missing Contract!', @rcode = 1
   	goto bspexit
   	end

if @pcotype is null
   	begin
   	select @pco = null
   	-- -- -- check ACO
   	if @aco is null
   		begin
   		select @msg = 'Missing ACO!', @rcode = 1
   		goto bspexit
   		end
   	end
else
   	begin
   	select @aco = null
   	-- -- -- check PCO
   	if @pco is null
   		begin
   		select @msg = 'Missing PCO!', @rcode = 1
   		goto bspexit
   		end
   	end

-- -- -- validate company - get phase group
select @phasegroup=PhaseGroup from HQCO with (nolock) where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg='Missing data group for HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
	goto bspexit
	end

if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
	goto bspexit
	end

---- check to make sure we have at least one status code
select @validcnt = count(*) from PMSC with (nolock)
if @validcnt = 0
	begin
	select @msg = 'At least one status code is required to initialize change orders.', @rcode = 1
	goto bspexit
	end

-- -- -- get begin status for PCO items
select @beginstatus=BeginStatus, @finalstatus=FinalStatus 
from PMCO with (nolock) where PMCo=@pmco
-- -- -- if missing begin status
if @beginstatus is null
   	begin
   	select @beginstatus = min(Status) from PMSC with (nolock) where CodeType = 'B'
   	if @@rowcount = 0
   		begin
   		select @beginstatus = min(Status) from PMSC with (nolock)
   		end
   	end
-- -- -- if missing final status
if @finalstatus is null
   	begin
   	select @finalstatus = min(Status) from PMSC with (nolock) where CodeType = 'F'
   	if @@rowcount = 0
   		begin
   		select @finalstatus = min(Status) from PMSC with (nolock)
   		end
   	end

-- -- -- declare cursor on PMOZ for UserId and COItem is not null
declare bcPMOZ cursor for select ContractItem, Description, COItem, AddlUnits, UM, UnitPrice, Amount, Fixed, Generate
from PMOZ
where UserId = @approvedby and isnull(COItem,'') <> ''

-- -- -- open cursor
open bcPMOZ
set @opencursor = 1

PMOZ_loop:
fetch next from bcPMOZ into @contractitem, @codesc, @coitem, @counits, @coum, @coitemuc, @coamount, @fixedyn, @generateyn
if @@fetch_status <> 0 goto PMOZ_end


-- -- -- initialize item, either a ACO Item or PCO Item depending on whether PCOType is null
if isnull(@pcotype,'') = ''
   	begin
   	-- -- -- ACO items - no fixed amount
   	insert into bPMOI (PMCo, Project, ACO, ACOItem, Description, Status, UM,
   			Units, UnitPrice, PendingAmount, ApprovedAmt, Issue, Contract, ContractItem,
   			Approved, ApprovedBy, ApprovedDate, ForcePhaseYN, FixedAmountYN, FixedAmount)
   	select @pmco, @project, @aco, @coitem, @codesc, @finalstatus, @coum,
   			@counits, @coitemuc, 0, @coamount, null, @contract, @contractitem, 
   			'Y', @approvedby, @approveddate, 'N', 'N', 0
   	if @@rowcount = 0
   		begin
   		select @msg = 'Error occurred initializing ACO Item: ' + isnull(@coitem,'') + '.' + char(13) + char(10), @rcode = 1
   		goto PMOZ_loop
   		end

   	-- -- -- if generate flag is 'Y' then execute SP to generate ACO detail
   	if @generateyn = 'Y'
   		begin
   		exec @retcode = dbo.bspPMOLACOGenerate @pmco, @project, @aco, @coitem, @contract, @contractitem, @errmsg output
   		end
   	end
else
   	begin
   	-- -- -- PCO items - update fixed amount if FixedAmt flag is 'Y'
   	if @fixedyn = 'Y'
   		begin
   		if not exists(select PMCo from bPMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
   						and PCO=@pco and PCOItem=@coitem)
   			begin
   			insert into bPMOI (PMCo,Project,PCOType,PCO,PCOItem,Description,Status,UM,Units,UnitPrice,
   					PendingAmount,Issue,Contract,ContractItem,Approved,ForcePhaseYN,FixedAmountYN,FixedAmount)
   			select @pmco, @project, @pcotype, @pco, @coitem, @codesc, @beginstatus, @coum, @counits, @coitemuc,
   					0, null, @contract, @contractitem, 'N', 'N', 'Y', @coamount
   			-- -- -- insert markups and addons
   			if @@rowcount <> 0
   				begin
   				---- PMOM
   				insert into bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
   				select @pmco, @project, @pcotype, @pco, @coitem, @phasegroup, a.CostType, 0, isnull(a.Markup,0)
   				from bPMPC a where a.PMCo=@pmco and a.Project=@project
   				and not exists(select PMCo from bPMOM b where b.PMCo=@pmco and b.Project=@project and b.PCOType=@pcotype
   							and b.PCO=@pco and b.PCOItem=@coitem and b.CostType=a.CostType)
   				---- PMOA
   				insert into dbo.bPMOA(PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent,
							AddOnAmount, Status, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup)
   				select @pmco, @project, @pcotype, @pco, @coitem, a.AddOn, a.Basis, a.Pct,
							a.Amount, 'N', a.TotalType, a.Include, a.NetCalcLevel, a.BasisCostType, a.PhaseGroup
   				from dbo.bPMPA a
				----#132046
				join dbo.bPMOP h on h.PMCo=a.PMCo and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
				join dbo.bPMDT t on t.DocType=h.PCOType
				----#134354
				where a.PMCo=@pmco and a.Project=@project and a.Standard = 'Y'
				and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
   				and not exists(select PMCo from dbo.bPMOA b where b.PMCo=@pmco and b.Project=@project and b.PCOType=@pcotype
   							and b.PCO=@pco and b.PCOItem=@coitem and b.AddOn=a.AddOn)
   				end
   			end
   		end
	else
   		begin
   		insert into bPMOI (PMCo,Project,PCOType,PCO,PCOItem,Description,Status,UM,Units,UnitPrice,
   				PendingAmount,Issue,Contract,ContractItem,Approved,ForcePhaseYN,FixedAmountYN,FixedAmount)
   		select @pmco, @project, @pcotype, @pco, @coitem, @codesc, @beginstatus, @coum, @counits, 0,
   				0, null, @contract, @contractitem, 'N', 'N', 'N', 0
   		-- -- -- insert markups and addons
   		if @@rowcount <> 0
   			begin
   			---- PMOM
   			insert into bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
   			select @pmco, @project, @pcotype, @pco, @coitem, @phasegroup, a.CostType, 0, isnull(a.Markup,0)
   			from bPMPC a where a.PMCo=@pmco and a.Project=@project
   			and not exists(select PMCo from bPMOM b where b.PMCo=@pmco and b.Project=@project and b.PCOType=@pcotype
   						and b.PCO=@pco and b.PCOItem=@coitem and b.CostType=a.CostType)
   			---- PMOA
   			insert into dbo.bPMOA(PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent,
					AddOnAmount, Status, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup)
   			select @pmco, @project, @pcotype, @pco, @coitem, a.AddOn, a.Basis, a.Pct,
					a.Amount, 'N', a.TotalType, a.Include, a.NetCalcLevel, a.BasisCostType, a.PhaseGroup
   			from dbo.bPMPA a
			----#132046
			join dbo.bPMOP h on h.PMCo=a.PMCo and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
			join dbo.bPMDT t on t.DocType=h.PCOType
			----#134354
			where a.PMCo=@pmco and a.Project=@project and a.Standard = 'Y'
			and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
   			and not exists(select PMCo from dbo.bPMOA b where b.PMCo=@pmco and b.Project=@project and b.PCOType=@pcotype
   						and b.PCO=@pco and b.PCOItem=@coitem and b.AddOn=a.AddOn)
   			end
   		end

	-- -- -- if generate flag is 'Y' then execute SP to generate PCO detail
   	if @generateyn = 'Y'
   		begin
   		exec @retcode = dbo.bspPMOLPCOGenerate @pmco, @project, @pcotype, @pco, @coitem, @contract, @contractitem, @errmsg output
   		end

   	-- -- -- calculate pending amount, addons, markups
   	exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @coitem
   	end


-- -- -- remove row from PMOZ
select @coitem_count = @coitem_count + 1
delete from PMOZ where PMCo=@pmco and UserId=@approvedby and ContractItem=@contractitem and COItem=@coitem


goto PMOZ_loop





PMOZ_end:
	if @opencursor = 1
		begin
		close bcPMOZ
		deallocate bcPMOZ
		set @opencursor = 0
		end


bspexit:
	if @opencursor = 1
		begin
		close bcPMOZ
		deallocate bcPMOZ
		set @opencursor = 0
		end

	if @rcode = 0 
		select @msg = 'There were CO Items: ' + convert(varchar(8),@coitem_count) + ' initialized.'
	else
		select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOItemsInitialize] TO [public]
GO
