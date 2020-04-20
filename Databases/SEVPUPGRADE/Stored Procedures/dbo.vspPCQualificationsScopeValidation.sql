SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************
    * CREATED BY:	JB		3/16/2010
    * MODIFIED BY:
    *             
    * USAGE: Validates the PC Qualification Scope and Scope/Phase Combination.
    *
    *****************************************************/
CREATE     proc [dbo].[vspPCQualificationsScopeValidation]
	(
	@VendorGroup bGroup = NULL,
	@Scope VARCHAR(10) = NULL,
	@PhaseGroup TINYINT = NULL, 
	@Phase bPhase = NULL, 
	@msg VARCHAR(255) OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode INT
	SELECT @rcode = 0
	
	--Validate fields that should not be null
	IF (@VendorGroup IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Vendor Group.'
		GOTO vspExit
	END
	
	IF (@PhaseGroup IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Phase Group.'
		GOTO vspExit
	END
	
	--Validate Scope if it was entered
	IF (@Scope IS NOT NULL)
	BEGIN
		EXEC @rcode = vspPCScopeCodeValidation @VendorGroup, @Scope, @msg OUTPUT
		
		IF (@rcode <> 0 )
		BEGIN
			--The Scope entered is invalid
			GOTO vspExit 
		END
	END
	
	IF (@Phase IS NOT NULL)
	BEGIN
		--Validate that the scope/phase combination is valid
		IF NOT EXISTS(SELECT 1 FROM PCScopePhases WHERE VendorGroup = @VendorGroup AND ScopeCode = @Scope AND PhaseGroup = @PhaseGroup AND Phase = @Phase)
		BEGIN
			SELECT @rcode = 1, @msg = 'Invalid Scope: Phase ''' + @Phase + ''' does not belong to Scope ' + @Scope + '.'
			GOTO vspExit
		END
	END

	vspExit:
	RETURN @rcode
END



GO
GRANT EXECUTE ON  [dbo].[vspPCQualificationsScopeValidation] TO [public]
GO
