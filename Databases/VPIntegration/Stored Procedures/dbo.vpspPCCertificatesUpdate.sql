SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
* Author:		Jeremiah Barkley
* Create date: 2/1/10
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* Description:	<PC Certificates Update Script>
				
-- =============================================
*/
CREATE PROCEDURE [dbo].[vpspPCCertificatesUpdate]
    (
      @Key_VendorGroup bGroup,
      @Key_Vendor bVendor,
      @Key_CertificateType VARCHAR(20),
      @Certificate VARCHAR(30),
      @Agency VARCHAR(60),
      @KeyID BIGINT,
      @Notes VARCHAR(MAX)
    )
AS 
    SET NOCOUNT ON ;

    BEGIN
	-- Validation
	
	
	-- Update 
        UPDATE  PCCertificates
        SET     Certificate = @Certificate,
                Agency = @Agency,
                Notes = @Notes
        WHERE   VendorGroup = @Key_VendorGroup
                AND Vendor = @Key_Vendor
                AND CertificateType = @Key_CertificateType

        vpspExit:

    END




GO
GRANT EXECUTE ON  [dbo].[vpspPCCertificatesUpdate] TO [VCSPortal]
GO
