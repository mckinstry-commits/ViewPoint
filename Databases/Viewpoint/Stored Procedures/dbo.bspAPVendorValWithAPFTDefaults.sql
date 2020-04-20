SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPVendorValWithAPFTDefaults    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE  proc [dbo].[bspAPVendorValWithAPFTDefaults]
   /*************************************
   * validates AP Vendors against APVM and returns V1099Type, 
   * V1099Box, AddressSeq and Address for AP1099Totals defaults
   *
   * Modified by:	kb 10/29/2 - issue #18878 - fix double quotes
   *				MV 11/17/11 - RK-10093 - return Vendor 1099 Address Seq and address
   *				MV 11/30/11 = TK-10484 - fixed where clause on select from bAPAA
   * Pass:
   *	AP Vendor Group
   *	AP Vendor
   *
   * Success returns:
   *	0 V1099Type and V1099Box from bAPVM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@VendorGroup bGroup = null, @Vendor bVendor = null, @vendorout bVendor output,
   	@V1099Type varchar(10) = null output, @V1099Box tinyint = null output, 
   	@AddressSeq tinyint output, @MailingAddr1 varchar(60) output, @MailingAddr2 varchar(60) output,
   	@msg varchar(60) output)
   	
	AS 
   	SET NOCOUNT ON
   	
   	DECLARE @rcode int
   	SELECT @rcode = 0
   	
	IF @VendorGroup IS NULL
   	BEGIN
   		SELECT @msg = 'Missing Vendor Group', @rcode = 1
   		GOTO bspexit
   	END
   
	IF @Vendor IS NULL
   	BEGIN
   		SELECT @msg = 'Missing Vendor', @rcode = 1
   		GOTO bspexit
   	END
   
   		
   	 /* If @vendor is numeric then try to find Vendor number */
    IF dbo.bfIsInteger(@Vendor) = 1 and len(@Vendor) < 7
    BEGIN
		SELECT @vendorout = Vendor,@V1099Type=V1099Type, @V1099Box=V1099Box,
             @AddressSeq = V1099AddressSeq, @msg=Name
    	FROM dbo.APVM
    	WHERE VendorGroup = @VendorGroup and Vendor = convert(int,convert(float, @Vendor))
    END 
    	
    /* if not numeric or not found try to find as Sort Name */
   	if @vendorout is null	
    BEGIN
        SELECT @vendorout = Vendor,@V1099Type=V1099Type, @V1099Box=V1099Box,
             @AddressSeq = V1099AddressSeq, @msg=Name
    	FROM dbo.APVM
    	WHERE VendorGroup = @VendorGroup and SortName = upper(@Vendor) order by SortName
    	
     /* if not found,  try to find closest */
       	if @@rowcount = 0
        BEGIN
			SELECT @vendorout = Vendor,@V1099Type=V1099Type, @V1099Box=V1099Box,
				@AddressSeq = V1099AddressSeq, @msg=Name
    		FROM dbo.APVM
    		WHERE VendorGroup = @VendorGroup and SortName like upper(@Vendor) + '%' order by SortName
    		IF @@rowcount = 0
     	  	BEGIN
    			SELECT @msg = 'Not a valid Vendor', @rcode = 1
    			GOTO bspexit
    	   	END
    	END
    END
    
    IF @vendorout IS NOT NULL
    BEGIN
		IF @AddressSeq IS NOT NULL
			BEGIN
			SELECT	@MailingAddr1 =	ISNULL(Address,''),
					@MailingAddr2 =	ISNULL(City,'') + Space(1) + ISNULL(State,'') + SPACE(1) + ISNULL(Zip,'')
			FROM dbo.bAPAA 
			WHERE VendorGroup=@VendorGroup AND Vendor=@vendorout AND AddressSeq = @AddressSeq
			END
		ELSE
			BEGIN
			SELECT	@MailingAddr1 =	ISNULL(Address,''),
					@MailingAddr2 =	ISNULL(City,'') + Space(1) + ISNULL(State,'') + SPACE(1) + ISNULL(Zip,'')
			FROM dbo.bAPVM 
			WHERE VendorGroup=@VendorGroup AND Vendor=@vendorout
			END
    END
   
   bspexit:
   	RETURN @rcode
   	
   	

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValWithAPFTDefaults] TO [public]
GO
