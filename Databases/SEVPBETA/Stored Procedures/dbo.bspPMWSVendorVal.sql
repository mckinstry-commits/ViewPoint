SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWSVendorVal    Script Date: 8/28/99 9:33:09 AM ******/
CREATE proc [dbo].[bspPMWSVendorVal]
/***********************************************************
    * CREATED BY: GF 06/17/99
 * Modified By:	GF 05/26/2006 - #27996 6.x changes
 *
    *
    * Usage: Used within PM imports to validate the entry by either Sort Name or number.
    *
    * Input params:
    *	@apco		AP company
    *	@vendgroup	Vendor Group
    *	@vendor		Vendor sort name or number
    *
    * Output params:
    *	@vendorout	Vendor number
    *	@msg		Vendor Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    *****************************************************/
(@apco bCompany, @vendorgroup bGroup = null, @vendor varchar(15) = null,
 @vendorout bVendor=null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @type char(1), @active bYN

select @rcode = 0

if @vendorgroup is null
       begin
       select @msg = 'Missing Vendor Group', @rcode = 1
       goto bspexit
       end

if @vendor is null
       begin
       select @msg = 'Missing Vendor', @rcode = 1
       goto bspexit
       end

------ If @vendor is numeric then try to find Vendor number
if isnumeric(@vendor) = 1
	begin
	select @vendorout=Vendor, @msg=Name
	from APVM with (nolock) where VendorGroup=@vendorgroup and Vendor=convert(int,convert(float, @vendor))
	------ if not numeric or not found try to find as Sort Name
	if @@rowcount = 0
		begin
		select @vendorout=Vendor, @msg=Name
		from APVM with (nolock) where VendorGroup=@vendorgroup and SortName=@vendor
		------ if not found,  try to find closest
		if @@rowcount = 0
			begin
			set rowcount 1
			select @vendorout=Vendor, @msg=Name
			from APVM with (nolock) where VendorGroup=@vendorgroup and SortName like @vendor + '%'
			if @@rowcount = 0
				begin
				select @msg = 'Not a valid Vendor', @rcode = 1
				goto bspexit
				end
			end
		end
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWSVendorVal] TO [public]
GO
