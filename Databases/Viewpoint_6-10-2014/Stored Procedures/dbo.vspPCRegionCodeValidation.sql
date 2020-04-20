SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob VH 12/22/08
-- Usage:		Validates RegionCode using the given vendorGroup and regionCode parameters

-- Input params:
--	@vendorGroup		VendorGroup
--	@regionCode			RegionCode

-- Output params:
--	@msg		RegionCode error message

-- Return code:
--0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCRegionCodeValidation]
	(@vendorGroup bGroup = NULL,
	@regionCode VARCHAR(10) = NULL,
	@msg VARCHAR(100) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SET @rcode = 0
	
	SELECT @msg = Description
	FROM PCRegionCodes (NOLOCK)
	WHERE VendorGroup = @vendorGroup AND RegionCode = @regionCode

	-- Check for existance
	IF @@rowcount = 0
	BEGIN
		-- No record matches. Do input checks and output error message
		SET @rcode = 1
	
		IF @vendorGroup IS NULL
		BEGIN
			SELECT @msg = 'VendorGroup is a required parameter!', @rcode = 1
			GOTO vspExit
		END
		
		IF @regionCode IS NULL
		BEGIN
			SELECT @msg = 'RegionCode is a required parameter!', @rcode = 1
			GOTO vspExit
		END
		
		SELECT @msg = @regionCode + ' is an invalid RegionCode!', @rcode = 1
	END
	
	vspExit:
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCRegionCodeValidation] TO [public]
GO
