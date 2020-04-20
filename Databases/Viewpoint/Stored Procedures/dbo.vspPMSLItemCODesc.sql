SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************/
CREATE proc [dbo].[vspPMSLItemCODesc]
/***********************************************************
* Created By:	DAN SO 01/13/2011
* Modified By:	GF 02/21/2011
*
* USAGE:
* used to return description for the PMSL Sequence
*
* INPUT PARAMETERS
*	@PMCo		- JC Company
*	@Project	- Project
*	@SLCo		- SL Company
*	@SL			- SL Subcontract
*	@SCO		- Subcontract CO
*	@Seq		- PMSL Sequence (may be null)
*
* OUTPUT PARAMETERS
*   @msg	- error message if error occurs
* RETURN VALUE
*   0- Success
*   1 - Failure
*****************************************************/
(@PMCo bCompany = NULL, @Project bJob = NULL, @SLCo bCompany = NULL,
 @SL VARCHAR(30) = NULL, @SCO SMALLINT = NULL, @Seq INT = NULL,
 @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode int

SET @rcode = 0
SET @msg = ''

----------------------------
-- CHECK INPUT PARAMETERS --
----------------------------
IF @PMCo IS NULL
	BEGIN
		SET @msg = 'Missing PM Company!'
		SET @rcode = 1
		GOTO vspexit
	END

IF @Project IS NULL
	BEGIN
		SET @msg = 'Missing Project!'
		SET @rcode = 1
		GOTO vspexit
	END

IF @SLCo IS NULL
	BEGIN
		SET @msg = 'Missing SL Company!'
		SET @rcode = 1
		GOTO vspexit
	END

IF @SL IS NULL
	BEGIN
		SET @msg = 'Missing Subcontract!'
		SET @rcode = 1
		GOTO vspexit
	END
	
IF @SCO IS NULL
	BEGIN
		SET @msg = 'Missing Subcontract Change Order!'
		SET @rcode = 1
		GOTO vspexit
	END



---------------------
-- GET DESCRIPTION --
---------------------
IF @Seq IS NOT NULL
	BEGIN
	SELECT @msg = ISNULL(SLItemDescription,'')
	FROM dbo.PMSL
	WHERE PMCo = @PMCo AND Project = @Project
	AND SLCo=@SLCo AND SL = @SL
	AND Seq = @Seq
	END


vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSLItemCODesc] TO [public]
GO
