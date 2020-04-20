SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE          PROCEDURE [dbo].[vspVPMenuGetCompanySubFolders]
/**************************************************
* Created: GG 07/11/03
* Modified: JRK 01/14/04 Ignore subfolders 255, used internally for Reports and Programs folders.
* Modified: JRK 01/20/04 Include the new ViewOptions field.
* Modified: JRK 01/23/04 - Return a ViewOptionsChanged initialized to "N".
*
* Used by VPMenu to retrieve company-specific ("our Viewpoint") sub-folders
* Retrieves for all companies > 0.
*
* Inputs:
*	none
*
* Output:
*	resultset of users' sub folders from vDDSF
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int

set @rcode = 0

-- return resultset of company sub-folders
select Co, SubFolder, Title, ViewOptions
from vDDSF
where Co <> 0 and SubFolder <> 255	-- Company 0 represents user-specific.  We want company-specific.
order by Co, Title
   
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetCompanySubFolders]'
	return @rcode














GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetCompanySubFolders] TO [public]
GO
