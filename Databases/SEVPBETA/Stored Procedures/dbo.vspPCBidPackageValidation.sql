SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPCBidPackageValidation]
  /***********************************************************
   * CREATED BY:	JVH	2/3/2010
   * MODIFIED BY:
   *				
   * USAGE:
   * Used in PC Bid Package to return the description for a bid package
   *
   * INPUT PARAMETERS
   *   JCCo   
   *   PotentialProject
   *   BidPackage
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Bid Package if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
	
	(@JCCo bCompany, @PotentialProject VARCHAR(20), @BidPackage VARCHAR(20), @UniqueAttchID uniqueidentifier output, @ReplyToEmail VARCHAR(60) OUTPUT,
	@msg VARCHAR(255) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Get Description
	SELECT @msg = [Description], @UniqueAttchID = lower(UniqueAttchID), @ReplyToEmail = PrimaryContactEmail
	FROM dbo.PCBidPackage WITH (NOLOCK)
	WHERE JCCo = @JCCo AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage
		
	-- Check for existance
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Bid package not on file!'
		RETURN 1
	END
		
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidPackageValidation] TO [public]
GO
