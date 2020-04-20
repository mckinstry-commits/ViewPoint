SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[vspAPVendorValForAPVC]
    (@apco bCompany, @vendgroup bGroup = null, @vendor varchar(15) = null, @activeopt char(1) = null,
        @typeopt char(1) = null,@vendorout bVendor=null output, @notes varchar(8000) output, @msg varchar(60) output)
    /***********************************************************
     * CREATED BY: MV 03/21/06 for APVendComp 6X recode
     * MODIFIED By : 
     *
     * Usage:
     *	Used by APVendComp to validate the entry by either Sort Name or number.
     * 	Checks Active flag and Vendor Type, based on options passed as input params.
     *
     * Input params:
     *	@apco		AP company
     *	@vendgroup	Vendor Group
     *	@vendor		Vendor sort name or number
     *	@activeopt	Controls validation based on Active flag
     *			'Y' = must be an active
     *			'N' = must be inactive
     *			'X' = can be any value
     *	@typeopt	Controls validation based on Vendor Type
     *			'R' = must be Regular
     *			'S' = must be Supplier
     *			'X' = can be any value
     *
     * Output params:
     *	@vendorout	Vendor number
     *	@notes		Vendor notes
     *	@msg		Vendor Name or error message
     *
     * Return code:
     *	0 = success, 1 = failure
     *****************************************************/
    as
    set nocount on
    declare @rcode int, @type char(1), @active bYN
    select @rcode = 0
   
   	if @vendorout = 0	-- #27261
   	begin
   	select @vendorout = null
   	end
   
    /* check required input params */
    if @vendgroup is null
    	begin
    	select @msg = 'Missing Vendor Group.', @rcode = 1
    	goto bspexit
    	end
    if @vendor is null
    	begin
    	select @msg = 'Missing Vendor.', @rcode = 1
    	goto bspexit
    	end
    if @activeopt is null
    	begin
    	select @msg = 'Missing Active option for Vendor validation.', @rcode = 1
    	goto bspexit
    	end
    if @typeopt is null
    	begin
    	select @msg = 'Missing Type option for Vendor validation.', @rcode = 1
    	goto bspexit
    	end
   
    /* If @vendor is numeric then try to find Vendor number */
    if dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7 --#24723
   --  if isnumeric(@vendor) = 1 
    	select @vendorout = Vendor,@notes = Notes, @msg = Name, @type = Type,@active=ActiveYN
    	from APVM with (nolock)
    	where VendorGroup = @vendgroup and Vendor = convert(int,convert(float, @vendor))
    /* if not numeric or not found try to find as Sort Name */
   	if @vendorout is null	-- #24723 
   --  if @@rowcount = 0
    	begin
        select @vendorout = Vendor,@notes = Notes, @msg = Name, @type = Type,@active=ActiveYN
    	from APVM with (nolock)
    	where VendorGroup = @vendgroup and SortName = @vendor
    	 /* if not found,  try to find closest */
       	if @@rowcount = 0
           		begin
            	set rowcount 1
            	select @vendorout = Vendor,@notes = Notes, @msg = Name, @type = Type,@active=ActiveYN
    			from APVM with (nolock)
    			where VendorGroup = @vendgroup and SortName like @vendor + '%'
    		if @@rowcount = 0
     	  		begin
    	    		select @msg = 'Not a valid Vendor', @rcode = 1
    			goto bspexit
    	   		end
    		end
    	end
    if @typeopt <> 'X' and @type <> @typeopt
    	begin
    	select @msg='Invalid type option!'
    	if @typeopt = 'R' select @msg = 'Must be a regular Vendor.'
    	if @typeopt = 'S' select @msg = 'Must be a Supplier.'
    	select @rcode = 1
    	goto bspexit
    	end
    if @activeopt <> 'X' and @active <> @activeopt
    	begin
    	select @msg='Invalid active status!'
    	if @activeopt = 'Y' select @msg = 'Must be an active Vendor.'
    	if @activeopt = 'N' select @msg = 'Must be an inactive Vendor.'
    	select @rcode = 1
    	goto bspexit
    	end
 		

    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPVendorValForAPVC] TO [public]
GO
