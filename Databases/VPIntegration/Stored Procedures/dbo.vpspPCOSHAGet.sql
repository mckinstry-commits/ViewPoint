SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCOSHAGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
	SELECT *
	FROM PCOSHA
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCOSHAGet] TO [VCSPortal]
GO
