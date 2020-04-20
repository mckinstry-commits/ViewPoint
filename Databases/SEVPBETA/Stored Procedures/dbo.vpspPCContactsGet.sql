SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--Modified:    TRL 11/14/2011 TK-09993 and Vendor Group to join statement to prevent duplicate records in grid
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCContactsGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
	SELECT
		pcc.[VendorGroup]
		,pcc.[Vendor]
		,pcc.[Seq] + 0 AS Seq -- When saving, the seq is marked as AllowNull = false. By adding 0 it is then marked as AllowNull = true.
		,pcc.[Name]
		,pcc.[Title]
		,pcc.[CompanyYears]
		,pcc.[RoleYears]
		,pcc.[Phone]
		,pcc.[Cell]
		,pcc.[Email]
		,pcc.[Fax]
		,pcc.[PrefMethod]
		,pcc.[IsBidContact]
		,dbo.vpfYesNo(IsBidContact) AS IsBidContactDescription
		,pcc.[ContactTypeCode]
		,pcc.[KeyID]
		,pcctc.[Description] AS ContactTypeCodeDescription
		,c1.[DisplayValue] AS PrefMethodDescription
	FROM dbo.PCContacts pcc LEFT JOIN dbo.PCContactTypeCodes pcctc ON  pcc.VendorGroup = pcctc.VendorGroup and  pcc.ContactTypeCode = pcctc.ContactTypeCode
		LEFT JOIN DDCI c1 ON c1.ComboType = 'PMPrefMethod' AND pcc.PrefMethod = c1.DatabaseValue
	WHERE pcc.VendorGroup = @VendorGroup AND pcc.Vendor = @Vendor
END


GO
GRANT EXECUTE ON  [dbo].[vpspPCContactsGet] TO [VCSPortal]
GO
