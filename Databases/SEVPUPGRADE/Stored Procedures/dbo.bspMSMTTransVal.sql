SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE      procedure [dbo].[bspMSMTTransVal]
/***********************************************************
 * Created By:	GF 02/18/2005
 * Modified By:	GF 06/07/2005 - issue #28900 missing customer group from MSTD for calculations.
 *				GF 08/04/2005 - issue #29479 changed from hauler invoice to material invoice in messages.
 *								Also loosened up validation for customer, Job, and ToLoc to allow for null values.
 *				GF 10/20/2005 - issue #30113 - for SaleType 'J', 'I' tax option is sometimes null, check and set to zero
 *				GF 10/29/2007 - issue #122769 - allow tickets with zero units to be added.
 *				GF 12/18/2007 - issue #126509 for tickets with zero units, set total cost = material total.
 *				GP 06/25/2008 - issue #127986 added null input in place of @quote, @phasegroup & @matlphase 
 *									for call to bspMSMatlPayUnitCostGet
 *				gf 07/15/2008 - issue #128458 international GST/PST
 *
 *
 *
 * Called from the MS Material Vendor Worksheet form to validate a MSTrans
 * and return Material Vendor payment related info.
 *
   *
   * INPUT PARAMETERS
   *   @co                 MS Co#
   *   @mth                Batch Month
   *   @batchid		    Batch ID
   *	@xmstransmth		MS transaction month to validate
   *   @xmstrans           MSTrans to validate
   *   @xvendorgroup       Vendor Group restriction
   *   @xvendor            Material Vendor
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
   *   @matlgroup          Material Group
   *   @material           Material
   *   @um					UM
   *   @matlunits			Material Units
   *   @unitprice			Unit Price
   *   @pecm				Price ECM
   *	@unitcost			Unit Cost
   *	@ecm				Cost ECM
   *	@totalcost			Total Cost
   *	@taxcode			Tax Code
   *	@taxbasis			Tax Basis
   *	@taxtotal			Tax Total
   *	@fromloc			From Location
*		@taxtype			Tax Type
   *
   *
   *	@msg                Material description or error message if error occurs
   *
   * RETURN VALUE
   *   0               success
   *   1               fail
 *****************************************************/
 (@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @xmstransmth bMonth = null, 
  @xmstrans bTrans = null, @xvendorgroup bGroup = null, @xvendor bVendor = null, @xcustgroup bGroup = null,
  @xcustomer bCustomer = null, @xcustjob varchar(20) = null, @xjcco bCompany = null, @xjob bJob = null,
  @xsaletype varchar(1) = 'N', @xinco bCompany = null, @xtoloc bLoc = null, @apco bCompany = null,
  @taxgroup bGroup = null, @costoption tinyint = null, @taxoption tinyint = null, @adjusttax bYN = 'N',
  @ticket varchar(10) output, @saledate bDate output, @matlgroup bGroup output, @material bMatl output,
  @um bUM output, @matlunits bUnits output, @unitprice bUnitCost output, @pecm bECM output,
  @unitcost bUnitCost output, @ecm bECM output, @totalcost bDollar output, @taxcode bTaxCode output,
  @taxbasis bDollar output, @taxamt bDollar output, @fromloc bLoc output, @taxable bYN output,
  @actualunitcost bUnitCost output, @taxtype tinyint output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255), @vendorgroup bGroup, @matlvendor bVendor, 
   		@matlapref bAPReference, @void char(1), @inusebatchid bBatchID, @saletype varchar(1),
   		@custgroup bGroup, @customer bCustomer, @custjob varchar(20), @jcco bCompany, @job bJob,
   		@inco bCompany, @toloc bLoc, @matltotal bDollar

select @rcode = 0

if @taxoption is null select @taxoption = 0

if @xvendorgroup is null or @xvendor is null
	begin
	select @msg = 'Missing Vendor Group and/or Material Vendor!', @rcode = 1
	goto bspexit
	end

---- get MSTD detail
select @ticket = Ticket, @saledate = SaleDate, @vendorgroup = VendorGroup, @matlgroup = MatlGroup,
   		@material = Material, @matlvendor = MatlVendor, @saletype = SaleType, @custgroup=CustGroup, @customer = Customer,
   		@custjob = CustJob, @jcco = JCCo, @job = Job, @inco = INCo, @toloc = ToLoc,
   		@matlapref = MatlAPRef, @void = Void, @inusebatchid = InUseBatchId, @um = UM,
   		@matlunits = MatlUnits, @unitprice = UnitPrice, @pecm = ECM, @fromloc = FromLoc,
		@matltotal = MatlTotal, @taxtype = TaxType
from bMSTD with (Nolock) 
where MSCo = @co and Mth = @xmstransmth and MSTrans = @xmstrans
if @@rowcount = 0
       begin
       select @msg = 'Invalid MS Transaction', @rcode = 1
       goto bspexit
       end

---- check restrictions
if @xvendorgroup <> @vendorgroup
       begin
       select @msg = 'Invalid, Transaction has different Vendor Group.', @rcode = 1
       goto bspexit
       end
   
   if @xvendor <> @matlvendor
       begin
       select @msg = 'Invalid, Transaction posted to Material Vendor ' + convert(varchar(8),isnull(@matlvendor,'')), @rcode = 1
       goto bspexit
       end
   
   if @void = 'Y'
       begin
       select @msg = 'Invalid, Transaction is voided.', @rcode = 1
       goto bspexit
       end
   
   if @matlapref is not null
       begin
       select @msg = 'Invalid, Transaction is on AP Reference ' + isnull(@matlapref,''), @rcode = 1
       goto bspexit
       end
   
   if isnull(@inusebatchid,@batchid) <> @batchid	-- check for use by another batch
       begin
       select @msg = 'Invalid, Transaction is in use by batch ' + isnull(convert(varchar(10), @inusebatchid),''), @rcode = 1
       goto bspexit
       end
   
---- get material description
select @msg=Description, @taxable=Taxable
from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0 
 	begin
 	select @msg = 'Material not on file', @taxable = 'N'
 	end

if @xsaletype <> 'N' and @xsaletype <> @saletype
	begin
	select @msg = 'The MSTrans sale type: ' + isnull(@saletype,'') + ' is different from the material invoice sales type restriction.', @rcode = 1
	goto bspexit
	end

if @xsaletype = 'C'
	begin
	-- -- -- #29479
	if @customer <> isnull(@xcustomer,@customer)
		begin
		select @msg = 'Invalid MS Trans, Customer: ' + isnull(convert(varchar(10),@customer),'') + ' assigned to MS Trans differs from Material Invoice.', @rcode = 1
		goto bspexit
		end
	if isnull(@custjob,'') <> isnull(@xcustjob,'')
		begin
		select @msg = 'Invalid MS Trans, Customer: ' + isnull(convert(varchar(10),@customer),'') + ' - Customer Job: ' + isnull(@custjob,'') + ' assigned to MS Trans differs from Material Invoice.', @rcode = 1
		goto bspexit
		end
	end
   
   
if @xsaletype = 'J'
	begin
	-- -- -- issue #29479
	if @jcco <> isnull(@xjcco,@jcco) or @job <> isnull(@xjob,@job)
		begin
		select @msg = 'Invalid MS Trans, JCCo: ' + isnull(convert(varchar(3),@jcco),'') + ' - Job: ' + isnull(@job,'') + ' assigned to MS Trans differs from Material Invoice.', @rcode = 1
		goto bspexit
		end
	end
   
   
if @xsaletype = 'I'
	begin
	if @inco <> isnull(@xinco,@inco) or @toloc <> isnull(@xtoloc,@toloc)
		begin
		select @msg = 'Invalid MS Trans, INCo: ' + isnull(convert(varchar(3),@inco),'') + ' - Sell To Location: ' + isnull(@toloc,'') + ' assigned to MS Trans differs from Material Invoice.', @rcode = 1
		goto bspexit
		end
	end


-- -- -- get tax group
select @taxgroup = TaxGroup
from bHQCO with (nolock) where HQCo=@apco
if @@rowcount = 0 set @taxgroup = null
   
-- -- -- call material vendor payment unit cost get SP to return MSMT values
-- -- -- this SP is shared with msterial vendor payment detail manuall adding
-- -- -- of transactions. So if need to change, do in both SP's. Parameters
-- -- -- are slightly different depending on sale type.
if @saletype = 'C'
exec @retcode = dbo.bspMSMatlPayUnitCostGet @co, @apco, @taxgroup, @costoption, @taxoption,
				@adjusttax, @vendorgroup, @matlvendor, @matlgroup, @material, @um, @taxable,
				@saletype, @saledate, @fromloc, @custgroup, @customer, null, null, null, null,
				@matlunits, @unitprice, @pecm, null, null, null, @unitcost output, @ecm output, @totalcost output,
				@taxcode output, @taxbasis output, @taxamt output, @actualunitcost output, @errmsg output

if @saletype = 'J'
exec @retcode = dbo.bspMSMatlPayUnitCostGet @co, @apco, @taxgroup, @costoption, @taxoption,
				@adjusttax, @vendorgroup, @matlvendor, @matlgroup, @material, @um, @taxable,
				@saletype, @saledate, @fromloc, null, null, @jcco, @job, null, null,
				@matlunits, @unitprice, @pecm, null, null, null, @unitcost output, @ecm output, @totalcost output,
				@taxcode output, @taxbasis output, @taxamt output, @actualunitcost output, @errmsg output

if @saletype = 'I'
exec @retcode = dbo.bspMSMatlPayUnitCostGet @co, @apco, @taxgroup, @costoption, @taxoption,
				@adjusttax, @vendorgroup, @matlvendor, @matlgroup, @material, @um, @taxable,
				@saletype, @saledate, @fromloc, null, null, null, null, @inco, @toloc,
				@matlunits, @unitprice, @pecm, null, null, null, @unitcost output, @ecm output, @totalcost output,
				@taxcode output, @taxbasis output, @taxamt output, @actualunitcost output, @errmsg output

if @retcode <> 0
	begin
	select @unitcost = 0, @ecm = 'E', @totalcost = 0, @taxcode = null,
			@taxbasis = 0, @taxamt = 0, @taxtype = null
	end

---- #126509 when zero material units set @totalcost = @materialtotal
if @matlunits = 0
	begin
	select @unitcost = 0, @ecm = 'E', @totalcost = @matltotal
	end




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSMTTransVal] TO [public]
GO
