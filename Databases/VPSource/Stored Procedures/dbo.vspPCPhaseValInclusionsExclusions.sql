SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		GP		12/22/08
-- Modify:				
-- Usage:		Validates Phase using the given PMCo, PotentialProject, VendorGroup, and ScopeCode parameters

-- Input params:
--	@vendorGroup		VendorGroup
--	@scopeCode			ScopeCode

-- Output params:
--	@msg		ScopeCode error message

-- Return code:
--0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCPhaseValInclusionsExclusions]
	(@PMCo bCompany = null, 
	@PotentialProject varchar(20) = null, 
	@PhaseGroup tinyint = null, 
	@Phase bPhase = null,
	@msg VARCHAR(255) OUTPUT)
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SET @rcode = 0
	
	--Validation
	IF @PMCo IS NULL
	BEGIN
		SELECT @msg = 'PMCo is a required parameter!', @rcode = 1
		GOTO vspexit
	END
	
	IF @PotentialProject IS NULL
	BEGIN
		SELECT @msg = 'PotentialProject is a required parameter!', @rcode = 1
		GOTO vspexit
	END		
	
	IF @PhaseGroup IS NULL
	BEGIN
		SELECT @msg = 'PhaseGroup is a required parameter!', @rcode = 1
		GOTO vspexit
	END
	
	IF @Phase IS NULL
	BEGIN
		SELECT @msg = 'Phase is a required parameter!', @rcode = 1
		GOTO vspexit
	END	

	--Find record assigned to specified PMCo, PotentialProject, VendorGroup, and ScopeCode	
	if exists
		(SELECT TOP 1 1
		FROM dbo.PCBidPackageScopes WITH (NOLOCK)
		WHERE JCCo = @PMCo AND PotentialProject = @PotentialProject and PhaseGroup = @PhaseGroup and Phase = @Phase)
	begin
		--Set @msg to Scope Description in master table
		SELECT @msg = Description
		FROM dbo.JCPM WITH (NOLOCK)
		WHERE PhaseGroup = @PhaseGroup and Phase = @Phase
	end
	else
	begin
		--Set @msg if record not found
		SELECT @msg = @Phase + ' Phase not assigned to any Bid Packages for this Company and Potential Project!', @rcode = 1
	end
	


vspexit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPCPhaseValInclusionsExclusions] TO [public]
GO
