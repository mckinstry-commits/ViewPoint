SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspRPGetReportID]
/********************************************
*	Created By: Dave C 6/23/2010
*	Modified By: HH 01/31/12 - TK-12099, extend RPRT.FileName from varchar(60) to varchar(255)
*
*	Usage:
*		Called from VPMenu to return a report ID from a report file name.
*		This feature is a part of #136716 to provide report developers a
*		command line switch to be able to launch Viewpoint to a specific
*		report.
*
*	Input Parameters:
*		@fileName
*
*	Output Parameters:
*		@reportID
*
*	Success returns:
*		ReportID from RPRT
*
*	Error returns:
*		DBNull
*		
********************************************/
(@fileName varchar(255), @reportID int output)

AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT	@reportID = ReportID
	FROM	dbo.RPRT
	WHERE	FileName = @fileName;
END



GO
GRANT EXECUTE ON  [dbo].[vspRPGetReportID] TO [public]
GO
