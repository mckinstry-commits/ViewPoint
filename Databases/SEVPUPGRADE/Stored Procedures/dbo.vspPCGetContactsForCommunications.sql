SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/19/10
-- Description:	Returns the list of contacts for a specific project and if specified a bid package
--
-- Modified By:	GP 3/12/2010 - Issue 129020 added case for MessageStatus and ContactStatus
--				GF 06/25/2012 TK-15757 added formatted fax to select from PC Contacts
--
-- =============================================
CREATE PROCEDURE [dbo].[vspPCGetContactsForCommunications]
	@JCCo bCompany, @PotentialProject VARCHAR(20), @BidPackage VARCHAR(20),
	@Vendor bVendor, @ContactSeq TINYINT, @Scope VARCHAR(10), @Phase bPhase, @MessageStatus CHAR(1), @BidResponse CHAR(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT DISTINCT ContactRollup.Vendor
			,PCQualifications.Name AS VendorName
			,ContactRollup.ContactSeq AS Seq
			,PCContacts.Name AS ContactName
			,PCContacts.Phone
			,PCContacts.Email
			,PCContacts.Fax
			----TK-00000
			,PCContacts.FormattedFax
			,ciPrefMethod.DisplayValue AS PrefMethod
			,ciMessageStatus.DisplayValue AS MessageStatus
			,ciResponse.DisplayValue AS ContactStatus
			,ContactRollup.LastSent
			,ContactRollup.VendorGroup
			,PCContacts.KeyID AS ContactKeyID
	FROM
		(SELECT PCBidPackageBidList.JCCo, PCBidPackageBidList.PotentialProject, PCBidPackageBidList.VendorGroup, PCBidPackageBidList.Vendor, PCBidPackageBidList.ContactSeq,
				CASE WHEN COUNT(CASE WHEN BidResponse = 'W' THEN 1 ELSE NULL END) > 0 THEN 'W' WHEN COUNT(CASE WHEN BidResponse = 'U' THEN 1 ELSE NULL END) > 0 THEN 'U' WHEN COUNT(CASE WHEN BidResponse = 'D' THEN 1 ELSE NULL END) > 0 THEN 'D' ELSE 'N' END AS BidResponse,
				CASE WHEN COUNT(CASE WHEN MessageStatus = 'S' THEN 1 ELSE NULL END) > 0 THEN 'S' WHEN COUNT(CASE WHEN MessageStatus = 'F' THEN 1 ELSE NULL END) > 0 THEN 'F' ELSE 'N' END AS MessageStatus,
				MAX(LastSent) AS LastSent
			FROM PCBidPackageBidList
				LEFT JOIN vPCBidCoverage ON PCBidPackageBidList.JCCo = vPCBidCoverage.JCCo 
					AND PCBidPackageBidList.PotentialProject = vPCBidCoverage.PotentialProject AND PCBidPackageBidList.BidPackage = vPCBidCoverage.BidPackage AND PCBidPackageBidList.VendorGroup = vPCBidCoverage.VendorGroup AND PCBidPackageBidList.Vendor = vPCBidCoverage.Vendor AND PCBidPackageBidList.ContactSeq = vPCBidCoverage.ContactSeq
			WHERE PCBidPackageBidList.JCCo = @JCCo AND PCBidPackageBidList.PotentialProject = @PotentialProject AND (@BidPackage IS NULL OR PCBidPackageBidList.BidPackage = @BidPackage)
			GROUP BY PCBidPackageBidList.JCCo, PCBidPackageBidList.PotentialProject, PCBidPackageBidList.VendorGroup, PCBidPackageBidList.Vendor, PCBidPackageBidList.ContactSeq) ContactRollup
		INNER JOIN PCQualifications	ON ContactRollup.VendorGroup = PCQualifications.VendorGroup AND ContactRollup.Vendor = PCQualifications.Vendor
		INNER JOIN PCContacts WITH (NOLOCK) ON ContactRollup.VendorGroup = PCContacts.VendorGroup AND ContactRollup.Vendor = PCContacts.Vendor AND ContactRollup.ContactSeq = PCContacts.Seq
		LEFT JOIN PCScopes WITH (NOLOCK) ON ContactRollup.VendorGroup = PCScopes.VendorGroup AND ContactRollup.Vendor = PCScopes.Vendor
		LEFT JOIN DDCI ciResponse WITH (NOLOCK) ON ciResponse.ComboType = 'PCBidResponse' AND ciResponse.DatabaseValue = ContactRollup.BidResponse
		LEFT JOIN DDCI ciMessageStatus WITH (NOLOCK) ON ciMessageStatus.ComboType = 'PCMessageStatus' AND ciMessageStatus.DatabaseValue = ContactRollup.MessageStatus
		LEFT JOIN DDCI ciPrefMethod WITH (NOLOCK) ON ciPrefMethod.ComboType = 'PMPrefMethod' AND ciPrefMethod.DatabaseValue = PCContacts.PrefMethod
		WHERE (@Vendor IS NULL OR ContactRollup.Vendor = @Vendor)
			AND (@ContactSeq IS NULL OR ContactRollup.ContactSeq = @ContactSeq)
			AND (@Scope IS NULL OR PCScopes.ScopeCode = @Scope)
			AND (@Phase IS NULL OR PCScopes.PhaseCode = @Phase)
			AND (@MessageStatus IS NULL OR ContactRollup.MessageStatus = @MessageStatus)
			AND (@BidResponse IS NULL OR ContactRollup.BidResponse = @BidResponse)
END
GO
GRANT EXECUTE ON  [dbo].[vspPCGetContactsForCommunications] TO [public]
GO
