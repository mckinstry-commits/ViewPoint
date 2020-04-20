SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspIMFirstImportId    Script Date: 11/29/2006 ******/
CREATE  proc [dbo].[vspIMFirstImportId]
/*************************************
 * Created By:	DANF 11/29/06
 * Modified By:
 *
 *
 * USAGE:
 * Called from IM to return the first importid
 *
 *
 * INPUT PARAMETERS
 * @importid			Importid
 *
 * Success returns:
 *	The first importid
 *
 * Error returns:
 *	1 and error message
 **************************************/
( @importid varchar(20) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

select top 1 @importid= ImportId
from bIMWE with (nolock)
where ImportId=@importid
if @@rowcount <> 1 select @importid = ''

if isnull(@importid,'') = ''
	begin
		-- -- -- get the first importid 
		select top 1 @importid= ImportId
		from bIMWE with (nolock)
		order by ImportId 
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMFirstImportId] TO [public]
GO
