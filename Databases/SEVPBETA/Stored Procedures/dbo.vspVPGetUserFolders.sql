SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetUserFolders]
/**************************************************
* Created: CC 9/23/2008
* Modified: 
*	
*
*	Gets custom folders by user, and the company folder
*
* Inputs:
*	Company, Username
*
* Output:
*	resultset of Viewpoint menu struecture
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
	WHERE o.Active = 'Y' AND VPUserName = SUSER_SNAME() AND SubFolder <> 255 

	UNION ALL

	SELECT DDSF.[Mod], SubFolder, DDSF.Title, Co 
	FROM DDSF 
	WHERE VPUserName = SUSER_SNAME() AND SubFolder <> 255  AND [Mod] = ''
) AS Folders
ORDER BY Folders.[Mod], Folders.Title


GO
GRANT EXECUTE ON  [dbo].[vspVPGetUserFolders] TO [public]
GO
