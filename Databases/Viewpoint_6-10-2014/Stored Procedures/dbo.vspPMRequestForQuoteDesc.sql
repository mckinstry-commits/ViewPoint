SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMRequestForQuoteDesc]
/***********************************************************
* CREATED BY:	GP	02/28/2013 - TFS 42499
* MODIFIED BY:	
*				
* USAGE:
* Used in PM Request For Quote to return a description.
*
* INPUT PARAMETERS
*   PMCo   
*   Project
*	RFQ
*
* OUTPUT PARAMETERS
*   @msg		Description if found.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @RFQ bDocument, @msg VARCHAR(255) OUTPUT)
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


--Get Description
SELECT @msg = [Description] FROM dbo.PMRequestForQuote WHERE PMCo = @PMCo AND Project = @Project AND RFQ = @RFQ
	

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteDesc] TO [public]
GO
