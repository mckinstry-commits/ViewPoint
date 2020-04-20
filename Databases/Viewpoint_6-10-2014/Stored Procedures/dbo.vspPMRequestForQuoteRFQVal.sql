SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE	PROCEDURE [dbo].[vspPMRequestForQuoteRFQVal]
/***********************************************************
* CREATED BY:	STO	04/03/2013
* MODIFIED BY:
*				
* USAGE:
* Used in PM Request for Quote Copy 
* to validate that the RFQ does not already exist.
*
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @RFQ bDocument, @msg varchar(255) output)
as
set nocount on



--Validate
IF @PMCo IS NULL
BEGIN
	SET @msg = 'Missing PM Company.'
	RETURN 1
END

IF @Project IS NULL
BEGIN
	SET @msg = 'Missing Project.'
	RETURN 1
END

IF @RFQ IS NULL
BEGIN
	SET @msg = 'Missing RFQ.'
	RETURN 1
END

--Check to make sure RFQ is not a duplicate
IF EXISTS (SELECT 1 
			FROM dbo.PMRequestForQuote
			WHERE PMCo = @PMCo AND Project = @Project AND RFQ = @RFQ)
BEGIN
	SET @msg = 'The RFQ already exists. The RFQ must be new.'
	RETURN 1
END

--Success
RETURN 0	
	
GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteRFQVal] TO [public]
GO
