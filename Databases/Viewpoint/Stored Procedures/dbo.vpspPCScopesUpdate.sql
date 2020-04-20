SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCScopesUpdate]
	(@Original_KeyID BIGINT, @Key_VendorGroup bGroup, @Key_Vendor bVendor, @PhaseCode bPhase, @ScopeCode VARCHAR(30), @SelfPerformed bYN, @WorkPrevious bPct, @WorkNext bPct, @NoPriorWork bYN, @PhaseGroup INT, @JCCo INT, @Key_Seq TINYINT)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @rcode INT
	SET @rcode = 0

	IF @PhaseCode IS NOT NULL
	BEGIN
		-- We need to get the phase group for the user if it is not already set
		IF @PhaseGroup IS NULL
		BEGIN
			SELECT @PhaseGroup = PhaseGroup
			FROM HQCO
			WHERE HQCo = @JCCo
		END

		DECLARE @InputMask VARCHAR(30), 
		@FormattedPhaseCode VARCHAR(50)
	
		-- Get input mask for bPhase
		SELECT @InputMask = InputMask 
			FROM DDDTShared WITH (NOLOCK)
			WHERE Datatype = 'bPhase'

		-- Format value to phase
		EXEC @rcode = dbo.bspHQFormatMultiPart @PhaseCode, @InputMask, @FormattedPhaseCode OUTPUT
		
		IF @rcode = 0 
		BEGIN
			SET @PhaseCode = @FormattedPhaseCode
		END
	END
	
	IF @rcode != 0 
	BEGIN	
		RAISERROR('Error Formatting Phase code %s!', 16, 1, @PhaseCode)
	END
	ELSE
	BEGIN
		UPDATE PCScopes
		SET
			VendorGroup = @Key_VendorGroup,
			Vendor = @Key_Vendor,
			PhaseCode = @PhaseCode,
			ScopeCode = @ScopeCode,
			SelfPerformed = @SelfPerformed,
			WorkPrevious = @WorkPrevious,
			WorkNext = @WorkNext,
			NoPriorWork = @NoPriorWork,
			PhaseGroup = @PhaseGroup
		WHERE KeyID = @Original_KeyID
		
		EXEC vpspPCScopesGet @Key_VendorGroup, @Key_Vendor, @JCCo, @Key_Seq
	END
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCScopesUpdate] TO [VCSPortal]
GO
