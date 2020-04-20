SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPMenuGetAllSubfolderTemplates]  
/**************************************************  
* Created: JRK 05/25/2005  
* Modified:
*   Dave C 5/22/09 - Changed proc to return from DDTFShared, excluding all hidden records
*  
* Gets the collection of subfolder templates, but not the template details.  
* Useful in VPMenu for displaying a list of all templates for a user  
* to choose from.  
*  
* Inputs:  
* -none-  
*  
* Output:  
* resultset of Viewpoint Modules with access info  
* @errmsg  Error message  
*  
*  
* Return code:  
* @rcode 0 = success, 1 = failure  
*  
****************************************************/  
 (@errmsg varchar(512) output)  
as  
  
set nocount on   
  
declare @rcode int  
select @rcode = 0  
  
/*  
if @co is null  
 begin  
 select @errmsg = 'Missing required input parameter: Company #', @rcode = 1  
 goto vspexit  
 end  
*/  
  
select FolderTemplate, Title, Mod  
from DDTFShared Where Active = 'Y'
order by Title  
  
-- Exit  
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetAllSubfolderTemplates]'  
return @rcode  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetAllSubfolderTemplates] TO [public]
GO
