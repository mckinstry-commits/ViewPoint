SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspAPAddtlAddrVal]
    	
    /***********************************************************
     * CREATED BY: MV   10/25/02
     * MODIFIED By :	MV 03/11/08 #127347 International addresses
     *					MV 10/12/11 TK-08960 fixed validation sp 
     *
     * USAGE:
     * validates AP Additional Addresses and returns address info
     * an error is returned if any of the following occurs
     * no vendorgroup passed, no vendor passed, seq does not exist
     *
     * INPUT PARAMETERS
     *   VendorGroup   vendorgroup associated with the vendor
     *   Vendor	    Vendor
     *	AddressSeq    sequence # for the vendor address
     *	Type		    1 for Pay, 2 for PO	
     *	
     * OUTPUT PARAMETERS
     *   @name		from APVM                       
     *   @desc		Description from bAPAA
     *	@addr		Address
     *	@city		City
     *	@st			State
     *	@zip			Zip
     *	@addr   		Address2
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/ 
    (@vendorgrp bGroup, @vendor bVendor, @seq int, @type varchar(1), @name char(60)output,
    	@address char(60) output, @city char(30)output, @state varchar(4) output,
		@country char(2) output, @zip bZip output,@addr2 char(60) output, @msg varchar(255) output) 
    as
    set nocount on
    
    	declare @rcode int
    	select @rcode = 0
    
    if @vendorgrp is null
    	begin
    	select @msg = 'Missing Vendor Group!', @rcode = 1
    	goto bspexit
    	end
    
    if @vendor is null
    	begin
    	select @msg = 'Missing Vendor!', @rcode = 1
    	goto bspexit
    	end
    
    if @seq is null
    	begin
    	select @msg = 'Missing Address Sequence!', @rcode = 1
    	goto bspexit
    	end
    
    
    if @type is null
    	begin
    	select @msg = 'Missing Address Type!', @rcode = 1
    	goto bspexit
    	end
 
IF @type = '0'
BEGIN
    SELECT @address=Address, @city=City, @state=State, @country=Country, @zip=Zip,@addr2=Address2, @msg=Description
	FROM dbo.bAPAA
	WHERE VendorGroup=@vendorgrp and Vendor=@vendor and AddressSeq=@seq 
	IF @@rowcount = 0
	BEGIN
    	SELECT @msg = 'Invalid Address Sequence!', @rcode = 1
    	GOTO bspexit
    END
END    
if @type = '1'
	begin
    select @address=Address, @city=City, @state=State, @country=Country, @zip=Zip,@addr2=Address2, @msg=Description
	from APAA where VendorGroup=@vendorgrp and Vendor=@vendor and AddressSeq=@seq and Type in(0,1)
	if @@rowcount = 0
		begin
    	select @msg = 'Invalid Address Sequence!', @rcode = 1
    	goto bspexit
    	end
    end
    
if @type = '2'
    begin
    select @address=Address, @city=City, @state=State,@country=Country,@zip=Zip,@addr2=Address2, @msg=Description
	from APAA where VendorGroup=@vendorgrp and Vendor=@vendor and AddressSeq=@seq and Type in(0,2)
	if @@rowcount = 0
    	begin
    	select @msg = 'Invalid Address Sequence!', @rcode = 1
    	goto bspexit
    	end
    end
    
    select @name=Name 
    	from APVM
    	where VendorGroup = @vendorgrp and Vendor = @vendor 
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPAddtlAddrVal] TO [public]
GO
