SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMDrawingLogDistributionGet]
-- =============================================
-- Created By:	GF 11/10/2011 TK-00000
-- Modified By:
--
--
-- Description:	Gets the drawing log distribution list
-- =============================================
(@DrawingLogID BIGINT, @KeyID BIGINT = NULL)
AS
SET NOCOUNT ON;

SELECT
	CAST(i.[KeyID] as BIGINT) as KeyID
	,i.[Seq]
	,i.[VendorGroup]
	,i.[SentToFirm]
	,f.[FirmName] as SentToFirmName
	,i.[SentToContact]
	,m.[FirstName] + ' ' + m.[LastName] AS 'ContactName'
	,i.[Send]
	,dbo.vpfYesNo(i.[Send]) AS SendDescription
	,i.[PrefMethod]
	,cp.[DisplayValue] as 'PrefMethodDescription'
	,i.[CC]
	,cc.[DisplayValue] as 'CCDescription'
	,i.[DateSent]
	,i.[DateSigned]
	,i.[InspectionLogID]
	,i.[PMCo]
	,i.[Project]
	,i.[InspectionType]
	,i.[InspectionCode]
	,i.[Notes]
	,i.[UniqueAttchID]
	
FROM dbo.PMDistribution i WITH (NOLOCK)
	LEFT JOIN dbo.PMFM f WITH (NOLOCK) ON i.VendorGroup = f.VendorGroup AND i.SentToFirm = f.FirmNumber
	LEFT JOIN dbo.PMPM m WITH (NOLOCK) ON i.VendorGroup = m.VendorGroup AND i.SentToFirm = m.FirmNumber AND i.SentToContact = m.ContactCode
	LEFT JOIN dbo.DDCI cp WITH (NOLOCK) ON cp.ComboType = 'PMPrefMethod' AND i.PrefMethod = cp.DatabaseValue
	LEFT JOIN dbo.DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMCC' AND i.CC = cc.DatabaseValue

WHERE i.[DrawingLogID] = @DrawingLogID
AND i.[KeyID] = ISNULL(@KeyID, i.[KeyID])


GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogDistributionGet] TO [VCSPortal]
GO
