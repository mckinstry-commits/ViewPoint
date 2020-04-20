SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        CREATE       PROCEDURE [dbo].[vspVPMenuCopySubfolderTemplateDetail]  
/**************************************************  
* Created: JRK 05/27/2005  
* Modified:   Dave C 5/22/2009 - Changed to use DDTDShared view
*   
*  
* Copies a collection of subfolder template detail for a specified template  
* into the user subfolder items table (DDSI).  
* Used in VPMenu when populating a subfolder with shortcuts to forms and reports  
* from a subfolder template (eg, Project Manager template).  
*  
* Inputs:  
* @id  smallint value identifies the FolderTemplate  
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
 (@templateid smallint = null, @co bCompany = null, @user bVPUserName = null, @mod char(2) = null,  
  @subfolder smallint = null, @errmsg varchar(512) output)  
as  
  
set nocount on   
  
declare @rcode int  
select @rcode = 0  
  
  
if @templateid is null or @co is null or @user is null or @mod is null or @subfolder is null  
 begin  
 select @errmsg = 'Missing required input parameter: templateid, co, user, mod or subfolder.', @rcode = 1  
 goto vspexit  
 end  
  
insert into DDSI (Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq)  
select @co, @user, @mod, @subfolder, d.ItemType, d.MenuItem, d.MenuSeq  
from DDTDShared d  
where d.FolderTemplate=@templateid  
order by d.MenuSeq  
  
  
vspexit:  
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuCopySubfolderTemplateDetail]'  
return @rcode  
  
  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[vspVPMenuCopySubfolderTemplateDetail] TO [public]
GO
