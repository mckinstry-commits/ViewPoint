SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCOwnersGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
	SELECT [VendorGroup]
		,[Vendor]
		,[Seq] + 0 AS Seq
		,[Name]
		,[Role]
		,[BirthYear]
		,[Ownership]
		,[KeyID]
	FROM [dbo].[PCOwners]
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCOwnersGet] TO [VCSPortal]
GO
