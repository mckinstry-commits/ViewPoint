SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetListOfProjects]
/****************************************
 * Created By:	CC 08/31/2010
 * Modified By:	
 *
 *	Called by Tree view in my viewpoint to get list of available projects for current company
 *
 * Returns:
 * dataset of projects for the current company
 *
 *
 **************************************/
(@Company bCompany)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT Job
	FROM dbo.JCJM
	WHERE JCCo = @Company AND JobStatus IN (0,1);
	
END



GO
GRANT EXECUTE ON  [dbo].[vspVPGetListOfProjects] TO [public]
GO
