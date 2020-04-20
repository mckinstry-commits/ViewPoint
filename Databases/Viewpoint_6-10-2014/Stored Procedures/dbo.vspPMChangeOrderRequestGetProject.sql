SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE proc [dbo].[vspPMChangeOrderRequestGetProject]
CREATE  proc [dbo].[vspPMChangeOrderRequestGetProject]
/***********************************************************
* CREATED BY:	DAN SO	03/26/2011
* MODIFIED BY:	TL 07/11/2013 Bug: 54382 , Task: 54798 Return Minimum Project for Contract
*				
* USAGE:
* Return a valid min Project from a Contract
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*
* OUTPUT PARAMETERS
*	@Project	- Get Min Project for the Contract
*   @msg		- Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@PMCo bCompany = NULL, @Contract bContract = NULL, 
 @Project bProject output, @msg varchar(255) output)
 
AS

SET NOCOUNT ON

DECLARE	@rcode int

SET @rcode = 0

-------------------------------
-- CHECK INCOMING PARAMETERS --
-------------------------------
IF @PMCo IS NULL
BEGIN
	SET @msg = 'Missing PM Company.'
	SET @rcode = 1
	GOTO vspexit
END

IF @Contract IS NULL
BEGIN
	SET @msg = 'Missing Contract.'
	SET @rcode = 1
	GOTO vspexit
END

SELECT @Project = Min(Project) FROM dbo.JCJMPM with (NOLOCK) WHERE PMCo = @PMCo  AND Contract = @Contract

IF ISNULL(@Project,'') = ''
BEGIN
	SET @msg =  'Could not find a Project associated with Contract .' + ISNULL(@Contract,'N/A')
	SET @rcode = 1
	GOTO vspexit
END
	
vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestGetProject] TO [public]
GO
