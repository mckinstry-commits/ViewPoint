SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMSubmittalPackageCreateRevisionRevVal]
/***********************************************************
* CREATED BY:	GPT	09/05/2012
* MODIFIED BY:	GP	11/30/2012 TK-19818 - Changed submittal and package to bDocument
*				
* USAGE:
* Used in PM Submittal Package Create Revision 
* to validate that the package doesn't exist.
*
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @Package bDocument, @Revision varchar(5), @msg varchar(255) output)
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

IF @Revision IS NULL
BEGIN
	SET @msg = 'Missing Revision.'
	RETURN 1
END

--Check to make sure revision is not a duplicate
IF EXISTS (SELECT 1 
			FROM dbo.PMSubmittalPackage
			WHERE PMCo = @PMCo AND Project = @Project AND Package = @Package AND PackageRev = @Revision)
BEGIN
	SET @msg = 'The package revision must be new.'
	RETURN 1
END

--Success
RETURN 0	
	
GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalPackageCreateRevisionRevVal] TO [public]
GO
