SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Jeremiah Barkley>
-- Create date: <1/21/09>
-- Description:	<PCScopesInsert Script>
--				GF 06/20/2012 TK-15926 missing Key_Seq parameter
--
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCScopesInsert]
	-- Add the parameters for the stored procedure here
	(@Key_VendorGroup bGroup,
	 @Key_Vendor bVendor,
	 ----TK-15926
	 @Key_Seq VARCHAR(3),
	 @PhaseCode bPhase, 
	 @ScopeCode VARCHAR(10), 
	 @SelfPerformed bYN, 
	 @WorkPrevious bPct, 
	 @WorkNext bPct, 
	 @NoPriorWork bYN, 
	 @JCCo INT)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @NextSeq TINYINT, @PhaseGroup INT
	SELECT @NextSeq = ISNULL(MAX(Seq) + 1, 1) FROM PCScopes WHERE VendorGroup = @Key_VendorGroup AND Vendor = @Key_Vendor
	
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
		INSERT INTO PCScopes
			(Vendor, VendorGroup, Seq, PhaseCode, ScopeCode, SelfPerformed, WorkPrevious, WorkNext, NoPriorWork, PhaseGroup)
		VALUES
			(@Key_Vendor, @Key_VendorGroup, @NextSeq, @PhaseCode, @ScopeCode, @SelfPerformed, @WorkPrevious, @WorkNext, @NoPriorWork, @PhaseGroup)
			
		EXECUTE vpspPCScopesGet @Key_VendorGroup, @Key_Vendor, @JCCo, @NextSeq
	END
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCScopesInsert] TO [VCSPortal]
GO
