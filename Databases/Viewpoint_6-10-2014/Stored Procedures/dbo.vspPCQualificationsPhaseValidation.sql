SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***********************************************************
    * CREATED BY:	JB		3/16/2010
    * MODIFIED BY:	GP		10/21/2010 - Issue #139801 added error message if phase not assigned to entered scope
    *             
    * USAGE: Validates the PC Qualifications Phase AND Scope/Phase Combination.
    *
    *****************************************************/
CREATE     proc [dbo].[vspPCQualificationsPhaseValidation]
	(
	@Company bCompany,
	@VendorGroup bGroup = NULL,
	@Scope VARCHAR(10) = NULL,
	@PhaseGroup TINYINT = NULL, 
	@Phase bPhase = NULL, 
	@ScopeOut VARCHAR(10) OUTPUT,
	@msg VARCHAR(255) OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode INT
	SELECT @rcode = 0
	
	--Validate fields that should not be null
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
	
	IF (@PhaseGroup IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Phase Group.'
		GOTO vspExit
	END
	
	--Validate Phase if it was entered
	IF (@Phase IS NOT NULL)
	BEGIN
		EXEC @rcode = bspJCPMValUseValidChars @Company, @PhaseGroup, @Phase, NULL, @msg OUTPUT
		IF (@rcode <> 0)
		BEGIN
			GOTO vspExit
		END
		
		--Update the Scope based on the Phase
		SELECT @ScopeOut = ScopeCode FROM PCScopePhases WHERE VendorGroup = @VendorGroup AND PhaseGroup = @PhaseGroup AND Phase = @Phase
	END
	
	--Display error if Scope was entered and Phase does not belong to it
	IF (@Scope is not null and @ScopeOut is null)
	BEGIN
		SELECT @rcode = 1, @msg = 'Phase ' + @Phase + ' is not assigned to Scope ' + @Scope + ' in the PC Scope Codes form.'
		GOTO vspExit
	END
	
	vspExit:
	RETURN @rcode
END




GO
GRANT EXECUTE ON  [dbo].[vspPCQualificationsPhaseValidation] TO [public]
GO
