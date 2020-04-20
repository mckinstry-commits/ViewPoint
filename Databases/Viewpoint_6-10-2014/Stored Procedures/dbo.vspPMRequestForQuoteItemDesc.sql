SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspPMRequestForQuoteItemDesc]
/***********************************************************
* CREATED BY:	GP	03/01/2013 - TFS 42607
* MODIFIED BY:	
*				
* USAGE:
* Used in PM Request For Quote Detail to return a item description.
*
* INPUT PARAMETERS
*   PMCo   
*   Project
*	RFQ
*	RFQItem
*
* OUTPUT PARAMETERS
*   @msg		Description if found.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @RFQ bDocument, @RFQItem int, @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON


--Validate
IF @Project IS NULL
BEGIN
	SELECT @msg = 'Missing Project.'
	RETURN 1
END

IF @PMCo IS NULL
BEGIN
	SELECT @msg = 'Missing PM Company.'
	RETURN 1
END

IF @RFQ IS NULL
BEGIN
	SELECT @msg = 'Missing RFQ.'
	RETURN 1
END

IF @RFQItem IS NULL
BEGIN
	SELECT @msg = 'Missing RFQ Item.'
	RETURN 1
END


--Get Description
SELECT @msg = [Description] FROM dbo.PMRequestForQuoteDetail WHERE PMCo = @PMCo AND Project = @Project AND RFQ = @RFQ AND RFQItem = @RFQItem
	

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteItemDesc] TO [public]
GO
