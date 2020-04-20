SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPMRequestForQuoteMigrateData]
/***********************************************************
* CREATED BY:	GP	04/01/2013 TFS 13558
* MODIFIED BY:	GP	05/31/2013 TFS 49467 - Added migration for user defined fields
*				GP	08/19/2013 TFS 57803 - Added ResponsiblePerson, VendorGroup, and FirmNumber to insert
*				
* USAGE:
*	Used in PM Request for Quote Migrate Data to push data to PMRequestForQuote and create PCO record relation.
*
* INPUT PARAMETERS
*   PMRQKeyID - source KeyID to find record and link to PMRQ
*	RFQ - some original from PMRQ, duplicates modified to be unique
*	Description - some original from PMRQ, user can override for duplicate records
*
* OUTPUT PARAMETERS
*   @Msg	Errors
*
* RETURN VALUE
*   0       Success
*   1       Failure
*****************************************************/ 

(@PMRQKeyID BIGINT, @RFQ bDocument, @Description bItemDesc, @NewRFQKeyID BIGINT OUTPUT, @Msg VARCHAR(255) = NULL OUTPUT)
AS
SET NOCOUNT ON


--Validate
IF @PMRQKeyID IS NULL
BEGIN
	SET @Msg = 'Invalid source KeyID.'
	RETURN 1
END

IF @RFQ IS NULL
BEGIN
	SET @Msg = 'Invalid RFQ.'
	RETURN 1
END


DECLARE @PCOKeyID BIGINT



--Insert new RFQ header record
INSERT dbo.vPMRequestForQuote (PMCo, Project, RFQ, CreateDate, DueDate, [Description], [Status], Notes, UniqueAttchID, PMRQKeyID, ResponsiblePerson, VendorGroup, FirmNumber)
SELECT PMCo, Project, @RFQ, RFQDate, DateDue, @Description, [Status], Notes, UniqueAttchID, @PMRQKeyID, ResponsiblePerson, VendorGroup, FirmNumber
FROM dbo.PMRQ
WHERE KeyID = @PMRQKeyID

SELECT @NewRFQKeyID = SCOPE_IDENTITY()


--Get PCO KeyID
SELECT @PCOKeyID = PMOP.KeyID
FROM dbo.PMRQ
JOIN dbo.PMOP ON PMOP.PMCo = PMRQ.PMCo AND PMOP.Project = PMRQ.Project AND PMOP.PCOType = PMRQ.PCOType AND PMOP.PCO = PMRQ.PCO
WHERE PMRQ.KeyID = @PMRQKeyID

--Insert record relation if PCO still exists
IF @PCOKeyID IS NOT NULL
BEGIN
	INSERT dbo.vPMRelateRecord (RecTableName, RECID, LinkTableName, LINKID)
	VALUES ('PMRequestForQuote', @NewRFQKeyID, 'PMOP', @PCOKeyID)
END




RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteMigrateData] TO [public]
GO
