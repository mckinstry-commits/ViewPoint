SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetListOfFilteredProjects]
/****************************************
 * Created By:	HH 03/14/2011
 * Modified By:	
 * 				GPT 01/16/2012 Added ProjectManagerFilterIsNone logic. TK-11526
 *
 *	Called by Tree view in my viewpoint to get list of available projects for current company filtered by JobStatus
 *
 * Returns:
 * dataset of projects for the current company
 *
 *
 **************************************/
(
@Company bCompany,
@JobStatus int,
@ProjectManager int,
@ProjectManagerFilterIsNone bit = 0)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT	'All', '' AS Job
	
	UNION ALL
	
	SELECT	Job, [Description]
	FROM dbo.JCJM
	WHERE JCCo = @Company AND (JobStatus = COALESCE(@JobStatus, JobStatus) OR @JobStatus = -1)
	AND (
			( @ProjectManagerFilterIsNone = 0 AND (ProjectMgr = @ProjectManager OR @ProjectManager IS NULL)) 
			OR  
			( @ProjectManagerFilterIsNone = 1 AND ProjectMgr IS NULL)
	    )
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetListOfFilteredProjects] TO [public]
GO
