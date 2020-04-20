SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMInspectionLogDistributionGet]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/14/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--
--
-- Description:	Gets the inspection log distribution list
-- =============================================
(@InspectionLogID BIGINT, @KeyID BIGINT = NULL)
AS
SET NOCOUNT ON;

	SELECT
		CAST(i.[KeyID] as BIGINT) as KeyID
		,i.[Seq]
		,i.[VendorGroup]
		,i.[SentToFirm]
		,f.[FirmName] as SentToFirmName
		,i.[SentToContact]
		,m.[FirstName] + ' ' + m.[LastName] AS 'FirstLastName'
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
		
	FROM PMDistribution i WITH (NOLOCK)
		LEFT JOIN PMFM f WITH (NOLOCK) ON i.VendorGroup = f.VendorGroup AND i.SentToFirm = f.FirmNumber
		LEFT JOIN PMPM m WITH (NOLOCK) ON i.VendorGroup = m.VendorGroup AND i.SentToFirm = m.FirmNumber AND i.SentToContact = m.ContactCode
		LEFT JOIN DDCI cp WITH (NOLOCK) ON cp.ComboType = 'PMPrefMethod' AND i.PrefMethod = cp.DatabaseValue
		LEFT JOIN DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMCC' AND i.CC = cc.DatabaseValue
	
	WHERE i.[InspectionLogID] = @InspectionLogID
	AND i.[KeyID] = ISNULL(@KeyID, i.[KeyID])


GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogDistributionGet] TO [VCSPortal]
GO
