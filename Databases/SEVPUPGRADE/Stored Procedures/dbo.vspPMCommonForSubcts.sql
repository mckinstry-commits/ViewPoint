SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************************/
CREATE proc [dbo].[vspPMCommonForSubcts]
/********************************************************
* Created By:	GF 06/16/2006
* Modified By:	GF 12/19/2007 - issue #124407 return JCCO allow posting to closed job flags.
*				GF 09/15/2008 - issue #129811
*				GF 06/26/2009 - issue #24641 added 2 output parameters for document category info
*				GF 07/21/2009 - issue #129667 added 2 output params for matl cost type and option
*				GF 02/16/2010 - issue #136053 added output parameter for PMCO.SLItemCOAutoAdd and JCCO.GLCO
*				GP 03/29/2011 - V1# TK-03456 added output parameter for PMCO.BeginStatus
*				TK 04/11/2011 - TK-04041 added output parameter for PMCO.LockDownACOItems
*				GF 05/13/2011 - TK-05225
*				GF 10/18/2012 TK-18032 SL Claims removed use certified column
*
* USAGE:
* Retrieves common info from PMCO for use in various
* form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	PM Company
*
* OUTPUT PARAMETERS:
* From PMCO:	APCO, OurFirm, SLCostType, SLCT1Option, PhaseDescYN
* From HQCO:	PhaseGroup, VendorGroup, CustGroup, MatlGroup, UseTaxGroup
* From JCCO:	ARCO, PostClosedJobs, PostSoftClosedJobs
* @country		HQCO Country Code, MtlCostType, MTCT1Option
* @slitemautoadd	PM Company option to allow SL Add Items form to run
*
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@pmco bCompany=0, @doccat varchar(10) = null,
 @apco bCompany = null output, @pmco_ourfirm bVendor = null output,
 @phasegroup bGroup = null output, @vendorgroup bGroup = null output, @usetaxgroup bGroup = null output,
 @custgroup bGroup = null output, @arco bCompany = null output, @matlgroup bGroup = null output,
 @slcosttype bJCCType = null output, @slct1option tinyint = null output, @phasedescyn bYN = 'N' output,
 @slinuse bYN = 'Y' output, @pmcoexists bYN = 'Y' output, @liclevel tinyint = 2 output,
 @postclosedjobs bYN = 'N' output, @postsoftclosedjobs bYN = 'N' output, @country varchar(2) output,
 @salestaxgroup bGroup = null output, @usetaxonmaterial bYN = 'Y' output,
 @pmcu_inactive bYN = 'N' output, @pmcu_doccat varchar(10) = null output, @mtlcosttype bJCCType = null output,
 @mtct1option tinyint = null output, @slitemcoautoadd bYN = 'N' output,
 @jcglco bCompany = 0 output, @slitemcomanual bYN = 'N' output, @DefaultBeginStatus bStatus output,
 @LockdownACOItems bYN output)
as 
set nocount on

declare @rcode INT, @PMCoStatus bStatus

select @rcode = 0, @pmcoexists = 'Y', @phasedescyn = 'N', @slinuse = 'Y', @liclevel = 2,
		@usetaxonmaterial = 'Y', @slitemcoautoadd = 'N', @slitemcomanual = 'N'

---- get PM license level
select @liclevel = LicLevel from vDDMO where Mod='PM'
if @@rowcount = 0 select @liclevel = 2


---- Get info from PMCO #136053
select @apco=APCo, @pmco_ourfirm=OurFirm, @slcosttype=SLCostType, @slct1option=SLCT1Option,
		@phasedescyn=PhaseDescYN, @slinuse=SLInUse, @mtlcosttype=MtlCostType,
		@mtct1option=MTCT1Option, @slitemcoautoadd = SLItemCOAutoAdd,
		@slitemcomanual = SLItemCOManual, @LockdownACOItems = LockDownACOItems,
		----TK-05225
		@PMCoStatus = BeginStatus
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0 select @pmcoexists = 'N'

---- get default begin status from PMSC if one exists for document category TK-05225
SELECT TOP 1 @DefaultBeginStatus = Status
FROM dbo.PMSC WHERE DocCat = @doccat AND CodeType = 'B'
GROUP BY Status
IF @@ROWCOUNT = 0 SET @DefaultBeginStatus = @PMCoStatus

---- get AR company and Post Flags from JCCo
select @arco=ARCo, @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs,
		@usetaxonmaterial=UseTaxOnMaterial, @jcglco=GLCo
from dbo.JCCO with (nolock) where JCCo = @pmco
if @@rowcount = 0
	begin
	select @arco = @pmco, @postsoftclosedjobs = 'N', @postclosedjobs = 'N', @usetaxonmaterial = 'N'
	end

---- get customer group from HQCo for AR Company
if @pmcoexists = 'Y'
	select @custgroup=CustGroup from HQCO with (nolock) where HQCo=@arco
else
	select @custgroup=CustGroup from HQCO with (nolock) where HQCo=@pmco

---- get vendor group from HQCO for AP company
if @pmcoexists = 'Y'
	begin
	select @vendorgroup=VendorGroup, @country=DefaultCountry, @salestaxgroup=TaxGroup
	from HQCO with (nolock) where HQCo=@apco
	end
else
	begin
	select @vendorgroup=VendorGroup, @country=DefaultCountry, @salestaxgroup=TaxGroup
	from HQCO with (nolock) where HQCo=@pmco
	end

---- get phase group from HQCO for JC company
select @phasegroup=PhaseGroup, @usetaxgroup=TaxGroup, @matlgroup=MatlGroup
from HQCO with (nolock) where HQCo = @pmco

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




bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMCommonForSubcts] TO [public]
GO
