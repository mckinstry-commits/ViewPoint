SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
	Modified: AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*************************************************************************/
CREATE PROCEDURE [dbo].[vpspPCReferencesUpdate]
    (
      @Original_KeyID BIGINT,
      @VendorGroup bGroup,
      @Vendor bVendor,
      @ReferenceTypeCode VARCHAR(10),
      @Contact VARCHAR(30),
      @Company VARCHAR(60),
      @Address VARCHAR(30),
      @City VARCHAR(30),
      @State VARCHAR(4),
      @Country CHAR(2),
      @Zip bZip,
      @Phone bPhone,
      @Fax bPhone,
      @Email VARCHAR(60),
      @Notes VARCHAR(MAX)
    )
AS 
    SET NOCOUNT ON ;

    BEGIN
        UPDATE  PCReferences
        SET     VendorGroup = @VendorGroup,
                Vendor = @Vendor,
                ReferenceTypeCode = @ReferenceTypeCode,
                Contact = @Contact,
                Company = @Company,
                Address = @Address,
                City = @City,
                State = @State,
                Country = @Country,
                Zip = @Zip,
                Phone = @Phone,
                Fax = @Fax,
                Email = @Email,
                Notes = @Notes
        WHERE   KeyID = @Original_KeyID
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPCReferencesUpdate] TO [VCSPortal]
GO
