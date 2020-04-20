SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCQualificationsInfoUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @Name VARCHAR(60), @SortName bSortName, @Phone bPhone, @AddnlInfo VARCHAR(60), @Address VARCHAR(60), @City VARCHAR(30), @CompanyState VARCHAR(4), @Zip bZip, @CompanyCountry CHAR(2), @Address2 VARCHAR(60), @POAddress VARCHAR(60), @POCity VARCHAR(30), @POState VARCHAR(4), @POZip bZip, @POCountry CHAR(2), @POAddress2 VARCHAR(60), @Type CHAR(1), @EMail VARCHAR(60), @URL VARCHAR(60))
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
		State = @CompanyState,
		Zip = @Zip,
		Country = @CompanyCountry,
		Address2 = @Address2,
		POAddress = @POAddress,
		POCity = @POCity,
		POState = @POState,
		POZip = @POZip,
		POCountry = @POCountry,
		POAddress2 = @POAddress2,
		Type = @Type,
		EMail = @EMail,
		URL = @URL
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsInfoUpdate] TO [VCSPortal]
GO
