SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
    * CREATED BY:	JB		3/9/2010
    * MODIFIED BY:
    *             
    * USAGE: Validates a Scopes Phases.
    *
    *****************************************************/
CREATE     proc [dbo].[vspPCValidateScopePhase]
	(
	@Company bCompany,
	@VendorGroup bGroup = NULL,
	@Scope VARCHAR(10) = NULL,
	@PhaseGroup TINYINT = NULL, 
	@Phase bPhase = NULL,  
	@msg VARCHAR(255) OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode INT, @FoundScope VARCHAR(10)
	SELECT @rcode = 0
	
	--Validate fields are not null
	IF (@Company IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Company.'
		GOTO vspExit
	END
	
	IF (@VendorGroup IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Vendor Group.'
		GOTO vspExit
	END
	
	IF (@Scope IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Scope.'
		GOTO vspExit
	END
	
	IF (@PhaseGroup IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Phase Group.'
		GOTO vspExit
	END
	
	IF (@Phase IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Phase.'
		GOTO vspExit
	END
	
	--Validate Phase
	EXEC @rcode = bspJCPMValUseValidChars @Company, @PhaseGroup, @Phase, NULL, @msg OUTPUT
	IF (@rcode <> 0)
	BEGIN
		GOTO vspExit
	END
	
	--Validate that Phase isn't already assigned to another scope
	SELECT @FoundScope = ScopeCode FROM PCScopePhases WHERE VendorGroup = @VendorGroup AND PhaseGroup = @PhaseGroup AND Phase = @Phase
	IF (NOT @FoundScope IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Phase ''' + @Phase + ''' has already been assigned.  It must first be removed from Scope Code ' + @FoundScope + ' to be assigned.' 
	END

	vspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCValidateScopePhase] TO [public]
GO
