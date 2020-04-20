SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob VH 12/22/08
-- Usage:		Validates ContactTypeCode using the given vendorGroup and contactTypeCode parameters

-- Input params:
--	@vendorGroup		VendorGroup
--	@contactTypeCode	ContactTypeCode

-- Output params:
--	@msg		ContactTypeCode error message

-- Return code:
--0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCContactTypeValidation]
	(@vendorGroup bGroup = NULL,
	@contactTypeCode VARCHAR(10) = NULL,
	@msg VARCHAR(100) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SET @rcode = 0

	SELECT @msg = Description
	FROM PCContactTypeCodes (NOLOCK)
	WHERE VendorGroup = @vendorGroup AND ContactTypeCode = @contactTypeCode

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
		
		IF @contactTypeCode IS NULL
		BEGIN
			SELECT @msg = 'ContactTypeCode is a required parameter!', @rcode = 1
			GOTO vspExit
		END
		
		SELECT @msg = @contactTypeCode + ' is an invalid ContactTypeCode!', @rcode = 1
	END
	
	vspExit:
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCContactTypeValidation] TO [public]
GO
