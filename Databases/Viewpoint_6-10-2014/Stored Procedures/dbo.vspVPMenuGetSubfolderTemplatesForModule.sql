SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE     PROCEDURE [dbo].[vspVPMenuGetSubfolderTemplatesForModule]
/**************************************************
* Created: JRK 05/25/2005
* Modified: 
*	
*
* Gets the collection of subfolder templates, but not the template details.
* Useful in VPMenu for displaying a list of all templates for a user
* to choose from.
*
* Inputs:
*	@mod		2-char module code, like "PM".
*
* Output:
*	resultset of Viewpoint Modules with access info
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@mod char(2) = null, @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0


if @mod is null
	begin
	select @errmsg = 'Missing required input parameter: mod', @rcode = 1
	goto vspexit
	end


select FolderTemplate, Title, Mod
from vDDTF
where Mod=@mod
order by Title

vspexit:
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetSubfolderTemplatesForModule]'
return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetSubfolderTemplatesForModule] TO [public]
GO
