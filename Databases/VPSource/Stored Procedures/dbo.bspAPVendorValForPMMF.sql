SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
   CREATE proc [dbo].[bspAPVendorValForPMMF]
/***********************************************************
* Created By:	GF	01/01/2001
* Modified By:	MV	06/03/2004	- #24723 validate vendor for length
*				GF	08/19/2005	- issue #29524 return active flag for warning if inactive.
*				MV	06/28/2006	- #121302 order by SortName, upper(@vendor)
*				CHS 02/02/2010	- #135565
*
* Usage:
*	Used by PMMaterials, PMSubcontracts and PMPCOSItemsDetail to validate the entry by either Sort Name or number.
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
*  @jcco       JC Company
*  @job        Job
*
* Output params:
* @vendorout	Vendor number
* @holdyn		Vendor Hold Flag
* @taxcode		Vendor tax Code
* @active		Vendor Active Flag
* @msg		Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
   (@jcco bCompany = null, @job bJob = null, @apco bCompany, @vendgroup bGroup = null,
    @vendor varchar(15) = null, @activeopt char(1) = null, @typeopt char(1) = null,
    @vendorout bVendor=null output, @holdyn bYN = null output, @taxcode bTaxCode=null output,
    @active bYN = 'Y' output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @type char(1), @basetaxon varchar(1), @jobtaxcode bTaxCode
   
   select @rcode = 0
   
   -- check required input params
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
   
   -- If @vendor is numeric then try to find Vendor number
   if dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7 --#24723
   -- if isnumeric(@vendor) = 1 
   	select @vendorout=Vendor, @msg=Name, @active=ActiveYN, @type=Type, @taxcode=TaxCode
   	from APVM where VendorGroup=@vendgroup and Vendor = convert(int,convert(float, @vendor))
   
   -- if not numeric or not found try to find as Sort Name
   if @vendorout is null	--#24723
   -- if @@rowcount = 0
   	begin
       select @vendorout = Vendor, @msg = Name,  @active = ActiveYN, @type = Type, @taxcode=TaxCode
   	from APVM
   	where VendorGroup = @vendgroup and SortName = upper(@vendor) order by SortName
   
       -- if not found,  try to find closest
      	if @@rowcount = 0
          		begin
           		set rowcount 1
           		select @vendorout = Vendor, @msg = Name, @active = ActiveYN, @type = Type, @taxcode=TaxCode
   		from APVM
   		where VendorGroup = @vendgroup and SortName like upper(@vendor) + '%'order by SortName
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
   
   -- #135565 - CHS
   if @job is not null
       begin
       select @basetaxon=BaseTaxOn, @jobtaxcode=TaxCode
       from bJCJM where JCCo=@jcco and Job=@job
       if @basetaxon = 'J' select @taxcode=@jobtaxcode
       
       if @basetaxon = 'O' 
		begin
		select @taxcode=isnull(TaxCode, @jobtaxcode)
		from bAPVM where VendorGroup=@vendgroup and Vendor=@vendor	
		end
       end

	else
		begin
		if @basetaxon = 'O' 
			begin
			select @taxcode=TaxCode
			from bAPVM where VendorGroup=@vendgroup and Vendor=@vendor	
			end
		end
   
   
   bspexit:
       if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValForPMMF] TO [public]
GO
