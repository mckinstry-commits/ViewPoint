SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPCOAddonDistCosts    Script Date: 8/28/99 9:33:05 AM ******/
CREATE proc [dbo].[vspPMPCOAddonDistCosts]
/***********************************************************
* CREATED BY:	GF 01/13/2008 - issue #129669 proportionally distribute add-on costs
* MODIFIED BY:
*
*
*
*
*
* USAGE: This procedure will be called when a PCO item is approved or assigned to
* a ACO Item to create phase cost type records using PMOB for add-ons that are
* cost based and amounts need to be distributed when PCO item is approved.
*
*
* INPUT PARAMETERS
* PMCO
* PROJECT
* PCOType
* PCO
* PCOItem
* ACO
* ACOItem
*
*
* OUTPUT PARAMETERS
*
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
 @pcoitem bPCOItem = null, @aco bACO = null, @acoitem bPCOItem = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor int, @phasegroup bGroup, @phase bPhase,
		@costtype bJCCType, @amttodist bDollar, @estunits bUnits, @esthours bHrs


select @rcode = 0, @opencursor = 0

if @pmco is null or @project is null or @pcotype is null or @pco is null or @pcoitem is null or @aco is null or @acoitem is null
	begin
	goto bspexit
	end

---- if no records exist in PMOB for PCO Item
---- then there is nothing to distribute
if not exists(select 1 from bPMOB with (nolock) where PMCo=@pmco and Project=@project
			and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
	begin
	goto bspexit
	end

---------------------------------
---- declare cursor for PMOB ----
---------------------------------

---- declare cursor on PMOB to create approved change order detail
declare bcPMOB cursor local FAST_FORWARD for select PhaseGroup, Phase, CostType, isnull(AmtToDistribute,0)
from bPMOB where PMCo=@pmco and Project=@project
and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem

-- open cursor
open bcPMOB
select @opencursor = 1

PMOB_loop:
fetch next from bcPMOB into @phasegroup, @phase, @costtype, @amttodist

if @@fetch_status <> 0 goto PMOB_end

---- need to insert or update an existing record in PMOL for the ACO Item
select @estunits=EstUnits, @esthours=EstHours
from bPMOL with (nolock)
where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
if @@rowcount = 1
	begin
	---- detail exists, will update estimate cost, distributed amount, and
	---- recalculate unit cost and hour cost.
	update bPMOL
			set EstCost = EstCost + isnull(@amttodist,0),
				DistributedAmt = DistributedAmt + isnull(@amttodist,0),
				UnitCost = case when @estunits <> 0 then ((EstCost + @amttodist) / @estunits) else 0 end,
				HourCost = case when @esthours <> 0 then ((EstCost + @amttodist) / @esthours) else 0 end
	where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
	and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
	end
else
	begin
	---- detail does not exist, we are adding a new lump sum record, no units, no hours
	---- add estimate cost and distributed amount, send flag = 'Y', created from addon = 'Y'
	insert into bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase,
			CostType, EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost,
			SendYN, InterfacedDate, CreatedFromAddOn, DistributedAmt)
	select @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @phasegroup, @phase,
			@costtype, 0, 'LS', 0, 0, 0, 0, 'E', @amttodist,
			'Y', null, 'Y', @amttodist
	end

---- remove record in bPMOB
delete from bPMOB from bPMOB
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype


goto PMOB_loop


PMOB_end:
	if @opencursor = 1
		begin
		close bcPMOB
		deallocate bcPMOB
		select @opencursor = 0
		end


bspexit:
	if @opencursor = 1
		begin
		close bcPMOB
		deallocate bcPMOB
		select @opencursor = 0
		end
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAddonDistCosts] TO [public]
GO
