SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPCOAddonRevUnappr    Script Date: 8/28/99 9:33:05 AM ******/
CREATE proc [dbo].[vspPMPCOAddonRevUnappr]
/***********************************************************
 * CREATED BY:	GF 04/30/2008 - issue #22100 Project Addon Revenue
 * MODIFIED BY:
 *
 *
 *
 * USAGE: Called from vspPMUnapproveItem to check for addons assigned
 * to the PCO Item that have had the revenue re-directed to the ACO
 * item being unapproved.
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
 * Addon
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

declare @rcode int, @opencursor tinyint, @addon int, @revacoitemid bigint, 
		@revacoitemamt bDollar, @approvedamt bDollar, @units bUnits,
		@unitprice bUnitCost


select @rcode = 0, @opencursor = 0


---- declare cursor on PMPA Project Addons for redirect addons
declare bcPMOA cursor local FAST_FORWARD for select AddOn, RevACOItemId, isnull(RevACOItemAmt,0)
from bPMOA where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and RevACOItemId is not null

-- open cursor
open bcPMOA
-- set open cursor flag to true
select @opencursor = 1

PMOA_loop:
fetch next from bcPMOA into @addon, @revacoitemid, @revacoitemamt

if @@fetch_status <> 0 goto PMOA_end

---- update the PMOI amount for the acoitem id backing out the amount
select @units=Units, @unitprice=UnitPrice, @approvedamt=ApprovedAmt
from bPMOI with (nolock) where KeyID=@revacoitemid
if @@rowcount = 0 goto PMOA_loop

---- update Approved Amount in PMOI for the add-on ACO item
set @approvedamt = @approvedamt - @revacoitemamt
if @units <> 0 select @unitprice = @approvedamt / @units
update bPMOI set ApprovedAmt = @approvedamt, UnitPrice=@unitprice
where KeyID=@revacoitemid

---- update bPMOA remove reference to the ACO Item for this addon
update bPMOA set RevACOItemId=null, RevACOItemAmt=null
where PMCo=@pmco and Project=@project and PCOType=@pcotype
and PCO=@pco and PCOItem=@pcoitem and AddOn=@addon


goto PMOA_loop


PMOA_end:
if @opencursor = 1
	begin
	close bcPMOA
	deallocate bcPMOA
	select @opencursor = 0
	end


bspexit:
	if @opencursor = 1
		begin
		close bcPMOA
		deallocate bcPMOA
		select @opencursor = 0
		end
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAddonRevUnappr] TO [public]
GO
