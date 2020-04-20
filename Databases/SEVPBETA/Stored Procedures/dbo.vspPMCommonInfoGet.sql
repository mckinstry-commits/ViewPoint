SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspPMCommonInfoGet]
/********************************************************
 * Created By:	GF 11/27/2006
 * Modified By:	GF 03/12/2008 - issue #127076 changed state to varchar(4).
 *				GF 03/13/2008 - issue #127432 removed address output parameters
  *				GF 05/26/2009 - issue #24641
  *				GP 03/15/2011 - V1# B-02919 added @defaultBeginStatus from PMCO
 *             GPT 10/01/2012 - SecurityGroups are now int instead of smallint. TK-18120 
 *
 * USAGE:
 * Retrieves common info from PMCO for use in various
 * form's DDFH LoadProc field 
 *
 * INPUT PARAMETERS:
 *	PM Company
 *
 * OUTPUT PARAMETERS:
 * From PMCO
 * APCO, INCO, MSCO, PRCO, EMCO
 * From HQCO
 * PhaseGroup, VendorGroup
 * From APCO
 * PMVendUpdYN, PMVendAddYN
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @apco bCompany = null output, @inco bCompany = null output, @msco bCompany = null output,
 @prco bCompany =null output, @emco bCompany = null output, @pmco_ourfirm bVendor = null output,
 @phasegroup bGroup = null output, @vendorgroup bGroup = null output, @pmvendupdyn bYN = 'N' output, 
 @pmvendaddyn bYN = 'N' output, @usetaxgroup bGroup = null output, @custgroup bGroup = null output,
 @jobdefaultsecuritygroup int = null output, @jobsecuritystatus bYN = 'N'output,
 @contractdefaultsecuritygroup int = null output, @contractsecuritystatus bYN = 'N' output,
 @arco bCompany = null output, @defaultbilltype bBillType output, @matlgroup bGroup = null output,
 @slcosttype bJCCType = null output, @mtlcosttype bJCCType = null output,
 @slct1option tinyint = null output, @pmcoexists varchar(1) = 'Y' output, @defaultBegStatus bStatus output, 
 @errmsg varchar(255) output)
as 
set nocount on

declare @rcode int, @errortext varchar(255), @pmco_exists bYN

select @rcode = 0, @pmvendupdyn = 'N', @pmvendaddyn = 'N', @pmcoexists = 'Y'

---- missing MS company
if @pmco is null
	begin
   	select @errmsg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

---- Get info from PMCO
select @apco=APCo, @inco=INCo, @msco=MSCo, @emco=EMCo, @prco=PRCo, @pmco_ourfirm=OurFirm,
		@slcosttype=SLCostType, @mtlcosttype=MtlCostType, @slct1option=SLCT1Option, @defaultBegStatus=BeginStatus
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount <> 1
	begin
	select @errmsg = 'PM Company ' + convert(varchar(3), @pmco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

--if @@rowcount = 0 select @pmcoexists = 'N'

---- get AR company from JCCo
select @arco=ARCo, @defaultbilltype=DefaultBillType
from JCCO with (nolock) where JCCo = @pmco

---- get customer group from HQCo for AR Company
if @pmcoexists = 'Y'
	select @custgroup=CustGroup from HQCO with (nolock) where HQCo=@arco
else
	select @custgroup=CustGroup from HQCO with (nolock) where HQCo=@pmco

---- get vendor group from HQCO for AP company
if @pmcoexists = 'Y'
	select @vendorgroup=VendorGroup from HQCO with (nolock) where HQCo=@apco
else
	select @vendorgroup=VendorGroup from HQCO with (nolock) where HQCo=@pmco

---- get phase group from HQCO for JC company
select @phasegroup = PhaseGroup, @usetaxgroup = TaxGroup, @matlgroup=MatlGroup
from HQCO with (nolock) where HQCo = @pmco

---- get APCO Update flags
if @pmcoexists = 'Y'
	begin
	select @pmvendupdyn=PMVendUpdYN, @pmvendaddyn=PMVendAddYN
	from APCO with (nolock) where APCo=@apco
	end
else
	begin
	select @pmvendupdyn = 'N', @pmvendaddyn = 'N'
	end

---- get data type security information for the bJob data type.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bJob', @DflSecurtiyGroup = @jobdefaultsecuritygroup output, @Secure = @jobsecuritystatus output, @msg = @errortext output
---- if @rcode <> 0
---- 	begin
---- 	select @errmsg = 'Error in retrieving bJob data type security!', @rcode = 1
---- 	goto bspexit
---- 	end

---- get data type security information for the bJob data type.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bContract', @DflSecurtiyGroup = @contractdefaultsecuritygroup output, @Secure = @contractsecuritystatus output, @msg = @errortext output
---- if @rcode <> 0
---- 	begin
---- 	select @errmsg = 'Error in retrieving bContract data type security!', @rcode = 1
---- 	goto bspexit
---- 	end

---- initialize document categories
if not exists(select 1 from bPMCT)
	begin
	declare @sql nvarchar(max)
	set @sql = 'exec dbo.vspPMCTInitialize'
	exec (@sql)
	end
	

bspexit:
	if @rcode<> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonInfoGet] TO [public]
GO
