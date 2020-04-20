SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMRFIResponseGet]
-- =============================================
-- Author:		Jeremiah Barkley
-- Modified by:	GP	4/7/2011	Added Type and DateReceived
-- Create date: 8/19/09
-- Description:	Gets an RFI response or response list
-- =============================================
(@RFIID BIGINT, @KeyID BIGINT = NULL, @VPUserName bVPUserName)
AS
SET NOCOUNT ON;

	SELECT 
		CAST(r.[KeyID] as BIGINT) as KeyID
		,r.[Seq]
		,r.[DisplayOrder]
		,r.[Send]
		,dbo.vpfYesNo(r.[Send]) AS SendDescription
		,r.[DateRequired]
		,r.[VendorGroup]
		,r.[RespondFirm]
		,f.[FirmName] as FirmName
		,r.[RespondContact]
		,m.[FirstName] + ' ' + m.[LastName] AS 'ContactName'
		,r.[Notes]
		,r.[LastDate]
		,r.[LastBy]
		,r.[RFIID]
		,r.[PMCo]
		,r.[Project]
		,r.[RFIType]
		,r.[RFI]
		,r.[UniqueAttchID]
		,@VPUserName AS 'VPUserName'
		,r.[Type]
		,r.DateReceived
		,t.TypeDescription
		
	FROM [PMRFIResponse] r WITH (NOLOCK)
		LEFT JOIN PMFM f WITH (NOLOCK) ON r.[VendorGroup] = f.[VendorGroup] AND r.[RespondFirm] = f.[FirmNumber]
		LEFT JOIN PMPM m WITH (NOLOCK) ON r.[VendorGroup] = m.[VendorGroup] AND r.[RespondFirm] = m.[FirmNumber] AND r.[RespondContact] = m.[ContactCode]
		LEFT JOIN pvPMLookupRFIResponseType t ON t.[KeyField]=r.[Type]
		
	WHERE r.[RFIID] = @RFIID
	AND r.[KeyID] = ISNULL(@KeyID, r.[KeyID])

GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIResponseGet] TO [VCSPortal]
GO
