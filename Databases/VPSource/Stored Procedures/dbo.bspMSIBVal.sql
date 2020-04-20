
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************************/
CREATE  procedure [dbo].[bspMSIBVal]
/***********************************************************
* CREATED BY: GG 11/18/00
* MODIFIED By :GG 01/09/01 - fixed ARFields
*              GF 01/19/2001 - another fix to ARFields
*              GF 05/11/2001 - fix for null misc distribution code
*              GG 07/03/01 - add hierarchal Quote search  - #13888
*				GG 02/07/02 - #14177 - AR auto payments
*				GF 03/21/2003 - issue #20798 - added validation for active location and material
*				GF 06/26/2003 - #21682 added with nolock to select statements
*				GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
*				GG 02/02/04 - #20538 - split GL units flag
*				GF 02/24/2003 - #23824 - need to check GLSaleFlag whether there is a @matlvendor for
*								update units to GL account.
*				GF 06/14/2004 - #24820 - not converting to std units correctly. Need to use temp var for row count
*				GF 04/05/2005 - issue #27601 - validate AR TaxGroup to MSTD TaxGroup must be same
*				GF 05/08/2007 - issue #124383 added error checking for unit price more than 12 char when AR Interface level 3
*				GF 07/07/2008 - issue #128290 MS International tax enhancement
*				MV 02/04/10 - issue #136500 - bspHQTaxRateGetAll added NULL output param
*				GF 04/01/2010 - issue #129350 surcharges
*				GF 05/16/2011 - issue #143485 surcharge with no haul 'N' use sales account
*				ERICV 06/14/11 - Issue 142792 Added check for null GL accounts: @salesglacct, @lmcustsurrevoutglacct, @lmcustsurrevequipglacct
*				MV 10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*				GF 08/15/2012 TK-17081 validation for own/outside haul sales account depending on hauler type.
*				GF 08/17/2012 TK-17283 added tax group and tax code for hauler MSAR transaction
*				GF 03/25/2013 TFS-44951 backed out TK-17283. Need to redo that issue.
*
*
* USAGE:
* Called from MS Batch Process form to validate an Invoice batch.
* Adds distribution entries in bMSAR for AR Lines, bMSIG for GL,
* and bMSMX for AR Misc Distributions.
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco          MS Co#
*   @mth           Batch Month
*   @batchid       Batch ID
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN VALUE
*   0              success
*   1              fail
*****************************************************/
@msco bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
as
set nocount on
   
declare @rcode int, @errorstart varchar(30), @errortext varchar(255), @status tinyint, @msglco bCompany,
		@jrnl bJrnl, @arco bCompany, @arglco bCompany, @openMSIBcursor tinyint, @seq int, @msinv varchar(10),
		@custgroup bGroup, @customer bCustomer, @custjob varchar(20), @custpo varchar(20), @description bDesc,
		@paymenttype char(1), @rectype tinyint, @payterms bPayTerms, @invdate bDate, @applytoinv varchar(10),
		@intercoinv bYN, @interfaced bYN, @void bYN, @msihmth bMonth, @msihcustgroup bGroup, @msihcustomer bCustomer,
		@msihcustjob varchar(20), @msihcustpo varchar(20), @msihpaymenttype char(1), @msihrectype tinyint,
		@msihinvdate bDate, @msihapplytoinv varchar(10), @msihintercoinv bYN, @msihinusebatchid bBatchID,
		@msihvoid bYN, @arstatus char(1), @ardistcode varchar(10), @misconinv bYN, @recglacct bGLAcct, @armth bMonth,
		@artrans bTrans, @openMSIDcursor tinyint, @mstrans bTrans, @fromloc bLoc, @matlvendor bVendor, @matlgroup bGroup,
		@material bMatl, @matlum bUM, @matlunits bUnits, @unitprice bUnitCost, @ecm char(1), @matltotal bDollar,
		@haultype char(1), @haultotal bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar,
		@taxtotal bDollar, @discoff bDollar, @taxdisc bDollar, @matlcategory varchar(10), @stdum bUM, @glunits bYN,
		@umconv bUnitCost, @stkunits bUnits, @losalesglacct bGLAcct, @loqtyglacct bGLAcct, @lmsalesglacct bGLAcct,
		@lmqtyglacct bGLAcct, @lohaulrevequipglacct bGLAcct, @lohaulrevoutglacct bGLAcct, @lmhaulrevequipglacct bGLAcct,
		@lmhaulrevoutglacct bGLAcct, @salesglacct bGLAcct, @qtyglacct bGLAcct, @arfields varchar(125), @glco bCompany,
		@arglacct bGLAcct, @apglacct bGLAcct, @gltotal bDollar, @msdistcode varchar(10), @miscdistcode varchar(10),
		@haulrevglacct bGLAcct, @taxglacct bGLAcct, @arinterfacelvl tinyint, @arrectype tinyint, @autoapply bYN,
		@cmco bCompany, @cmacct bCMAcct, @msihcmco bCompany, @msihcmacct bCMAcct, @cmglacct bGLAcct, @cmglco bCompany,
		@discdate bDate, @msihdiscdate bDate, @ardiscglacct bGLAcct, @lmdiscglacct bGLAcct, @discglacct bGLAcct,
		@validcnt int, @artaxgroup bGroup,
		----International Sales Tax
		@taxrate bRate, @gstrate bRate, @pstrate bRate, @valueadd varchar(1), @saledate bDate,
		@HQTXcrdGLAcct bGLAcct, @oldHQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct, @oldHQTXcrdGLAcctPST bGLAcct, 
		@TaxAmount bDollar, @TaxAmountPST bDollar, @oldTaxAmount bDollar, @oldTaxAmountPST bDollar,
		---- #129350
		@SurchargeKeyID bigint, @SurchargeCode varchar(10),
		@lmcustsurrevequipglacct bGLAcct, @lmcustsurrevoutglacct bGLAcct, @surchargerevglacct bGLAcct
		---- #129350



set @rcode = 0


---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @msco, @mth, @batchid, 'MS Invoice', 'MSIB', @errmsg output, @status output
if @rcode <> 0 goto bspexit
if @status < 0 or @status > 3
	begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	end
    
---- set HQ Batch status to 1 (validation in progress)
update bHQBC set Status = 1
where Co = @msco and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end

---- clear HQ Batch Errors
delete bHQBE where Co = @msco and Mth = @mth and BatchId = @batchid

---- clear AR, GL, and AR Misc distribution entries
delete bMSAR where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSIG where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSMX where MSCo = @msco and Mth = @mth and BatchId = @batchid

---- get Company info from MS Company
select @msglco = GLCo, @jrnl = Jrnl, @arco = ARCo,
	   @arinterfacelvl = ARInterfaceLvl, @autoapply = AutoApplyCash
from bMSCO with (nolock) where MSCo = @msco
if @@rowcount = 0
	begin
    select @errmsg = 'Invalid MS Company #' + convert(varchar(3),isnull(@msco,'')), @rcode = 1
    goto bspexit
    end
---- validate Month in MS GL Co# - subledgers must be open
exec @rcode = bspHQBatchMonthVal @msglco, @mth, 'MS', @errmsg output
if @rcode <> 0 goto bspexit

---- validate Journal
if not exists(select top 1 1 from bGLJR with (nolock) where GLCo = @msglco and Jrnl = @jrnl)
	begin
    select @errmsg = 'Invalid Journal ' + isnull(@jrnl,'') + ' assigned in MS Company!', @rcode = 1
    goto bspexit
    end
    
---- validate AR Co#
select @arglco = GLCo from bARCO with (nolock) where ARCo = @arco
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid AR Company #' + convert(varchar(3),isnull(@arco,'')), @rcode = 1
	goto bspexit
	end

---- get AR Company Tax Group from HQ
select @artaxgroup = TaxGroup from bHQCO with (nolock) where HQCo=@arco
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to get HQ information for AR Company #' + convert(varchar(3),isnull(@arco,'')), @rcode = 1
	goto bspexit
	end

---- validate Month in AR GL Co# - subledgers must be open
if @arglco <> @msglco
	begin
	exec @rcode = bspHQBatchMonthVal @arglco, @mth, 'AR', @errmsg output
	if @rcode <> 0 goto bspexit
	---- validate Journal
	if not exists(select top 1 1 from bGLJR with (nolock) where GLCo = @arglco and Jrnl = @jrnl)
		begin
    	select @errmsg = 'Journal ' + isnull(@jrnl,'') + ' is invalid in AR GL Company!', @rcode = 1
    	goto bspexit
    	end
	end
    
---- declare cursor on MS Invoice Batch Header for validation
declare bcMSIB cursor LOCAL FAST_FORWARD for
select BatchSeq, MSInv, CustGroup, Customer, CustJob, CustPO, Description,
		PaymentType, RecType, PayTerms, InvDate, DiscDate, ApplyToInv, InterCoInv,
		Interfaced, Void, CMCo, CMAcct
from bMSIB with (nolock)
where Co = @msco and Mth = @mth and BatchId = @batchid

-- open cursor
open bcMSIB

-- set open cursor flag to true
select @openMSIBcursor = 1

MSIB_loop:
fetch next from bcMSIB into @seq, @msinv, @custgroup, @customer, @custjob, @custpo, @description,
			@paymenttype, @rectype, @payterms, @invdate, @discdate, @applytoinv, @intercoinv,
			@interfaced, @void, @cmco, @cmacct

if @@fetch_status <> 0 goto MSIB_end

---- save Batch Sequence # for any errors that may be found
select @errorstart = 'Seq#' + convert(varchar(6),@seq)

-- validate Invoice #
if @interfaced = 'Y' or @void = 'Y' -- previously interfaced or to be voided
	begin
	select @msihmth = Mth, @msihcustgroup = CustGroup, @msihcustomer = Customer, @msihcustjob = CustJob,
			@msihcustpo = CustPO, @msihpaymenttype = PaymentType, @msihrectype = RecType, @msihinvdate = InvDate,
			@msihdiscdate = DiscDate, @msihapplytoinv = ApplyToInv, @msihintercoinv = InterCoInv,
			@msihinusebatchid = InUseBatchId, @msihvoid = Void, @msihcmco = CMCo, @msihcmacct = CMAcct
	from bMSIH with (nolock) 
	where MSCo = @msco and MSInv = @msinv
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' -  Invalid Invoice #.'
		goto MSIB_error
		end
		
	if @msihvoid = 'Y'
		begin
		select @errortext = @errorstart + ' - Invoice already voided.'
		goto MSIB_error
		end
		
	if isnull(@msihinusebatchid,0) <> @batchid
		begin
		select @errortext = @errorstart + ' - Existing Invoice is not locked by this batch.'
		goto MSIB_error
		end
		
	if @msihmth <> @mth
		begin
		select @errortext = @errorstart + ' - Existing Invoice was posted in another month.'
		goto MSIB_error
		end
		
	if @msihcustgroup <> @custgroup or @msihcustomer <> @customer or isnull(@msihcustjob,'') <> isnull(@custjob,'')
			or isnull(@msihcustpo,'') <> isnull(@custpo,'') or @msihpaymenttype <> @paymenttype
			or @msihrectype <> @rectype or @msihinvdate <> @invdate or isnull(@msihdiscdate,'') <> isnull(@discdate,'')
			or isnull(@msihapplytoinv,'') <> isnull(@applytoinv,'') or @msihintercoinv <> @intercoinv
			or isnull(@msihcmco,0) <> isnull(@cmco,0) or isnull(@msihcmacct,0) <> isnull(@cmacct,0)
		begin
		select @errortext = @errorstart + ' - Batch header information does not match existing Invoice header.'
		goto MSIB_error
		end
	end

---- if already Interfaced and not being Voided (reprint only), skip remaining validation and distributions
if @interfaced = 'Y' and @void = 'N' goto MSIB_loop
    
---- validate Customer
select @arstatus = Status, @ardistcode = MiscDistCode, @misconinv = MiscOnInv
from bARCM with (nolock) 
where CustGroup = @custgroup and Customer = @customer
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid Customer.'
	goto MSIB_error
	end
if @arstatus = 'I'
	begin
	select @errortext = @errorstart + ' - Inactive Customer.'
	goto MSIB_error
	end
	
---- validate Payment Type
if @paymenttype not in ('A','C','X')
	begin
	select @errortext = @errorstart + ' - Invalid Payment Type, must be A, C, or X.'
	goto MSIB_error
	end
	
if @paymenttype = 'C' and @autoapply = 'Y'
	begin
	---- validate CM Co# and CM Account
	select @cmglco = GLCo, @cmglacct = GLAcct
	from bCMAC with (nolock) where CMCo = @cmco and CMAcct = @cmacct
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid CM Co# and Account, valid values needed to apply payment.'
		goto MSIB_error
		end
	
	---- validate Month in CM GL Co# - subledgers must be open
	if @cmglco not in (@msglco, @arglco)
		begin
		exec @rcode = bspHQBatchMonthVal @cmglco, @mth, 'CM', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - ' + @errmsg
			goto MSIB_error
			end
			
		---- validate Journal
		if not exists(select top 1 1 from bGLJR with (nolock) where GLCo = @cmglco and Jrnl = @jrnl)
			begin
			select @errortext = @errorstart + ' - Journal ' + isnull(@jrnl,'') + ' is invalid in CM GL Company!'
			goto MSIB_error
			end
		end
	end

if (@paymenttype <> 'C' or @autoapply = 'N') and (@cmco is not null or @cmacct is not null)
	begin
	select @errortext = @errorstart + ' - CM Co# and CM Account must be null.'
	goto MSIB_error
	end
	
---- validate Receivable Type
select @recglacct = GLARAcct, @ardiscglacct = GLDiscountAcct
from bARRT with (nolock) where ARCo = @arco and RecType = @rectype
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid Receivable Type.'
	goto MSIB_error
	end
	
---- validate Payment Terms
if @payterms is not null
	begin
	if not exists(select top 1 1 from bHQPT with (nolock) where PayTerms = @payterms)
		begin
		select @errortext = @errorstart + ' - Invalid Payment Terms.'
		goto MSIB_error
		end
	end

---- validate Discount Date 
if @discdate is null and (select sum(d.DiscOff) from bMSID i with (nolock)
		join bMSTD d with (nolock) on i.Co = d.MSCo and i.Mth = d.Mth and i.MSTrans = d.MSTrans
		where i.Co = @msco and i.Mth = @mth and i.BatchId = @batchid and i.BatchSeq = @seq) <> 0
	begin
	select @errortext = @errorstart + ' - Discount Date is required when discount is offered.'
	goto MSIB_error
	end

---- validate Apply To Invoice
if @applytoinv is not null
	begin
	---- get first transaction with matching info
	select @armth = null
	select top 1 @armth = Mth, @artrans = ARTrans, @arrectype = RecType
	from bARTH with (nolock) 
	where ARCo = @arco and ARTransType = 'I' and CustGroup = @custgroup
	and Customer = @customer and Invoice = @applytoinv
	order by Mth, ARTrans
	
	if @armth is null
		begin
		select @errortext = @errorstart + ' - Apply To Invoice for the Customer does not exist in AR.'
		goto MSIB_error
		end
		
	if @arrectype <> @rectype
		begin
		select @errortext = @errorstart + ' - Apply To Invoice posted to a different Receivable Type.'
		goto MSIB_error
		end
	end

---- declare cursor on MS Invoice Batch Detail for validation and distributions
declare bcMSID cursor LOCAL FAST_FORWARD 
for select MSTrans
from bMSID with (nolock) where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

---- open cursor
open bcMSID

---- set open cursor flag to true
select @openMSIDcursor = 1

MSID_loop:
fetch next from bcMSID into @mstrans

if @@fetch_status <> 0 goto MSID_end

---- add MS Trans# to error message
select @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Trans#' + convert(varchar(8),@mstrans)

---- validate Trans# and get info for distributions
select @fromloc = FromLoc, @matlvendor = MatlVendor, @custjob = CustJob, @custpo = CustPO,
		@matlgroup = MatlGroup, @material = Material, @matlum = UM, @matlunits = MatlUnits,
		@unitprice = UnitPrice, @ecm = ECM, @matltotal = MatlTotal, @haultype = HaulerType,
		@haultotal = HaulTotal, @taxgroup = TaxGroup, @taxcode = TaxCode, @taxtype = TaxType,
		@taxbasis = TaxBasis, @taxtotal = TaxTotal, @discoff = DiscOff, @taxdisc = TaxDisc,
		@saledate = SaleDate,
		----#129350
		@SurchargeKeyID = SurchargeKeyID, @SurchargeCode = SurchargeCode
		----#129350
from dbo.bMSTD with (nolock) where MSCo = @msco and Mth = @mth and MSTrans = @mstrans
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid or missing MS Transaction#.'
	goto MSID_error
	end

---- Invoice Detail already validated via triggers on bMSID
---- issue #27601 - validate AR TaxGroup to MSTD TaxGroup must be same
if isnull(@taxcode,'') <> ''
	begin
	if @artaxgroup <> @taxgroup
		begin
		select @errortext = @errorstart + ' - MS Ticket Tax Group: ' + isnull(convert(varchar(3),@taxgroup),'') + ' must match AR Tax Group: ' + isnull(convert(varchar(3),@artaxgroup),'') + '.'
		goto MSID_error
		end
	end

---- if Invoice to be voided, reverse signs on units and dollars
if @void = 'Y'
	begin
	select @matlunits = -@matlunits, @matltotal = -@matltotal, @haultotal = -@haultotal,
		   @taxbasis = -@taxbasis, @taxtotal = -@taxtotal, @discoff = -@discoff,
		   @taxdisc = -@taxdisc
	end

---- validate Material - changed per issue #20798
select @matlcategory = Category, @stdum = StdUM
from dbo.bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material and Active = 'Y'
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid Material, ' + isnull(@material,'') + ' must be setup in HQ and active!'
	goto MSID_error
	end
    
---- get GL units update flag from IN Materials - issue #20798 - issue #23824
select @glunits = 'N', @umconv = 1
if /*@matlvendor is null and*/ @matlunits <> 0
	begin
	---- get stocked material info
	select @glunits = GLSaleUnits from bINMT with (nolock) 
	where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and Active = 'Y'
	---- #24820
	select @validcnt = @@rowcount
	if @validcnt = 0 and @matlvendor is null
		begin
		select @errortext = @errorstart + ' - Invalid Material, ' + isnull(@material,'') + ' at From Location, must be active!'
		goto MSID_error
		end

	---- get material conversion factor
	if @validcnt <> 0 and @matlum <> @stdum
		begin
		select @umconv = Conversion from bINMU with (nolock) 
		where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @matlum
		---- #24820
		select @validcnt = @@rowcount
		if @validcnt = 0 and @matlvendor is null
			begin
			select @errortext = @errorstart + ' - Invalid Unit of Measure!'
			goto MSID_error
			end
		if @validcnt = 0 and @matlvendor is not null
		select @umconv = 0
		end

	---- convert units sold to std u/m
	select @stkunits = @matlunits * @umconv
	end


---- get GL Accounts based on Location with overrides by Category - issue #20798
select @losalesglacct = null, @loqtyglacct = null
select @lohaulrevequipglacct = null, @lohaulrevoutglacct = null

select @lmsalesglacct = CustSalesGLAcct, @lmqtyglacct = CustQtyGLAcct, @lmdiscglacct = ARDiscountGLAcct,
		@lmhaulrevequipglacct = CustHaulRevEquipGLAcct, @lmhaulrevoutglacct = CustHaulRevOutGLAcct,
	   	---- #129350
		@lmcustsurrevequipglacct = CustSurchargeRevEquipGLAcct,
		@lmcustsurrevoutglacct = CustSurchargeRevOutGLAcct
		---- #129350
from dbo.bINLM with (nolock) where INCo = @msco and Loc = @fromloc and Active = 'Y'
if @@rowcount = 0
	begin
	select errortext = @errorstart + ' - Invalid From Location, ' + isnull(@fromloc,'') + ' must be setup in IN and active!'
	goto MSID_error
	end

---- get any GL Account overrides based on Material Category
select @losalesglacct = CustSalesGLAcct, @loqtyglacct = CustQtyGLAcct,
		@lohaulrevequipglacct = CustHaulRevEquipGLAcct, @lohaulrevoutglacct = CustHaulRevOutGLAcct
from dbo.bINLO with (nolock) 
where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @matlcategory

---- assign Qty Accounts
set @qtyglacct = isnull(@loqtyglacct,@lmqtyglacct)
---- assign sales accounts
set @salesglacct = isnull(@losalesglacct,@lmsalesglacct)

---- validate Sales Account
exec @rcode = bspGLACfPostable @msglco, @salesglacct, 'I', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - Sales Account ' + isnull(@errmsg,'')
	goto MSID_error
	end

----TK-17081 validate surcharge outside haul GL account
if @SurchargeKeyID IS NOT NULL AND @haultype = 'H'
	BEGIN
	IF @lmcustsurrevoutglacct IS NULL
		BEGIN
		SELECT @errortext = @errorstart + 'Missing Haul - Outside Haulers customer sales GL account.'
		GOTO MSID_error
		END
		
	---- validate GL account
	exec @rcode = bspGLACfPostable @msglco, @lmcustsurrevoutglacct, 'I', @errmsg output
	if @rcode <> 0
		BEGIN
		SELECT @errortext = @errorstart + ' - Haul - Outside Haulers customer sales GL accoun ' + isnull(@errmsg,'')
		GOTO MSID_error
		END
	END
	
----TK-17081 validate surcharge own equipment GL account
if @SurchargeKeyID IS NOT NULL AND @haultype = 'E' 
	BEGIN
	IF @lmcustsurrevequipglacct IS NULL
		BEGIN
		SELECT @errortext = @errorstart + 'Missing Haul - Own Equipment customer sales GL account.'
		GOTO MSID_error
		END

	---- validate GL account
	exec @rcode = bspGLACfPostable @msglco, @lmcustsurrevequipglacct, 'I', @errmsg output
	if @rcode <> 0
		BEGIN
		SELECT @errortext = @errorstart + ' - Haul - Own Equipment customer sales GL account ' + isnull(@errmsg,'')
		GOTO MSID_error
		END
	END


---- assign AR interface fields, used to create AR Invoice Lines based on interface level
select @arfields = ''
select @arfields = @arfields + convert(char(10),@fromloc)
---- interfacing material
if @arinterfacelvl > 1
	begin
	select @arfields = @arfields + convert(char(3),@matlgroup) + convert(char(20),@material) + convert(char(3),@matlum)
	end
else
	begin
	select @arfields = @arfields + '                          ' -- 26 spaces
	end

---- interfacing unit price
if @arinterfacelvl > 2
	begin
	---- need to verify unit price will fit in 12 characters, otherwise arithmetic overflow error will occur
	---- for positive number amount must be greater than 999,999.99999
	if @unitprice > 999999.99999
		begin
		select @errortext = @errorstart + ' - Unit Price exceeds the mask allowed for AR Interface level 3'
		goto MSID_error
		end
	if @unitprice < -99999.99999
		begin
		select @errortext = @errorstart + ' - Unit Price exceeds the mask allowed for AR Interface level 3'
		goto MSID_error
		end
		
	---- add unit cost and ecm
	select @arfields = @arfields + convert(char(12),@unitprice) + isnull(@ecm,' ')
	end
else
	begin
	select @arfields = @arfields + '             '	-- 13 spaces
	end

----#129350
---- add GLCo and Sales Account to AR Fields
if @SurchargeKeyID is null
	begin
	select @arfields = @arfields + convert(char(3),@msglco) + convert(char(20),@salesglacct)
	end
else
	begin
	if @haultype = 'N' 
		BEGIN
		IF @salesglacct IS NULL
			BEGIN
			select @errortext = @errorstart + ' - Sales GLAcct is not set.'
			goto MSID_error
			END
		ELSE
			set @arfields = @arfields + convert(char(3),@msglco) + convert(char(20),@salesglacct)
		END
	if @haultype = 'H' 
		BEGIN
		IF @lmcustsurrevoutglacct IS NULL
		BEGIN
			select @errortext = @errorstart + ' - Cust Surcharge RevOut GLAcct is not set.'
			goto MSID_error
		END
		ELSE
			set @arfields = @arfields + convert(char(3),@msglco) + convert(char(20),@lmcustsurrevoutglacct)
	END
	if @haultype = 'E' 
	BEGIN
		IF @lmcustsurrevequipglacct IS NULL
		BEGIN
			select @errortext = @errorstart + ' - Cust Surcharge Rev Equip GLAcct is not set.'
			goto MSID_error
		END
		ELSE
			set @arfields = @arfields + convert(char(3),@msglco) + convert(char(20),@lmcustsurrevequipglacct)
	END
	end
----#129350

---- add tax code to AR Fields
if @taxcode is not null
	begin
	select @arfields = @arfields + convert(char(3),@taxgroup) + convert(char(10),@taxcode)
	end
else
	begin
	select @arfields = @arfields + '             '    -- 13 spaces
	end

---- add customer job to AR Fields
if @custjob is not null
	begin
	select @arfields = @arfields + convert(char(20),@custjob)
	end
else
	begin
	select @arfields = @arfields + '                    '  -- 20 spaces
	end

---- add customer PO to AR Fields
if @custpo is not null
	begin
	select @arfields = @arfields + convert(char(20),@custpo)
	end
else
	begin
	select @arfields = @arfields + '                    '  -- 20 spaces
	end


---- #129350
if @SurchargeKeyID is null
	begin
	---- add AR Line distribution entry for Material, Tax, and Discount (no haul)
	insert bMSAR(MSCo, Mth, BatchId, BatchSeq, ARFields, MSTrans, FromLoc, MatlGroup, Material,
			UM, MatlUnits, UnitPrice, ECM, MatlTotal, HaulTotal, GLCo, GLAcct, TaxGroup, TaxCode,
			TaxBasis, TaxTotal, DiscOff, TaxDisc, CustJob, CustPO)
	values(@msco, @mth, @batchid, @seq, @arfields, @mstrans, @fromloc, @matlgroup, @material,
			@matlum, @matlunits, @unitprice, @ecm, @matltotal, 0, @msglco, @salesglacct, @taxgroup, @taxcode,
			@taxbasis, @taxtotal, @discoff, @taxdisc, @custjob, @custpo)
	end
else
	begin
	---- add AR Line distribution entry for Surcharge, Tax, and Discount
	insert bMSAR(MSCo, Mth, BatchId, BatchSeq, ARFields, MSTrans, FromLoc, MatlGroup, Material,
			UM, MatlUnits, UnitPrice, ECM, MatlTotal, HaulTotal, GLCo, GLAcct, TaxGroup, TaxCode,
			TaxBasis, TaxTotal, DiscOff, TaxDisc, CustJob, CustPO)
	values(@msco, @mth, @batchid, @seq, @arfields, @mstrans, @fromloc, @matlgroup, @material,
			@matlum, @matlunits, @unitprice, @ecm, @matltotal, 0, @msglco,
			case @haultype when 'N' then @salesglacct
						   when 'E' then @lmcustsurrevequipglacct
						   when 'H' then @lmcustsurrevoutglacct end,				 
			@taxgroup, @taxcode, @taxbasis, @taxtotal, @discoff, @taxdisc, @custjob, @custpo)
	end


---- validate AR GL Account based on Invoice Receivable Type
exec @rcode = bspGLACfPostable @msglco, @recglacct, 'R', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - AR GL Account ' + isnull(@errmsg,'')
	goto MSID_error
	end

---- AR debit for total sale
update bMSIG set Amount = Amount + @matltotal + @haultotal + @taxtotal
where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
and GLAcct = @recglacct and BatchSeq = @seq
if @@rowcount = 0
	begin
	insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
			CustPO, Description, InvDate, Amount)
	values(@msco, @mth, @batchid, @arglco, @recglacct, @seq, @msinv, @custgroup, @customer, @custjob,
			@custpo, @description, @invdate, @matltotal + @haultotal + @taxtotal)
	end

----#129350
if @SurchargeKeyID is null
	begin
	---- Sales credit for material (no haul or tax) or no surcharges
	update bMSIG set Amount = Amount - @matltotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco
	and GLAcct = @salesglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @msglco, @salesglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, -@matltotal)
		end
	end
----#129350

---- Qty Sold --
if @glunits = 'Y' and @qtyglacct is not null
	begin
	---- validate Sales Qty Account
	exec @rcode = bspGLACQtyVal @msglco, @qtyglacct, @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Sales Qty Account ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- Sales Qty (credit units sold)
	update bMSIG set Amount = Amount - @stkunits
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco
	and GLAcct = @qtyglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @msglco, @qtyglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, -@stkunits)
		end
	end

---- Haul Revenue credit
if @haultotal <> 0
	begin
	---- get Haul Revenue GL Accounts (Equip or Outside)
	if @haultype = 'E' select @haulrevglacct = isnull(@lohaulrevequipglacct,@lmhaulrevequipglacct)
	if @haultype = 'H' select @haulrevglacct = isnull(@lohaulrevoutglacct,@lmhaulrevoutglacct)
	-- validate Haul Revenue Account
	exec @rcode = bspGLACfPostable @msglco, @haulrevglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Haul Revenue Account ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- Haul Revenue credit
	update bMSIG set Amount = Amount - @haultotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco
	and GLAcct = @haulrevglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @msglco, @haulrevglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, -@haultotal)
		end

	---- assign AR interface fields for Haul entry
	select @arfields = ''
	select @arfields = @arfields + convert(char(10),@fromloc)
	select @arfields = @arfields + '                          ' -- 26 spaces (material info)
	select @arfields = @arfields + '             '	-- 13 spaces (unit price info)
	select @arfields = @arfields + convert(char(3),@msglco) + convert(char(20),@haulrevglacct)

	---- spaces for tax info
	select @arfields = @arfields + '             '    -- 13 spaces (tax info)
	
	---- customer job to AR Fields
	if @custjob is not null
		begin
		select @arfields = @arfields + convert(char(20),@custjob)
		end
	else
		begin
		select @arfields = @arfields + '                    '  -- 20 spaces
		end
	
	---- customer po to AR fields
	if @custpo is not null
		begin
		select @arfields = @arfields + convert(char(20),@custpo)
		end
	else
		begin
		select @arfields = @arfields + '                    '  -- 20 spaces
		end

	---- add AR Line distribution entry for Haul
	update bMSAR set HaulTotal = HaulTotal + @haultotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ARFields = @arfields
	and MSTrans = @mstrans
	if @@rowcount = 0
		begin
		insert bMSAR(MSCo, Mth, BatchId, BatchSeq, ARFields, MSTrans, FromLoc, MatlGroup, Material, UM,
				MatlUnits, UnitPrice, ECM, MatlTotal, HaulTotal, GLCo, GLAcct, TaxGroup, TaxCode, TaxBasis,
				TaxTotal, DiscOff, TaxDisc, CustJob, CustPO)
		values(@msco, @mth, @batchid, @seq, @arfields, @mstrans, @fromloc, @matlgroup, @material, @matlum,
				0, 0, null, 0, @haultotal, @msglco, @haulrevglacct
				----TFS-44951
				, NULL, NULL, 0, 0, 0, 0, @custjob, @custpo)
		end
	end


----#129350 surcharge revenue credit
if @SurchargeKeyID is not null and @matltotal <> 0
	begin
	---- get surcharge Revenue GL Accounts (Equip or Outside)
	----#143485
	IF @haultype = 'N' SET @surchargerevglacct = @salesglacct
	if @haultype = 'E' set @surchargerevglacct = @lmcustsurrevequipglacct
	if @haultype = 'H' set @surchargerevglacct = @lmcustsurrevoutglacct
	-- validate surcharge Revenue Account
	exec @rcode = bspGLACfPostable @msglco, @surchargerevglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Surcharge Revenue Account ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- Surcharge Revenue credit
	update bMSIG set Amount = Amount - @matltotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco
	and GLAcct = @surchargerevglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @msglco, @surchargerevglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, -@matltotal)
		end
	end


---- Tax Accrual credit
if @taxtotal <> 0
	begin
	select @HQTXcrdGLAcct = null, @HQTXcrdGLAcctPST = null, @TaxAmount = 0, @TaxAmountPST = 0
	---- get tax rates for international
	exec @rcode = dbo.bspHQTaxRateGetAll @taxgroup, @taxcode, @saledate, null,
				@taxrate output, @gstrate output, @pstrate output, @HQTXcrdGLAcct output,
				null, null, null, @HQTXcrdGLAcctPST output, null, NULL,NULL,@errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Tax Code: ' + isnull(@taxcode,'') + ' is not valid. ' + isnull(@errmsg,'')
		goto MSID_error
		end
	if @pstrate = 0
		begin
			/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
			   In any case:
			   a)  @taxrate is the correct value.  
			   b)  Standard US:	Credit GLAcct */
		select @TaxAmount = @taxtotal
		end
	else
		begin
		---- VAT MultiLevel:  Breakout GST and PST for proper GL distribution.
		if @taxrate <> 0
			begin
			select @TaxAmount = (@taxtotal * @gstrate) / @taxrate		--GST TaxAmount
			select @TaxAmountPST = @taxtotal - @TaxAmount				--PST TaxAmount
			end
		end

	---- validate tax accrual account in AR GL Co#
	exec @rcode = dbo.bspGLACfPostable @arglco, @HQTXcrdGLAcct, 'N', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Tax Accrual GL account ' + isnull(@errmsg,'')
		goto MSID_error
		end

	---- Tax Accrual credit
	update bMSIG set Amount = Amount - @TaxAmount
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
	and GLAcct = @HQTXcrdGLAcct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer,
			CustJob, CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @arglco, @HQTXcrdGLAcct, @seq, @msinv, @custgroup, @customer,
			@custjob, @custpo, @description, @invdate, -@TaxAmount)
		end

	---- validate PST tax accrual account if we have one
	if @pstrate <> 0 and @TaxAmountPST <> 0
		begin
		exec @rcode = dbo.bspGLACfPostable @arglco, @HQTXcrdGLAcctPST, 'N', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - PST Tax Accrual GL account ' + isnull(@errmsg,'')
			goto MSID_error
			end

		---- Tax Accrual credit - PST
		update bMSIG set Amount = Amount - @TaxAmountPST
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
		and GLAcct = @HQTXcrdGLAcctPST and BatchSeq = @seq
		if @@rowcount = 0
			begin
			insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer,
					CustJob, CustPO, Description, InvDate, Amount)
			values(@msco, @mth, @batchid, @arglco, @HQTXcrdGLAcctPST, @seq, @msinv, @custgroup, @customer,
					@custjob, @custpo, @description, @invdate, -@TaxAmountPST)
			end
		end
	end


---- add Intercompany entries if needed
if @arglco <> @msglco
	begin
	---- get interco GL Accounts
	select @arglacct = ARGLAcct, @apglacct = APGLAcct
	from bGLIA with (nolock) where ARGLCo = @msglco and APGLCo = @arglco
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL for these companies!'
		goto MSID_error
		end
		
	---- validate Intercompany AR GL Account
	exec @rcode = bspGLACfPostable @msglco, @arglacct, 'R', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Intercompany AR Account  ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- Intercompany AR debit (posted in IN/MS GL Co#)
	select @gltotal = @matltotal + @haultotal	-- does not include tax
	update bMSIG set Amount = Amount + @gltotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco
	and GLAcct = @arglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @msglco, @arglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, @gltotal)
		end

	---- validate Intercompany AP GL Account
	exec @rcode = bspGLACfPostable @arglco, @apglacct, 'P', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Intercompany AP Account  ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- Intercompany AP credit (posted in AR GL Co#)
	update bMSIG set Amount = Amount - @gltotal 
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
	and GLAcct = @apglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @arglco, @apglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, -@gltotal)
		end
	end


---- #14177 - add GL distrubtions for auto payments
if @autoapply = 'Y' and @paymenttype = 'C'
	begin
	---- validate Cash GL Account 
	exec @rcode = bspGLACfPostable @cmglco, @cmglacct, 'C', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - CM Cash Account  ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- Cash debit for payment (posted in CM GL Co#)
	update bMSIG set Amount = Amount + @matltotal + @haultotal + @taxtotal - @discoff - @taxdisc -- less all discounts
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @cmglco
	and GLAcct = @cmglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
				CustPO, Description, InvDate, Amount)
		values(@msco, @mth, @batchid, @cmglco, @cmglacct, @seq, @msinv, @custgroup, @customer, @custjob,
				@custpo, @description, @invdate, (@matltotal + @haultotal + @taxtotal - @discoff))
		end

	---- validate AR Discount GL Account
	if @discoff <> 0
		begin
		select @discglacct = isnull(@lmdiscglacct, @ardiscglacct)
		exec @rcode = bspGLACfPostable @arglco, @discglacct, 'R', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - AR Discount GL Account  ' + isnull(@errmsg,'')
			goto MSID_error
			end
			
		---- Discount taken debit (posted in AR GL Co#)
		update bMSIG set Amount = Amount + @discoff 
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
		and GLAcct = @discglacct and BatchSeq = @seq
		if @@rowcount = 0
			begin
			insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
					CustPO, Description, InvDate, Amount)
			values(@msco, @mth, @batchid, @arglco, @discglacct, @seq, @msinv, @custgroup, @customer, @custjob,
					@custpo, @description, @invdate, @discoff)
			end
		end
		
	---- Tax Accural debit (posted in AR GL Co#) - reduces tax liability by tax discount amount
	if @taxdisc <> 0
		begin
		---- Tax Accrual Account validated with Tax - cannot have TaxDisc w/o Tax
		update bMSIG set Amount = Amount + @taxdisc
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
		and GLAcct = @taxglacct and BatchSeq = @seq
		if @@rowcount = 0
			begin
			insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
					CustPO, Description, InvDate, Amount)
			values(@msco, @mth, @batchid, @arglco, @taxglacct, @seq, @msinv, @custgroup, @customer, @custjob,
					@custpo, @description, @invdate, @taxdisc)
			end
		end

	---- AR credit for full amount (posted in AR GL Co#) -- account already validated, should offset orig debit
	update bMSIG set Amount = Amount - @matltotal - @haultotal - @taxtotal 
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
	and GLAcct = @recglacct and BatchSeq = @seq
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Unable to add AR credit distribution for payment  ' + isnull(@errmsg,'')
		goto MSID_error
		end
		
	---- add Intercompany entries if needed
	if @arglco <> @cmglco
		begin
		select @gltotal = @matltotal + @haultotal + @taxtotal - @discoff - @taxdisc	-- total less all discounts
		---- get interco GL Accounts
		select @arglacct = ARGLAcct, @apglacct = APGLAcct
		from bGLIA with (nolock) where ARGLCo = @arglco and APGLCo = @cmglco
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL for the AR and CM companies!'
			goto MSID_error
			end
			
		---- validate Intercompany AR GL Account
		exec @rcode = bspGLACfPostable @arglco, @arglacct, 'R', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Intercompany AR Account  ' + isnull(@errmsg,'')
			goto MSID_error
			end
			
		---- Intercompany AR debit (posted in AR GL Co#) - matches Cash debit
		update bMSIG set Amount = Amount + @gltotal 
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @arglco
		and GLAcct = @arglacct and BatchSeq = @seq
		if @@rowcount = 0
			begin
			insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
					CustPO, Description, InvDate, Amount)
			values(@msco, @mth, @batchid, @arglco, @arglacct, @seq, @msinv, @custgroup, @customer, @custjob,
					@custpo, @description, @invdate, @gltotal)
			end
			
		---- validate Intercompany AP GL Account
		exec @rcode = bspGLACfPostable @cmglco, @apglacct, 'P', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Intercompany AP Account  ' + isnull(@errmsg,'')
			goto MSID_error
			end
			
		---- Intercompany AP credit (posted in AR GL Co#)
		update bMSIG set Amount = Amount - @gltotal 
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @cmglco
		and GLAcct = @apglacct and BatchSeq = @seq
		if @@rowcount = 0
			begin
			insert bMSIG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob,
					CustPO, Description, InvDate, Amount)
			values(@msco, @mth, @batchid, @cmglco, @apglacct, @seq, @msinv, @custgroup, @customer, @custjob,
					@custpo, @description, @invdate, -@gltotal)
			end
		end
	end


/****************** finished with GL distributions *******************/
    
---- if Customer flagged for Misc Dist on Invoice, create Misc Dist codes
if @misconinv = 'Y'
	begin
	-- check for Misc Dist Code override on Quote
	select @msdistcode = null
	select @msdistcode = MiscDistCode
	from bMSQH with (nolock) 
	where MSCo = @msco and CustGroup = @custgroup and Customer = @customer
	and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'') and Active = 'Y' -- must be Active
	if @@rowcount = 0
		begin
		---- if no Quote found at Customer PO level, check at Customer Job level
		select @msdistcode = MiscDistCode
		from bMSQH with (nolock) 
		where MSCo = @msco and CustGroup = @custgroup and Customer = @customer
		and isnull(CustJob,'') = isnull(@custjob,'') and CustPO is null and Active = 'Y'
		if @@rowcount = 0
			begin
			---- if no Quote found at Customer Job level, check at Customer level
			select @msdistcode = MiscDistCode
			from bMSQH with (nolock) 
			where MSCo = @msco and CustGroup = @custgroup and Customer = @customer
			and CustJob is null and CustPO is null and Active = 'Y'
			end
		end

	---- select Misc Dist Code
	select @miscdistcode = isnull(@msdistcode,@ardistcode)
	if @miscdistcode is null goto MSID_loop
	
	---- validate Misc Dist Code
	if not exists(select top 1 1 from bARMC with (nolock) where CustGroup = @custgroup and MiscDistCode = @miscdistcode)
		begin
		select @errortext = @errorstart + ' - Invalid AR Misc Dist Code'
		goto MSID_error
		end
		
	---- add or update amounts in bMSMX
	update bMSMX set Amount = Amount + @matltotal + @haultotal + @taxtotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid
	and BatchSeq = @seq and MiscDistCode = @miscdistcode
	if @@rowcount = 0
		begin
		insert bMSMX(MSCo, Mth, BatchId, BatchSeq, MiscDistCode, Amount)
		values(@msco, @mth, @batchid, @seq, @miscdistcode, @matltotal + @haultotal + @taxtotal)
		end
	end


/****** DONE WITH THIS TRANSACTION ******/

goto MSID_loop


MSID_error:	-- record error message and go to next Invoice Detail
	exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto MSID_loop

MSID_end:   -- finished with Invoice Detail
	close bcMSID
	deallocate bcMSID
	select @openMSIDcursor = 0
	goto MSIB_loop  -- next Invoice Header

MSIB_error:	-- record error message and go to next Invoice Header
	exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto MSIB_loop

MSIB_end:   -- finished with Invoice Headers
	close bcMSIB
	deallocate bcMSIB
	select @openMSIBcursor = 0



---- make sure debits and credits balance
select @glco = m.GLCo from bMSIG m with (nolock) 
join bGLAC g with (nolock) on m.GLCo = g.GLCo and m.GLAcct = g.GLAcct and g.AcctType <> 'M'  -- exclude memo accounts for qtys
where m.MSCo = @msco and m.Mth = @mth and m.BatchId = @batchid
group by m.GLCo
having isnull(sum(Amount),0) <> 0
if @@rowcount <> 0
	begin
	select @errortext = 'GL Company ' + convert(varchar(3),isnull(@glco,'')) + ' entries don''t balance!'
	exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end

---- check HQ Batch Errors and update HQ Batch Control status
set @status = 3	-- valid - ok to post
if exists(select top 1 1 from bHQBE with (nolock) where Co = @msco and Mth = @mth and BatchId = @batchid)
	begin
	set @status = 2	-- validation errors
	end
	
---- update batch status
update bHQBC
set Status = @status
where Co = @msco and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end




bspexit:
	if @openMSIDcursor = 1
		begin
		close bcMSID
		deallocate bcMSID
		end
	if @openMSIBcursor = 1
		begin
		close bcMSIB
		deallocate bcMSIB
		end

	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode



GO

GRANT EXECUTE ON  [dbo].[bspMSIBVal] TO [public]
GO
