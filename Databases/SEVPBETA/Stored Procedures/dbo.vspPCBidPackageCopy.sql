SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  /***********************************************************
   * CREATED BY:	DAN SO 08/20/2010
   * MODIFIED BY:
   *				
   * USAGE:
   * Copy an existing Bid Package. 
   *
   * INPUT PARAMETERS
   *   JCCo   
   *   PotentialProject
   *   BidPackage
   *
   * OUTPUT PARAMETERS
   *   @msg      
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
--CREATE PROCEDURE [dbo].[vspPCBidPackageCopy]
CREATE PROCEDURE [dbo].[vspPCBidPackageCopy]	
	(@JCCo bCompany, @SourcePotentialProject VARCHAR(20), @BidPackage VARCHAR(20), 
	@DestinationPotentialProject VARCHAR(20), @DestinationBidPackage VARCHAR(20), @CopyInfo bYN = 'N', @CopyScopePhase bYN = 'N',
	@CopyBidList bYN = 'N', @CopyInclusionsExclusions bYN = 'N',
	@msg VARCHAR(255) OUTPUT)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- DECLARE VARIABLES --
	DECLARE @rcode		INT,
			@TransError INT

	-- PRIME VARIABLES --
	SET @rcode = 0


	--------------------------------
	-- VERIFY INCOMING PARAMETERS --
	--------------------------------
	IF @JCCo IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing JCCo value'
			GOTO vspExit
		END

	IF @SourcePotentialProject IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Source Potential Project value'
			GOTO vspExit
		END

	IF @BidPackage IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Bid Package value'
			GOTO vspExit
		END

	IF @DestinationPotentialProject IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Destination Potential Project value'
			GOTO vspExit
		END
		
	IF @DestinationBidPackage IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing New Bid Package ID'
			GOTO vspExit
		END


	---------------------
	-- VERIFY PACKAGES --
	---------------------
	-- VERIFY ORIGINAL PACKAGE EXISTS --
	IF NOT EXISTS (SELECT TOP 1 1 FROM vPCBidPackage WITH (NOLOCK)
								 WHERE JCCo = @JCCo 
								   AND PotentialProject = @SourcePotentialProject 
								   AND BidPackage = @BidPackage)
		BEGIN
			SET @rcode = 1
			SET @msg = 'Potential Project: ' + @SourcePotentialProject + ' BidPackage: ' + @BidPackage + ' does not exist!'
			GOTO vspExit
		END

	-- VERIFY NEW PACKAGE DOES NOT EXIST --
	IF EXISTS (SELECT TOP 1 1 FROM vPCBidPackage WITH (NOLOCK)
							 WHERE JCCo = @JCCo 
							   AND PotentialProject = @DestinationPotentialProject 
							   AND BidPackage = @DestinationBidPackage)
		BEGIN
			SET @rcode = 1
			SET @msg = 'Potential Project: ' + @DestinationPotentialProject + ' BidPackage: ' + @DestinationBidPackage + ' already exists!'
			GOTO vspExit
		END


	----------------------------
	-- START THE COPY PROCESS --
	----------------------------
	BEGIN TRANSACTION
		
		-- COPY Info TAB INFORMATION --
		IF UPPER(@CopyInfo) = 'Y'
			BEGIN
				INSERT INTO vPCBidPackage
						(JCCo, PotentialProject, BidPackage, Description, PackageDetails,
							SealedBid, PrimaryContact, PrimaryContactPhone, PrimaryContactEmail,
							SecondaryContact, SecondaryContactPhone, SecondaryContactEmail, Notes)
					SELECT
						a.JCCo, @DestinationPotentialProject, @DestinationBidPackage, a.Description, a.PackageDetails,
							a.SealedBid, a.PrimaryContact, a.PrimaryContactPhone, a.PrimaryContactEmail,
							a.SecondaryContact, a.SecondaryContactPhone, a.SecondaryContactEmail, a.Notes
					  FROM vPCBidPackage a WITH (NOLOCK)
					 WHERE a.JCCo = @JCCo 
					   AND a.PotentialProject = @SourcePotentialProject 
					   AND a.BidPackage = @BidPackage

				-- ERROR CHECK --
				SET @TransError = @@ERROR
				IF @TransError <> 0
					BEGIN
						SET @msg = 'Info Section'
						GOTO vspTransactionError
					END
			END	--IF UPPER
			
			
		-- COPY Scope/Phase TAB INFORMATION --
		IF UPPER(@CopyScopePhase) = 'Y'
			BEGIN
				INSERT INTO vPCBidPackageScopes
						(JCCo, PotentialProject, BidPackage, Seq, VendorGroup, ScopeCode,
							PhaseGroup, Phase, Notes)
					SELECT
						a.JCCo, @DestinationPotentialProject, @DestinationBidPackage, a.Seq, a.VendorGroup, a.ScopeCode,
							a.PhaseGroup, a.Phase, a.Notes
					  FROM vPCBidPackageScopes a WITH (NOLOCK)
					 WHERE a.JCCo = @JCCo 
					   AND a.PotentialProject = @SourcePotentialProject 
					   AND a.BidPackage = @BidPackage

				-- ERROR CHECK --
				SET @TransError = @@ERROR
				IF @TransError <> 0
					BEGIN
						SET @msg = 'Scope/Phase Section'
						GOTO vspTransactionError
					END
			END	--IF UPPER
	
	
		-- COPY Bid List TAB INFORMATION --
		IF UPPER(@CopyBidList) = 'Y'
			BEGIN
				INSERT INTO vPCBidPackageBidList
						(JCCo, PotentialProject, BidPackage, VendorGroup, Vendor,
							ContactSeq, Notes)
					SELECT
						a.JCCo, @DestinationPotentialProject, @DestinationBidPackage, a.VendorGroup, a.Vendor,
							a.ContactSeq, a.Notes
					  FROM vPCBidPackageBidList a WITH (NOLOCK)
					 WHERE a.JCCo = @JCCo 
					   AND a.PotentialProject = @SourcePotentialProject 
					   AND a.BidPackage = @BidPackage

				-- ERROR CHECK --
				SET @TransError = @@ERROR
				IF @TransError <> 0
					BEGIN
						SET @msg = 'Bid List Section'
						GOTO vspTransactionError
					END
			END	-- IF UPPER
	
	
		-- COPY Inclusions/Exclusions TAB INFORMATION --
		IF UPPER(@CopyInclusionsExclusions) = 'Y'
			BEGIN
				INSERT INTO vPCBidPackageScopeNotes
						(JCCo, PotentialProject, BidPackage, Seq, VendorGroup, ScopeCode,
							PhaseGroup, Phase, [Type], Detail, DateEntered, EnteredBy, Notes)
					SELECT
						a.JCCo, @DestinationPotentialProject, @DestinationBidPackage, a.Seq, a.VendorGroup, a.ScopeCode,
							a.PhaseGroup, a.Phase, a.Type, a.Detail, dbo.vfDateOnly(), SUSER_NAME(), a.Notes
					  FROM vPCBidPackageScopeNotes a WITH (NOLOCK)
					 WHERE a.JCCo = @JCCo 
					   AND a.PotentialProject = @SourcePotentialProject 
					   AND a.BidPackage = @BidPackage

				-- ERROR CHECK --
				SET @TransError = @@ERROR
				IF @TransError <> 0
					BEGIN
						SET @msg = 'Inclusions/Exclusions Section'
						GOTO vspTransactionError
					END
			END	-- IF UPPER


	COMMIT TRANSACTION

			
	--------------------
	-- ERROR HANDLING --
	--------------------
	vspTransactionError:
		IF @TransError <> 0
			BEGIN
				SET @rcode = 1
				SET @msg = 'Copy Aborted - Unexpected error occurred in: ' + @msg 
				ROLLBACK TRANSACTION
			END

	vspExit:
		RETURN @rcode


END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidPackageCopy] TO [public]
GO
