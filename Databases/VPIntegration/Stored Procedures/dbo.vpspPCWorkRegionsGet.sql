SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--Modified:			 TRL 11/14/2011  TK-09990 added VendorGroup to Join statement to fix duplicate records
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCWorkRegionsGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
	SELECT 
		pcwr.[VendorGroup]
		,[Vendor]
		,pcwr.[RegionCode]
		,pcrc.Description AS RegionCodeDescription
		,[WorkPrevious]
		,[WorkNext]
		,[NoPriorWork]
		,dbo.vpfYesNo(NoPriorWork) AS NoPriorWorkDescription
		,pcwr.[KeyID]
	FROM [dbo].[PCWorkRegions] pcwr LEFT JOIN dbo.PCRegionCodes pcrc ON pcwr.VendorGroup = pcrc.VendorGroup and pcwr.RegionCode = pcrc.RegionCode
	WHERE pcwr.VendorGroup = @VendorGroup AND pcwr.Vendor = @Vendor
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCWorkRegionsGet] TO [VCSPortal]
GO
