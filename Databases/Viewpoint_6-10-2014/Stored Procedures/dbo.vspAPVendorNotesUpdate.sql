SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROC [dbo].[vspAPVendorNotesUpdate]
  /***************************************************
  * CREATED BY    : MV  3/17/06 for APVendComp 6X recode
  * LAST MODIFIED : AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
  * Usage:
  *   updates APVM Notes
  *
  * Input:
  *	@vendorgroup
  *	@vendor
  * @notes     
  *
  * Output:
  *   @msg          description 
  *
  * Returns:
  *	0             success
  * 1             error
  *************************************************/
    (
      @vendorgroup INT,
      @vendor bVendor,
      @notes VARCHAR(MAX),
      @msg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON
  
    DECLARE @rcode INT
  
    SELECT  @rcode = 0
  
   
    UPDATE  APVM
    SET     Notes = @notes
    WHERE   VendorGroup = @vendorgroup
            AND Vendor = @vendor
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Vendor notes failed to update',
                    @rcode = 1
        END
 
  
    bspexit:
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPVendorNotesUpdate] TO [public]
GO
