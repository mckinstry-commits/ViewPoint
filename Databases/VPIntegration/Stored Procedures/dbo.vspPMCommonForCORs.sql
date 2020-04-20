SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
-- CREATE proc [dbo].[vspPMCommonForCORs]
CREATE proc [dbo].[vspPMCommonForCORs]
/********************************************************
 * Created By:	 DAN SO 03/21/2001 - B-02927 - COR - Distribution - copied from vspPMCommonInfoGet
 *										needed to add document category information
 * Modified By:	GF 05/14/2011 TK-05225
 *				GPT 10/11/2012 TK-18120 Security Group fields are now int not smallint.
 *               
 *
 * USAGE:
 * Retrieves common info from PMCO for use in various
 * form's DDFH LoadProc field 
 *
 * INPUT PARAMETERS:
 *	PM Company
 *  Doc Category (newly added)
 *
 * OUTPUT PARAMETERS:
 * From PMCO
 * APCO, INCO, MSCO, PRCO, EMCO
 * From HQCO
 * PhaseGroup, VendorGroup
 * From APCO
 * PMVendUpdYN, PMVendAddYN
 * NEWLY ADDED: @pmcu_inactive & @pmcu_doccat
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @doccat varchar(10) = null,
 @apco bCompany = null output, @inco bCompany = null output, @msco bCompany = null output,
 @prco bCompany =null output, @emco bCompany = null output, @pmco_ourfirm bVendor = null output,
 @phasegroup bGroup = null output, @vendorgroup bGroup = null output, @pmvendupdyn bYN = 'N' output, 
 @pmvendaddyn bYN = 'N' output, @usetaxgroup bGroup = null output, @custgroup bGroup = null output,
 @jobdefaultsecuritygroup int = null output, @jobsecuritystatus bYN = 'N'output,
 @contractdefaultsecuritygroup int = null output, @contractsecuritystatus bYN = 'N' output,
 @arco bCompany = null output, @defaultbilltype bBillType output, @matlgroup bGroup = null output,
 @slcosttype bJCCType = null output, @mtlcosttype bJCCType = null output,
 @slct1option tinyint = null output, @pmcoexists varchar(1) = 'Y' output,
 @DefaultBeginStatus bStatus = NULL OUTPUT, @pmcu_inactive bYN = 'N' output,
 @pmcu_doccat varchar(10) = null output, @errmsg varchar(255) output)
as 
set nocount on

declare @rcode int, @errortext varchar(255), @pmco_exists bYN, @PMCoStatus bStatus

select @rcode = 0, @pmvendupdyn = 'N', @pmvendaddyn = 'N', @pmcoexists = 'Y'

---- missing MS company
if @pmco is null
	begin
   	select @errmsg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

---- Get info from PMCO
select @apco=APCo, @inco=INCo, @msco=MSCo, @emco=EMCo, @prco=PRCo, @pmco_ourfirm=OurFirm,
		@slcosttype=SLCostType, @mtlcosttype=MtlCostType, @slct1option=SLCT1Option,
		----TK-05225
		@PMCoStatus = BeginStatus
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount <> 1
	begin
	select @errmsg = 'PM Company ' + convert(varchar(3), @pmco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- get default begin status from PMSC if one exists for document category TK-05225
SELECT TOP 1 @DefaultBeginStatus = Status
FROM dbo.PMSC WHERE DocCat = @doccat AND CodeType = 'B'
GROUP BY Status
IF @@ROWCOUNT = 0 SET @DefaultBeginStatus = @PMCoStatus

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

---- get data type security information for the bJob data type.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bContract', @DflSecurtiyGroup = @contractdefaultsecuritygroup output, @Secure = @contractsecuritystatus output, @msg = @errortext output


-------------
-- B-02927 --
-------------
---- initialize document categories
if not exists(select 1 from PMCU where DocCat = @doccat)
	begin
	declare @sql nvarchar(max)
	set @sql = 'exec dbo.vspPMCTInitialize'
	exec (@sql)
	end
	
-------------
-- B-02927 --
-------------
---- get document category information 
select @pmcu_inactive=Inactive, @pmcu_doccat=DocCat
from PMCU with (nolock)
where DocCat = @doccat
if @@rowcount = 0
	begin
	set @pmcu_inactive = 'N'
	set @pmcu_doccat = @doccat
	end

bspexit:
	if @rcode<> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

select * from PMCU
GO
GRANT EXECUTE ON  [dbo].[vspPMCommonForCORs] TO [public]
GO
