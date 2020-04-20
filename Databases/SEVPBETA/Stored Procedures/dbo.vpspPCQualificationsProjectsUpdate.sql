SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsProjectsUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @LargestEverAmount NUMERIC(18,0), @LargestEverYear SMALLINT, @LargestEverProjectName VARCHAR(60), @LargestEverGC VARCHAR(60), @LargestEverInScope VARCHAR(60), @LargestThisYearAmount NUMERIC(18,0), @LargestThisYear SMALLINT, @LargestThisYearProjectName VARCHAR(60), @LargestThisYearGC VARCHAR(60), @LargestThisYearInScope VARCHAR(60), @LargestLastYearAmount NUMERIC(18,0), @LargestLastYear SMALLINT, @LargestLastYearProjectName VARCHAR(60), @LargestLastYearGC VARCHAR(60), @LargestLastYearInScope VARCHAR(60), @PreferMin TINYINT, @Prefer100K TINYINT, @Prefer200K TINYINT, @Prefer500K TINYINT, @Prefer1M TINYINT, @Prefer3M TINYINT, @Prefer6M TINYINT, @Prefer10M TINYINT, @Prefer15M TINYINT, @Prefer25M TINYINT, @Prefer50M TINYINT, @PreferMax TINYINT)
AS
SET NOCOUNT ON;

BEGIN
	-- Validation
	DECLARE @rcode INT
	IF not @LargestEverYear IS NULL
	BEGIN
		EXEC @rcode = vpspPCValidateYearField @LargestEverYear
		
		IF @rcode != 0
		BEGIN
			goto vpspExit
		END
	END
	
	IF not @LargestThisYear IS NULL
	BEGIN
		EXEC @rcode = vpspPCValidateYearField @LargestThisYear
		
		IF @rcode != 0
		BEGIN
			goto vpspExit
		END
	END
	
	IF not @LargestLastYear IS NULL
	BEGIN
		EXEC @rcode = vpspPCValidateYearField @LargestLastYear
		
		IF @rcode != 0
		BEGIN
			goto vpspExit
		END
	END
	
	
	
	-- Validation successful
	UPDATE PCQualifications
	SET
		LargestEverAmount = @LargestEverAmount,
		LargestEverYear = @LargestEverYear,
		LargestEverProjectName = @LargestEverProjectName,
		LargestEverGC = @LargestEverGC,
		LargestEverInScope = @LargestEverInScope,
		LargestThisYearAmount = @LargestThisYearAmount,
		LargestThisYear = @LargestThisYear,
		LargestThisYearProjectName = @LargestThisYearProjectName,
		LargestThisYearGC = @LargestThisYearGC,
		LargestThisYearInScope = @LargestThisYearInScope,
		LargestLastYearAmount = @LargestLastYearAmount,
		LargestLastYear = @LargestLastYear,
		LargestLastYearProjectName = @LargestLastYearProjectName,
		LargestLastYearGC = @LargestLastYearGC,
		LargestLastYearInScope = @LargestLastYearInScope,
		PreferMin = @PreferMin,
		Prefer100K = @Prefer100K,
		Prefer200K = @Prefer200K,
		Prefer500K = @Prefer500K,
		Prefer1M = @Prefer1M,
		Prefer3M = @Prefer3M,
		Prefer6M = @Prefer6M,
		Prefer10M = @Prefer10M,
		Prefer15M = @Prefer15M,
		Prefer25M = @Prefer25M,
		Prefer50M = @Prefer50M,
		PreferMax = @PreferMax
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
	
vpspExit:
	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsProjectsUpdate] TO [VCSPortal]
GO
