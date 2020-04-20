SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROC [dbo].[vspPMGetNextSubmittalPackage]
/***********************************************************
* CREATED BY:	TRL 03/14/2013 TFS Bug 43885 - add procedure to return formatted Package
* MODIFIED BY:	
*			
*			
* USAGE:
* Used in PM Submittal Package to get the next Package Number
*
*****************************************************/ 

(@PMCo bCompany = null, @Project bProject = null, @Package bDocument OUTPUT, @msg VARCHAR(255) OUTPUT)

AS

SET NOCOUNT ON

IF @PMCo IS NULL
BEGIN
	SELECT @msg = 'Missing PM Company'
	RETURN 1	
END

IF @Project IS NULL
BEGIN
	SELECT @msg = 'Missing Project'
	RETURN 1
END

--Get the next numeric Package number
SELECT @Package = Convert (varchar,(ISNULL(MAX(CAST (CAST (ISNULL(Package,0) AS float) AS int)),0) +1))
FROM dbo.PMSubmittalPackage 
WHERE PMCo = @PMCo AND Project = @Project AND ISNUMERIC(Package) = 1

--Format/Return new package number for bDocument 
Select @Package = dbo.bfJustifyStringToDatatype(@Package,'bDocument')

---------
--Success
---------
RETURN 0	

GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextSubmittalPackage] TO [public]
GO
