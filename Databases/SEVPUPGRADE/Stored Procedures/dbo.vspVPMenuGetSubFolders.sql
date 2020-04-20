SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE         PROCEDURE [dbo].[vspVPMenuGetSubFolders]
/**************************************************
* Created: GG 07/11/03
* Modified: JRK 01/20/04 - Don't get rows with SubFolder=255.  Return new ViewOptions field.
* Modified: JRK 01/23/04 - Return a ViewOptionsChanged field (bool) initialized to False.
*
* Used by VPMenu to retrieve user sub-folders.
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

-- return resultset of users sub-folders for 'My Viewpoint' and all module nodes
select Mod, SubFolder, Title, ViewOptions
from vDDSF
where VPUserName = suser_sname()
-- and SubFolder <> 0
 and SubFolder <> 255	-- sub-folder 0 reserved for Module level items.  255 reserved for Programs and Reports (for user sorting).
order by Mod, Title
   
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetSubFolders]'
	return @rcode













GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetSubFolders] TO [public]
GO
