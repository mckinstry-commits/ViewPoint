SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCUnionContractsGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
SELECT [VendorGroup]
      ,[Vendor]
      ,[Seq] + 0 AS Seq
      ,[LocalNumber]
      ,[Name]
      ,[Expiration]
      ,[KeyID]
	FROM PCUnionContracts
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCUnionContractsGet] TO [VCSPortal]
GO
