SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************************/
   CREATE   procedure [dbo].[bspMSWDTransVal]
   /***********************************************************
   * Created By:	GG 01/13/01
   * Modified By:	GF 03/25/2003 - issue #20785 added TransMth to bMSWD. Changed @mth parameter
   *							 to @xmstransmth. Instead of using batch month as before, now
   *							 use trans month from grid.
   *				GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
   *				GF 12/16/2004 - issue #18884, 20558, 25040 enhancements. pass in custgroup, customer,
   *								custjob, jcco, Job, inco, ToLoc
   *				GF 08/04/2005 - issue #29479 loosened up validation for customer and Job to allow for null values.
   *				DAN SO 03/13/2009 - Issue #131943 - return Freight Bill
   *				MH 10/14/2010 - Issue 1411016 - Return flag to indicate if transaction is a surcharge.
   *				MH 09/17/2011 - TK-01835
   *				GF 11/30/2011 - TK-00000 Hunter fix for Freight Bill
   *
   *
   *
   * Called from the MS Hauler Worksheet form to validate a MSTrans
   * and return Hauler payment related info.
   *
   * INPUT PARAMETERS
   *   @co                 MS Co#
   *   @mth                Batch Month
   *   @batchid		    Batch ID
   *	@xmstransmth		MS transaction month to validate
   *   @xmstrans           MSTrans to validate
   *   @xvendorgroup       Vendor Group restriction
   *   @xvendor            Haul Vendor
   *	@xcustgroup			Customer Group
   *	@xcustomer			Customer
   *	@xcustjob			Customer Job
   *	@xjcco				JC Company
   *	@xjob				JC Job
   *	@xsaletype			Sales Type Restriction
   *	@xinco				IN Company
   *	@xtoloc				IN Sell To Location
   *
   * OUTPUT PARAMETERS
   *	@ticket				Ticket
   *   @saledate           Sales date
   *   @fromloc            From Location
   *   @matlgroup          Material Group
   *   @material           Material
   *   @trucktype          Truck Type
   *   @truck              Truck #
   *   @paycode            Pay Code
   *   @paybasis           Pay Basis amount
   *   @payrate            Pay Rate
   *   @paytotal           Pay Total
   *   @FreightBill		   Freight Bill
   *   @issurcharge        Flag to indicate of transaction is a surcharge.
   *   @msg                success or error message
   *
   * RETURN VALUE
   *   0               success
   *   1               fail
   *****************************************************/
   (@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @xmstransmth bMonth = null, 
    @xmstrans bTrans = null, @xvendorgroup bGroup = null, @xvendor bVendor = null, @xcustgroup bGroup = null,
    @xcustomer bCustomer = null, @xcustjob varchar(20) = null, @xjcco bCompany = null, @xjob bJob = null,
    @xsaletype varchar(1) = 'N', @xinco bCompany = null, @xtoloc bLoc = null,
    @ticket varchar(10) output, @saledate bDate output, @fromloc bLoc output, @matlgroup bGroup output,
    @material bMatl output, @trucktype varchar(10) output, @truck bTruck output, @paycode bPayCode output,
    @paybasis bUnits output, @payrate bUnitCost output, @paytotal bDollar output, @FreightBill varchar(10) output,
	@issurcharge bYN output, @haulpaytaxtype tinyint output, @haulpaytaxcode bTaxCode output, 
	@haulpaytaxrate bRate output, @haulpaytaxamt bDollar output,  @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @haulertype char(1), @haulvendor bVendor, 
   		@apref bAPReference, @void char(1), @inusebatchid bBatchID, @saletype varchar(1),
   		@custgroup bGroup, @customer bCustomer, @custjob varchar(20), @jcco bCompany,
   		@job bJob, @inco bCompany, @toloc bLoc
   
   select @rcode = 0
   
   
   if @xvendorgroup is null or @xvendor is null
       begin
       select @msg = 'Missing Vendor Group and/or Haul Vendor!', @rcode = 1
       goto bspexit
       end
   
   -- get MSTD detail
   select @ticket = Ticket, @saledate = SaleDate, @fromloc = FromLoc, @vendorgroup = VendorGroup,
   		@matlgroup = MatlGroup, @material = Material, @haulertype = HaulerType, @haulvendor = HaulVendor, 
		@trucktype = TruckType, @truck = Truck, @paycode = PayCode, @paybasis = PayBasis, 
   		@payrate = PayRate, @paytotal = PayTotal, @apref = APRef, @void = Void, 
   		@inusebatchid = InUseBatchId, @saletype = SaleType, @customer = Customer, @custjob = CustJob, 
   		@jcco = JCCo, @job = Job, @inco = INCo, @toloc = ToLoc, @haulpaytaxcode = HaulPayTaxCode,
   		@haulpaytaxrate = HaulPayTaxRate, @haulpaytaxamt = HaulPayTaxAmt, @haulpaytaxtype = HaulPayTaxType
   from bMSTD with (Nolock) 
   where MSCo = @co and Mth = @xmstransmth and MSTrans = @xmstrans
   if @@rowcount = 0
       begin
       select @msg = 'Invalid MS Transaction', @rcode = 1
       goto bspexit
       end
   
	-- ISSUE: #131943 --
	-- GET FREIGHT BILL --
	SET @FreightBill = NULL
	SELECT @FreightBill = h.FreightBill
	----TK-00000
	FROM dbo.bMSTD d WITH (NOLOCK)
	JOIN dbo.bMSHH h WITH (NOLOCK) ON h.MSCo = d.MSCo AND h.Mth = d.Mth AND h.HaulTrans = d.HaulTrans
	WHERE d.MSCo = @co
		AND d.Mth = @xmstransmth
		AND d.MSTrans = @xmstrans
	---- FROM bMSHH h with (nolock)
	---- JOIN bMSTD d with (nolock) on h.MSCo = d.MSCo
	---- AND h.HaulTrans = d.HaulTrans
	---- WHERE h.Mth = @xmstransmth
	---- AND d.MSTrans = @xmstrans


   -- check restrictions
   if @haulertype <> 'H'
       begin
       select @msg = 'Invalid.  Transaction Hauler Type must be (H)', @rcode = 1
       goto bspexit
       end
   
   if @xvendorgroup <> @vendorgroup
       begin
       select @msg = 'Invalid, Transaction has different Vendor Group.', @rcode = 1
       goto bspexit
       end
   
   if @xvendor <> @haulvendor
       begin
       select @msg = 'Invalid, Transaction posted to Haul Vendor ' + convert(varchar(8),isnull(@haulvendor,'')), @rcode = 1
       goto bspexit
       end
   
   if @void = 'Y'
       begin
       select @msg = 'Invalid, Transaction is voided.', @rcode = 1
       goto bspexit
       end
   
   if @apref is not null
       begin
       select @msg = 'Invalid, Transaction is on AP Reference ' + isnull(@apref,''), @rcode = 1
       goto bspexit
       end
   
   if isnull(@inusebatchid,@batchid) <> @batchid	-- check for use by another batch
       begin
       select @msg = 'Invalid, Transaction is in use by batch ' + isnull(convert(varchar(10), @inusebatchid),''), @rcode = 1
       goto bspexit
       end
   
	select @issurcharge = case when SurchargeKeyID is not null then 'Y' else 'N' end
	from MSTD
	where MSCo = @co and Mth = @mth and MSTrans = @xmstrans   
   
   if @xsaletype = 'N' goto bspexit
   
   
   if @xsaletype <> @saletype
   	begin
   	select @msg = 'The MSTrans sale type: ' + isnull(@saletype,'') + ' is different from the hauler invoice sales type restriction.', @rcode = 1
   	goto bspexit
   	end
   
   
   if @xsaletype = 'C'
   	begin
   	-- -- -- issue #29479
   	if @customer <> isnull(@xcustomer,@customer)
   		begin
   		select @msg = 'Invalid MS Trans, Customer: ' + isnull(convert(varchar(10),@customer),'') + ' assigned to MS Trans differs from Hauler Invoice.', @rcode = 1
   		goto bspexit
   		end
   	if isnull(@custjob,'') <> isnull(@xcustjob,'')
   		begin
   		select @msg = 'Invalid MS Trans, Customer: ' + isnull(convert(varchar(10),@customer),'') + ' - Customer Job: ' + isnull(@custjob,'') + ' assigned to MS Trans differs from Hauler Invoice.', @rcode = 1
   		goto bspexit
   		end
   	end
  
   
   if @xsaletype = 'J'
   	begin
   	-- -- -- issue #29479
   	if @jcco <> isnull(@xjcco,@jcco) or @job <> isnull(@xjob,@job)
   		begin
   		select @msg = 'Invalid MS Trans, JCCo: ' + isnull(convert(varchar(3),@jcco),'') + ' - Job: ' + isnull(@job,'') + ' assigned to MS Trans differs from Hauler Invoice.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   
   if @xsaletype = 'I'
   	begin
   	if @inco <> @xinco or @toloc <> @xtoloc
   		begin
   		select @msg = 'Invalid MS Trans, INCo: ' + isnull(convert(varchar(3),@inco),'') + ' - Sell To Location: ' + isnull(@toloc,'') + ' assigned to MS Trans differs from Hauler Invoice.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   
   bspexit:
       if @rcode <> 0 select @msg = isnull(@msg,'')
    	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspMSWDTransVal] TO [public]
GO
