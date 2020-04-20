SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob VH 12/22/08
-- Usage:		Validates ProjectTypeCode using the given vendorGroup and projectTypeCode parameters

-- Input params:
--	@vendorGroup		VendorGroup
--	@projectTypeCode			ProjectTypeCode

-- Output params:
--	@msg		ProjectTypeCode error message

-- Return code:
--0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCProjectTypeValidation]
	(@vendorGroup bGroup = NULL,
	@projectTypeCode VARCHAR(10) = NULL,
	@msg VARCHAR(100) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SET @rcode = 0

	SELECT @msg = Description
	FROM PCProjectTypeCodes
	WHERE VendorGroup = @vendorGroup AND ProjectTypeCode = @projectTypeCode

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
		
		IF @projectTypeCode IS NULL
		BEGIN
			SELECT @msg = 'ProjectTypeCode is a required parameter!', @rcode = 1
			GOTO vspExit
		END
		
		SELECT @msg = @projectTypeCode + ' is an invalid ProjectTypeCode!', @rcode = 1
	END
	
	vspExit:
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCProjectTypeValidation] TO [public]
GO
