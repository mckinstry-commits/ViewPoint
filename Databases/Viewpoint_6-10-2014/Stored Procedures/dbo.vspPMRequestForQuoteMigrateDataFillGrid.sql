SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMRequestForQuoteMigrateDataFillGrid]
/***********************************************************
* CREATED BY:	GP	03/28/2013 TFS 13558
* MODIFIED BY:	
*				
* USAGE:
*	Used in PM Request for Quote Migrate Data to get filtered RFQ records to migrate.
*
* INPUT PARAMETERS
*   PMCo   
*   Project
*
* OUTPUT PARAMETERS
*   @msg	Errors
*
* RETURN VALUE
*   0       Success
*   1       Failure
*****************************************************/ 

(@PMCo bCompany = NULL, @Project bProject = NULL, @Msg VARCHAR(255) = NULL OUTPUT)
AS
SET NOCOUNT ON


DECLARE @Query VARCHAR(1000), @MainWhereClause VARCHAR(100), @WhereClause VARCHAR(100),
	@DuplicateCounter int, @DupPMCo bCompany, @DupProject bProject, @DupRFQ bDocument


--Validate
IF @PMCo IS NOT NULL 
	AND NOT EXISTS (SELECT 1 FROM dbo.PMCO WHERE PMCo = @PMCo)
BEGIN
	SET @Msg = 'Invalid PM Company.'
	RETURN 1
END

IF @PMCo IS NOT NULL AND @Project IS NOT NULL 
	AND NOT EXISTS (SELECT 1 FROM dbo.JCJMPM WHERE PMCo = @PMCo AND Project = @Project)
BEGIN
	SET @Msg = 'Invalid Project.'
	RETURN 1
END


--Drop temp tables (incase error and table still exists)
IF OBJECT_ID('tempdb.dbo.##RFQTemp') IS NOT NULL
BEGIN
    DROP TABLE ##RFQTemp
END

IF OBJECT_ID('tempdb.dbo.##RFQDuplicateTemp') IS NOT NULL
BEGIN
    DROP TABLE ##RFQDuplicateTemp
END


--Build initial select and exclude records already migrated
SET @Query = 
'SELECT PMRQ.PMCo, PMRQ.Project, PMRQ.RFQ, PMRQ.[Description], PMRQ.PCOType, PMRQ.PCO, PMOP.[Description] AS [PCO Description], PMRQ.KeyID, ''N'' AS [Duplicate] ' +
'INTO ##RFQTemp ' +
'FROM dbo.PMRQ ' +
'LEFT JOIN dbo.PMOP ON PMOP.PMCo = PMRQ.PMCo AND PMOP.Project = PMRQ.Project AND PMOP.PCOType = PMRQ.PCOType AND PMOP.PCO = PMRQ.PCO ' +
'LEFT JOIN dbo.PMRequestForQuote newRFQ ON newRFQ.PMRQKeyID = PMRQ.KeyID ' +
'WHERE newRFQ.PMRQKeyID IS NULL '

--Build where clause if PMCo and/or Project are provided (MainWhereClause used for primary select, WhereClause used for all others)
IF @PMCo IS NOT NULL
BEGIN
	SELECT @MainWhereClause = 'AND PMRQ.PMCo = ' + CAST(@PMCo AS VARCHAR(3)) + ' ',
		@WhereClause = 'WHERE PMRQ.PMCo = ' + CAST(@PMCo AS VARCHAR(3)) + ' '

	IF @Project IS NOT NULL
	BEGIN
		SELECT @MainWhereClause = @MainWhereClause + 'AND PMRQ.Project = ''' + @Project + ''' ',
			@WhereClause = @WhereClause + 'AND PMRQ.Project = ''' + @Project + ''' '
	END
END

--Add order by
SET @Query = @Query + ISNULL(@MainWhereClause,'') + 'ORDER BY PMRQ.PMCo, PMRQ.Project, PMRQ.RFQ'

--Populate temp table with RFQ records
EXECUTE (@Query)


--Find duplicates in PMRQ
SET @Query = 
'SELECT PMCo, Project, RFQ, ROW_NUMBER() OVER (ORDER BY PMCo, Project, RFQ) AS [Seq] ' +
'INTO ##RFQDuplicateTemp ' +
'FROM dbo.PMRQ ' +
ISNULL(@WhereClause,'') +
'GROUP BY PMCo, Project, RFQ ' +
'HAVING COUNT(*) > 1'

--Populate temp table with RFQ duplicate records
EXECUTE (@Query)

--Mark duplicates in temp table
UPDATE ##RFQTemp
SET Duplicate = 'Y'
FROM ##RFQTemp rfq
JOIN ##RFQDuplicateTemp dup ON dup.PMCo = rfq.PMCo AND dup.Project = rfq.Project AND dup.RFQ = rfq.RFQ 


--Find duplicates from PMRQ to PMRequestForQuote
IF OBJECT_ID('tempdb.dbo.##RFQDuplicateTemp') IS NOT NULL
BEGIN
    DROP TABLE ##RFQDuplicateTemp
END

SET @Query = 
'SELECT PMCo, Project, RFQ, ROW_NUMBER() OVER (ORDER BY PMCo, Project, RFQ) as [Seq] ' +
'INTO ##RFQDuplicateTemp ' +
'FROM dbo.PMRQ ' +
ISNULL(@WhereClause,'') +
'AND EXISTS (SELECT 1 FROM dbo.PMRequestForQuote new WHERE new.PMCo = PMRQ.PMCo AND new.Project = PMRQ.Project AND new.RFQ = PMRQ.RFQ) ' +
'GROUP BY PMCo, Project, RFQ'

--Populate temp table with RFQ duplicate records
EXECUTE (@Query)

--Mark duplicates in temp table
UPDATE ##RFQTemp
SET Duplicate = 'Y'
FROM ##RFQTemp rfq
JOIN ##RFQDuplicateTemp dup ON dup.PMCo = rfq.PMCo AND dup.Project = rfq.Project AND dup.RFQ = rfq.RFQ 


--Return RFQ records to fill grid
SELECT * FROM ##RFQTemp ORDER BY PMCo, Project, RFQ


--Drop temp tables
IF OBJECT_ID('tempdb.dbo.##RFQTemp') IS NOT NULL
BEGIN
    DROP TABLE ##RFQTemp
END

IF OBJECT_ID('tempdb.dbo.##RFQDuplicateTemp') IS NOT NULL
BEGIN
    DROP TABLE ##RFQDuplicateTemp
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteMigrateDataFillGrid] TO [public]
GO
