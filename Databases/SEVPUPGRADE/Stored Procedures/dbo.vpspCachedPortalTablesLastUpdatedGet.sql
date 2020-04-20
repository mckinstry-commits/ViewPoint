SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Unknown
-- Create date: Unknown
-- Description:	Retrieve the LastUpdateDate for each cached Portal table.
-- Modified: Chris G 8/23/2010 - Issue 140857 - Changed query to use new pPortalTableCache table.
--           Chris G 11/1/2010 - Issue 141950 - Handle CASE statement with dignity (avoid duplicates).
-- =============================================
CREATE PROCEDURE [dbo].[vpspCachedPortalTablesLastUpdatedGet]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- TEMP table to store results of CASE statements
	DECLARE @TempTableCache TABLE
	(
		TableName varchar(128),
		LastUpdatedDate datetime
	)
	
	INSERT INTO @TempTableCache (TableName, LastUpdatedDate)
		SELECT CASE TableName 
				WHEN 'pReportControls' THEN 'pPortalControlReports'
				WHEN 'pReportControlsCustom' THEN 'pPortalControlReports'
				WHEN 'pReportSecurity' THEN 'pReportSecurity'
				WHEN 'pReportSecurityCustom' THEN 'pReportSecurity'
				ELSE TableName
			END AS TableName,
			LastUpdatedDate
		FROM pPortalTableCache

	-- Portal can't handle duplicate TableNames but the architecture relies on
	-- the customizable tables to map into standard ones as though they are one table.  
	-- The cache may needs to be updated when either the standard or custom table is 
	-- changed.  This takes the MAX of the two to tell Portal the last time that one 
	-- of them changed.  Its a bit Hackish but necessary until Portal architecture is
	-- refactored.
	SELECT TableName, MAX(LastUpdatedDate) AS LastUpdatedDate FROM @TempTableCache GROUP BY TableName;
END


GO
GRANT EXECUTE ON  [dbo].[vpspCachedPortalTablesLastUpdatedGet] TO [VCSPortal]
GO
