SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSWDPayCodeVal]
   /******************************************************
    * Created:  GG 01/15/01
    * Modified: GG 07/03/01 - add hierarchal Quote search  - #13888
    *			 GF 03/25/2003 - issue #20785 added TransMth to bMSWD. Changed @mth parameter
    *							 to @transmth. Instead of using batch month as before, now
    *							 use trans month from grid.
	*			DAN SO 05/22/2008 - Issue# 28688 - added @payminamt to bspMSTicPayCodeRateGet call
    *
    * USAGE:   Validate MS Pay Code entered in MS Hauler Payment Worksheet
    *  and looks for default Pay Basis and Rate for a selected MS Trans#.
    *
    * Input:
    *  @msco           MS Company
    *  @transmth       MS Transaction Month
    *  @mstrans        MS Trans - used to find default pay info
    *  @xpaycode       Pay Code
    *
    * Output:
    *  @paybasis       Pay Basis Type
    *  @payrate        Pay Code Rate
    *  @payamount      Pay Amount
    *  @msg            Pay Code description from MSPC or error message
    *
    * Return Value
    *  0	success
    *  1	failure
    ***************************************************/
   (@msco bCompany = null, @transmth bMonth = null, @mstrans bTrans = null,
    @xpaycode bPayCode, @paybasis bUnits output, @payrate bUnitCost output,
    @payamount bDollar output, @payminamt bDollar output,
	@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @fromloc bLoc, @vendorgroup bGroup, @saletype char(1), @custgroup bGroup,
       @customer bCustomer, @custjob varchar(20), @custpo varchar(20), @jcco bCompany, @job bJob,
       @inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @units bUnits,
       @haulvendor bVendor, @truck bTruck, @trucktype varchar(10), @loads smallint, @miles bUnits,
       @hours bHrs, @zone varchar(10), @haultotal bDollar, @locgroup bGroup, @category varchar(10),
       @paybasistype tinyint, @quote varchar(10)
   

   select @rcode = 0
   
   select @fromloc = FromLoc, @vendorgroup = VendorGroup, @saletype = SaleType, @custgroup = CustGroup,
       @customer = Customer, @custjob = CustJob, @custpo = CustPO, @jcco = JCCo, @job = Job,
       @inco = INCo, @toloc = ToLoc, @matlgroup = MatlGroup, @material = Material, @um = UM,
       @units = MatlUnits, @haulvendor = HaulVendor, @truck = Truck, @trucktype = TruckType,
       @loads = Loads, @miles = Miles, @hours = Hours, @zone = Zone, @haultotal = HaulTotal
   from bMSTD with (Nolock) 
   where MSCo = @msco and Mth = @transmth and MSTrans = @mstrans
   if @@rowcount = 0
    	begin
    	select @msg = 'Invalid MS Trans#, cannot get necessary information for Pay Code.', @rcode = 1
    	goto bspexit
    	end
   
   --get Location Group
   select @locgroup = LocGroup
   from bINLM with (nolock) where INCo = @msco and Loc = @fromloc
   
   -- get material info
   select @category = Category
   from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
   
   -- validate Pay Code
   select @msg = Description, @paybasistype = PayBasis
   from bMSPC with (nolock) where MSCo = @msco and PayCode = @xpaycode
   if @@rowcount = 0
    	begin
    	select @msg = 'Invalid Pay Code.', @rcode = 1
    	goto bspexit
    	end
   
   -- get Quote (if one exists)
   if @saletype = 'C'
       begin
       select @quote = Quote
       from bMSQH with (nolock)
       where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
           and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'')
       and Active = 'Y'
       if @@rowcount = 0
           begin
           -- no active Quote at Cust PO level, check for one at Cust Job level
           select @quote = Quote
           from bMSQH with (nolock)
           where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
               and isnull(CustJob,'') = isnull(@custjob,'') and CustPO is null and Active = 'Y'
           if @@rowcount = 0
               begin
               -- no active Quote at Cust Job level, check for one at Customer level
               select @quote = Quote
               from bMSQH with (nolock)
               where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
                   and CustJob is null and CustPO is null and Active = 'Y'
               end
           end
       end
   
   if @saletype = 'J'
       select @quote = Quote
       from bMSQH with (nolock)
       where MSCo = @msco and QuoteType = 'J' and JCCo = @jcco and Job = @job
       and Active = 'Y'
   
   if @saletype = 'I'
       select @quote = Quote
       from bMSQH with (nolock)
       where MSCo = @msco and QuoteType = 'I' and INCo = @inco and Loc = @toloc
       and Active='Y'
   

   -- get default Pay Rate
   exec @rcode = dbo.bspMSTicPayCodeRateGet @msco,@xpaycode,@matlgroup,@material,@category,@locgroup,
                   @fromloc,@quote,@trucktype,@vendorgroup,@haulvendor,@truck,@um,@zone,@paybasistype,
                   @payrate output, @payminamt output, @msg output
   if @rcode <> 0 goto bspexit
   
   --assign default Pay Basis
   if @paybasistype = 1 select @paybasis = @units
   if @paybasistype = 2 select @paybasis = @hours
   if @paybasistype = 3 select @paybasis = @loads
   if @paybasistype = 4 and @miles <> 0 select @paybasis = @units / @miles
   if @paybasistype = 5 and @hours <> 0 select @paybasis = @units / @hours
   if @paybasistype = 6 select @paybasis = @haultotal
   
   select @payamount = isnull(@payrate,0) * isnull(@paybasis,0)
   
   
   
   bspexit:
   	if @rcode <> 0 select @msg = isnull(@msg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSWDPayCodeVal] TO [public]
GO
