SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspInsertvDocParticipantAP]
@co bCompany, 
@UserName bVPUserName,
@VendorId bVendor,
@VendorGroup bGroup

AS
BEGIN
	SET NOCOUNT ON;

	SELECT	NEWID() as ParticipantId,
				RTRIM(LEFT(Contact, CHARINDEX(' ',Contact))) AS FirstName,
				RIGHT(Contact , LEN(Contact) - CHARINDEX(' ',Contact) ) AS LastName,
				EMail as Email,
				Contact as DisplayName,
				'' as Title,
				'' as CompanyName,
				@co as CompanyNumber,		
				'Associated' as [Status],				
				'A0172E82-854D-6C2B-417A-8081D063A835' as DocumentRoleTypeId,
				@UserName as CreatedByUser,
				GETUTCDATE() as DBCreatedDate,
				1 as [Version]
	FROM APVM
	WHERE 
			Vendor = @VendorId AND 
			VendorGroup = @VendorGroup;			
END
GO
GRANT EXECUTE ON  [dbo].[vspInsertvDocParticipantAP] TO [public]
GO
