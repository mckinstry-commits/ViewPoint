SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--Modified:			TRL 11/14/2011 TK-09985 Added VendorGroup to Join State to prevent duplicate rows
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCProjectTypesGet]
	(@VendorGroup bGroup, @Vendor bVendor)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
		pcpt.[VendorGroup]
		,[Vendor]
		,pcpt.[ProjectTypeCode]
		,[WorkPrevious]
		,[WorkNext]
		,[NoPriorWork]
		,dbo.vpfYesNo(NoPriorWork) AS NoPriorWorkDescription
		,pcpt.[KeyID]
		,pcptc.Description
	FROM [dbo].[PCProjectTypes] pcpt LEFT JOIN dbo.PCProjectTypeCodes pcptc ON  pcpt.VendorGroup = pcptc.VendorGroup and pcpt.ProjectTypeCode = pcptc.ProjectTypeCode
	WHERE pcpt.[VendorGroup] = @VendorGroup AND [Vendor] = @Vendor
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCProjectTypesGet] TO [VCSPortal]
GO
