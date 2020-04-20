SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMTestLogDistributionGet]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/7/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--				GF 11/09/2011 TK-09904 SentToFirm change to SentToFirmName
--
-- Description:	Gets the test log distribution list
-- =============================================
(@TestLogID BIGINT, @KeyID BIGINT = NULL)
AS
SET NOCOUNT ON;

	SELECT
		CAST(t.[KeyID] as BIGINT) as KeyID
		,t.[Seq]
		,t.[VendorGroup]
		,t.[SentToFirm]
		----TK-09904
		,f.[FirmName] as SentToFirmName
		,t.[SentToContact]
		,m.[FirstName] + ' ' + m.[LastName] AS 'FirstLastName'
		,t.[Send]
		,dbo.vpfYesNo(t.[Send]) AS 'SendDescription'
		,t.[PrefMethod]
		,cp.[DisplayValue] as 'PrefMethodDescription'
		,t.[CC]
		,cc.[DisplayValue] as 'CCDescription'
		,t.[DateSent]
		,t.[DateSigned]
		,t.[TestLogID]
		,t.[PMCo]
		,t.[Project]
		,t.[TestType]
		,t.[TestCode]
		,t.[Notes]
		,t.[UniqueAttchID]
		
	FROM PMDistribution t WITH (NOLOCK)
		LEFT JOIN PMFM f WITH (NOLOCK) ON t.VendorGroup = f.VendorGroup AND t.SentToFirm = f.FirmNumber
		LEFT JOIN PMPM m WITH (NOLOCK) ON t.VendorGroup = m.VendorGroup AND t.SentToFirm = m.FirmNumber AND t.SentToContact = m.ContactCode
		LEFT JOIN DDCI cp WITH (NOLOCK) ON cp.ComboType = 'PMPrefMethod' AND t.PrefMethod = cp.DatabaseValue
		LEFT JOIN DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMCC' AND t.CC = cc.DatabaseValue
	
	WHERE t.[TestLogID] = @TestLogID
	AND t.[KeyID] = ISNULL(@KeyID, t.[KeyID])


GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogDistributionGet] TO [VCSPortal]
GO
