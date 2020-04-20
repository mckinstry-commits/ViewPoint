SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPVendorVal    Script Date:  ******/
CREATE proc [dbo].[vspAPVendorVal]
(@apco bCompany, @vendgroup bGroup = null, @vendor varchar(15) = null, @activeopt char(1) = null,
    @typeopt char(1) = null,@vendorout bVendor=null output, @payterms bPayTerms=null output,
    @eft char(1)=null output,@v1099yn bYN=null output,@v1099Type varchar(10) = null output,
    @v1099Box tinyint = null output,@holdyn bYN = null output, @addnlinfo varchar(60) = null output,
    @address varchar(60) = null output, @city varchar(30) = null output,@state varchar(4) = null output,
    @zip bZip = null output, @country char(2) = null output, @taxid varchar(12) = null output,
	@taxcode bTaxCode=null output, 
	@phone bPhone=null output, @email varchar(60)=null output, 
	@msg varchar(60) output) 
/***********************************************************
 * CREATED BY: TJL  03/26/08 - Issue #127347, International Address.
 * MODIFIED By :	DC 06/02/2009 - #132590 - Supplier info not populating from APVM
 *
 * Usage:
 *	*** Duplicate of bspAPVendorVal except Country has been added ***
 *
 *	Used by:
 *		AP1099Edit
 *		SLComply
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
 *	@payterms       payment terms for this vendor
 *  	@eft		'N' = Not used, payments made by check only.
 *			'A' = EFT Active
 *			'P' = PreNote, waiting for confirmation of valid Bank Acct and Transit#s, payments
 *				made by check only.'
 * 	@v1099yn	Does vendor use 1099
 *	@v1099Type	Default type for vendor's 1099
 *	@v1099Box	Default box for vendor's 1099
 *	@holdyn		Any hold codes in APVH for this vendor?
 *  @addnlinfo  vendor additional info
 *	@address	vendor payment address
 *	@city		vendor payment city
 *	@state		vendor payment state
 *	@zip		vendor payment zip
 *	@country	vendor payment country
 *	@taxid		vendor tax ID
 *	@taxcode	vendor tax Code
 *	@phone		vendor phone number   --DC #132590
 *	@email		vendor email address  --DC #132590
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
    	select @vendorout = Vendor, @payterms=PayTerms, @msg = Name, @active = ActiveYN, @type = Type,
    		@eft=EFT, @v1099yn=V1099YN, @v1099Type=V1099Type, @v1099Box=V1099Box,
            @addnlinfo=AddnlInfo, @address=Address,@city=City, @state=State,
            @zip=Zip, @country=Country, @taxid=TaxId, @taxcode=TaxCode,
            @phone = Phone, @email = EMail  --DC #132590
    	from APVM
    	where VendorGroup = @vendgroup and Vendor = convert(int,convert(float, @vendor))
    /* if not numeric or not found try to find as Sort Name */
   	if @vendorout is null	-- #24723 
   --  if @@rowcount = 0
    	begin
        	select @vendorout = Vendor, @payterms=PayTerms, @msg = Name,  @active = ActiveYN, @type = Type,
    		@eft=EFT, @v1099yn=V1099YN, @v1099Type=V1099Type, @v1099Box=V1099Box,
            @addnlinfo=AddnlInfo, @address=Address,@city=City, @state=State,
            @zip=Zip, @country=Country, @taxid=TaxId, @taxcode=TaxCode,
            @phone = Phone, @email = EMail  --DC #132590
    	from APVM
    	where VendorGroup = @vendgroup and SortName = upper(@vendor) order by SortName
    	 /* if not found,  try to find closest */
       	if @@rowcount = 0
           		begin
            		set rowcount 1
            		select @vendorout = Vendor, @payterms=PayTerms, @msg = Name, @active = ActiveYN, @type = Type,
    				@eft=EFT, @v1099yn=V1099YN, @v1099Type=V1099Type, @v1099Box=V1099Box,
                    @addnlinfo=AddnlInfo, @address=Address,@city=City, @state=State,
                    @zip=Zip, @country=Country, @taxid=TaxId, @taxcode=TaxCode,
                    @phone = Phone, @email = EMail  --DC #132590
    		from APVM
    		where VendorGroup = @vendgroup and SortName like upper(@vendor) + '%' order by SortName
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
    if exists(select * from bAPVH where APCo=@apco and VendorGroup=@vendgroup and Vendor=@vendorout)
    	begin
    	select @holdyn='Y'
    	end
    else
    	begin
    	select @holdyn='N'
    	end
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPVendorVal] TO [public]
GO
