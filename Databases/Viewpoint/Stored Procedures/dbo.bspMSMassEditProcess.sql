SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************************/
CREATE procedure [dbo].[bspMSMassEditProcess]
/****************************************************************
 * Created By:  GF 11/18/2000
 * Modified By: GG 01/23/01 - completed edit logic
 *              bc 09/28/01 - Issue # 14722
 *				 GF 05/01/02 - Issue #17143. Not getting all tickets using sale date range.
 *								Truck and TruckType not being nulled out if hauler type set to 'N'.
 *			GG 07/25/02 = #18092 - clear Haul Phase and Cost Type if Hauler Type set to 'N'
 *			GG 08/12/02 = #17811 - old/new template prices, pass @saledate to bspMSTicMatlVal
 *			GF 06/23/03 - #21575 - need to set return params to null before template get
 *			GF 10/05/2003 - #18672 - added PayTerms to MSQH, also output from bspMSTicTemplateGet
 *			GF 04/29/2004 - #24393 check DiscTax flag in ARCO before calculating tax discount
 *			GF 05/17/2004 - #24959 - too restrictive with where clause, haul code is not by haul type. moved outside haul type restriction
 *			GF 08/24/2004 - #25384 - for haul type ='H' truck is not required, do not skip as error if truck not set up.
 *			GF 11/24/2004 - #26300 - when haul type = 'E' and setting default haul basis, rate, rev basis, rate possible
 *							for rev basis, rate, total to return null. Only occurs when based on haul. Haul Code, UM not
 *							passed to revcode validation SP.
 *			GF 03/01/2005 - #19185 - material vendor enhancement, do not allow change for fromloc, material, um, units.
 *			GF 06/06/2005 - issue #28862 changing saletype from J or I to C, set @paytype = 'A' on account.
 *			GF 07/06/2005 - issue #29165 when setting UP to defaults, added quote phase pricing check.
 *				GF 03/03/2008 - issue #127261 - added output parameter HQPT.DiscOpt
 *			GP 04/29/2008 - #127970 Added output parameter @returnvendor where calling bspMSTicTruckVal
 *			DANSO 05/01/08 - #128127 - Added TaxCode to cursor filter
 *			GF 06/02/2008 - issue #128526 filter parameter for truck not used, using MSTD.Truck
 *			GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
 *			DAN SO 10/29/2008 - 130789 - Added output parameter @UpdateVendor where calling bspMSTicTruckVal
 *			DAN SO 11/10/2008 - 130957 - only use MatlMinAmt when number of units are > 0
 *			DAN SO 04/28/2009 - 133406 - Changed data type to bUnitCost for Haul Rate, Rev Rate, Pay Rate, Disc Rate to match DDFI & table datatype
 *			DAN SO 05/25/2009 - 133679 - Added input parameter @CurrentMode where calling bspMSTicTruckVal
 *			DAN SO 08/11/2009 - 135024 - Added @opthaulzone, @xhaulzone, and @haulzone
 *			DAN SO 01/21/2010 - Issue: #129350 - bspMSTicMatlVal has a new output parameter
 *			GF 03/21/2010 - issue #129350 surcharges the filter criteria applies for surcharges. But if for some reason
 *							we do not update a ticket that meets the filter criteria, then we need to still generate
 *							surcharges if flagged.
 *			DAN SO 10/17/2011 - D-03185 - Add support for TaxType - 1-Sales, 2-Use, 3-VAT
 *			GF 08/22/2012 TK-17309 flag when material total changes and re-calculate tax basis if needed
 *
 *
 * USAGE:
 * This procedure is called from the MS Mass Edit to process
 * changes to a MS Ticket Batch.
 *
 *
 *
 * INPUT PARAMETERS
 *  -- Filter criteria, values used to restrict batch entries for editing --
 *  @msco           MS Company
 *  @mth            Batch month
 *  @batchid        Batch ID#
 *  @fromsaledate   Beginning Sale Date
 *  @tosaledate     Ending Sale Date
 *  @fromloc        Sale From Location
 *  @material       Material
 *  @matlum         Material Unit of Measure
 *  @unitprice      Material Unit Price
 *  @ecm            Price per E/C/M
 *  @matlphase      Material JC Phase
 *  @matlct         Material JC Cost Type
 *  @taxcode        Tax Code
 *  @saletype       Sale Type (J/C/I)
 *  @customer       Customer #
 *  @custjob        Customer Job
 *  @custpo         Customer PO
 *  @hold           Hold (Y/N)
 *  @jcco           JC Company #
 *  @job            Job
 *  @inco           Sell To IN Company
 *  @toloc          Sell To Location
 *  @haultype       Hauler Type (E/H/N)
 *  @emco           EM Company #
 *  @equipment      Equipment
 *  @haulvendor     Haul Vendor #
 *  @truck          Truck #
 *  @haulcode       Haul Code
 *  @zone           Zone
 *  @haulphase      Haul JC Phase
 *  @haulct         Haul JC Cost Type
 *  @revcode        EM Revenue Code
 *  @paycode        Pay Code
 *
 *  -- Edit parameters, options are 0 = No change, 1 = Default, or 2 = Value (value supplied)
 *  @optsaledate    Sale Date option (0/2)
 *  @xsaledate      Sale Date value
 *  @optfromloc     From Location option (0/2)
 *  @xfromloc       From Location value
 *  @opttaxcode     Tax Code option (0/1/2)
 *  @xtaxcode       Tax Code value
 *  @opttaxbasis    Tax Basis option (0/1)
 *  @optdiscrate    Discount Rate option (0/1/2)
 *  @xdiscrate      Discount Rate value
 *  @optdiscbasis   Discount Basis option (0/1)
 *  @opttaxdisc     Tax Discount option (0/1)
 *  @optmaterial    Material option (0/2)
 *  @xmaterial      Material value
 *  @optum          Material Unit of Measure option (0/1/2)
 *  @xum            Material Unit of Measure value
 *  @optunits       Material Units (0/1)
 *  @optunitprice   Material Unit Price option (0/1/2)
 *  @xunitprice     Material Unit Price value
 *  @xecm           Unit Price per ECM value
 *  @optmatlphase   Material JC Phase option (0/1/2)
 *  @xmatlphase     Material JC Phase value
 *  @optmatlct      Material JC Cost Type (0/1/2)
 *  @xmatlct        Material JC Cost Type value
 *  @optsaletype    Sale Type option (0/2)
 *  @xsaletype      Sale Type value
 *  @optcustomer    Customer option (0/2)
 *  @xcustomer      Customer # value
 *  @opthold        Hold option (0/2)
 *  @xhold          Hold value
 *  @optcustjob     Customer Job option (0/2)
 *  @xcustjob       Customer Job value
 *  @optcustpo      Customer PO option (0/2)
 *  @xcustpo        Customer PO value
 *  @optjcco        JC Co# option (0/2)
 *  @xjcco          JC Co# value
 *  @optjob         Job option (0/2)
 *  @xjob           Job value
 *  @optinco        Sell To IN Co# option (0/2)
 *  @xinco          Sell To IN Co# value
 *  @opttoloc       Sell To Location option (0/2)
 *  @xtoloc         Sell To Location value
 *  @opthaultype    Hauler Type option (0/2)
 *  @xhaultype      Hauler Type value
 *  @optemco        EM Co# option (0/2)
 *  @xemco          EM Co# value
 *  @optequip       Equipment option (0/2)
 *  @xequipment     Equipment value
 *  @opthaulvendor  Haul Vendor option (0/2)
 *  @xhaulvendor    Haul Vendor value
 *  @opttruck       Truck option (0/2)
 *  @xtruck         Truck value
 *  @opthaulcode    Haul Code option (0/1/2)
 *  @xhaulcode      Haul Code value
 *  @opthaulbasis   Haul Basis option (0/1)
 *  @opthaulrate    Haul Rate option (0/1/2)
 *  @xhaulrate      Haul Rate value
 *  @opthaulphase   Haul JC Phase option (0/1/2)
 *  @xhaulphase     Haul JC Phase value
 *  @opthaulct      Haul JC Cost Type option (0/1/2)
 *  @xhaulct        Haul JC Cost Type value
 *  @optpaycode     Pay Code option (0/1/2)
 *  @xpaycode       Pay Code value
 *  @optpaybasis    Pay Basis option (0/1)
 *  @optpayrate     Pay Rate option (0/1/2)
 *  @xpayrate       Pay Rate value
 *  @optrevcode     EM Revenue Code option (0/2)
 *  @xrevcode       EM Revenue Code value
 *  @optrevbasis    EM Revenue Basis option (0/1)
 *  @optrevrate     EM Revenue Rate option (0/1/2)
 *  @xrevrate       EM Revenue Rate value
 *  @opthaulzone    Haul Zone option (0/2)
 *  @xhaulzone      Haul Zone value
 *  @chksurcharges	Re-create surcharges
 *	@opttaxtype		Tax Type Option (0/2)
 *	@xtaxtype		Tax Type Value (1-Sales,2-Use,3-VAT)
 *
 * OUTPUT PARAMETERS
 *  @msg            return message
 *
 * RETURN VALUE
 *   0              success
 *   1              fail
 ****************************************************************/
(@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @fromsaledate bDate = null,
 @tosaledate bDate = null, @zfromloc bLoc = null, @zmaterial bMatl = null, @zmatlum bUM = null,
 @zunitprice bUnitCost = null, @zecm bECM = null, @zmatlphase bPhase = null, @zmatlct bJCCType = null,
 @ztaxcode bTaxCode = null, @zsaletype varchar(1) = null, @zcustomer bCustomer = null,
 @zcustjob varchar(20) = null, @zcustpo varchar(20) = null, @zhold bYN = null, @zjcco bCompany = null,
 @zjob bJob = null, @zinco bCompany = null, @ztoloc bLoc = null, @zhaultype varchar(1) = null,
 @zemco bCompany = null, @zequipment bEquip = null, @zhaulvendor bVendor = null,
 @ztruck varchar(10) = null, @zhaulcode bHaulCode = null, @zzone varchar(10) = null,
 @zhaulphase bPhase = null, @zhaulct bJCCType = null, @zrevcode bRevCode = null, @zpaycode bPayCode = null,

 @optsaledate char(1) = null, @xsaledate bDate = null, @optfromloc char(1) = null, @xfromloc bLoc = null,
 @opttaxcode char(1) = null, @xtaxcode bTaxCode = null, @opttaxbasis char(1) = null, @optdiscrate char(1) = null,
 @xdiscrate bUnitCost = null, @optdiscbasis char(1) = null, @opttaxdisc char(1) = null, @optmaterial char(1) = null,
 @xmaterial bMatl = null, @optum char(1) = null, @xum bUM = null, @optunits char(1) = null,
 @optunitprice char(1) = null, @xunitprice bUnitCost = null, @xecm bECM = null, @optmatlphase char(1) = null,
 @xmatlphase bPhase = null, @optmatlct char(1) = null, @xmatlct bJCCType = null, @optsaletype char(1) = null,
 @xsaletype char(1) = null, @optcustomer char(1) = null, @xcustomer bCustomer = null, @opthold char(1) = null,

 @xhold char(1) = null, @optcustjob char(1) = null, @xcustjob varchar(20) = null, @optcustpo char(1) = null,
 @xcustpo varchar(20) = null, @optjcco char(1) = null, @xjcco bCompany = null, @optjob char(1) = null,
 @xjob bJob = null, @optinco char(1) = null, @xinco bCompany = null, @opttoloc char(1) = null,
 @xtoloc bLoc = null, @opthaultype char(1) = null, @xhaultype char(1) = null, @optemco char(1) = null,
 @xemco bCompany = null, @optequip char(1) = null, @xequipment bEquip = null, @opthaulvendor char(1) = null,

 @xhaulvendor bVendor = null, @opttruck char(1) = null, @xtruck varchar(10) = null, @opthaulcode char(1) = null,
 @xhaulcode bHaulCode = null, @opthaulbasis char(1) = null, @opthaulrate char(1) = null, @xhaulrate bUnitCost = null,
 @opthaulphase char(1) = null, @xhaulphase bPhase = null, @opthaulct char(1) = null, @xhaulct bJCCType = null,
 @optpaycode char(1) = null, @xpaycode bPayCode = null, @optpaybasis char(1) = null, @optpayrate char(1) = null,
 @xpayrate bUnitCost = null, @optrevcode char(1) = null, @xrevcode bRevCode = null, @optrevbasis char(1) = null,
 @optrevrate char(1) = null, @xrevrate bUnitCost = null, @opthaulzone char(1) = null, @xhaulzone varchar(10) = null,
 ----#129350
 @chksurcharges char(1) = 'N', 
 -- D-03185 --
@opttaxtype CHAR(1) = NULL, @xtaxtype tinyint = NULL,	
@msg varchar(2000) output)

as
set nocount on

declare @rcode int, @retcode int, @filtercount int, @changecount int, @errorcount int, @opencursor tinyint, @arco bCompany,
		@mscotaxopt tinyint, @status tinyint, @sql varchar(8000), @batchseq int, @saledate bDate, @vendorgroup bGroup,
		@matlvendor bVendor, @custgroup bGroup, @paytype char(1), @phasegroup bGroup, @matlgroup bGroup, @wghtum bUM,
		@matlunits bUnits, @matltotal bDollar, @matlcost bDollar, @driver bDesc, @emgroup bGroup, @prco bCompany,
		@employee bEmployee, @trucktype varchar(10), @loads smallint, @miles bUnits, @hours bHrs,
		@haulbasis bUnits, @haulrate bUnitCost, @haultotal bDollar, @haulzone varchar(10), @paybasis bUnits, @payrate bUnitCost,
		@paytotal bDollar, @revbasis bUnits, @revrate bUnitCost, @revtotal bDollar, @taxgroup bGroup, @taxtype tinyint,
		@taxbasis bDollar, @taxtotal bDollar, @discbasis bUnits, @discrate bUnitCost, @discoff bDollar,
		@taxdisc bDollar, @oldmsinv varchar(10), @oldapref bAPReference, @oldverify bYN, @rc int, @locgroup bGroup,
		@wghtopt tinyint, @fromloctaxcode bTaxCode, @fromlochaultaxopt tinyint, @quote varchar(10),
		@disctemplate smallint, @pricetemplate smallint, @dfltzone varchar(10), @haultaxopt tinyint,
		@purchasertaxcode bTaxCode, @payterms bPayTerms, @matldiscyn bYN, @hqptdiscrate bPct, @saveum bUM,
		@salesum bUM, @matldisctype char(1), @dfltdiscrate bUnitCost, @dfltmatlphase bPhase, @dfltmatlct bJCCType,
		@dflthaulphase bPhase, @dflthaulct bJCCType, @wghtumconv bUnitCost, @matlumconv bUnitCost, @matltaxable bYN,
		@dfltunitprice bUnitCost, @dfltecm bECM, @matlminamt bDollar, @dflthaulcode bHaulCode, @saveunits bUnits,
		@umconv bUnitCost, @stdum bUM, @saveunitprice bUnitCost, @saveecm bECM, @factor int, @dfltdriver bDesc,
		@dflttare bUnits, @truckwghtum bUM, @dflttrucktype varchar(10), @dfltpaycode bPayCode, @haulbasistype tinyint,
		@haultaxable bYN, @dflthaulrate bUnitCost, @haulminamt bDollar, @savehaulbasis bUnits, @savehaulrate bUnitCost,
		@dfltprco bCompany, @dfltemployee bEmployee, @dlfttare bUnits, @emcategory bCat, @dfltrevcode bRevCode,
		@dfltrevbasisamt bUnits, @dfltrevrate bDollar, @saverevrate bUnitCost, @dfltpayrate bUnitCost,
		@paybasistype tinyint, @savepaybasis bUnits, @savepayrate bUnitCost, @savetaxcode bTaxCode, @taxrate bRate,
		@savediscrate bUnitCost, @savediscbasis bUnits, @change char(1), @saverevbasis bUnits, @savetaxbasis bDollar,
		@savematlcost bDollar, @haulbased bYN, @oldmatlapref bAPReference, @priceopt tinyint, @custpriceopt tinyint,
		@jobpriceopt tinyint, @invpriceopt tinyint, @fromloc bLoc, @material bMatl, @matlum bUM, @unitprice bUnitCost,
		@ecm bECM, @matlphase bPhase, @matlct bJCCType, @taxcode bTaxCode, @saletype char(1), @customer bCustomer,
		@custjob varchar(20), @custpo varchar(20), @hold bYN, @jcco bCompany, @job bJob, @inco bCompany,
		@toloc bLoc, @haultype char(1), @emco bCompany, @equipment bEquip, @haulvendor bVendor, @truck varchar(10),
		@haulcode bHaulCode, @zone varchar(10), @haulphase bPhase, @haulct bJCCType, @revcode bRevCode, 
		@paycode bPayCode, @qmatldisc bYN, @qdiscrate bPct, @returnvendor bVendor, @UpdateVendor CHAR(1), @CurrentMode VARCHAR(10)

----TK-17309
DECLARE @MatlTotalChg CHAR(1)

select @rcode = 0, @filtercount=0, @changecount = 0, @errorcount = 0, @opencursor = 0

---- get info from MS Co#
select @arco = ARCo, @mscotaxopt = TaxOpt from bMSCO with (nolock) where MSCo = @msco
if @@rowcount = 0
	begin
	select @msg = 'Invalid MS Company #', @rcode = 1
	goto bspexit
	end

---- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @msco, @mth, @batchid, 'MS Tickets', 'MSTB', @msg output, @status output
if @rcode <> 0
	begin
	select @rcode = 1
	goto bspexit
	end
if @status <> 0
	begin
	select @msg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
	goto bspexit
	end

---- create cursor on MSTB to update tickets
declare bcMSTB cursor for select BatchSeq,SaleDate,FromLoc,VendorGroup,MatlVendor,SaleType,
		CustGroup,Customer,CustJob,CustPO,PaymentType,Hold,JCCo,Job,PhaseGroup,INCo,ToLoc,
		MatlGroup,Material,UM,MatlPhase,MatlJCCType,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,
		MatlCost,HaulerType,HaulVendor,Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,
		TruckType,Loads,Miles,Hours,Zone,HaulCode,HaulPhase,HaulJCCType,HaulBasis,HaulRate,
		HaulTotal,PayCode,PayBasis,PayRate,PayTotal,RevCode,RevBasis,RevRate,RevTotal,TaxGroup,
		TaxCode,TaxType,TaxBasis,TaxTotal,DiscBasis,DiscRate,DiscOff,TaxDisc,
		OldMSInv,OldAPRef,OldVerifyHaul,OldMatlAPRef
from MSTB where Co=@msco and Mth=@mth and BatchId=@batchid
and BatchTransType <> 'D' and Void = 'N' ---- skip deleted and voided tickets

---- open cursor
open bcMSTB
select @opencursor = 1

---- loop through all rows in MSTB cursor and update their info.
edit_loop:
fetch next from bcMSTB into @batchseq,@saledate,@fromloc,@vendorgroup, @matlvendor,@saletype,@custgroup,
		@customer,@custjob,@custpo,@paytype,@hold,@jcco,@job,@phasegroup,@inco,@toloc,@matlgroup,@material,
		@matlum,@matlphase,@matlct,@wghtum,@matlunits,@unitprice,@ecm,@matltotal,@matlcost,@haultype,@haulvendor,
		@truck,@driver,@emco,@equipment,@emgroup,@prco,@employee,@trucktype,@loads,@miles,@hours,@zone,@haulcode,
		@haulphase,@haulct,@haulbasis,@haulrate,@haultotal,@paycode,@paybasis,@payrate,@paytotal,@revcode,
		@revbasis,@revrate,@revtotal,@taxgroup,@taxcode,@taxtype,@taxbasis,@taxtotal,@discbasis,@discrate,
		@discoff,@taxdisc,@oldmsinv,@oldapref,@oldverify,@oldmatlapref

if @@fetch_status <> 0 goto edit_end

----TK-17309
SET @MatlTotalChg = 'N'

-- check filter parameters to restrict MSTB rows
IF isnull(@ztaxcode,'') <> ''
	begin
	IF @taxcode <> @ztaxcode GOTO edit_loop
	end
if isnull(@fromsaledate,'') <> ''
	begin
	if @saledate < @fromsaledate goto edit_loop
	end
if isnull(@tosaledate,'') <> ''
	begin
	if @saledate > @tosaledate goto edit_loop
	end
if isnull(@zfromloc,'') <> ''
	begin
	if @fromloc <> @zfromloc goto edit_loop
	end
if isnull(@zmaterial,'') <> ''
	begin
	if @material <> @zmaterial goto edit_loop
	end
if isnull(@zmatlum,'') <> ''
	begin
	if @matlum <> @zmatlum goto edit_loop
	end
if isnull(@zunitprice,-99.99999) <> -99.99999
	begin
	if @unitprice <> @zunitprice goto edit_loop
	if @ecm <> @zecm goto edit_loop
	end
if isnull(@zmatlphase,'') <> ''
	begin
	if @matlphase <> @zmatlphase goto edit_loop
	end
if isnull(@zmatlct,'') <> ''
	begin
	if @matlct <> @zmatlct goto edit_loop
	end

if isnull(@zsaletype,'') <> ''
	begin
	if @saletype <> @zsaletype goto edit_loop
	---- check customer info
	if @zsaletype = 'C'
		begin
		if isnull(@zcustomer,'') <> ''
			begin
			if @customer <> @zcustomer goto edit_loop
			end
		if isnull(@zcustjob,'') <> ''
			begin
			if @custjob <> @zcustjob goto edit_loop
			end
		if isnull(@zcustpo,'') <> ''
			begin
			if @custpo <> @zcustpo goto edit_loop
			end
		if isnull(@zhold,'') <> ''
			begin
			if @hold <> @zhold goto edit_loop
			end
		end
	---- check job info
	if @zsaletype = 'J'
		begin
		if isnull(@zjcco,'') <> ''
			begin
			if @jcco <> @zjcco goto edit_loop
			end
		if isnull(@zjob,'') <> ''
			begin
			if @job <> @zjob goto edit_loop
			end
		end
	---- check inventory info
	if @zsaletype = 'I'
		begin
		if isnull(@zinco,'') <> ''
			begin
			if @inco <> @zinco goto edit_loop
			end
		if isnull(@ztoloc,'') <> ''
			begin
			if @toloc <> @ztoloc goto edit_loop
			end
		end
	end

if isnull(@zhaultype,'') <> ''
	begin
	if @haultype <> @zhaultype goto edit_loop
	---- check equipment info
	if @zhaultype = 'E'
		begin
		if isnull(@zemco,'') <> ''
			begin
			if @emco <> @zemco goto edit_loop
			end
		if isnull(@zequipment,'') <> ''
			begin
			if @equipment <> @zequipment goto edit_loop
			end
		if isnull(@zrevcode,'') <> ''
			begin
			if @revcode <> @zrevcode goto edit_loop
			end
		end
	---- check hauler info
	if @zhaultype = 'H'
		begin
		if isnull(@zhaulvendor,'') <> ''
			begin
			if @haulvendor <> @zhaulvendor goto edit_loop
			end
		if isnull(@ztruck,'') <> ''
			begin
			if @truck <> @ztruck goto edit_loop
			end
		if isnull(@zpaycode,'') <> ''
			begin
			if @paycode <> @zpaycode goto edit_loop
			end
		end
	end

---- issue #24595 moved outside haul type restriction
if isnull(@zhaulcode,'') <> ''
	begin
	if @haulcode <> @zhaulcode goto edit_loop
	end
if isnull(@zzone,'') <> ''
	begin
	if @zone <> @zzone goto edit_loop
	end
if isnull(@zhaulphase,'') <> ''
	begin
	if @haulphase <> @zhaulphase goto edit_loop
	end
if isnull(@zhaulct,'') <> ''
	begin
	if @haulct <> @zhaulct goto edit_loop
	end

---- start ticket change process
select @filtercount = @filtercount + 1, @change = 'N'  ---- # of entries meeting filter criteria and change flag

---- Sales Date
if @optsaledate = 2 and @oldmsinv is null and @oldapref is null and isnull(@oldverify,'N') = 'N'
	begin
	select @saledate = @xsaledate, @change = 'Y'
	end

---- From Location
if @optfromloc = 2 and @oldmsinv is null and @oldapref is null and @oldmatlapref is null and isnull(@oldverify,'N') = 'N'
	begin
	select @fromloc = @xfromloc, @change = 'Y'
	end

---- get default info based on From Location
exec @rc = dbo.bspMSTicFromLocVal @msco, @fromloc,'Y', @locgroup output,
             @wghtopt output, @fromloctaxcode output, @fromlochaultaxopt output, @msg output
if @rc <> 0
	begin
	select @errorcount = @errorcount + 1
	goto edit_loop
	end
    
select @wghtum = case @wghtopt when 1 then 'LBS' when 2 then 'TON' when 3 then 'kg' else null end
    
---- Sale Type
if @optsaletype = 2 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
	begin
	select @saletype = @xsaletype, @change = 'Y'
	if @saletype <> 'J'
		begin
		select @jcco = null, @job = null, @phasegroup = null, @matlphase = null,
				@matlct = null, @haulphase = null, @haulct = null
		end
	if @saletype <> 'C'
		begin
		select @customer = null, @custjob = null, @custpo = null, @paytype = null,
   				@hold = 'N', @discrate = 0, @discbasis = 0, @taxdisc = 0
		end
	if @saletype <> 'I'
		begin
		select @inco = null, @toloc = null
		end
	---- issue #28862
	if @saletype = 'C' and @paytype is null
		begin
		select @paytype = 'A'
		end
	end

---- Customer
if @optcustomer = 2 and @oldmsinv is null
	begin
	select @customer = @xcustomer, @change = 'Y'
	select @custgroup = CustGroup from bHQCO where HQCo = @arco
	end
---- Customer Job
	if @optcustjob = 2 and @oldmsinv is null
             select @custjob = @xcustjob, @change = 'Y'
---- Customer PO
if @optcustpo = 2 and @oldmsinv is null
             select @custpo = @xcustpo, @change = 'Y'
---- Hold
if @opthold = 2 and @oldmsinv is null
             select @hold = @xhold, @change = 'Y'

---- JC Co#
if @optjcco = 2 and @saletype = 'J' and @oldmsinv is null -- check for interco invoice
	begin
	select @jcco = @xjcco, @change = 'Y'
	select @phasegroup = PhaseGroup from bHQCO where HQCo = @jcco
	end
---- Job
if @optjob = 2 and @saletype = 'J' and @oldmsinv is null
             select @job = @xjob, @change = 'Y'

---- IN Co#
if @optinco = 2 and @saletype = 'I' and @oldmsinv is null -- check for interco invoice
             select @inco = @xinco, @change = 'Y'
---- To Location
if @opttoloc = 2 and @saletype = 'I' and @oldmsinv is null
             select @toloc = @xtoloc, @change = 'Y'

set @payterms = null
---- get default info based on purchaser
select @quote = null, @disctemplate = null, @pricetemplate = null, @dfltzone = null, @haultaxopt = null, @purchasertaxcode = null
exec @rc = dbo.bspMSTicTemplateGet @msco, @saletype, @custgroup, @customer, @custjob, @custpo,
             @jcco, @job, @inco, @toloc, @fromloc, @quote output, @disctemplate output, @pricetemplate output,
             @dfltzone output, @haultaxopt output, @purchasertaxcode output, @payterms output,
			 @qmatldisc output, @qdiscrate output, null, @msg output
if @rc <> 0
	begin
	select @errorcount = @errorcount + 1
	goto edit_loop
	end

---- get Customer Pay Terms, used for discount default
set @matldiscyn = null
if @saletype = 'C' and @payterms is not null
	begin
	---- select @payterms = PayTerms from bARCM where CustGroup = @custgroup and Customer = @customer
	---- if @payterms is not null
	select @matldiscyn = MatlDisc, @hqptdiscrate = DiscRate from bHQPT with (nolock) where PayTerms = @payterms
	end

---- Material
if @optmaterial = 2 and @oldmsinv is null and @oldapref is null and @oldmatlapref is null
             select @material = @xmaterial, @change = 'Y'
---- U/M
select @saveum = @matlum    -- save material u/m, to be used with units change
if @optum = 1 and @oldmsinv is null and @oldmatlapref is null
	begin
	---- get default sales u/m
	select @matlum = SalesUM from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
	select @change = 'Y'
	end
if @optum = 2 and @oldmsinv is null and @oldmatlapref is null
             select @matlum = @xum, @change = 'Y'

---- get defaults info based on purchaser and material
exec @rc = dbo.bspMSTicMatlVal @msco, 'Y', @matlgroup, @material, @matlvendor, @fromloc, @saletype,
             @inco, @toloc, @locgroup, @phasegroup, @quote, @disctemplate, @pricetemplate, @wghtum, @matlum,
             @custgroup, @customer, @jcco, @job, @saledate, @salesum output, @matldisctype output, @dfltdiscrate output,
             @dfltmatlphase output, @dfltmatlct output, @dflthaulphase output, @dflthaulct output, @wghtumconv output,
             @matlumconv output, @matltaxable output, @dfltunitprice output, @dfltecm output, @matlminamt output,
             @dflthaulcode output, NULL, @msg = @msg output	-- ISSUE: #129350
if @rc <> 0
	begin
	select @errorcount = @errorcount + 1
	goto edit_loop
	end

---- issue #29165
---- get material unit price defaults. Needed now for pricing by quote phase
---- get IN company pricing options
select @custpriceopt=CustPriceOpt, @jobpriceopt=JobPriceOpt, @invpriceopt=InvPriceOpt
from bINCO with (nolock) where INCo=@msco
if @@rowcount = 0
	begin
	select @errorcount = @errorcount + 1
	goto edit_loop
	end

if @saletype = 'J' select @priceopt = @jobpriceopt
if @saletype = 'C' select @priceopt = @custpriceopt
if @saletype = 'I' select @priceopt = @invpriceopt
exec @retcode = dbo.bspMSTicMatlPriceGet @msco,@matlgroup,@material,@locgroup,@fromloc,@matlum,
   				@quote,@pricetemplate,@saledate,@jcco,@job,@custgroup,@customer,@inco,@toloc,@priceopt,
   				@saletype, @phasegroup, @matlphase, @matlvendor, @vendorgroup,
				@dfltunitprice output, @dfltecm output, @matlminamt output, @msg = @msg output
if @retcode <> 0
	begin
	select @dfltunitprice = 0, @dfltecm = 'E', @matlminamt = 0
	end

---- Matl Units - only recalculated if U/M has changed
select @saveunits = @matlunits      -- save material units
if @optunits = 1 and @oldmsinv is null and @oldmatlapref is null and isnull(@paytype,'A') not in ('C','X')
	begin
	select @umconv = 0
	---- get conversion factors if U/M has changed
	if isnull(@saveum,'') <> isnull(@matlum,'')
		begin
		select @stdum = StdUM from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material  -- use new matl
		if isnull(@stdum,'') = isnull(@saveum,'')
                     select @umconv = 1
		else
			begin
			select @umconv = Conversion
			from bINMU with (nolock) 
			where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @saveum
			if @@rowcount = 0
				begin
				select @umconv = Conversion
				from bHQMU with (nolock) 
				where MatlGroup = @matlgroup and Material = @material and UM = @saveum
				end
			end
		---- convert to std units under saved u/m
		if @umconv <> 0 and @matlumconv <> 0
                     select @matlunits = (@matlunits * @umconv) / @matlumconv, @change = 'Y'
		end
	end

---- Unit Price
select @saveunitprice = @unitprice, @saveecm = @ecm     -- save unit price and ecm
if @optunitprice = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
             select @unitprice = @dfltunitprice, @ecm = @dfltecm, @change = 'Y'
if @optunitprice = 2 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
             select @unitprice = @xunitprice, @ecm = @xecm, @change = 'Y'

---- Material Total - recalculated if eligible and units or unit price has changed
if @oldmsinv is null and isnull(@paytype,'A') not in ('C','X') and (@saveunits <> @matlunits
             or @saveunitprice <> @unitprice or @saveecm <> @ecm)
	begin
	select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
	select @matltotal = (@matlunits * @unitprice) / @factor
	----TK-17309
	SET @MatlTotalChg = 'Y'
	
		-- ISSUE: #130957 --
		IF @matlunits > 0 
			BEGIN
				if @matltotal < @matlminamt select @matltotal = @matlminamt
			END
	end

---- Material Cost - always recalculated
select @savematlcost = @matlcost
exec @rc = dbo.bspMSTicMatlCostGet @msco, @fromloc, @matlgroup, @material, @matlum,
             @matlunits, @matlcost output, @msg output
if @rc <> 0
	begin
	select @errorcount = @errorcount + 1
	goto edit_loop
	end
if isnull(@savematlcost,0) <> isnull(@matlcost,0) select @change = 'Y'

---- Matl/Haul Phase and Cost Type
if @saletype = 'J' and @oldmsinv is null  -- check for interco invoice
	begin
	if @optmatlphase = 1
                 select @matlphase = @dfltmatlphase, @change = 'Y'
	if @optmatlphase = 2
                 select @matlphase = @xmatlphase, @change = 'Y'
	if @optmatlct = 1
                 select @matlct = @dfltmatlct, @change = 'Y'
	if @optmatlct = 2
                 select @matlct = @xmatlct, @change = 'Y'
	if @opthaulphase = 1
                 select @haulphase = @dflthaulphase, @change = 'Y'
	if @opthaulphase = 2
                 select @haulphase = @xhaulphase, @change = 'Y'
	if @opthaulct = 1
                 select @haulct = @dflthaulct, @change = 'Y'
	if @opthaulct = 2
                 select @haulct = @xhaulct, @change = 'Y'
	end

---- Hauler Type
if @opthaultype = 2 and @oldmsinv is null and @oldapref is null and isnull(@oldverify,'N') = 'N'
             select @haultype = @xhaultype, @change = 'Y'

if @haultype <> 'E'
	begin
	select @emco = null, @equipment = null, @emgroup = null, @prco = null, @employee = null,
    			@revcode = null, @revbasis = 0, @revrate = 0, @revtotal = 0
	end
if @haultype <> 'H'
	begin
	select @haulvendor = null, @truck=null, @driver = null, @paycode = null, @paybasis = 0,
    			@payrate = 0, @paytotal = 0
	end
	
if @haultype = 'N'
	begin
	select @haulcode = null, @haulbasis = 0, @haulrate = 0, @haulzone = null, @haultotal = 0, @trucktype = null,
    			@haulphase = null, @haulct = null	-- #18092
	end
ELSE
	--ISSUE: #135024
	BEGIN
		IF @opthaulzone = 0 SELECT @haulzone = @zone, @change = 'Y'
		IF @opthaulzone = 2 SELECT @haulzone = @xhaulzone, @change = 'Y'
	END

if @haultype = 'E'
	begin
	---- EM Co#
	if @optemco = 2 and @oldapref is null and isnull(@oldverify,'N') = 'N'
		begin
		select @emco = @xemco, @change = 'Y'
		---- get EM Group
		select @emgroup = EMGroup from bHQCO with (nolock) where HQCo = @emco
		if @@rowcount = 0
			begin
			select @errorcount = @errorcount + 1
			goto edit_loop
			end
		end
	---- Equipment
	if @optequip = 2 and @oldapref is null and isnull(@oldverify,'N') = 'N'
                 select @equipment = @xequipment, @change = 'Y'
	end

if @haultype = 'H'
	begin
	---- Haul Vendor
	if @opthaulvendor = 2 and @oldapref is null and isnull(@oldverify,'N') = 'N'
                 select @haulvendor = @xhaulvendor, @change = 'Y'
	---- Truck
	if @opttruck = 2 and isnull(@oldverify,'N') = 'N'
                 select @truck = @xtruck, @change = 'Y'
	---- get Truck default info
	if @truck is not null
		begin
		exec @rc = dbo.bspMSTicTruckVal @vendorgroup, @haulvendor, @truck, @CurrentMode,
				@dfltdriver output, @dflttare output, @truckwghtum output, @dflttrucktype output, 
				@dfltpaycode output, @returnvendor output, @UpdateVendor output, @msg output
		---- a valid truck is no longer required, do not record error if truck not set up. issue #25384
		---- if @rc <> 0
----			begin
----			select @errorcount = @errorcount + 1
----			goto edit_loop
----			end
		end
	end

---- Haul Code
if @opthaulcode = 1 and @oldmsinv is null
             select @haulcode = @dflthaulcode, @change = 'Y'
if @opthaulcode = 2 and @oldmsinv is null
             select @haulcode = @xhaulcode, @change = 'Y'

if @haulcode is null select @haulbasis = 0, @haulrate = 0, @haultotal = 0



---- get Haul Code default info
if @haulcode is not null
	begin
	if @opthaulzone = 2 set @zone = @haulzone
	exec @rc = dbo.bspMSTicHaulCodeVal @msco, @haulcode, @matlgroup, @material, @locgroup, @fromloc,
                 @quote, @matlum, @trucktype, @zone, @haulbasistype output, @haultaxable output, @dflthaulrate output,
                 @haulminamt output, @msg = @msg output
	if @rc <> 0
		begin
		select @errorcount = @errorcount + 1
		goto edit_loop
		end
	---- Haul Basis
	select @savehaulbasis = @haulbasis      -- save Haul Basis
	if @opthaulbasis = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
		begin
		select @haulbasis = 0, @change = 'Y'
		if @haulbasistype in (1,4,5) select @haulbasis = @matlunits
		if @haulbasistype = 2 select @haulbasis = @hours
		if @haulbasistype = 3 select @haulbasis = @loads
		end
	---- Haul Rate
	select @savehaulrate = @haulrate    -- save Haul Rate
	if @opthaulrate = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
                 select @haulrate = @dflthaulrate, @change = 'Y'
	if @opthaulrate = 2 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
                 select @haulrate = @xhaulrate, @change = 'Y'
	---- Haul Total, recalculated if eligible and haul basis or rate has changed
	if @oldmsinv is null and isnull(@paytype,'A') not in ('C','X') and
                 (isnull(@savehaulbasis,0) <> isnull(@haulbasis,0) or isnull(@savehaulrate,0) <> isnull(@haulrate,0))
                 select @haultotal = @haulbasis * @haulrate
	end

---- get Equipment default info
if @equipment is not null
	begin
	exec @rc = dbo.bspMSTicEquipVal @emco, @equipment, @dfltprco output, @dfltemployee output,
                 @dflttare output, @truckwghtum output, @emcategory output, @dflttrucktype output,
                 @dfltrevcode output, @msg output
	if @rc <> 0
		begin
		select @errorcount = @errorcount + 1
		goto edit_loop
		end
	---- Revenue Code
	if @optrevcode = 1 and @oldapref is null
                 select @revcode = @dfltrevcode, @change = 'Y'
	if @optrevcode = 2 and @oldapref is null
                 select @revcode = @xrevcode, @change = 'Y'

	if @revcode is null select @revbasis = 0, @revrate = 0, @revtotal = 0

	---- get Revenue Code default info
	if @revcode is not null
		begin
		exec @rc = dbo.bspMSTicRevCodeVal @msco, @emco, @emgroup, @revcode, @equipment, @emcategory,
                     @jcco, @job, @matlgroup, @material, @fromloc, @matlunits, @matlumconv, @hours, 
   				  @dfltrevbasisamt output, @dfltrevrate output, null, null, null,
   				  @haulcode, @haulbased output, @matlum, null, @msg = @msg output
		if @rc <> 0
			begin
			select @errorcount = @errorcount + 1
			goto edit_loop
			end

	---- Revenue Basis
	select @saverevbasis = @revbasis    -- save Revenue Basis
	if @optrevbasis = 1 and @oldapref is null
                     select @revbasis = @dfltrevbasisamt, @change = 'Y'
	---- Revenue Rate
	select @saverevrate = @revrate      -- save Revenue Rate
	if @optrevrate = 1 and @oldapref is null
		begin
		select @revrate = @dfltrevrate, @change = 'Y'
		if @haulbased = 'Y'
   					select @revrate = @haulrate, @change = 'Y'
		end
	if @optrevrate = 2 and @oldapref is null
		select @revrate = @xrevrate, @change = 'Y'
		---- Revenue Total - recalculated if eligible and haul basis or rate has changed
		if @oldapref is null and (isnull(@saverevbasis,0) <> isnull(@revbasis,0)
                     or isnull(@saverevrate,0) <> isnull(@revrate,0))  select @revtotal = @revbasis * @revrate
		end
	end

---- Pay Code
if @optpaycode = 1 and @oldapref is null
	select @paycode = @dfltpaycode, @change = 'Y'
if @optpaycode = 2 and @oldapref is null
             select @paycode = @xpaycode, @change = 'Y'
    
if @paycode is null select @paybasis = 0, @payrate = 0, @paytotal = 0
---- get Pay Code default info
if @paycode is not null
	begin
	if @opthaulzone = 2 set @zone = @haulzone
	exec @rc = dbo.bspMSTicPayCodeVal @msco, @paycode, @matlgroup, @material, @locgroup, @fromloc,
                 @quote, @trucktype, @vendorgroup, @haulvendor, @truck, @matlum, @zone, @dfltpayrate output,
                 @paybasistype output, @msg = @msg output
	if @rc <> 0
		begin
		select @errorcount = @errorcount + 1
		goto edit_loop
		end
	---- Pay Basis
	select @savepaybasis = @paybasis      -- save Pay Basis
	if @optpaybasis = 1 and @oldapref is null
		begin
		select @paybasis = 0, @change = 'Y'
		if @paybasistype in (1,4,5) select @paybasis = @matlunits
		if @paybasistype = 2 select @paybasis = @hours
		if @paybasistype = 3 select @paybasis = @loads
		if @paybasistype = 6 select @paybasis = @haultotal
		end
	---- Pay Rate
	select @savepayrate = @payrate      -- save Pay Rate
	if @optpayrate = 1 and @oldapref is null
                 select @payrate = @dfltpayrate, @change = 'Y'
	if @optpayrate = 2 and @oldapref is null
                 select @payrate = @xpayrate, @change = 'Y'
	---- Pay Total - recalculated if eligible and pay basis or rate has changed
	if @oldapref is null and (isnull(@savepaybasis,0) <> isnull(@paybasis,0)
                 or isnull(@savepayrate,0) <> isnull(@payrate,0)) select @paytotal = @paybasis * @payrate
	end

---- Tax Code
select @savetaxcode = @taxcode      -- save Tax Code
if @opttaxcode = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
	begin
	if @mscotaxopt = 1 select @taxcode = @fromloctaxcode
	if @mscotaxopt in (2,3) select @taxcode = @purchasertaxcode
	if @mscotaxopt = 3 and @taxcode is null select @taxcode = @fromloctaxcode
	if @mscotaxopt = 4 and @haulcode is null select @taxcode = @fromloctaxcode
	if @mscotaxopt = 4 and @haulcode is not null select @taxcode = @purchasertaxcode
	select @change = 'Y'
	end

if @opttaxcode = 2 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
             select @taxcode = @xtaxcode, @change = 'Y'

-- D-03185 --
if @opttaxtype = 2
	set @taxtype = @xtaxtype

if @taxcode is null select @taxbasis = 0, @taxtotal = 0, @taxtype = null, @taxrate = 0


---- get Tax Code default info
if @taxcode is not null
	begin
	exec @rc = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @saledate, @taxrate output, @msg = @msg output
	if @rc <> 0
		begin
		select @errorcount = @errorcount + 1
		goto edit_loop
		end
	---- Tax Basis
	select @savetaxbasis = @taxbasis
	----TK-17309
	if @MatlTotalChg = 'Y' OR (@opttaxbasis = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X'))
		begin
		select @taxbasis = 0
		if @matltaxable = 'Y' select @taxbasis = @taxbasis + @matltotal
		if @haultaxable = 'Y' select @taxbasis = @taxbasis + @haultotal
		select @change = 'Y'
		end
	---- Tax Total - recalculated if eligible and tax basis or rate has changed
	if @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
                 and (isnull(@savetaxcode,'') <> isnull(@taxcode,'') or isnull(@savetaxbasis,0) <> isnull(@taxbasis,0))
                 select @taxtotal = @taxbasis * @taxrate
	end

---- Discount Rate
select @savediscrate = @discrate
if @optdiscrate = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
	begin
	select @discrate = 0, @change = 'Y'
	if @matldiscyn = 'N' select @discrate = @hqptdiscrate   -- Payment Terms rate
	if @matldiscyn = 'Y' select @discrate = @dfltdiscrate
	end

if @optdiscrate = 2 and @matldiscyn is not null and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
             select @discrate = @xdiscrate, @change = 'Y'

---- Discount Basis
select @savediscbasis = @discbasis
if @optdiscbasis = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
	begin
	select @discbasis = 0, @change = 'Y'
	if @matldiscyn = 'N' select @discbasis = @matltotal + @haultotal    -- discount based on ticket total
	if @matldiscyn = 'Y'    -- material based discount
		begin
		if @matldisctype = 'U' select @discbasis = @matlunits
		if @matldisctype = 'R' select @discbasis = @matltotal
		end
	end

---- Discount Total - recalculated if eligible and discount basis or rate has changed
if @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
             and (isnull(@savediscbasis,0) <> isnull(@discbasis,0) or isnull(@savediscrate,0) <> isnull(@discrate,0))
             select @discoff = @discbasis * @discrate

---- Tax Discount
if @opttaxdisc = 1 and @oldmsinv is null and isnull(@paytype,'A') not in ('C','X')
	begin
	---- calculate only when DiscTax flag is 'Y' for AR Company #24393
	if exists(select * from bARCO where ARCo=@arco and DiscTax= 'Y')
		begin
		select @taxdisc = @taxrate * @discoff, @change = 'Y'
		end
		end

if @change = 'Y'
	begin
	update bMSTB
		set SaleDate = @saledate,FromLoc = @fromloc,SaleType = @saletype,CustGroup = @custgroup,
			Customer = @customer,CustJob = @custjob,CustPO = @custpo,PaymentType = @paytype,
			Hold = @hold,JCCo = @jcco,Job = @job,PhaseGroup = @phasegroup,INCo = @inco,
			ToLoc = @toloc,Material = @material, UM = @matlum, MatlPhase = @matlphase, MatlJCCType = @matlct,
			WghtUM = @wghtum,MatlUnits = @matlunits,UnitPrice = @unitprice,ECM = @ecm,MatlTotal = @matltotal,
			MatlCost = @matlcost,HaulerType = @haultype, HaulVendor = @haulvendor, Truck = @truck,
			Driver = @driver, EMCo = @emco, Equipment = @equipment, EMGroup = @emgroup, PRCo = @prco,
			Employee = @employee, HaulCode = @haulcode, HaulPhase = @haulphase, HaulJCCType = @haulct,
			HaulBasis = @haulbasis, HaulRate = @haulrate, HaulTotal = @haultotal, Zone = @haulzone, PayCode = @paycode,
			PayBasis = @paybasis, PayRate = @payrate, PayTotal = @paytotal, RevCode = @revcode,
			RevBasis = @revbasis, RevRate = @revrate, RevTotal = @revtotal, TaxGroup = @taxgroup,
			TaxCode = @taxcode, TaxType = @taxtype, TaxBasis = @taxbasis, TaxTotal = @taxtotal,
			DiscBasis = @discbasis, DiscRate = @discrate, DiscOff = @discoff, TaxDisc = @taxdisc,
			TruckType = @trucktype
	where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	if @@rowcount <> 1
		begin
		select @msg = 'Unable to update batch entry!', @rcode = 1
		goto bspexit
		end
    
	select @changecount = @changecount + 1
	end


/*****************************************************
* we need to drop and re-add surcharges when checked
* for MSTB records that have not been changed already
* #129350
******************************************************/
---- if we have updated MSTB then the surcharge records if any were dropped and re-added so we are done
if @change = 'Y' goto edit_loop

---- check option
if isnull(@chksurcharges,'N') = 'N' goto edit_loop

---- do not do if cash sale
if isnull(@paytype,'A') <> 'A' goto edit_loop

---- update the changed flag which will force update trigger to fire
update bMSTB set Changed = 'N'
where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

select @changecount = @changecount + 1

goto edit_loop




edit_end:
select @msg = 'Editing complete. ' + char(13) + convert(varchar(6),@filtercount) + ' entries met the '
select @msg = @msg + 'filtering criteria. ' + char(13) + convert(varchar(6),@changecount)
select @msg = @msg + ' entries successfully changed. ' + char(13) + convert(varchar(6),@errorcount)
select @msg = @msg + ' entries skipped because of invalid values.'


goto bspexit


bspexit:
	if @opencursor = 1
		begin
		close bcMSTB
		deallocate bcMSTB
		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSMassEditProcess] TO [public]
GO
