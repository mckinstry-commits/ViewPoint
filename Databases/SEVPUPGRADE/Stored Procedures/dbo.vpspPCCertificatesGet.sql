SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 2/1/10
-- Description:	<PC Certificates Get Script>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCCertificatesGet]
	(@Key_VendorGroup bGroup, @Key_Vendor bVendor, @Key_CertificateType VARCHAR(20) = NULL)
AS
SET NOCOUNT ON;

BEGIN
	SELECT 
		c.[VendorGroup] as Key_VendorGroup,
		c.[Vendor] as Key_Vendor,
		c.[CertificateType] as Key_CertificateType,
		t.[Description] as CertificateTypeDescription,
		c.[Certificate] as Certificate,
		c.[Agency] as Agency,
		c.[KeyID],
		c.[Notes],
		c.[UniqueAttchID]
	FROM PCCertificates c
	INNER JOIN PCCertificateTypes t ON c.VendorGroup = t.VendorGroup AND c.CertificateType = t.CertificateType
	WHERE 
		c.VendorGroup = @Key_VendorGroup 
		AND c.Vendor = @Key_Vendor 
		AND c.CertificateType = ISNULL(@Key_CertificateType, c.CertificateType)
		
END




GO
GRANT EXECUTE ON  [dbo].[vpspPCCertificatesGet] TO [VCSPortal]
GO
