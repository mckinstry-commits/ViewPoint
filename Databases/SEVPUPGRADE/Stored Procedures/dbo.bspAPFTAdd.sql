SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPFTAdd    Script Date: 8/28/99 9:33:58 AM ******/
    CREATE  proc [dbo].[bspAPFTAdd]
    /***********************************************************
     * CREATED BY: EN 12/01/97
     * MODIFIED By : EN 12/01/97
     *               GF 07/10/2001 - Fixed insert to use columns and values.
     *               DANF 10/23/01 - Added boxes 14-18
     *              kb 10/28/2 - issue #18878 - fix double quotes
     *
     * USAGE:
     * Adds an APFT entry for the specified apco/vendorgroup/vendor/YEMO/1099type
     * if one does not already exist.
     * An error is returned if entry cannot be added.
     *
     *  INPUT PARAMETERS
     *   @apco	AP Company
     *   @vendgrp	Vendor group asssociated with vendor
     *   @vendor	Vendor number
     *   @yemo	Year ending month
     *   @1099type	1099 form type
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    (@apco bCompany,@vendgrp bGroup, @vendor bVendor, @yemo bDate, @1099type varchar(10),
    	@msg varchar(60) output)
    as
    set nocount on
   
    declare @rcode int, @box1amt bDollar, @box2amt bDollar, @box3amt bDollar, @box4amt bDollar,
    	@box5amt bDollar, @box6amt bDollar, @box7amt bDollar, @box8amt bDollar,
    	@box9amt bDollar, @box10amt bDollar, @box11amt bDollar, @box12amt bDollar,
    	@box13amt bDollar, @box14amt bDollar, @box15amt bDollar, @box16amt bDollar,
    	@box17amt bDollar, @box18amt bDollar
   
    select @rcode=0
    select @box1amt=0, @box2amt=0, @box3amt=0, @box4amt=0, @box5amt=0, @box6amt=0, @box7amt=0,
    	@box8amt=0, @box9amt=0, @box10amt=0, @box11amt=0, @box12amt=0, @box13amt=0,
       @box14amt=0, @box15amt=0, @box16amt=0, @box17amt=0, @box18amt=0
   
    if not exists (select * from bAPFT where APCo=@apco and VendorGroup=@vendgrp
    		and Vendor=@vendor and YEMO=@yemo and V1099Type=@1099type)
    	begin
    	insert into bAPFT (APCo, VendorGroup, Vendor, YEMO, V1099Type, Box1Amt, Box2Amt, Box3Amt,
               Box4Amt, Box5Amt, Box6Amt, Box7Amt, Box8Amt, Box9Amt, Box10Amt, Box11Amt,
               Box12Amt, Box13Amt, Box14Amt, Box15Amt, Box16Amt,
               Box17Amt, Box18Amt, AuditYN)
    	values(@apco, @vendgrp, @vendor, @yemo, @1099type, @box1amt, @box2amt, @box3amt,
               @box4amt, @box5amt, @box6amt, @box7amt, @box8amt, @box9amt, @box10amt, @box11amt,
               @box12amt, @box13amt, @box14amt, @box15amt, @box16amt,
               @box17amt, @box18amt, 'N')
    	if @@rowcount=0
    		select @msg = 'Error adding entry to APFT!' , @rcode=1
    	end
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPFTAdd] TO [public]
GO
