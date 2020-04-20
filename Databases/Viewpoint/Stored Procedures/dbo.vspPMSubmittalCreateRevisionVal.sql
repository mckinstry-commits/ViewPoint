SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMSubmittalCreateRevisionVal]
/***********************************************************
* CREATED BY:	GP	08/23/2012
* MODIFIED BY:	GP	11/30/2012 TK-19818 - Changed submittal and package to bDocument
*				
* USAGE:
* Used in PM Submittal Register Create Revision 
* to validate that the revision does not exist.
*
*****************************************************/ 

(@PMCo bCompany, @Project bProject, @Submittal bDocument, @Revision varchar(5), @msg varchar(255) output)
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

IF @Submittal IS NULL
BEGIN
	SET @msg = 'Missing Submittal.'
	RETURN 1
end

IF @Revision IS NULL
BEGIN
	SET @msg = 'Missing Revision.'
	RETURN 1
END

--Check to make sure revision is not a duplicate
IF EXISTS (SELECT 1 
			FROM dbo.PMSubmittal 
			WHERE PMCo = @PMCo AND Project = @Project AND SubmittalNumber = @Submittal AND SubmittalRev = @Revision)
BEGIN
	SET @msg = 'The revision already exists on this submittal.'
	RETURN 1
END

--Success
RETURN 0	
	
GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalCreateRevisionVal] TO [public]
GO
