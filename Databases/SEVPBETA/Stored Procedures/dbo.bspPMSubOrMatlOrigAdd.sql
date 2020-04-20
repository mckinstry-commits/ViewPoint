SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************/
CREATE proc [dbo].[bspPMSubOrMatlOrigAdd]
/***********************************************************
* Created By:	GF 07/13/2001 - New SP using parameters from PMCO.
* Modified By:	GF 08/28/2003 - issue #22306 - rounding problem with unit cost. Data type bDollar, s/b bUnitCost
*				GF 01/14/2009 - issue #131843 if units=0, amount<>0, and UM<>'LS' then do not add
*				GF 07/22/2009 - issue #129667 add material options with estimates
*				GF 11/30/2009 - issue #136810 missing material group
*				GF 12/09/2009 - issue #136967 - use phase description flag to set PMSL or PMMF description
*
*
*
* USAGE:
* adds a original detail record to PMSL using the generate options from PMCO. Up to 2 PMSL records will be created.
*
* Will be called from PMPhaseDetail form, bspPMTemplateCopy.
* May also be called from copy programs, will add procedures later.
*
* INPUT PARAMETERS
* @pmco        PM Company
* @project     PM Project
* @phasegroup  Phase Group
* @phase       Phase
* @costtype    Phase CostType
* @units       Estimate Units
* @um          Unit of Measure
* @unitcost    Estimate unit cost
* @amount      Estimate Cost
*
* OUTPUT PARAMETERS
*   @msg
* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@pmco bCompany, @project bJob, @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
 @units bUnits, @um bUM, @unitcost bUnitCost, @amount bDollar, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @apco bCompany, @dfltwcretpct bPct, @seqnum int, @slcosttype bJCCType,
		@slcosttype2 bJCCType, @mtlcosttype bJCCType, @mtlcosttype2 bJCCType,
		@addpmsl char(1), @addpmmf char(1), @inco bCompany, @msco bCompany,
		@vendorgroup bGroup, @materialgroup bGroup, @phasedesc_flag bYN,
		@matlphasedesc bYN, @phasedesc bItemDesc

select @rcode = 0, @msg = '', @dfltwcretpct = 0, @addpmsl = 'N', @addpmmf = 'N'

if isnull(@costtype,'') = '' goto bspexit

-- get needed information from PMCO for cost type creation
select @apco=APCo, @slcosttype=SLCostType, @slcosttype2=SLCostType2,
		@mtlcosttype=MtlCostType, @mtlcosttype2 = MatlCostType2,
		@inco=INCo, @msco=MSCo, @phasedesc_flag=PhaseDescYN,
		@matlphasedesc=MatlPhaseDesc
from dbo.PMCO with (nolock) where PMCo=@pmco

---- get vendorgroup from HQCO
select @vendorgroup=VendorGroup, @materialgroup=MatlGroup
from dbo.HQCO with (nolock) where HQCo=@apco
if @@rowcount = 0
	begin
	select @vendorgroup=VendorGroup
	from dbo.HQCO with (nolock) where HQCo=@pmco
	end

-- get default retg pct from JCCI to use as a default
select @dfltwcretpct = isnull(i.RetainPCT,0), @phasedesc=p.Description
from dbo.JCJP p with (nolock) 
join dbo.JCCI i with (nolock) on i.JCCo=p.JCCo and i.Contract=p.Contract and i.Item=p.Item
where p.JCCo=@pmco and p.Job=@project and p.PhaseGroup=@phasegroup and p.Phase=@phase

-- set units and unit cost to zero if UM = 'LS'
if @um = 'LS'
   begin
   select @units = 0, @unitcost = 0
   end

-- check if subcontract cost type. If valid set add flag.
if isnull(@slcosttype,'') = @costtype
   begin
   set @addpmsl = 'Y'
   end
if isnull(@slcosttype2,'') = @costtype
   begin
   set @addpmsl = 'Y'
   end

---- check if material cost type. if valid set add flag
if isnull(@mtlcosttype,'') = @costtype
	begin
	set @addpmmf = 'Y'
	end
if isnull(@mtlcosttype2,'') = @costtype
	begin
	set @addpmmf = 'Y'
	end

-- add record to PMSL
if @addpmsl = 'Y'
	BEGIN
	---- check if exists in PMSL
	if not exists(select top 1 1 from dbo.PMSL with (nolock) where PMCo=@pmco and Project=@project
				and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
		begin
		---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
		if isnull(@units,0) = 0 and isnull(@amount,0) <> 0 and isnull(@um,'LS') <> 'LS'
			begin
			goto bspexit
			end

		-- get next sequence number from bPMSL
		select @seqnum = isnull(max(Seq),0) +1
		from dbo.PMSL with (nolock) where PMCo=@pmco and Project=@project

		begin transaction

		insert into dbo.PMSL(PMCo, Project, Seq, PhaseGroup, Phase, RecordType, CostType, VendorGroup,
				SLCo, SLItemType, Units, UM, UnitCost, Amount, SendFlag, WCRetgPct, SMRetgPct,
				SLItemDescription)
		select @pmco, @project, @seqnum, @phasegroup, @phase, 'O', @costtype, @vendorgroup,
				@apco, 1, @units, @um, @unitcost, @amount, 'Y', @dfltwcretpct, @dfltwcretpct,
				case when isnull(@phasedesc_flag,'N') = 'Y' then @phasedesc else null end
		if @@rowcount <> 1
			begin
			select @msg= 'Error inserting cost type ' + convert(varchar(3),@costtype) + ' into PMSL', @rcode = 1
			rollback transaction
			goto bspexit
			end

		commit transaction
		end

	goto bspexit
	END


---- add record to PMMF
if @addpmmf = 'Y'
	BEGIN
	---- check if exists in PMMF
	if not exists(select top 1 1 from dbo.PMMF with (nolock) where PMCo=@pmco and Project=@project
				and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
		begin
		---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
		if isnull(@units,0) = 0 and isnull(@amount,0) <> 0 and isnull(@um,'LS') <> 'LS'
			begin
			goto bspexit
			end

		-- get next sequence number from bPMMF
		select @seqnum = isnull(max(Seq),0) +1
		from dbo.PMMF with (nolock) where PMCo=@pmco and Project=@project

		begin transaction

		insert into dbo.PMMF(PMCo, Project, Seq, PhaseGroup, Phase, RecordType, CostType, VendorGroup,
				MaterialGroup, MaterialOption, POCo, RecvYN, UM, Units, UnitCost, ECM, Amount,
				SendFlag, MtlDescription)
		select @pmco, @project, @seqnum, @phasegroup, @phase, 'O', @costtype, @vendorgroup,
				@materialgroup, 'P', @apco, 'N', @um, @units, @unitcost, 'E', @amount, 'Y',
				case when isnull(@matlphasedesc,'N') = 'Y' then @phasedesc else null end
		if @@rowcount <> 1
			begin
			select @msg= 'Error inserting cost type ' + convert(varchar(3),@costtype) + ' into PMMF', @rcode = 1
			rollback transaction
			goto bspexit
			end

		commit transaction
		end

	goto bspexit
	END




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSubOrMatlOrigAdd] TO [public]
GO
