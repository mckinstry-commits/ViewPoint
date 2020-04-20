SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROCEDURE [dbo].[vspVPGetUserMyTaskFolders]
/**************************************************  
* Created: Dave C 5/30/2009  
* Modified:   
*   
*  
* Gets custom folders by user, and the company folder  
*  
* Inputs:  
* Company, Username  
*  
* Output:  
* resultset of Viewpoint menu struecture  
*  
*  
*  
****************************************************/  
(@Co bCompany = 0, @UserName bVPUserName = NULL)  
  
AS  
  
SELECT Folders.* FROM  
(  
 SELECT [Mod], SubFolder, Title, Co FROM DDSF WHERE Co = @Co AND SubFolder <> 255  
  
 UNION ALL  
  
 -- sub-folder 0 reserved for Module level items.  255 reserved for Programs and Reports (for user sorting).  
 SELECT DDSF.[Mod], SubFolder, DDSF.Title, Co   
 FROM DDSF   
 INNER JOIN DDMO o (NOLOCK) ON DDSF.Mod = o.Mod  
 WHERE o.Active = 'Y' AND VPUserName = @UserName AND SubFolder <> 255   
  
 UNION ALL  
  
 SELECT DDSF.[Mod], SubFolder, DDSF.Title, Co   
 FROM DDSF   
 WHERE VPUserName = @UserName AND SubFolder <> 255  AND [Mod] = ''  
) AS Folders  
ORDER BY Folders.[Mod], Folders.Title  
GO
GRANT EXECUTE ON  [dbo].[vspVPGetUserMyTaskFolders] TO [public]
GO
