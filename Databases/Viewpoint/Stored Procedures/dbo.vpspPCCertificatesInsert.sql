SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
* Author:		Jeremiah Barkley
* Create date: 2/1/10
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* Description:	<PC Certificates Insert Script>
				
-- =============================================
*/
CREATE PROCEDURE [dbo].[vpspPCCertificatesInsert]
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
        DECLARE @msg VARCHAR(255)
	-- Validation
        IF EXISTS ( SELECT  1
                    FROM    PCCertificates
                    WHERE   VendorGroup = @Key_VendorGroup
                            AND Vendor = @Key_Vendor
                            AND CertificateType = @Key_CertificateType ) 
            BEGIN
                SET @msg = 'A record of type ' + @Key_CertificateType
                    + ' already exists.  Please select an unused type.'
                RAISERROR(@msg, 11, -1);
            END
        ELSE 
            BEGIN
		-- Insert new certificate type
                INSERT  INTO PCCertificates
                        ( VendorGroup,
                          Vendor,
                          CertificateType,
                          Certificate,
                          Agency,
                          Notes
                        )
                VALUES  ( @Key_VendorGroup,
                          @Key_Vendor,
                          @Key_CertificateType,
                          @Certificate,
                          @Agency,
                          @Notes
                        )
		
		-- Return the updated row
                EXECUTE vpspPCCertificatesGet @Key_VendorGroup, @Key_Vendor,
                    @Key_CertificateType
            END
        vpspExit:	
    END



GO
GRANT EXECUTE ON  [dbo].[vpspPCCertificatesInsert] TO [VCSPortal]
GO
