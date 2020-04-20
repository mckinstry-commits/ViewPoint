SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportIdVal    Script Date: 05/16/2006 ******/
CREATE proc [dbo].[vspPMImportIdVal]
/*************************************
 * Created By:	GF 05/16/2006 - for 6.x
 * Modified By:	
 *
 *
 *
 * validates PM Import Id from PM Import Data to see if currently exists.
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
(@pmco bCompany = null, @importid varchar(10) = null, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @template varchar(10), @description varchar(60), @import_pmco bCompany,
		@importdate bDate, @importby bVPUserName

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
select @template=Template, @import_pmco=PMCo, @importdate=ImportDate, @importby=ImportBy
from bPMWH with (nolock) where ImportId=@importid
if @@rowcount = 0 
   	begin
   	select @msg = 'New Import Id'
	goto bspexit
   	end

------ create description for display in PM Import Data
select @msg = 'Warning: This import id was imported by: ' + isnull(@importby,'') + ' on Date: ' + isnull(convert(varchar(20),@importdate,101),'') + ', all data in work files will be replaced.'





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportIdVal] TO [public]
GO
