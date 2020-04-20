SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE          PROCEDURE [dbo].[vspVPMenuGetPredefinedSubFolders]
/**************************************************
* Created: JRK 05/10/05 - Cloned from vspVPMenuGetSubFolders.
* Modified:
*
* Used by VPMenu to retrieve pre-defined sub-folders.  These are subfolders
* shipped with the software.  For example, PM Project Manager will be
* a subfolder of PM with some shortcuts in it.
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
from vDDSFc
order by Mod, Title
   
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetPredefinedSubFolders]'
	return @rcode














GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetPredefinedSubFolders] TO [public]
GO
