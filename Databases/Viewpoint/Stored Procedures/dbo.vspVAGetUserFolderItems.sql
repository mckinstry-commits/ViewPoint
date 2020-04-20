SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAGetUserFolderItems]        
/**************************************************          
* Created: Dave C 5/29/09          
* Modified:           
*           
*          
* Gets custom Items inside the Folders located in MyTasks        
*          
* Inputs:          
Username          
*          
* Output:          
* resultset of Viewpoint menu structure          
*          
*          
*          
****************************************************/          
(@UserName bVPUserName = NULL)        
        
AS          
  
select  
 d.SubFolder,  
 d.MenuItem,  
 f.Title As FriendlyName,  
 d.ItemType,  
 d.[Mod]   
from DDSI d  
 inner join DDFHShared f on d.MenuItem = f.Form  
where d.VPUserName = @UserName and d.[Mod] = ''  
  
UNION ALL  
  
select  
 d.SubFolder,  
 d.MenuItem,  
 r.Title As FriendlyName,  
 d.ItemType,  
 d.[Mod]   
from DDSI d  
 inner join RPRTShared r on d.MenuItem = r.ReportID  
where d.VPUserName = @UserName and d.ItemType = 'R' and d.[Mod] = ''
GO
GRANT EXECUTE ON  [dbo].[vspVAGetUserFolderItems] TO [public]
GO
