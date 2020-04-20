SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPOVendorVal    Script Date: 8/28/99 9:34:06 AM ******/
    CREATE         proc [dbo].[vspPOVendorVal]
    /***********************************************************
	* CREATED BY: DC  11/19/08
	* MODIFIED By :   DC 10/5/09 - conversion failed err when type Vendor name
	*
	*
	* Notes:
	*	Previously the vendor validation procedure in PO Entry was 
	*	bspAPVendorVal.  But I needed to modify that sp to return
	*	Vendor In Compliance.  Since I was hacking the sp, I just 
	*	created this new procedure, based on that procedure.
	*
	* Usage:
	*	Used by PO Entry Vendor input to validate the entry.
	* 	Checks Active flag and Vendor Type, based on options passed as input params.
	*
	* Input params:
	*	@poco		PO company
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
	*	@payterms       payment terms for this vendor
	*	@taxcode	vendor tax Code
	*   @compliedout	flag indicating if vendor is in compliance
	*	@msg		Vendor Name or error message
	*
	* Return code:
	*	0 = success, 1 = failure
     *****************************************************/
    (@poco bCompany, @vendgroup bGroup = null, @vendor varchar(15) = null, @activeopt char(1) = null,
        @typeopt char(1) = null, @orderdate bDate = null, @vendorout bVendor=null output, 
        @payterms bPayTerms=null output, @taxcode bTaxCode=null output, @compliedout bYN = null output, 
        @msg varchar(60) output) 
          
     
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
    	goto vspexit
    	end
    if @vendor is null
    	begin
    	select @msg = 'Missing Vendor.', @rcode = 1
    	goto vspexit
    	end
    if @activeopt is null
    	begin
    	select @msg = 'Missing Active option for Vendor validation.', @rcode = 1
    	goto vspexit
    	end
    if @typeopt is null
    	begin
    	select @msg = 'Missing Type option for Vendor validation.', @rcode = 1
    	goto vspexit
    	end
   
    /* If @vendor is numeric then try to find Vendor number */
    if dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7 --#24723
    	select @vendorout = Vendor, @payterms=PayTerms, @msg = Name, @active = ActiveYN, @type = Type,
    		@taxcode=TaxCode
    	from APVM
    	where VendorGroup = @vendgroup and Vendor = convert(int,convert(float, @vendor))
    /* if not numeric or not found try to find as Sort Name */
   	if @vendorout is null	-- #24723 
    	begin
		select @vendorout = Vendor, @payterms=PayTerms, @msg = Name,  @active = ActiveYN, @type = Type,
    		@taxcode=TaxCode
    	from APVM
    	where VendorGroup = @vendgroup and SortName = upper(@vendor) order by SortName
    	 /* if not found,  try to find closest */
       	if @@rowcount = 0
			begin
			set rowcount 1
			select @vendorout = Vendor, @payterms=PayTerms, @msg = Name, @active = ActiveYN, @type = Type,
    				@taxcode=TaxCode
			from APVM
			where VendorGroup = @vendgroup and SortName like upper(@vendor) + '%' order by SortName
			if @@rowcount = 0
     	  		begin
				select @msg = 'Not a valid Vendor', @rcode = 1
    			goto vspexit
    	   		end
    		end
    	end
    if @typeopt <> 'X' and @type <> @typeopt
    	begin
    	select @msg='Invalid type option!'
    	if @typeopt = 'R' select @msg = 'Must be a regular Vendor.'
    	if @typeopt = 'S' select @msg = 'Must be a Supplier.'
    	select @rcode = 1
    	goto vspexit
    	end
    if @activeopt <> 'X' and @active <> @activeopt
    	begin
    	select @msg='Invalid active status!'
    	if @activeopt = 'Y' select @msg = 'Must be an active Vendor.'
    	if @activeopt = 'N' select @msg = 'Must be an inactive Vendor.'
    	select @rcode = 1
    	goto vspexit
    	end

	if exists(select top 1 1 from bAPVC v join bHQCP h on v.CompCode=h.CompCode
		where v.APCo=@poco and v.VendorGroup=@vendgroup 
			and v.Vendor=@vendorout  --DC #135861
			and v.Verify='Y' 
			and ((h.CompType='D' and (v.ExpDate<@orderdate or v.ExpDate is null)) or (h.CompType='F' and (v.Complied='N' or v.Complied is null))))
   		begin
   		select @compliedout = 'N'
   		end
	else
		begin
		select @compliedout = 'Y'
		end

    vspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOVendorVal] TO [public]
GO
