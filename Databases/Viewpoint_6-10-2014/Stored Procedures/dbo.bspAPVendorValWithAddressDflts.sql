SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPVendorValWithAddressDflts    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE    proc [dbo].[bspAPVendorValWithAddressDflts]
   /*************************************
   * Created by EN 7/16/97
   * Modified by EN 7/16/97
   *             EN 1/22/00 - expand dimension of @name to varchar(60) and include AddnlInfo in output list
   *             kb 10/29/2 - issue #18878 - fix double quotes
   *			  MV 06/03/304 - #24723 - validate vendor for length.
   *			  MV 03/04/05 - #27144 - if @vendrout comes in as 0, make it null
   *			 MV 06/28/06 - #121302 order by SortName, upper(@vendor)
   *			 mh 3/14/08 - ?.  Added @country output param.  Retrieve from APVM or HQCO.  Added
   *							code to assign @name value to @msg
   * Usage:
   * 	validates AP Vendors against APVM and returns name, address,
   * 	city, state and zip for form defaults
   *
   * Input params:
   *	@vendgroup	AP Vendor Group
   *	@vendor		AP Vendor
   *
   * Output params:
   *	@vendrout	Vendor number
   *	@name		Vendor name
   *   @addnlinfo  Vendor's additional info
   *	@address	Vendor's payment address
   *	@city		Vendor's city
   *	@state		Vendor's state
   *	@zip		Vendor's zip
   *	@msg		Error message
   *
   * Return code:
   *	0=success, 1=failure
   **************************************/
	(@vendgroup bGroup = null, @vendor varchar(15) = null, @vendrout bVendor = null output,
	@name varchar(60) = null output, @addnlinfo varchar(60) = null output, @address varchar(60) = null output,
	@city varchar(30) = null output, @state varchar(4) = null output,
	@zip bZip = null output, @country char(2) output, @msg varchar(60) output)

	as
	set nocount on
	declare @rcode int
	select @rcode = 0

	if @vendrout = 0 -- #27144
	begin
		select @vendrout = null
	end
   
	if @vendgroup is null
	begin
		select @msg = 'Missing Vendor Group', @rcode = 1
		goto bspexit
	end
   
	if @vendor is null
	begin
		select @msg = 'Missing Vendor', @rcode = 1
		goto bspexit
	end
   
	/* If @vendor is numeric then try to find Vendor number */
	if dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7 --#24723
	-- if isnumeric(@vendor) = 1 
	select @vendrout = v.Vendor, @name = v.Name, @addnlinfo = v.AddnlInfo, @address = v.Address, 
	@city = v.City, @state = v.State, @zip = v.Zip, @country = isnull(v.Country, isnull(h.DefaultCountry,'')) 
	from dbo.APVM v (nolock)
	left join dbo.HQCO h (nolock) on v.VendorGroup = h.VendorGroup
	where v.VendorGroup = @vendgroup and v.Vendor = convert(int,convert(float, @vendor))

	/* if not numeric or not found try to find as Sort Name */
	if @vendrout is null 	--#24723
	-- if @@rowcount = 0
	begin
		select @vendrout = v.Vendor, @name = v.Name, @addnlinfo = v.AddnlInfo, 
		@address = v.Address, @city = v.City, @state = v.State, @zip = v.Zip, 
		@country = isnull(v.Country, isnull(h.DefaultCountry,'')) 
		from dbo.APVM v (nolock)
		left join dbo.HQCO h (nolock) on v.VendorGroup = h.VendorGroup
		where v.VendorGroup = @vendgroup and v.SortName = upper(@vendor) order by v.SortName

		/* if not found,  try to find closest */
		if @@rowcount = 0
		begin
			set rowcount 1
			select @vendrout = v.Vendor, @name = v.Name, @addnlinfo = v.AddnlInfo, @address = v.Address, 
			@city = v.City, @state = v.State, @zip = v.Zip, @country = isnull(v.Country, isnull(h.DefaultCountry,'')) 
			from dbo.APVM v (nolock) 
			left join dbo.HQCO h (nolock) on v.VendorGroup = h.VendorGroup
			where v.VendorGroup = @vendgroup and v.SortName like upper(@vendor) + '%' order by v.SortName

			if @@rowcount = 0
			begin
				select @msg = 'Not a valid Vendor', @rcode = 1
			end
   		end
   	end
   
	if @rcode <> 1 
	begin
		select @msg = @name
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValWithAddressDflts] TO [public]
GO
