SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/5/10
-- Description:	Return the contact name. Also allows for automatically adding
--	a contact to the projects bidder list if not a part of it.
-- =============================================
CREATE PROCEDURE [dbo].[vspPCBidListContactValidation]
	(@JCCo bCompany, @PotentialProject VARCHAR(20), @VendorGroup bGroup, @Vendor bVendor, @ContactSeq TINYINT, @Phone bPhone OUTPUT, @Email VARCHAR(60) OUTPUT, @msg VARCHAR(255) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @msg = Name, @Phone = Phone, @Email = Email
	FROM PCContacts
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @ContactSeq

	-- Check for existance
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Contact doesn''t exist for the supplied vendor!'
		RETURN 1
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidListContactValidation] TO [public]
GO
