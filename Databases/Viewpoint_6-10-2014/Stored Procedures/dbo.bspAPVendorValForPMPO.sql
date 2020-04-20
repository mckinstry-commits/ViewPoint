SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPVendorValForPMPO ******/
CREATE proc [dbo].[bspAPVendorValForPMPO]
/***********************************************************
* CREATED BY:	GF 03/15/2010 - issue #120252 for PM PO Header to return the Firm for the vendor
* MODIFIED By:
*
*
*
* Usage:
* Used by PM PO Header to validate the vendor entry by either Sort Name or number.
* Checks Active flag and Vendor Type, based on options passed as input params.
*
* Input params:
* @apco			AP company
* @vendorgroup	Vendor Group
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
* @vendorout	Vendor number
* @payterms		payment terms for this vendor
* @holdyn		Any hold codes in APVH for this vendor?
* @holdcode		first APVH hold code for the vendor
* @taxcode		vendor tax Code
* @vendorfirm	first PMFM Firm for vendor
* @msg			Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
(@apco bCompany, @vendorgroup bGroup = null, @vendor varchar(15) = null, @activeopt char(1) = null,
 @typeopt char(1) = null, @vendorout bVendor = null output, @payterms bPayTerms = null output,
 @holdyn bYN = null output, @holdcode bHoldCode = null output, @taxcode bTaxCode=null output,
 @vendorfirm bVendor = null output, @msg varchar(255) output) 
as
set nocount on

declare @rcode int, @type char(1), @active bYN

set @rcode = 0
   
if @vendorout = 0	-- #27261
	begin
	select @vendorout = null
	end

---- check required input params
if @vendorgroup is null
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
   
---- If @vendor is numeric then try to find Vendor number
if dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7
	select @vendorout = Vendor, @payterms=PayTerms, @msg = Name, @active = ActiveYN,
			@type = Type, @taxcode=TaxCode
	from dbo.APVM with (nolock)
	where VendorGroup = @vendorgroup and Vendor = convert(int,convert(float, @vendor))
	
---- if not numeric or not found try to find as Sort Name
if @vendorout is null
	begin
    	select @vendorout = Vendor, @payterms=PayTerms, @msg = Name,  @active = ActiveYN,
    		@type = Type, @taxcode=TaxCode
	from dbo.APVM with (nolock)
	where VendorGroup = @vendorgroup and SortName = upper(@vendor) order by SortName
	---- if not found,  try to find closest
   	if @@rowcount = 0
		begin
		set rowcount 1
		select @vendorout = Vendor, @payterms=PayTerms, @msg = Name, @active = ActiveYN,
				@type = Type, @taxcode=TaxCode
		from dbo.APVM with (nolock)
		where VendorGroup = @vendorgroup and SortName like upper(@vendor) + '%' order by SortName
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
	
if exists(select * from bAPVH where APCo=@apco and VendorGroup=@vendorgroup and Vendor=@vendorout)
	begin
	select @holdyn='Y'
	end
else
	begin
	select @holdyn='N'
	end


---- get first firm in PMFM using the vendor
set @vendorfirm = null
select top 1 @vendorfirm = f.FirmNumber
from dbo.PMFM f with (nolock)
where f.VendorGroup=@vendorgroup and f.Vendor=@vendorout

---- get first hold code in APVC using the vendor
set @holdcode = null
select top 1 @holdcode = h.HoldCode
from dbo.APVH h with (nolock)
where h.APCo=@apco and h.VendorGroup=@vendorgroup and h.Vendor=@vendorout
    	
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValForPMPO] TO [public]
GO
