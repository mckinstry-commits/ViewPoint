SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley 5/3/10
-- Usage:		Validates that a contact type code can be deleted.

-- Input params:
--	@VendorGroup		VendorGroup
--	@ContactTypeCode	ContactTypeCode

-- Output params:
--	@msg				Error message

-- Return code:
--	0 = success, 1 = failure

--=============================================
CREATE PROCEDURE [dbo].[vspPCContactTypeDeleteValidation]
(
	@VendorGroup bGroup = NULL, 
	@ContactTypeCode varchar(10) = NULL, 
	@msg varchar(255) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	SET @rcode = 0
	
	IF EXISTS(SELECT Top 1 1 FROM dbo.PCContacts WHERE VendorGroup = @VendorGroup AND ContactTypeCode = @ContactTypeCode)
	BEGIN
		SELECT @msg = 'Contact Type Code ''' + @ContactTypeCode + ''' cannot be deleted because it is in use in one or more records in PC Pre-Qualification Info Contacts.', @rcode = 1
	END

	RETURN @rcode
END



GO
GRANT EXECUTE ON  [dbo].[vspPCContactTypeDeleteValidation] TO [public]
GO
