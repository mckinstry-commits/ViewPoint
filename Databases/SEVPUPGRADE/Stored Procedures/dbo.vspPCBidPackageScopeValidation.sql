SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
    * CREATED BY:	JB		3/10/2010
    * MODIFIED BY:
    *             
    * USAGE: Validates the Bid Package Scope AND Scope Combination.
    *
    *****************************************************/
CREATE     proc [dbo].[vspPCBidPackageScopeValidation]
	(
	@Company bCompany,
	@PotentialProject VARCHAR(20) = NULL,
	@BidPackage VARCHAR(20) = NULL,
	@Seq BIGINT = NULL,
	@VendorGroup bGroup = NULL,
	@Scope VARCHAR(10) = NULL,
	@PhaseGroup TINYINT = NULL, 
	@Phase bPhase = NULL, 
	@msg VARCHAR(255) OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode INT, @errmsg VARCHAR(255)
	SELECT @rcode = 0
	
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
	
	--Validate the the Scope/Phase combination doesn't already exist in the bid package
	IF (@Phase IS NULL)
	BEGIN
		
		IF (EXISTS(
			SELECT * FROM PCBidPackageScopes WHERE JCCo = @Company
						AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage
						AND VendorGroup = @VendorGroup 
						AND ScopeCode = @Scope 
						AND PhaseGroup = @PhaseGroup
						AND Phase IS NULL
						AND Seq <> @Seq
			))
		BEGIN
			SELECT @rcode = 1, @msg = 'Invalid Scope: This Scope ' + @Scope +  ' already exists for this bid package.  A phase will need to be added to continue.'
			GOTO vspExit
		END
	END
	ELSE
	BEGIN
		--Validate that the scope/phase combination is valid
		IF NOT EXISTS(SELECT 1 FROM PCScopePhases WHERE VendorGroup = @VendorGroup AND ScopeCode = @Scope AND PhaseGroup = @PhaseGroup AND Phase = @Phase)
		BEGIN
			SELECT @rcode = 1, @msg = 'Invalid Scope: Phase ''' + @Phase + ''' does not belong to Scope ' + @Scope + '.'
			GOTO vspExit
		END
		
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
			SELECT @rcode = 1, @msg = 'Invalid Scope: This Scope ' + @Scope + '/Phase ''' + @Phase + ''' combination ' + 'already exists for this bid package.'
			GOTO vspExit
		END
	END

	vspExit:
	RETURN @rcode
END


GO
GRANT EXECUTE ON  [dbo].[vspPCBidPackageScopeValidation] TO [public]
GO
