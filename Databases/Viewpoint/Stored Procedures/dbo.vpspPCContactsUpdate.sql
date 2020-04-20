SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCContactsUpdate]
	-- Add the parameters for the stored procedure here
	(@Original_KeyID INT, @Name VARCHAR(30), @Title VARCHAR(30), @CompanyYears TINYINT, @RoleYears TINYINT, @Phone bPhone, @Cell bPhone, @Email VARCHAR(60), @ContactTypeCode VARCHAR(10), @Fax bPhone, @PrefMethod CHAR(1), @IsBidContact bYN)
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCContacts
	SET
		Name = @Name,
		Title = @Title,
		CompanyYears = @CompanyYears,
		RoleYears = @RoleYears,
		Phone = @Phone,
		Cell = @Cell,
		Email = @Email,
		ContactTypeCode = @ContactTypeCode,
		Fax = @Fax,
		PrefMethod = @PrefMethod,
		IsBidContact = @IsBidContact
	WHERE KeyID = @Original_KeyID
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCContactsUpdate] TO [VCSPortal]
GO
