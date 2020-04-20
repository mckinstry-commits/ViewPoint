SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob VH 12/22/08
-- Usage:		Validates ReferenceTypeCode using the given vendorGroup and referenceTypeCode parameters

-- Input params:
--	@vendorGroup		VendorGroup
--	@referenceTypeCode			ReferenceTypeCode

-- Output params:
--	@msg		ReferenceTypeCode error message

-- Return code:
--0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCReferenceTypeValidation]
	(@vendorGroup bGroup = NULL,
	@referenceTypeCode VARCHAR(10) = NULL,
	@msg VARCHAR(100) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SET @rcode = 0
	
	SELECT @msg = Description
	FROM PCReferenceTypeCodes (NOLOCK)
	WHERE VendorGroup = @vendorGroup AND ReferenceTypeCode = @referenceTypeCode

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
		
		IF @referenceTypeCode IS NULL
		BEGIN
			SELECT @msg = 'ReferenceTypeCode is a required parameter!', @rcode = 1
			GOTO vspExit
		END
		
		SELECT @msg = @referenceTypeCode + ' is an invalid ReferenceTypeCode!', @rcode = 1
	END
	
	vspExit:
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCReferenceTypeValidation] TO [public]
GO
