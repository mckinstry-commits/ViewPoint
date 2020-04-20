SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE procedure [dbo].[bspMSMatlPayUnitCostGet]
/***********************************************************
   * Created By:	GF 02/25/2005
   * Modified By:	GF 05/13/2005 - issue #28685 changed how adjust for tax is handled.
   *				GP 06/23/2008 - Issue #127986 - added input for @quote, @phasegroup & @matlphase and check for 
   *									@costoption = 4, by Material Vendor.
   *
   *
   *
   *
   * Called from the MS Material Vendor Payment Initialization stored procedure
   * and from MS Material Vendor Payment MS Trans validation store procedure
   * to get unit cost, total cost, tax code, tax basis, and tax amount.
   *
   * No tax type in MSMT, only sales taxes allowed. The tax group will come
   * from the AP Company passed in as a parameter.
   *
   *
   * INPUT PARAMETERS
   *   @msco               MS Co#
   *   @apco               AP Co#
   *   @taxgroup           AP Tax Group
   *   @costoption         Cost Option
   *	@taxoption			Tax Option
   *   @adjusttax          Adjust Tax Flag
   *   @vendorgroup		Vendor Group
   *   @vendor				Matl Vendor
   *	@matlgroup			Material group
   *	@material			Material
   *	@um					Material UM
   *	@taxable			Material taxable flag
   *	@saletype			MS Sale Type
   *	@saledate			MS Sale Date
   *	@fromloc			MS From location
   *	@custgroup			Customer Group
   *	@customer			Customer
   *	@jcco				JC Co#
   *	@job				JC Job
   *	@inco				IN Company
   *	@toloc				IN Sell to Location
   *	@matlunits			MS Units Sold
   *   @unitprice			MS Unit price
   *   @pecm				MS Unit price ecm
   *	@quote				MS Quote
   *	@phasegroup			MS PhaseGroup
   *	@matlphase			MS MatlPhase
   *
   *
   * OUTPUT PARAMETERS
   *	@unitcost			Unit Cost
   *	@ecm				Unit Cost ECM
   *	@totalcost			Total Cost
   *	@taxcode			Tax code
   *	@taxbasis			Tax Basis
   *	@taxamt				Tax Amount
   *	@actualunitcost		Actual Unit Cost before adjusted for tax
   *
   *
   * OUTPUT PARAMETERS
   *   @msg            success or error message
   *
   * RETURN VALUE
   *   0               success
   *   1               fail
   *****************************************************/
(@msco bCompany, @apco bCompany, @taxgroup bGroup, @costoption tinyint, @taxoption tinyint,
 @adjusttax bYN, @vendorgroup bGroup, @matlvendor bVendor, @matlgroup bGroup, @material bMatl,
 @um bUM, @taxable bYN, @saletype varchar(1), @saledate bDate, @fromloc bLoc, @custgroup bGroup,
 @customer bCustomer, @jcco bCompany, @job bJob, @inco bCompany, @toloc bLoc, @matlunits bUnits,
 @unitprice bUnitCost, @pecm bECM, @quote varchar(10) = null, @phasegroup bGroup = null,
 @matlphase bPhase = null, @unitcost bUnitCost output, @ecm bECM output,
 @totalcost bDollar output, @taxcode bTaxCode output, @taxbasis bDollar output,
 @taxamt bDollar output, @actualunitcost bUnitCost output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255), @arcm_taxcode bTaxCode, @from_taxcode bTaxCode,
   		@jcjm_taxcode bTaxCode, @basetaxon varchar(1), @to_taxcode bTaxCode, @factor smallint,
   		@povm_unitcost bUnitCost, @povm_ecm bECM, @lastunitcost bUnitCost, @lastecm bECM,
   		@taxrate bRate, @new_unitcost float

select @rcode = 0

---- get tax code for sold from location
select @from_taxcode=TaxCode
from bINLM with (nolock) where INCo=@msco and Loc=@fromloc
if @@rowcount = 0 or isnull(@from_taxcode,'') = ''
	begin
   	select @from_taxcode = null
	end

---- get tax code from ARCM if customer sale
if @saletype = 'C'
   	begin
   	select @arcm_taxcode = TaxCode
   	from bARCM where CustGroup=@custgroup and Customer=@customer
   	if @@rowcount = 0 or isnull(@arcm_taxcode,'') = ''
		begin
   		select @arcm_taxcode = null
		end
   	end

---- get tax code from JCJM if job sale
---- consider base tax on option in JCJM
if @saletype = 'J'
   	begin
   	select @basetaxon=BaseTaxOn, @jcjm_taxcode=TaxCode
   	from bJCJM where JCCo=@jcco and Job=@job
   	if @basetaxon = 'V'
   		begin
   		select @jcjm_taxcode = TaxCode
   		from bAPVM where VendorGroup=@vendorgroup and Vendor=@matlvendor
   		end
   	if isnull(@jcjm_taxcode,'') = '' set @jcjm_taxcode = null
   	end

---- get tax code from INLM for to location if inventory sale
if @saletype = 'I'
   	begin
   	---- get tax code for sold to location
   	select @to_taxcode = TaxCode
   	from bINLM where INCo=@inco and Loc=@toloc
   	if @@rowcount = 0 or isnull(@to_taxcode,'') = ''
		begin
   		select @to_taxcode = null
		end
   	end

---- set unit cost based on cost option. Options are: 0 - none,
---- 1 - MS ticket sales price, 2 - PO Vendor Materials, 3 - Inventory Last cost.
if @costoption = 0
	begin
   	select @unitcost = 0, @ecm = 'E'
	end

if @costoption = 1
	begin
   	select @unitcost = @unitprice, @ecm = @pecm
	end

if @costoption = 2
   	begin
   	---- customer sale
   	if @saletype = 'C'
   		exec @retcode = dbo.bspHQMatUnitCostDflt @vendorgroup, @matlvendor, @matlgroup, @material, @um,
   					null, null, null, null, @povm_unitcost output, @povm_ecm output, null, @errmsg output
   	---- job sale
   	if @saletype = 'J'
   		exec @retcode = dbo.bspHQMatUnitCostDflt @vendorgroup, @matlvendor, @matlgroup, @material, @um,
   					@jcco, @job, null, null, @povm_unitcost output, @povm_ecm output, null, @errmsg output
   	---- inventory sale
   	if @saletype = 'I'
   		exec @retcode = dbo.bspHQMatUnitCostDflt @vendorgroup, @matlvendor, @matlgroup, @material, @um,
   					null, null, @inco, @toloc, @povm_unitcost output, @povm_ecm output, null, @errmsg output
   	if @retcode <> 0
		begin
   		select @unitcost = 0, @ecm = 'E'
		end
   	else
		begin
   		select @unitcost = @povm_unitcost, @ecm = @povm_ecm
		end
   	---- check for nulls
   	if @unitcost is null set @unitcost = 0
   	if @ecm is null set @ecm = 'E'
   	end

if @costoption = 3
   	begin
   	select @lastunitcost=LastCost, @lastecm=LastECM
   	from bINMU with (nolock) where INCo=@msco and Loc=@fromloc
   	and MatlGroup=@matlgroup and Material=@material and UM=@um
   	if @@rowcount = 0
   		begin
   		select @lastunitcost=LastCost, @lastecm=LastECM
   		from bINMT with (nolock) where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   		if @@rowcount = 0
			begin
   			select @lastunitcost = 0, @lastecm = 'E'
			end
   		end
   	select @unitcost = @lastunitcost, @ecm = @lastecm
   	end


-- Issue 127986
IF @costoption = 4
BEGIN

	-- With PhaseGroup and Phase
	SELECT @unitcost = UnitCost, @ecm = ECM
	FROM bMSQD with(nolock)
	WHERE MSCo = @msco and Quote = @quote and FromLoc = @fromloc and MatlGroup = @matlgroup 
		and Material = @material and UM = @um and PhaseGroup = @phasegroup and Phase = @matlphase 
		and MatlVendor = @matlvendor

	-- Without PhaseGroup and Phase
   	SELECT @unitcost=UnitCost, @ecm=ECM
   	FROM bMSQD with(nolock) 
	WHERE MSCo = @msco and Quote = @quote and FromLoc = @fromloc and MatlGroup = @matlgroup 
		and Material = @material and UM = @um and MatlVendor=@matlvendor

	-- Default
	IF @unitcost is null and @ecm is null
	BEGIN
		SELECT @unitcost = 0, @ecm = 'E'
	END

END

			
---- tax options: 0 - tax exempt, 1 - sold to customer/job/location, 2 - sold from location
---- material must be taxable, if not calculate cost and exit
if @taxoption = 0 or @taxable = 'N'
   	begin
   	select @actualunitcost = @unitcost
   	-- -- -- calculate total cost
   	select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   	select @totalcost = (@matlunits * @unitcost) / @factor
   	-- -- -- calculate tax basis and amount
   	select @taxcode = null, @taxbasis = 0, @taxamt = 0
   	if @totalcost is null set @totalcost = 0
   	goto bspexit
   	end


if @taxoption = 1
	begin
   	if @saletype = 'C' select @taxcode = @arcm_taxcode
   	if @saletype = 'J' select @taxcode = @jcjm_taxcode
   	if @saletype = 'I' select @taxcode = @to_taxcode
	end

if @taxoption = 2
	begin
   	select @taxcode = @from_taxcode
	end

---- get tax rate for tax code
if @taxcode is not null
   	begin
   	exec @retcode = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @saledate, @taxrate output, null, null, @errmsg output
   	if @retcode <> 0 select @taxrate = 0
   	end
else
   	begin
   	select @taxrate = 0
   	end


---- if missing tax code, then no tax just cost
if isnull(@taxcode,'') = ''
   	begin
   	---- calculate total cost
   	select @actualunitcost = @unitcost
   	select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   	select @totalcost = (@matlunits * @unitcost) / @factor
   	---- calculate tax basis and amount
   	select @taxbasis = 0, @taxamt = 0
   	goto bspexit
   	end

---- adjust unit cost for sales tax
if @adjusttax <> 'Y'
   	begin
   	select @actualunitcost = @unitcost
   	-- -- -- calculate total cost
   	select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   	select @totalcost = (@matlunits * @unitcost) / @factor
   	-- -- -- calculate tax basis and amount
   	select @taxbasis = @totalcost, @taxamt = (@taxbasis * @taxrate)
   	end
else
   	begin
   	select @actualunitcost = @unitcost
   	select @new_unitcost = @unitcost / (1+@taxrate)
   	select @unitcost = @new_unitcost
   	-- -- -- calculate total cost
   	select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   	select @totalcost = (@matlunits * @unitcost) / @factor
   	select @taxbasis = @totalcost, @taxamt = (@taxbasis * @taxrate)
   	end


if @unitcost is null set @unitcost = 0
if @totalcost is null set @totalcost = 0



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSMatlPayUnitCostGet] TO [public]
GO
