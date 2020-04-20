SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCStatesGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
	SELECT 
		pcs.[VendorGroup]
		,pcs.[Vendor]
		,pcs.[Country]
		,pcs.[State]
		,pcs.[License]
		,pcs.[Expiration]
		,pcs.[SalesTaxNo]
		,pcs.[UINo]
		,pcs.[KeyID]
		,hqc.[CountryName]
		,hqs.[Name] as StateName
	FROM PCStates pcs
	LEFT JOIN dbo.HQCountry hqc ON pcs.[Country] = hqc.[Country]
	LEFT JOIN dbo.HQST hqs ON pcs.[State] = hqs.[State] AND pcs.[Country] = hqs.[Country]
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor
END



GO
GRANT EXECUTE ON  [dbo].[vpspPCStatesGet] TO [VCSPortal]
GO
