SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCQualificationsUpdate]
	(@Original_VendorGroup bGroup, @Original_Vendor bVendor, @Name VARCHAR(60), @SortName bSortName, @Phone bPhone, @AddnlInfo VARCHAR(60), @Address VARCHAR(60), @City VARCHAR(30), @State VARCHAR(4), @Zip bZip, @Country CHAR(2), @Address2 VARCHAR(60), @POAddress VARCHAR(60), @POCity VARCHAR(30), @POState VARCHAR(4), @POZip bZip, @POCountry CHAR(2), @POAddress2 VARCHAR(60), @Type CHAR(1), @EMail VARCHAR(60), @URL VARCHAR(60), @OrganizationType VARCHAR(20), @OrganizationCountry VARCHAR(2), @OrganizationState VARCHAR(4), @OrganizationDate bDate, @TIN VARCHAR(20), @OfficeType CHAR(1), @Qualified bYN, @ParentName VARCHAR(60), @ParentAddress1 VARCHAR(60), @ParentCity VARCHAR(30), @ParentState VARCHAR(4), @ParentZip bZip, @ParentCountry CHAR(2), @ParentAddress2 VARCHAR(60), @OtherNames VARCHAR(200), @TradeAssociations VARCHAR(60), @DoNotUse bYN, @DoNotUseReason VARCHAR(MAX))
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCQualifications
	SET
		Name = @Name,
		SortName = @SortName,
		Phone = @Phone,
		AddnlInfo = @AddnlInfo,
		Address = @Address,
		City = @City,
		State = @State,
		Zip = @Zip,
		Country = @Country,
		Address2 = @Address2,
		POAddress = @POAddress,
		POCity = @POCity,
		POState = @POState,
		POZip = @POZip,
		POCountry = @POCountry,
		POAddress2 = @POAddress2,
		Type = @Type,
		EMail = @EMail,
		URL = @URL,
		OrganizationType = @OrganizationType,
		OrganizationCountry = @OrganizationCountry,
		OrganizationState = @OrganizationState,
		OrganizationDate = @OrganizationDate,
		TIN = @TIN,
		OfficeType = @OfficeType,
		Qualified = @Qualified,
		ParentName = @ParentName,
		ParentAddress1 = @ParentAddress1,
		ParentCity = @ParentCity,
		ParentState = @ParentState,
		ParentZip = @ParentZip,
		ParentCountry = @ParentCountry,
		ParentAddress2 = @ParentAddress2,
		OtherNames = @OtherNames,
		TradeAssociations = @TradeAssociations,
		DoNotUse = @DoNotUse,
		DoNotUseReason = @DoNotUseReason
	WHERE VendorGroup = @Original_VendorGroup AND Vendor = @Original_Vendor
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsUpdate] TO [VCSPortal]
GO
