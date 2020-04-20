SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************/
CREATE proc [dbo].[vspPMCommonForPMPO]
/********************************************************
 * Created By:	GF 06/26/2009
 * Modified By:	GF 05/13/2011 TK-05225
 *				GF 04/15/2012 TK-14088 check if Work flow is active
 *               
 *
 * USAGE:
 * Retrieves common info from PMCO for use in PMPO Header
 * form DDFH LoadProc field. 
 *
 * INPUT PARAMETERS:
 *	PM Company
 * Form document category
 *
 * OUTPUT PARAMETERS:
 * From PMCO
 * APCO, INCO, MSCO, MatlGroup, TaxGroup
 * From HQCO
 * PhaseGroup, VendorGroup
 * From APCO
 * MtlCostType, MSInUse, INInUse, RQInUse
 * from PMCO
 * INMatlGroup
 * from HQCO for INCO
 * @country				HQCO Country Code
 * @pmcu_inactive		Document Category Inactive
 * @pmcu_doccat			Document Category
 * @pmco_begstatus		PM Company Begin Status
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @doccat varchar(10) = null,
 @apco bCompany = null output, @inco bCompany = null output, @msco bCompany = null output,
 @pmco_ourfirm bVendor = null output, @phasegroup bGroup = null output, @vendorgroup bGroup = null output,
 @usetaxgroup bGroup = null output, @matlgroup bGroup = null output, @mtlcosttype bJCCType = null output,
 @msinuse bYN = 'Y' output, @ininuse bYN = 'Y' output, @rqinuse bYN = 'Y' output, @mtct1option tinyint = null output,
 @phasedescyn bYN = 'N' output, @salestaxgroup bGroup = null output, @poinuse bYN = 'Y' output,
 @pmcoexists bYN = 'Y' output, @usetaxonmaterial bYN = 'Y' output, @inmatlgroup bGroup output,
 @liclevel tinyint = 2 output, @postclosedjobs bYN = 'N' output, @postsoftclosedjobs bYN = 'N' output,
 @country varchar(2) output,@pmcu_inactive bYN = 'N' output, @pmcu_doccat varchar(10) = null OUTPUT,
 @DefaultBeginStatus bStatus = NULL OUTPUT
 ----TK-14088
 ,@WorkFlowActive CHAR(1) = 'Y' OUTPUT)
as 
set nocount on

declare @rcode int, @errortext varchar(255), @PMCoStatus bStatus

select @rcode = 0, @phasedescyn = 'N', @pmcoexists = 'Y', @poinuse = 'Y', @msinuse = 'Y',
	   @ininuse = 'Y', @rqinuse = 'Y', @usetaxonmaterial = 'Y', @liclevel = 2,
	   @PMCoStatus = NULL

---- get PM license level
select @liclevel = LicLevel from vDDMO where Mod='PM'
if @@rowcount = 0 select @liclevel = 2

---- Get info from PMCO
select @apco=APCo, @inco=INCo, @msco=MSCo, @pmco_ourfirm=OurFirm, @mtlcosttype=MtlCostType,
		@mtct1option=MTCT1Option, @ininuse=INInUse, @msinuse=MSInUse, @rqinuse=RQInUse,
		@phasedescyn=PhaseDescYN, @poinuse=POInUse,
		----TK-05225
		@PMCoStatus=BeginStatus
from dbo.PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0 SET @pmcoexists = 'N'

---- get default begin status from PMSC if one exists for document category TK-05225
SELECT TOP 1 @DefaultBeginStatus = Status
FROM dbo.PMSC WHERE DocCat = @doccat AND CodeType = 'B'
GROUP BY Status
IF @@ROWCOUNT = 0 SET @DefaultBeginStatus = @PMCoStatus

---- get vendor group from HQCO for AP company
if @pmcoexists = 'Y'
	begin
	select @vendorgroup=VendorGroup, @salestaxgroup=TaxGroup, @matlgroup=MatlGroup,
			 @country=DefaultCountry
	from HQCO with (nolock) where HQCo=@apco
	end
else
	begin
	select @vendorgroup=VendorGroup, @salestaxgroup=TaxGroup, @matlgroup=MatlGroup,
			 @country=DefaultCountry
	from HQCO with (nolock) where HQCo=@pmco
	end

---- get phase group from HQCO for JC company
select @phasegroup = PhaseGroup, @usetaxgroup = TaxGroup
from HQCO with (nolock) where HQCo=@pmco

---- get JC Company info
select @usetaxonmaterial=UseTaxOnMaterial, @postclosedjobs=PostClosedJobs,
		@postsoftclosedjobs=PostSoftClosedJobs
from JCCO with (nolock) where JCCo=@pmco
if @@rowcount = 0
	begin
	select @usetaxonmaterial = 'N', @postsoftclosedjobs = 'N', @postclosedjobs = 'N'
	end


---- get IN Material Group
if isnull(@inco,0) <> 0
	begin
   	select @inmatlgroup=MatlGroup from bHQCO with (nolock) where HQCo=@inco
   	end

---- initialize document categories if not exist
if not exists(select 1 from PMCU where DocCat = @doccat)
	begin
	declare @sql nvarchar(max)
	set @sql = 'exec dbo.vspPMCTInitialize'
	exec (@sql)
	end
	
---- get document category information
select @pmcu_inactive=Inactive, @pmcu_doccat=DocCat
from PMCU with (nolock)
where DocCat = @doccat
if @@rowcount = 0
	begin
	set @pmcu_inactive = 'N'
	set @pmcu_doccat = @doccat
	end

---- TK-14088 work flow active
SET @WorkFlowActive = 'Y'
IF EXISTS(SELECT 1 FROM dbo.vDDMO WHERE Mod = 'WF' AND Active = 'N')
	BEGIN
	SET @WorkFlowActive = 'N'
	END






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonForPMPO] TO [public]
GO
