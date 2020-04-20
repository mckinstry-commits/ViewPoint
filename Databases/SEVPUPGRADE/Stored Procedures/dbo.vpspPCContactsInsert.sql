SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Jeremiah Barkley>
-- Create date: <1/21/09>
-- Description:	<PCContactsInsert Script>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCContactsInsert]
	-- Add the parameters for the stored procedure here
	(@Vendor bVendor, @VendorGroup bGroup, @Name VARCHAR(30), @Title VARCHAR(30), @CompanyYears TINYINT, @RoleYears TINYINT, @Phone bPhone, @Cell bPhone, @Email VARCHAR(60), @ContactTypeCode VARCHAR(10), @Fax bPhone, @PrefMethod CHAR(1), @IsBidContact bYN)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @NextSeq TINYINT
	SELECT @NextSeq = ISNULL(MAX(Seq) + 1, 1) FROM PCContacts WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor
	
	INSERT INTO PCContacts
	( 
		Vendor, 
		VendorGroup, 
		Seq, 
		Name, 
		Title, 
		CompanyYears, 
		RoleYears, 
		Phone, 
		Cell, 
		Email, 
		ContactTypeCode,
		Fax,
		PrefMethod,
		IsBidContact
	)
	VALUES
	(
		@Vendor, 
		@VendorGroup, 
		@NextSeq, 
		@Name, 
		@Title, 
		@CompanyYears, 
		@RoleYears, 
		@Phone, 
		@Cell, 
		@Email, 
		@ContactTypeCode,
		@Fax,
		@PrefMethod,
		@IsBidContact
	)
END





GO
GRANT EXECUTE ON  [dbo].[vpspPCContactsInsert] TO [VCSPortal]
GO
