SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 2/1/10
-- Description:	<PC Certificates Delete Script>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCCertificatesDelete]
	(@Original_Key_VendorGroup bGroup, @Original_Key_Vendor bVendor, @Original_Key_CertificateType VARCHAR(20))
AS
SET NOCOUNT ON;

BEGIN
	DELETE FROM PCCertificates
	WHERE
		VendorGroup = @Original_Key_VendorGroup
		AND Vendor = @Original_Key_Vendor
		AND CertificateType = @Original_Key_CertificateType
END




GO
GRANT EXECUTE ON  [dbo].[vpspPCCertificatesDelete] TO [VCSPortal]
GO
