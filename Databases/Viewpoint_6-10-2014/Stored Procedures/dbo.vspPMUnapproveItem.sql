SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMUnapproveItem    Script Date: 01/05/2006 ******/
CREATE proc [dbo].[vspPMUnapproveItem]
/***********************************************************
* Created By:	GF 01/05/2006 6.x version
* Modified By:  GF 04/30/2008 - issue #22100 addon revenue item redirect
*				GF 07/24/2008 - issue #129065 need to make sure PMMF and PMSL have no rows for unapproved ACO/ACOItem
*				GF 01/13/2008 - issue #129669 distributed cost add-ons enhancement
*				GF 01/18/2010 - issue #137581 allow unapprove when subcontract detail has been interfaced
*				GF 06/06/2010 - issue #139869 after PMOL unapproved and Item updated check for PMOL records to delete
*				DAN SO 05/17/2011 - TK-05219 - Do not remove SubCO value when Unapproving (backed out for now)
*				GF 06/20/2011 - TK-06177 fix for TK-05219 do not remove subco
*				TL  01/11/2012 TK-11599 changed Status code update, Gets Status code from PMCO, then from 1st PMSC, "B" status type
*				
*
*
* USAGE:
* Unapproves an ACO, ACOItem from PMMF, PMSL, PMOL, PMOI.
* Subtracts Change of days amount from PMOH.
*
* Validates that no detail has been interfaced for ACO Item
* and checks JCOI to see if ACO Item exists.
*
*
* INPUT PARAMETERS
*    pmco           pm company
*    project        project
*    pcotype        pending change order type
*    pco            pending change order
*    pcoitem        pending change order item
*    aco            approved change order
*    acoitem        approved change order item
*
* OUTPUT PARAMETERS
*    msg            error message.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem,
 @aco bACO, @acoitem bACOItem, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @newaco bACO, @newacoitem bACOItem, @interfaceddate bDate,
   		@approveddate bDate, @approvedamt bDollar, @approvedby varchar(15), @approved bYN,
   		@begstatus bStatus, @newsubco smallint, @count int, @desc varchar(255), 
   		@pmohchgdays smallint

select @rcode = 0

if @pmco is null or @project is null or @pcotype is null or @pco is null or
		@pcoitem is null or @aco is null or @acoitem is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end

-- -- -- check PMSL for interfaced records 137581
--if exists(select 1 from PMSL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
--			and PCO=@pco and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem and InterfaceDate is not null)
--	begin
--	select @msg = 'Subcontract detail has been interfaced for this change order item. Cannot unapprove.', @rcode = 1
--	goto bspexit
--	end

-- -- -- check PMMF for interfaced records
if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
			and PCO=@pco and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem and InterfaceDate is not null)
	begin
	select @msg = 'Materail detail has been interfaced for this change order item. Cannot unapprove.', @rcode = 1
	goto bspexit
	end

-- -- -- check PMOL for interfaced records. if found then check and see if ACO item exists in JCOI
if exists(select 1 from PMOL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
			and PCO=@pco and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem and InterfacedDate is not null)
	begin
	if exists(select 1 from JCOI with (nolock) where JCCo=@pmco and Job=@project and ACO=@aco and ACOItem=@acoitem)
		begin
		select @msg = 'Must delete ACO Item in Job Cost before unapproving!', @rcode = 1
		goto bspexit
		end
	end


-- -- -- begin unapprove process
begin transaction

-- -- -- remove ACO & ACOItem from PMMF
select @count = 0, @newaco = null, @newacoitem = null
select @count=count(*) from bPMMF with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem

---- update bPMMF and remove ACO, ACOItem
update bPMMF set ACO = @newaco, ACOItem = @newacoitem
where PMCo = @pmco and Project = @project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem and InterfaceDate is null
if @@rowcount <> @count
	begin
	select @msg = 'Unable to unapprove material records, unapproval aborted!', @rcode=1
	rollback
	goto bspexit
	end

---- now remove any PMMF records for the ACO, ACOItem that do not have a PCOType, PCO, PCOItem
delete from bPMMF
where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem and InterfaceDate is null
and PCOType is null and PCO is null and PCOItem is null


-- -- -- remove ACO, ACOItem, and SubCO from PMSL
select @count = 0, @newaco = null, @newacoitem = null, @newsubco = null
select @count=count(*) from bPMSL with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem

---- update bPMSL TK-06177
update bPMSL set ACO = @newaco, ACOItem = @newacoitem ----SubCO=@newsubco --TK-05219 backed out
where PMCo = @pmco and Project = @project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem ----and InterfaceDate is null 137581
if @@rowcount <> @count
	begin
	select @msg = 'Unable to unapprove subcontract records, unapproval aborted!', @rcode=1
	rollback
	goto bspexit
	end

---- now remove any PMSL records for the ACO, ACOItem that do not have a PCOType, PCO, PCOItem
delete from bPMSL
where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem and InterfaceDate is null
and PCOType is null and PCO is null and PCOItem is null


---- delete records from PMOL that have been created from add-ons #129669
delete from bPMOL
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem and CreatedFromAddOn = 'Y'

---- now back-out the distributed amount from any other PMOL records #129669
update bPMOL
		Set UnitCost = case when isnull(EstUnits,0) <> 0 then ((EstCost - DistributedAmt) / EstUnits) else 0 end,
			HourCost = case when isnull(EstHours,0) <> 0 then ((EstCost - DistributedAmt) / EstHours) else 0 end,
			EstCost = EstCost - DistributedAmt, DistributedAmt = 0
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem and DistributedAmt <> 0


-- -- -- remove ACO & ACOItem & InterfacedDate from PMOL
select @count = 0, @newaco = null, @newacoitem = null, @interfaceddate = null
select @count=count(*) from bPMOL with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem

-- -- -- update bPMOL
update bPMOL set ACO = @newaco, ACOItem = @newacoitem, InterfacedDate = @interfaceddate
where PMCo = @pmco and Project = @project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem
if @@rowcount <> @count
	begin
	select @msg = 'Unable to unapprove change order item detail records, unapproval aborted!', @rcode=1
	rollback
	goto bspexit
	end

---- check for PMOA addons for this PCO Item where the revenue has been re-directed to a different ACO Item
---- execute procedure to back out addon amount for revenue from the approved addon aco item
exec @retcode = dbo.vspPMPCOAddonRevUnappr @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @msg output

---- #139869 now remove any PMOL records for the ACO, ACOItem that do not have a PCOType, PCO, PCOItem - CLEANUP
delete from bPMOL
where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
and PCOType is null and PCO is null and PCOItem is null
---- #139869

-- -- -- remove ACO & ACOItem & ApprovedAmt & ApprovedBy & Approved & ApprovedDate
-- -- -- and set status to first beginning status in PMOI
select @count = 0, @newaco = null, @newacoitem = null, @approveddate = null,
       @approvedamt = null, @approvedby = null, @approved = 'N'

-- -- -- retrieve a beginning status code for to set change order item
select @begstatus = BeginStatus from dbo.PMCO where PMCo = @pmco and BeginStatus is not null

if @begstatus is null		
begin
	select @begstatus = Min([Status]) from bPMSC with (nolock) where CodeType = 'B' and DocCat = 'PCO'
	
	IF @begstatus = NULL
	begin
		SELECT  @begstatus = min([Status]) FROM dbo.PMSC WHERE   CodeType = 'B' and ActiveAllYN='Y'
	end
end

select @count=count(*) from bPMOI with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem

-- -- -- update bPMOI
update bPMOI set ACO = @newaco, ACOItem = @newacoitem, ApprovedDate = @approveddate,
          ApprovedAmt = @approvedamt, ApprovedBy = @approvedby, Approved = @approved,
          Status = isnull(@begstatus, Status)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
and PCOItem=@pcoitem and ACO=@aco and ACOItem=@acoitem
if @@rowcount <> @count
	begin
	select @msg = 'Unable to unapprove change order item records, unapproval aborted!', @rcode=1
	rollback
	goto bspexit
	end

-- -- -- Subtract the changedays amount from PMOH to keep total updated
update bPMOH set ChangeDays = (select Sum(ChangeDays) 
from bPMOI with (nolock) where ACO = @aco and Project = @project and PMCo = @pmco)
where ACO = @aco and Project = @project and PMCo = @pmco

---- run add-on calculates to re-calculate add-ons when item is unapproved #129669
exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem



commit transaction





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'') 
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMUnapproveItem] TO [public]
GO
