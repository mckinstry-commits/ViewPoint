SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspPMSubmittalPackageDescription]
/***********************************************************
* CREATED BY:	GP	08/24/2012
* MODIFIED BY:	GP	11/30/2012 TK-19818 - Changed submittal and package to bDocument
*				
* USAGE:
* Used in PM Submittal Package to return a description to the package field.
*
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @Package bDocument, @msg varchar(255) output)
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

IF @Package IS NULL
BEGIN
	SET @msg = 'Missing Package.'
	RETURN 1
END

--Check to make sure revision is not a duplicate
SELECT @msg = [Description]
FROM dbo.PMSubmittalPackage
WHERE PMCo = @PMCo AND Project = @Project AND Package = @Package


--Success
RETURN 0	
	

GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalPackageDescription] TO [public]
GO
