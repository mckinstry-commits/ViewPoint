SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWHVal    Script Date: 8/28/99 9:35:22 AM ******/
CREATE proc [dbo].[bspPMWHVal]
/*************************************
    * Created By:	GF 01/15/1999
    * Modified By:	GF 09/29/2003 - issue #21923 added @pmco as input parameter for validation
    *				GF 12/12/2003 - #23212 - check error messages, wrap concatenated values with isnull
	*				GF 05/31/2006 - #27996 - changes for 6.x to return create xref values
    *
    *
    * validates PM Import Id from Import edit and Upload
    *
    * Pass:
    *	PM Company
    *	PM Import Id
    *
    * Success returns:
    *	0 and Template & Description
    *
    * Error returns:
    *	1 and error message
    **************************************/
(@pmco bCompany = null, @importid varchar(10) = null, @createphase varchar(1) = 'A' output,
 @createcosttype varchar(1) = 'A' output, @createvendor varchar(1) = 'A' output,
 @creatematl varchar(1) = 'A' output, @createum varchar(1) = 'A' output,
 @template varchar(10) = null output, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @description varchar(60), @import_pmco bCompany

select @rcode = 0

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company.', @rcode = 1
   	goto bspexit
   	end

if @importid is null
	begin
	select @msg = 'Missing Import Id', @rcode=1
	goto bspexit
	end

------ read PMWH info
select @template=Template, @import_pmco=PMCo
from PMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0 
	begin
   	select @msg = 'Not a valid Import Id', @rcode=1
   	end

------ validate PMUT and get template info
select @description=Description, @createphase=CreatePhase, @createcosttype=CreateCostType,
		@createvendor=CreateVendor, @creatematl=CreateMatl, @createum=CreateUM
from PMUT with (nolock) where Template=@template
if @@rowcount = 0
	begin
	select @msg = 'Invalid template assigned to import id.', @rcode = 1
	goto bspexit
	end

------if @import_pmco <> @pmco
------   	begin
------   	select @msg = 'Template was imported in PM Company: ' + convert(varchar(3),@import_pmco) + ' - access from that company.', @rcode = 1
------   	goto bspexit
------   	end

select @msg = @template + ' - ' + isnull(@description,'')



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWHVal] TO [public]
GO
