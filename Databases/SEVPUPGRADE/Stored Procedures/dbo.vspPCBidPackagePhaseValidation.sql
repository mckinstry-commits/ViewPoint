SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************
    * CREATED BY:	JB		3/10/2010
    * MODIFIED BY:
    *             
    * USAGE: Validates the Bid Package Scope AND Scope/Phase Combination.
    *
    *****************************************************/
CREATE     proc [dbo].[vspPCBidPackagePhaseValidation]
	(
	@Company bCompany,
	@PotentialProject VARCHAR(20) = NULL,
	@BidPackage VARCHAR(20) = NULL,
	@Seq BIGINT = NULL,
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
	
	DECLARE @rcode INT, @errmsg VARCHAR(255)
	SELECT @rcode = 0, @msg = NULL
	
	--Validate fields that should not be null
	IF (@Company IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Company.'
		GOTO vspExit
	END
	
	IF (@PotentialProject IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Potential Project.'
		GOTO vspExit
	END
	
	IF (@BidPackage IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Bid Package.'
		GOTO vspExit
	END
	
	IF (@Seq IS NULL)
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid Seq #.'
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
	
	--Validate the the Scope/Phase combination doesn't already exist in the bid package
	IF (@Scope IS NULL)
	BEGIN
		IF (EXISTS(
			SELECT * FROM PCBidPackageScopes WHERE JCCo = @Company
						AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage
						AND VendorGroup = @VendorGroup 
						AND ScopeCode IS NULL 
						AND PhaseGroup = @PhaseGroup
						AND Phase = @Phase
						AND Seq <> @Seq
			))
		BEGIN
			SELECT @rcode = 1, @msg = 'Invalid Phase: This Scope ' + @Scope +  ' already exists for this bid package.  A phase will need to be added to continue.'
			GOTO vspExit
		END
	END
	ELSE
	BEGIN
		IF (EXISTS(
			SELECT * FROM PCBidPackageScopes WHERE JCCo = @Company
						AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage
						AND VendorGroup = @VendorGroup 
						AND ScopeCode = @Scope 
						AND PhaseGroup = @PhaseGroup
						AND Phase = @Phase
						AND Seq <> @Seq
			))
		BEGIN
			SELECT @rcode = 1, @msg = 'Invalid Phase: This Scope ' + @Scope + '/Phase ''' + @Phase + ''' combination ' + 'already exists for this bid package.'
			GOTO vspExit
		END
	END

	vspExit:
	RETURN @rcode
END



GO
GRANT EXECUTE ON  [dbo].[vspPCBidPackagePhaseValidation] TO [public]
GO
