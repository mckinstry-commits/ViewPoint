SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/5/10
-- Description:	Return the vendor name. Also returns information about whether the vendor is a do not use vendor or not.
-- =============================================
CREATE PROCEDURE [dbo].[vspPCBidListVendorValidation]
	(@VendorGroup bGroup, @Vendor bVendor, @IsADoNotUseVendor bYN OUTPUT, @DoNotUseVendorReason VARCHAR(MAX) OUTPUT, @msg VARCHAR(255) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @IsADoNotUseVendor = DoNotUse, @DoNotUseVendorReason = DoNotUseReason, @msg = Name
	FROM PCQualifications
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

	-- Check for existance
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Vendor doesn''t exist!'
		RETURN 1
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidListVendorValidation] TO [public]
GO
