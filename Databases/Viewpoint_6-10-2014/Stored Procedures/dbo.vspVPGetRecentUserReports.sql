SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVPGetRecentUserReports]
/**************************************************
* Created: CC 08/15/2008
* Modified: CC 07/15/2009 - Issue #133695 - Hide forms that are not applicable to the current country
*			RM 03/22/2010 - Issue #133409 - Remove join to RPRM to avoid duplicates. Do not need to check Active flag, per Andrew.  
*			
*	
*	Gets top n most recently viewed reports for the given user.
* 
*
* Inputs:
*	@co					Company
*	@User				Username
*	@NumberOfReports	Number of Reports to display
*
* Output:
*	resultset	Reports with access info
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
(@co bCompany = NULL, 
@User bVPUserName = NULL,
@NumberOfReports int = 0,
@country CHAR(2) = NULL,
@errmsg VARCHAR(512) OUTPUT)

AS

SET NOCOUNT ON

DECLARE @rcode int, 
		@opencursor tinyint,
		@reportid int,
		@access tinyint
	
IF @co IS NULL
	BEGIN
		SELECT @errmsg = 'Missing required input parameter(s): Company #', @rcode = 1
		GOTO vspexit
	END

SELECT @rcode = 0

-- use a local table to hold all Reports for the Module
DECLARE @allreports TABLE(
							ReportID int, 
							Title VARCHAR(60), 
							ReportType VARCHAR(10),
							LastAccessed datetime, 
							Accessible CHAR(1), 
							[Status] CHAR(8),
							AppType VARCHAR(30), 
							IconKey VARCHAR(20)
						  )

	INSERT @allreports (ReportID, Title, ReportType, LastAccessed, Accessible, Status, AppType, IconKey)
	SELECT 
		t.ReportID,  
		t.Title, 
		t.ReportType, 
		u.LastAccessed, 
		'Y', 
		t.Status, 
		t.AppType, 
		t.IconKey
	FROM RPRTShared t
	LEFT OUTER JOIN vRPUP u ON u.ReportID = t.ReportID AND u.VPUserName = @User
	WHERE	t.ShowOnMenu = 'Y' 
			AND (t.Country = @country OR t.Country IS NULL)

IF @User = 'viewpointcs' GOTO return_results	-- Viewpoint system user has access to all reports 

-- create a cursor to process each Report
DECLARE vcReports CURSOR LOCAL FAST_FORWARD FOR
SELECT ReportID FROM @allreports

OPEN vcReports
SET @opencursor = 1
;
report_loop:	-- check Security for each Report
	FETCH NEXT FROM vcReports INTO @reportid
	IF @@fetch_status <> 0 GOTO end_report_loop

	EXEC @rcode = vspRPReportSecurity @co, @reportid, @access = @access OUTPUT, @errmsg = @errmsg OUTPUT
	IF @rcode <> 0 GOTO vspexit
	
	UPDATE @allreports
	SET Accessible = CASE 
						WHEN @access = 0 THEN 'Y' 
						ELSE 'N' 
					 END
	WHERE ReportID = @reportid

	GOTO report_loop

end_report_loop:	--  all Reports checked
	CLOSE vcReports
	DEALLOCATE vcReports
	SELECT @opencursor = 0

return_results:	-- return resultset
	SELECT TOP(@NumberOfReports)
		ReportID, 
		Title, 
		ReportType, 
		LastAccessed, 
		Accessible, 
		AppType, 
		IconKey
	FROM @allreports
	WHERE Accessible = 'Y'
	ORDER BY LastAccessed DESC
   
vspexit:
	IF @opencursor = 1
		BEGIN
			CLOSE vcReports
			DEALLOCATE vcReports
		END

	IF @rcode <> 0 SELECT @errmsg = @errmsg + CHAR(13) + CHAR(10) + '[vspVPGetRecentUserReports]'
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspVPGetRecentUserReports] TO [public]
GO
