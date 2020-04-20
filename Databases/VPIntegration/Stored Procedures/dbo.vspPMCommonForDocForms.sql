SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspPMCommonForDocForms]
/********************************************************
 * Created By:	GF 06/17/2009 - issue #24641
 * Modified By:	TRL 03/29/2011 TK-03405 added output for default RFIStatus
 *				GP 06/30/2011 - TK-05540 Fixed default beginning status to look at PMSC before PMCO   
 *
 * USAGE:
 * Retrieves common info from PMCo and PMCU for use in various
 * PM Document Forms LoadProc field 
 *
 * INPUT PARAMETERS:
 *	PM Company
 *
 * OUTPUT PARAMETERS:
 *
 *
 *
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany = 0, @doccat varchar(10) = null,
 @apco bCompany = null output, @pmco_ourfirm bVendor = null output,
 @phasegroup bGroup = null output, @vendorgroup bGroup = null output,
 @matlgroup bGroup = null output, @pmcoexists varchar(1) = 'Y' output,
 @pmcu_inactive bYN = 'N' output, @pmcu_doccat varchar(10) = null output,
 @prco bCompany = null output, @emco bCompany = null output, @RFIStatus bStatus = null output,
 @errmsg varchar(255) output)
as 
set nocount on

declare @rcode int, @errortext varchar(255), @pmco_exists bYN

select @rcode = 0, @pmcoexists = 'Y'

---- missing MS company
if @pmco is null
	begin
   	select @errmsg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

--Get default begin status for RFI
select @RFIStatus = min([Status]) from dbo.PMSC where CodeType = 'B' and DocCat = 'RFI'
if @RFIStatus is null	select @RFIStatus = isnull(RFIStatus, BeginStatus) from dbo.PMCO where PMCo = @pmco

---- Get info from PMCO
select @apco=APCo, @emco=EMCo, @prco=PRCo, @pmco_ourfirm=OurFirm
from dbo.PMCO with (nolock) where PMCo=@pmco
if @@rowcount <> 1
	begin
	select @errmsg = 'PM Company ' + convert(varchar(3), @pmco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- initialize document categories if not exist
if not exists(select 1 from dbo.PMCU where DocCat = @doccat)
	begin
	declare @sql nvarchar(max)
	set @sql = 'exec dbo.vspPMCTInitialize'
	exec (@sql)
	end
	
---- get document category information
select @pmcu_inactive=Inactive, @pmcu_doccat=DocCat
from dbo.PMCU with (nolock)
where DocCat = @doccat
if @@rowcount = 0
	begin
	set @pmcu_inactive = 'N'
	set @pmcu_doccat = @doccat
	end

---- get vendor group from HQCO for AP company
if @pmcoexists = 'Y'
	begin
	select @vendorgroup=VendorGroup from dbo.bHQCO where HQCo=@apco
	end
else
	begin
	select @vendorgroup=VendorGroup from dbo.bHQCO where HQCo=@pmco
	end

---- get phase group from HQCO for JC company
select @phasegroup = PhaseGroup, @matlgroup=MatlGroup
from dbo.bHQCO where HQCo = @pmco



	

bspexit:
	if @rcode<> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonForDocForms] TO [public]
GO
