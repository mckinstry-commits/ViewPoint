SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob VH 12/22/08
-- Usage:		Validates ScopeCode using the given vendorGroup and scopeCode parameters

-- Input params:
--	@vendorGroup		VendorGroup
--	@scopeCode			ScopeCode

-- Output params:
--	@msg		ScopeCode error message

-- Return code:
--0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCScopeCodeValidation]
	(@vendorGroup bGroup = NULL,
	@scopeCode VARCHAR(10) = NULL,
	@msg VARCHAR(100) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SET @rcode = 0
	
	SELECT @msg = Description
	FROM PCScopeCodes (NOLOCK)
	WHERE VendorGroup = @vendorGroup AND ScopeCode = @scopeCode

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
		
		IF @scopeCode IS NULL
		BEGIN
			SELECT @msg = 'ScopeCode is a required parameter!', @rcode = 1
			GOTO vspExit
		END
		
		SELECT @msg = @scopeCode + ' is an invalid ScopeCode!', @rcode = 1
	END
	
	vspExit:
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCScopeCodeValidation] TO [public]
GO
