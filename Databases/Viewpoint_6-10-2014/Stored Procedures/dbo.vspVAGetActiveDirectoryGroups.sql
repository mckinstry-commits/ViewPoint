SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAGetActiveDirectoryGroups]
/***********************************************************************
*  Created by: 	CC 02-22-2011
*
*  Altered by: 	
*              	
*              	
*							
* Usage: returns a datatable of groups & their domain name from sys.database_principals
* 
***********************************************************************/

AS  
BEGIN
	SET NOCOUNT ON;
	SELECT	  LEFT([name], CHARINDEX('\',[name])-1) AS DomainName
			, [name] 
	FROM sys.database_principals 
	WHERE [type] ='G';
END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetActiveDirectoryGroups] TO [public]
GO
