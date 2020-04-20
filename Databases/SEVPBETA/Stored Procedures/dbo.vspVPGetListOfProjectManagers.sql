SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetListOfProjectManagers]
/****************************************
 * Created By:	GPT 01/05/2012
 * Modified By:	
 * 				GPT 01/16/2012 Added 'None' to the result set
 *
 *	Called by the VCSCanvasFilterPart for WC to get a list of the project managers
 *   for the select company.  (PM Workcenter Only)
 *
 * Returns:
 * dataset of project managers for the current company
 *
 *
 **************************************/
(@Company bCompany)	
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT	-1 AS [ProjectMgr], 'All' AS [Name]
	
	UNION ALL
	
	SELECT	-2 AS [ProjectMgr], 'None' AS [Name]
	UNION ALL
	
	SELECT [ProjectMgr], [Name] FROM dbo.JCMP 
	WHERE JCCo = @Company
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetListOfProjectManagers] TO [public]
GO
