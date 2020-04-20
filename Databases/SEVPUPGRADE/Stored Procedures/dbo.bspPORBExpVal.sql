SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  procedure [dbo].[bspPORBExpVal]
/***********************************************************
* CREATED: DANF 04/11/01
* MODIFIED: GG 07/27/01 - #14131 fixed GL distributions related to 'old' IN entries, removed unused code
*                           related to retainage, discounts, and misc amounts
*		DANF 08/01/01 - Correct GL Distributions related to tax
*		DANF 02/11/02 - Correct debug selects
*		MV 04/19/01   - 16892 - tax GL distributions for all non-burdened cost options
*		DANF 05/01/02 - Added Interface levels from PORH for Initializing Receipts.
*		DANF 07/22/02 - Corrected Receipt update check.
*		DANF 09/05/02 - 17738 Added Phase Group to bspPORBExpValJob & bspJCCAGlacctDflt
* 		DANF 02/20/03 - 20294 Added PO and POItem to bspPORBExpValGLInsert
*		DANF 06/16/03 - 21519 Correct back out burdened IN distribution.
*		DANF 06/26/03 - 21625 Corrected back out of Old Gl account
*		MV 09/04/03   - 21978 performance enhancements
*		RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*		DANF 10/13/2004 - #25741 Correct error message for gl variance accounts
*		MV 05/26/05 - #28714 - calc RemCmtdCost for tax on POs for update to JCCD the same as PO calculates it
*		MV 08/16/05 - #29558 - calc StdUnitCost using AvgECM for Inventory type POs
*		MV 05/25/07 - #124293 - use @avgecm if @oldavgecm is null
*		DC 03/07/08 - Issue #127075:  Modify PO/RQ  for International addresses
*		DC 8/27/08 - Issue #128289 PO International Sales Tax
*		DC 11/5/08 - #130915  - Null value in HQTX ! DbtGLAcct causing batch validation error
*		MV 12/16/08 - #131491 - GST GL Distribution for EM, Job and Exp - null value in HQTXDbtGLAcct causing insert trigger err
*		MV 02/26/09 - #132452 - If HQTXDbtGLAcct is null zero out GST amount - Job 
*		TJL 04/01/09 - Issue #131487, Total rewrite for multple problems related to PO International Sales Tax
*		DC 12/8/09 - #122288 - Store TaxRate in POIT.
*		DC 12/8/09 - NOTE:  I removed a lot of commented code from this procedure, because it was old and was not needed.
*		MV 08/12/10 - #140906 - 'validate old IN Co#, Location, Material, and UM' was too restrictive in executing bspPORBExpValInv
*		mh 11/19/10 - #131640 SM Changes for PO integration.
*		GF 12/09/2010 -= issue #141031
*		GF 07/27/2011 - TK-07029
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*		GF 08/22/2011 - TK-07879 PO Item Line
*		JVH 9/1/11 - TK-08138 Capture SM GL distributions
*		GF 10/20/2011 TK-09213 GL Sub Type for S - Service
*		DAN SO 05/14/2012 - TK-14880 - per Jeremy Myrland - "I wouldn't expect GST to be impacted at all for PO receipt entry."
*		DAN SO 06/12/2012 - TK-15622 - Same as above (TK-14880) - problem - GST is being treated as PST (like sales tax).
*									   Will need to deduct GST from GL Distributions.  This problem affects PO and SL, but not AP.
*									   AP uses a different stored proc to get the correct Tax Rates and Types.
*		GF 09/13/2012 TK-17927 additional change for TK-14880 and TK-15622 po item types 2-6 gl out of balance
*
* USAGE:
* Called from bspPORBVal to validate the receiveing detail of a Batch Sequence and
* create distributions in bPORJ, bPORE, bPORN, and/or bPORG.
*
* Errors in batch added to bHQBE
*
* INPUT PARAMETERS:
*  @poco               PO Company
*  @mth                Batch month
*  @batchid            Batch ID#
*  @batchseq           Batch sequence - a transaction
*  @porbpotrans        PO Transaction # for type 'C' and 'D', null if 'A'
*  @pohdvendorgroup    Vendor Group - current
*  @pohdvendor         Vendor # - current
*  @sortname           Vendor Sort Name - current
*  @oldvendorgroup     Vendor Group - old
*  @oldvendor          Vendor # - old
*  @oldsortname        Vendor Sort Name = old
*  @porbdesc           Transaction description - current
*  @olddesc            Transaction description - old
*  @receivier          Receiver Number
*  @oldreceiver        Old Receiever Number
*  @POItemLine			PO Item Line
*  @OldPOItemLine		Old PO Item LIne
*
* OUTPUT PARAMETERS
*    @errmsg           error message
*
* RETURN VALUE
*    0                 success
*    1                 failure
*****************************************************/
@poco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @apline smallint, @porbbatchtranstype char(1), @porbpotrans bTrans,
	@porbpo varchar(30), @porbpoitem bItem, @porbrecvddate bDate, @porbrecvdby varchar(10), @porbdesc bDesc,
	@porbrecvdunits bUnits, @porbrecvdcost bDollar, @porbbounits bUnits,
	@porbbocost bDollar, @porbreceiver# varchar(20),
	@oldporbpo varchar(30), @oldporbpoitem bItem, @oldporbrecvddate bDate, @oldporbrecvdby varchar(10), @oldporbdesc bDesc,
	@oldporbrecvdunits bUnits, @oldporbrecvdcost bDollar,
	@oldporbbounits bUnits, @oldporbbocost bDollar, @oldporbreceiver# varchar(20),
	----TK-07879
	@PORBPOItemLine INT, @OldPORBPOItemLine INT, @HQBatchDistributionID bigint, @errmsg varchar(255) output
   
as

set nocount on   

select @porbbatchtranstype 'PORBBatchTransType', @porbpo 'PORBpo', @porbpoitem 'PORBpoitem'

declare @rcode int, @sortname varchar(15), @oldsortname varchar(15), @errorstart varchar(50), @errortext varchar(255), @recyn bYN,
	@jcum bUM, @jcunits bUnits, @emum bUM, @emunits bUnits, @stdum bUM, @stdunits bUnits, @costopt tinyint,
	@fixedunitcost bUnitCost, @fixedecm bECM, @burdenyn bYN, @loctaxglacct bGLAcct, @locmiscglacct bGLAcct,
	@locvarianceglacct bGLAcct, @accounttype char(1), @intercoarglacct bGLAcct, @intercoapglacct bGLAcct,
	@active bYN, /*@taxaccrualacct bGLAcct,*/ @taxphase bPhase, @taxct bJCCType, @taxglacct bGLAcct,
	@retglacct bGLAcct, @oldrecyn bYN, @oldjcum bUM, @oldjcunits bUnits, @oldemum bUM, @oldemunits bUnits, @oldstdum bUM,
	@oldstdunits bUnits, @oldcostopt tinyint, @oldfixedunitcost bUnitCost, @oldfixedecm bECM, @oldburdenyn bYN,
	@oldloctaxglacct bGLAcct, @oldlocmiscglacct bGLAcct, @oldlocvarianceglacct bGLAcct, @oldintercoarglacct bGLAcct,
	@oldintercoapglacct bGLAcct, @oldapglacct bGLAcct,@oldtaxphase bPhase, @oldtaxct bJCCType, /*@oldtaxaccrualacct bGLAcct,*/
	@oldtaxglacct bGLAcct, @change char(1), @totalcost bDollar, @rniunits bUnits, @rnicost bDollar, @remcmtdcost bDollar,
	@jcunitcost bUnitCost, @postedcost bDollar, @oldpostedcost bDollar,
	@stdunitcost bUnitCost, @i smallint, @stdecm bECM, @variance bDollar, @upglacct bGLAcct, @glamt bDollar,
	@upphase bPhase, @upunits bUnits, @upjcctype bJCCType, @upum bUM, @upjcum bUM, @upjcunits bUnits, @upjcecm bECM,
	@postedtaxbasis bDollar, @postedtaxamt bDollar, @oldpostedtaxbasis bDollar, @oldpostedtaxamt bDollar, @factor smallint,
	@taxrate bRate, @oldtaxrate bRate, @stdtotalcost bDollar, @unitcost bUnitCost,
	@oldporbunitcost bUnitCost, @porbunitcost bUnitCost, @porbecm bECM, @oldavgecm bECM, @avgecm bECM
   
-- apco declares
declare @apglco bCompany, @expjrnl bJrnl, @pototyn bYN, @netamtopt bYN, @retpaytype tinyint,
	@discoffglacct bGLAcct, @retholdcode bHoldCode, @potaxbasis bDollar

-- poco declares
declare @receiptupdate bYN, @glaccrualacct bGLAcct, @glrecexpinterfacelvl tinyint,
	@glrecexpsummarydesc varchar(60), @glrecexpdetaildesc varchar(60),
	@recjcinterfacelvl tinyint, @receminterfacelvl tinyint,
	@recininterfacelvl tinyint, @source bSource
   
-- APLB declares
declare	@grossamt bDollar, @taxbasis bDollar, @taxamt bDollar,
	@oldgrossamt bDollar, @oldtaxbasis bDollar, @oldtaxamt bDollar
   
-- declare new and changed PO Header
declare @pohdvendorgroup bGroup,  @pohdvendor bVendor, @pohddesc bDesc,
	@pohdorderdate bDate, @pohdorderby varchar(10), @pohdexpdate bDate,
	@pohdstatus tinyint, @pohdjcco bCompany, @pohdjob bJob, @pohdinco bCompany, @pohdloc bLoc,
	@pohdshiploc varchar(10), @pohdaddress varchar(60), @pohdcity varchar(30), @pohdstate varchar(4),
	@pohdzip bZip, @pohdshipins varchar(60), @pohdholdcode bHoldCode, @pohdpayterms bPayTerms,
	@pohdcompgroup varchar(10), @pohdmthclosed bMonth, @pohdinusemth bMonth,
	@pohdinusebatchid bBatchID, @pohdapproved bYN, @pohdapprovedby bVPUserName,
	@pohdpurge bYN, @pohdaddedmth bMonth, @pohdaddedbatchid bBatchID
   
-- declare old PO Header
declare @oldpohdvendorgroup bGroup,  @oldpohdvendor bVendor, @oldpohddesc bDesc,
	@oldpohdorderdate bDate, @oldpohdorderby varchar(10), @oldpohdexpdate bDate,
	@oldpohdstatus tinyint, @oldpohdjcco bCompany, @oldpohdjob bJob, @oldpohdinco bCompany, @oldpohdloc bLoc,
	@oldpohdshiploc varchar(10), @oldpohdaddress varchar(60), @oldpohdcity varchar(30), @oldpohdstate varchar(4),
	@oldpohdzip bZip, @oldpohdshipins varchar(60), @oldpohdholdcode bHoldCode, @oldpohdpayterms bPayTerms,
	@oldpohdcompgroup varchar(10), @oldpohdmthclosed bMonth, @oldpohdinusemth bMonth,
	@oldpohdinusebatchid bBatchID, @oldpohdapproved bYN, @oldpohdapprovedby bVPUserName,
	@oldpohdpurge bYN, @oldpohdaddedmth bMonth, @oldpohdaddedbatchid bBatchID
   
-- declare new  and changes PO Item
declare @poititemtype tinyint, @poitmatlgroup bGroup, @poitmaterial bMatl, @poirvendmatid varchar(30),
	@poitdesc bDesc, @poitum bUM, @poitrecvyn bYN, @poitposttoco bCompany, @poitloc bLoc,
	@poitjob bJob, @poitphasegroup bGroup, @poitphase bPhase, @poitjcctype bJCCType, @poitequip bEquip,
	@poitcomptype varchar(10), @poitcomponent bEquip, @poitemgroup bGroup, @poitcostcode bCostCode,
	@poitemctype bEMCType, @poitwo bWO, @poitwoitem bItem, @poitglco bCompany, @poitglacct bGLAcct,
	@poitreqdate bDate, @poittaxgroup bGroup, @poittaxcode bTaxCode, @poittaxtype tinyint,
	@poitorigunits bUnits, @poitorigunitcost bUnitCost, @poitorigecm bECM, @poitorigcost bDollar,
	@poitorigtax bDollar, @poitcurunits bUnits, @poitcurunitcost bUnitCost, @poitcurecm bECM,
	@poitcurcost bDollar, @poitcurtax bDollar, @poitrecvduntis bUnits, @poitrecvdcost bDollar,   
	@poitbounits bUnits, @poitbocost bDollar, @poittotalunits bUnits, @poittotalcost bDollar,
	@poittotaltax bDollar, @poitinvunits bUnits, @poitinvcost bDollar, @poitinvtax bDollar,
	@poitremunits bUnits, @poitremcost bDollar, @poitremtax bDollar, @poitinusemth bMonth,
	@poitinusebatchid bBatchID, @poitposteddate bDate, @poitrequisitionnum varchar(20),
	@poitaddedmth bMonth, @poitaddedbatchid bBatchID,
	@SMCo bCompany, @SMWorkOrder int, @SMScope int, @SMWorkCompleted int
   
-- declare old PO Item
declare @oldpoititemtype tinyint, @oldpoitmatlgroup bGroup, @oldpoitmaterial bMatl, @oldpoirvendmatid varchar(30),
	@oldpoitdesc bDesc, @oldpoitum bUM, @oldpoitrecvyn bYN, @oldpoitposttoco bCompany, @oldpoitloc bLoc,
	@oldpoitjob bJob, @oldpoitphasegroup bGroup, @oldpoitphase bPhase, @oldpoitjcctype bJCCType, @oldpoitequip bEquip,
	@oldpoitcomptype varchar(10), @oldpoitcomponent bEquip, @oldpoitemgroup bGroup, @oldpoitcostcode bCostCode,
	@oldpoitemctype bEMCType, @oldpoitwo bWO, @oldpoitwoitem bItem, @oldpoitglco bCompany, @oldpoitglacct bGLAcct,
	@oldpoitreqdate bDate, @oldpoittaxgroup bGroup, @oldpoittaxcode bTaxCode, @oldpoittaxtype tinyint,
	@oldpoitorigunits bUnits, @oldpoitorigunitcost bUnitCost, @oldpoitorigecm bECM, @oldpoitorigcost bDollar,
	@oldpoitorigtax bDollar, @oldpoitcurunits bUnits, @oldpoitcurunitcost bUnitCost, @oldpoitcurecm bECM,
	@oldpoitcurcost bDollar, @oldpoitcurtax bDollar, @oldpoitrecvduntis bUnits, @oldpoitrecvdcost bDollar,
	@oldpoitbounits bUnits, @oldpoitbocost bDollar, @oldpoittotalunits bUnits, @oldpoittotalcost bDollar,
	@oldpoittotaltax bDollar, @oldpoitinvunits bUnits, @oldpoitinvcost bDollar, @oldpoitinvtax bDollar,
	@oldpoitremunits bUnits, @oldpoitremcost bDollar, @oldpoitremtax bDollar, @oldpoitinusemth bMonth,
	@oldpoitinusebatchid bBatchID, @oldpoitposteddate bDate, @oldpoitrequisitionnum varchar(20),
	@oldpoitaddedmth bMonth, @oldpoitaddedbatchid bBatchID,
	@OldSMCo bCompany, @OldSMWorkOrder int, @OldSMScope int, @OldSMWorkCompleted int
		
--DC #128289 declare variables for taxes 
declare @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct, @dateposted bDate, @psttaxbasis bDollar,
	@gsttaxbasis bDollar, @psttaxamt bDollar, @gsttaxamt bDollar, @oldpsttaxbasis bDollar, 
	@oldgsttaxbasis bDollar, @oldpsttaxamt bDollar, @oldgsttaxamt bDollar, @valueadd char(1), @oldvalueadd char(1),
	@oldgstrate bRate, @oldpstrate bRate, @oldHQTXdebtGLAcct bGLAcct

--Declare for keeping track of GL Distriubtions
--Currently only used for the SM PO Item Lines
DECLARE @GLEntryID bigint, @TransDesc varchar(60)
      
select @rcode = 0, 
	@dateposted = dbo.vfDateOnly(), ----#141031
	@postedtaxamt = 0, @oldpostedtaxamt = 0,  --DC #128289
	@taxbasis = 0, @taxamt = 0, @gsttaxamt = 0, @psttaxamt = 0,
	@oldtaxbasis = 0, @oldtaxamt = 0, @oldgsttaxamt = 0, @oldpsttaxamt = 0
   
-- get AP Company info
select @apglco = GLCo, @expjrnl = ExpJrnl, @pototyn = POTotYN, @netamtopt = NetAmtOpt,
	@retpaytype = RetPayType, @discoffglacct = DiscOffGLAcct, @retholdcode = RetHoldCode
from bAPCO WITH (NOLOCK) where APCo = @poco
if @@rowcount = 0
	begin
	select @errortext = ' Invalid AP Company!', @rcode = 1
	goto PORB_error
	end
   
-- get PO Company info
select @receiptupdate = ReceiptUpdate, @glaccrualacct = GLAccrualAcct, @glrecexpinterfacelvl = GLRecExpInterfacelvl,
	 @glrecexpsummarydesc = GLRecExpSummaryDesc, @glrecexpdetaildesc = GLRecExpDetailDesc,
	 @recjcinterfacelvl = RecJCInterfacelvl, @receminterfacelvl = RecEMInterfacelvl,
	 @recininterfacelvl = RecINInterfacelvl
from bPOCO WITH (NOLOCK) where POCo = @poco
if @@rowcount = 0
	begin
	select @errortext = ' Invalid PO Company!', @rcode = 1
	goto PORB_error
	end
   
--   Over Ride Interface levels if Initializing Expenses from Receipts.
select @source=Source
from bHQBC WITH (NOLOCK)
where Co = @poco and Mth = @mth and BatchId = @batchid
   
if isnull(@source,'') = 'PO InitRec'
	begin   
	-- get PORH info
	select @receiptupdate = ReceiptUpdate, @glaccrualacct = GLAccrualAcct, @glrecexpinterfacelvl = GLRecExpInterfacelvl,
         @glrecexpsummarydesc = GLRecExpSummaryDesc, @glrecexpdetaildesc = GLRecExpDetailDesc,
         @recjcinterfacelvl = RecJCInterfacelvl, @receminterfacelvl = RecEMInterfacelvl,
         @recininterfacelvl = RecINInterfacelvl
	from bPORH WITH (NOLOCK)
	where Co = @poco and Mth = @mth and BatchId = @batchid
	if @@rowcount = 0
		begin
		select @errortext = ' Missing Receipt Header for Interface levels!', @rcode = 1
		goto PORB_error
		end
    end
   
if @receiptupdate <> 'Y' and isnull(@source,'') <> 'PO InitRec'
	begin
    select @errortext = ' PO Company is not ready to accept Expense entries on receipt!', @rcode = 1
    goto PORB_error
    end
   
if @receiptupdate = 'Y' and isnull(@glaccrualacct,'') = ''
    begin
    select @errortext = ' PO Company has invalid GL Accrual Account!', @rcode = 1
    goto PORB_error
    end
  
 --print 'Reading Added Po Values'
if @porbbatchtranstype in ('A','C')  -- common validation for Add and Change entries
	begin
	--- Read PO Header from POHD   
	select @pohdvendorgroup = VendorGroup,  @pohdvendor = Vendor, @pohddesc = Description,
        @pohdorderdate = OrderDate, @pohdorderby = OrderedBy, @pohdexpdate = ExpDate,
        @pohdstatus = Status, @pohdjcco = JCCo, @pohdjob = Job, @pohdinco = INCo, @pohdloc = Loc,
        @pohdshiploc = ShipLoc, @pohdaddress = Address, @pohdcity = City, @pohdstate = State,
        @pohdzip = Zip, @pohdshipins = ShipIns, @pohdholdcode = HoldCode, @pohdpayterms = PayTerms,
        @pohdcompgroup = CompGroup, @pohdmthclosed = MthClosed, @pohdinusemth = InUseMth,
        @pohdinusebatchid = InUseBatchId, @pohdapproved = Approved, @pohdapprovedby = ApprovedBy,
        @pohdpurge = Purge, @pohdaddedmth = AddedMth, @pohdaddedbatchid = AddedBatchID
	from dbo.bPOHD WITH (NOLOCK) where POCo = @poco and PO = @porbpo
	if @@rowcount = 0
		begin
		select @errortext = ' Invalid PO: ' + @porbpo, @rcode = 1
		goto bspexit
		end
	if @pohdstatus <> 0   -- status must be open
		begin
		select @errortext = ' PO: ' + @porbpo + ' is not open!', @rcode = 1
		goto PORB_error
  		end
	if @pohdinusemth <> @mth or @pohdinusebatchid <> @batchid
		begin
		select @errortext = ' PO: ' + @porbpo + ' is already in use by another batch!', @rcode = 1
		goto PORB_error
  		end

	-- get AP Vendor Info
	select @sortname = SortName
	from bAPVM WITH (NOLOCK) where VendorGroup = @pohdvendorgroup and Vendor = @pohdvendor
	if @@rowcount = 0
		begin
		select @errortext = ' Invalid AP Vendor ' + convert(varchar(6),@pohdvendor) + ' !', @rcode = 1
		goto PORB_error
		end      

	---- Read PO Item from POIT TK-07879
	SELECT  @poititemtype = line.ItemType, @poitmatlgroup = item.MatlGroup, @poitmaterial = item.Material,
			@poirvendmatid = item.VendMatId, @poitdesc = item.Description, @poitum = item.UM,
			@poitrecvyn = item.RecvYN, @poitposttoco = line.PostToCo, @poitloc = line.Loc,
			@poitjob = line.Job, @poitphasegroup = line.PhaseGroup, @poitphase = line.Phase, @poitjcctype = line.JCCType,
			@poitequip = line.Equip, @poitcomptype = line.CompType, @poitcomponent = line.Component,
			@poitemgroup = line.EMGroup, @poitcostcode = line.CostCode, @poitemctype = line.EMCType,
			@poitwo = line.WO, @poitwoitem = line.WOItem, @poitglco = line.GLCo,
			@poitglacct = line.GLAcct, @poitreqdate = line.ReqDate, @poittaxgroup = line.TaxGroup,
			@poittaxcode = line.TaxCode, @poittaxtype = line.TaxType, @poitorigunits = line.OrigUnits,
			@poitorigunitcost = item.OrigUnitCost, @poitorigecm = item.OrigECM, @poitorigcost = line.OrigCost,
			@poitorigtax = line.OrigTax, @poitcurunits = line.CurUnits, @poitcurunitcost = item.CurUnitCost,
			@poitcurecm = item.CurECM, @poitcurcost = item.CurCost, @poitcurtax = line.CurTax,
			@poitrecvduntis = line.RecvdUnits, @poitrecvdcost = line.RecvdCost, @poitbounits = line.BOUnits,
			@poitbocost = line.BOCost, @poittotalunits = line.TotalUnits, @poittotalcost = line.TotalCost,
			@poittotaltax = line.TotalTax, @poitinvunits = line.InvUnits, @poitinvcost = line.InvCost,
			@poitinvtax = line.InvTax, @poitremunits = line.RemUnits, @poitremcost = line.RemCost,
			@poitremtax = line.RemTax, @poitinusemth = line.InUseMth, @poitinusebatchid = line.InUseBatchId,
			@poitposteddate = line.PostedDate, @poitrequisitionnum = item.RequisitionNum,
			@poitaddedmth = item.AddedMth, @poitaddedbatchid = item.AddedBatchID,
			@taxrate = line.TaxRate, @gstrate = line.GSTRate,  --DC #122288
			@SMCo = line.SMCo, @SMWorkOrder = line.SMWorkOrder, @SMScope = line.SMScope, @SMWorkCompleted = line.SMWorkCompleted
	FROM dbo.vPOItemLine line
	INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
	WHERE line.POCo = @poco
		AND line.PO = @porbpo
		AND line.POItem = @porbpoitem
		AND line.POItemLine = @PORBPOItemLine
	----from dbo.bPOIT WITH (NOLOCK) where POCo = @poco and PO = @porbpo and POItem = @porbpoitem
	if @@rowcount = 0
		Begin
		select @errortext = ' Invalid PO: ' + @porbpo + ' Item:' + convert(varchar(6),@porbpoitem), @rcode = 1
		goto PORB_error
  		END

	--Build out the description so that it can be saved off with
	--the GL Transaction Entries. Only currently used for SM Line types.
	SELECT @TransDesc = @glrecexpdetaildesc,
		@TransDesc = REPLACE(@TransDesc, 'InvDesc', dbo.vfToString(@porbdesc)),
		@TransDesc = REPLACE(@TransDesc, 'Vendor#', dbo.vfToString(@pohdvendor)),
		@TransDesc = REPLACE(@TransDesc, 'SortName', dbo.vfToString(@sortname)),
		@TransDesc = REPLACE(@TransDesc, 'Receiver#', dbo.vfToString(@porbreceiver#)),
		@TransDesc = REPLACE(@TransDesc, 'ReceiptDate', dbo.vfToString(CONVERT(VARCHAR, @porbrecvddate, 107))),
		@TransDesc = REPLACE(@TransDesc, 'InvDate', dbo.vfToString(CONVERT(VARCHAR, @porbrecvddate, 107))),
		@TransDesc = REPLACE(@TransDesc, 'PO#', dbo.vfToString(@porbpo)),
		@TransDesc = REPLACE(@TransDesc, 'POItem', dbo.vfToString(@porbpoitem)),
		@TransDesc = REPLACE(@TransDesc, 'POItemLine', dbo.vfToString(@PORBPOItemLine))
		--We don't update the Trans# description since we don't know it yet. 
		--If it is in there at the time of posting we should put it in.
   
	end -- end new and changed values
      
if @porbbatchtranstype in ('D','C')  -- common validation for Deleted entries
	begin   
	--- Read PO Header from POHD
	select @oldpohdvendorgroup = VendorGroup,  @oldpohdvendor = Vendor, @oldpohddesc = Description,
        @oldpohdorderdate = OrderDate, @oldpohdorderby = OrderedBy, @oldpohdexpdate = ExpDate,
        @oldpohdstatus = Status, @oldpohdjcco = JCCo, @oldpohdjob = Job, @oldpohdinco = INCo, @pohdloc = Loc,
        @oldpohdshiploc = ShipLoc, @oldpohdaddress = Address, @oldpohdcity = City, @oldpohdstate = State,
        @oldpohdzip = Zip, @oldpohdshipins = ShipIns, @oldpohdholdcode = HoldCode, @oldpohdpayterms = PayTerms,
        @oldpohdcompgroup = CompGroup, @oldpohdmthclosed = MthClosed, @oldpohdinusemth = InUseMth,
        @oldpohdinusebatchid = InUseBatchId, @oldpohdapproved = Approved, @oldpohdapprovedby = ApprovedBy,
        @oldpohdpurge = Purge, @oldpohdaddedmth = AddedMth, @oldpohdaddedbatchid = AddedBatchID
	from bPOHD WITH (NOLOCK) where POCo = @poco and PO = @oldporbpo
	if @@rowcount = 0
		begin
		select @errortext = ' Invalid PO: ' + @oldporbpo, @rcode = 1
		goto bspexit
		end
	if @oldpohdstatus <> 0   -- status must be open
		begin
		select @errortext = ' PO: ' + @oldporbpo + ' is not open!', @rcode = 1
		goto bspexit
  		end
	if @oldpohdinusemth <> @mth or @oldpohdinusebatchid <> @batchid
		begin
		select @errortext = ' PO: ' + @oldporbpo + ' is already in use by another batch!', @rcode = 1
		goto bspexit
  		end

	-- get AP Vendor Info
	select @oldsortname = SortName
	from bAPVM WITH (NOLOCK) where VendorGroup = @oldpohdvendorgroup and Vendor = @oldpohdvendor
	if @@rowcount = 0
		begin
		select @errortext = ' Invalid AP Vendor ' + convert(varchar(6),@oldpohdvendor) + ' !', @rcode = 1
		goto bspexit
		end

	--- Read PO Item from POIT TK-07879
	select  @oldpoititemtype = line.ItemType, @oldpoitmatlgroup = item.MatlGroup, @oldpoitmaterial = item.Material,
			@oldpoirvendmatid = item.VendMatId, @oldpoitdesc = item.Description, @oldpoitum = item.UM,
			@oldpoitrecvyn = item.RecvYN, @oldpoitposttoco = line.PostToCo, @oldpoitloc = line.Loc,
			@oldpoitjob = line.Job, @oldpoitphasegroup = line.PhaseGroup, @oldpoitphase = line.Phase,
			@oldpoitjcctype = line.JCCType, @oldpoitequip = line.Equip, @oldpoitcomptype = line.CompType,
			@oldpoitcomponent = line.Component, @oldpoitemgroup = line.EMGroup, @oldpoitcostcode = line.CostCode,
			@oldpoitemctype = line.EMCType, @oldpoitwo = line.WO, @oldpoitwoitem = line.WOItem,
			@oldpoitglco = line.GLCo, @oldpoitglacct = line.GLAcct, @oldpoitreqdate = line.ReqDate,
			@oldpoittaxgroup = line.TaxGroup, @oldpoittaxcode = line.TaxCode, @oldpoittaxtype = line.TaxType,
			@oldpoitorigunits = line.OrigUnits, @oldpoitorigunitcost = item.OrigUnitCost, @oldpoitorigecm = item.OrigECM,
			@oldpoitorigcost = line.OrigCost, @oldpoitorigtax = line.OrigTax, @oldpoitcurunits = line.CurUnits,
			@oldpoitcurunitcost = item.CurUnitCost, @oldpoitcurecm = item.CurECM, @oldpoitcurcost = line.CurCost,
			@oldpoitcurtax = line.CurTax, @oldpoitrecvduntis = line.RecvdUnits, @oldpoitrecvdcost = line.RecvdCost,
			@oldpoitbounits = line.BOUnits, @oldpoitbocost = line.BOCost, @oldpoittotalunits = line.TotalUnits,
			@oldpoittotalcost = line.TotalCost, @oldpoittotaltax = line.TotalTax, @oldpoitinvunits = line.InvUnits,
			@oldpoitinvcost = line.InvCost, @oldpoitinvtax = line.InvTax, @oldpoitremunits = line.RemUnits,
			@oldpoitremcost = line.RemCost, @oldpoitremtax = line.RemTax, @oldpoitinusemth = line.InUseMth,
			@oldpoitinusebatchid = line.InUseBatchId, @oldpoitposteddate = line.PostedDate,
			@oldpoitrequisitionnum = item.RequisitionNum, @oldpoitaddedmth = item.AddedMth,
			@oldpoitaddedbatchid = item.AddedBatchID,
			@oldtaxrate = line.TaxRate, @oldgstrate = line.GSTRate,  --DC #122288
			@OldSMCo = line.SMCo, @OldSMWorkOrder = line.SMWorkOrder, @OldSMScope = line.SMScope, @OldSMWorkCompleted = line.SMWorkCompleted
	FROM dbo.vPOItemLine line
	INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
	WHERE line.POCo = @poco
		AND line.PO = @oldporbpo
		AND line.POItem = @oldporbpoitem
		AND line.POItemLine = @OldPORBPOItemLine
	----from bPOIT WITH (NOLOCK) where POCo = @poco and PO = @oldporbpo and POItem = @oldporbpoitem
	if @@rowcount = 0
		begin
		select @errortext = ' Invalid PO: ' + @oldporbpo + ' Item:' + convert(varchar(6),@oldporbpoitem), @rcode = 1
		goto bspexit
  		end
	end
   
-- Set Gross Amount and Tax Amount
select @grossamt = 0, @taxamt = 0, @taxbasis = 0, @oldgrossamt = 0, @oldtaxamt = 0, @oldtaxbasis = 0

select @errorstart = 'Seq#: ' + convert(varchar(6),@batchseq) + ' '

-- Check new LS entry
IF @poitum <> 'LS'
	begin
    select @factor = case @poitorigecm when 'C' then 100 when 'M' then 1000 else 1 end
    select @grossamt = (@poitorigunitcost * @porbrecvdunits) / @factor
    end
else
	begin
	select @grossamt = @porbrecvdcost
	end
		
IF @poittaxcode is not null
	BEGIN
	-- if @reqdate is null use today's date
	if isnull(@porbrecvddate,'') = '' select @porbrecvddate = @dateposted
	-- get Tax Rate	
	--select @taxrate = 0  DC #122288
	select @pstrate = 0 --DC #122288

	--DC #122288
	exec @rcode = vspHQTaxRateGet @poittaxgroup, @poittaxcode, @porbrecvddate, @valueadd output, NULL, NULL, NULL, 
		NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output				
	/*exec @rcode = bspHQTaxRateGetAll @poittaxgroup, @poittaxcode, @porbrecvddate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
		null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output*/
    if @rcode <> 0
		begin
		select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
        goto PORB_error
        end
        
    -- TK-15622 --
    SET @pstrate = @taxrate - @gstrate
	--select @pstrate = (case when @HQTXdebtGLAcct is null then 0 else @taxrate - @gstrate end)  --(case when @gstrate = 0 then 0 else @taxrate - @gstrate end)  --DC #122288

    -------------------------------------------------
    -- TK-15622 - purposely commented out - NO GST --
    -------------------------------------------------
	-- validate GST Debit Tax GL Account if there is one
	--if @HQTXdebtGLAcct is not null
	--	begin
	--	exec @rcode = bspGLACfPostable @poitglco, @HQTXdebtGLAcct, null, @errmsg output
	--		if @rcode <> 0
	--		begin
	--		select @errortext = @errorstart + '- GST Expense GL Acct:' + isnull(@HQTXdebtGLAcct, '') + 
	--			':  ' + isnull(@errmsg,'')  
	--		goto PORB_error
	--		end
	--	end	   	        

	if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
		begin
		-- We have an Intl VAT code being used as a Single Level Code
		if (select GST from bHQTX with (nolock) where TaxGroup = @poittaxgroup and TaxCode = @poittaxcode) = 'Y'
			begin
			select @gstrate = @taxrate
			end
		end
	
	select @taxbasis = @grossamt, @taxamt = @taxbasis * @taxrate						--Full TaxAmount based upon combined TaxRate	1000 * .155 = 155
	select @gsttaxamt = case when @taxrate = 0 then 0 else
		case @valueadd when 'Y' then (@taxamt * @gstrate) / @taxrate else 0 end end		--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
	select @psttaxamt = case @valueadd when 'Y' then @taxamt - @gsttaxamt else 0 end	--PST Tax Amount.  (Rounding errors to PST)		155 - 50 = 105
	
	-- TK-14880 --
	--SET @gsttaxamt = 0
	END		
     
-- Check old LS entry
if @oldpoitum <> 'LS'
	begin
    select @factor = case @oldpoitorigecm when 'C' then 100 when 'M' then 1000 else 1 end
    select @oldgrossamt = (@oldpoitorigunitcost * @oldporbrecvdunits) / @factor
    end
else
	begin
	select @oldgrossamt = @oldporbrecvdcost
	end 		
		
if @oldpoittaxcode is not null
	begin   
	-- if @reqdate is null use today's date
	if isnull(@oldporbrecvddate,'') = '' select @oldporbrecvddate = @dateposted
	-- get Tax Rate
	--select @oldtaxrate = 0  DC #122288
	select @oldpstrate = 0 --DC #122288
	
	-- Unlike the NEW item taxcode, we do not call a separate procedure such as 'bspPORBExpValNew' that would
	-- return the @oldtaxphase and @oldtaxct values.  Therefore we need to return those values here.  For consistency
	-- I have chosen to return the @oldtaxrate from the next procedure rather than from here.
	--DC #122288
	exec @rcode = vspHQTaxRateGet @oldpoittaxgroup, @oldpoittaxcode, @oldporbrecvddate, @oldvalueadd output, NULL, @oldtaxphase output, @oldtaxct output, 
		NULL, NULL, NULL, NULL, @oldHQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output					
    /*exec @rcode = bspHQTaxRateGet @oldpoittaxgroup, @oldpoittaxcode, @oldporbrecvddate,
		null, @oldtaxphase output, @oldtaxct output, @errmsg output*/
    if @rcode <> 0
		begin
        select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
        goto PORB_error
	    end

	-- TK-15622 --
	SET @oldpstrate = @oldtaxrate - @oldgstrate
	--select @oldpstrate = (case when @oldHQTXdebtGLAcct is null then 0 else @oldtaxrate - @oldgstrate end)   --(case when @oldgstrate = 0 then 0 else @oldtaxrate - @oldgstrate end)  --DC #122288

	/*exec @rcode = bspHQTaxRateGetAll @oldpoittaxgroup, @oldpoittaxcode, @oldporbrecvddate, @oldvalueadd output, @oldtaxrate output, @oldgstrate output, @oldpstrate output, 
		null, null, @oldHQTXdebtGLAcct output, null, null, 
		null, @errmsg output
    if @rcode <> 0
		begin
		select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
        goto PORB_error
        end*/
        
    -------------------------------------------------
    -- TK-15622 - purposely commented out - NO GST --
    -------------------------------------------------
    -- validate GST Debit Tax GL Account if there is one
	--if @oldHQTXdebtGLAcct is not null
	--	BEGIN
	--	exec @rcode = bspGLACfPostable @oldpoitglco, @oldHQTXdebtGLAcct, null, @errmsg output
	--	if @rcode <> 0
	--		begin
	--		select @errortext = @errorstart + '- GST Expense GL Acct:' + isnull(@oldHQTXdebtGLAcct, '') + 
	--			':  ' + isnull(@errmsg,'')  
	--		goto PORB_error
	--		end
	--	END

	if @oldgstrate = 0 and @oldpstrate = 0 and @oldvalueadd = 'Y'
		begin
		-- We have an Intl VAT code being used as a Single Level Code
		if (select GST from bHQTX with (nolock) where TaxGroup = @oldpoittaxgroup and TaxCode = @oldpoittaxcode) = 'Y'
			begin
			select @oldgstrate = @oldtaxrate
			end
		end
	
	select @oldtaxbasis = @oldgrossamt, @oldtaxamt = @oldtaxbasis * @oldtaxrate						--Full TaxAmount based upon combined TaxRate	1000 * .155 = 155
	select @oldgsttaxamt = case when @oldtaxrate = 0 then 0 else
		case @oldvalueadd when 'Y' then (@oldtaxamt * @oldgstrate) / @oldtaxrate else 0 end end		--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
	select @oldpsttaxamt = case @oldvalueadd when 'Y' then @oldtaxamt - @oldgsttaxamt else 0 end	--PST Tax Amount.  (Rounding errors to PST)		155 - 50 = 105            
	
	-- TK-14880 --
	--SET @oldgsttaxamt = 0	
	end		        
   
--  validate Batch Transaction Type
if @porbbatchtranstype not in ('A', 'C', 'D')
	begin
	select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
	goto PORB_error
	end
if @porbbatchtranstype in ('A','C')  -- common validation for Add and Change entries
	begin
    exec @rcode = dbo.bspPORBExpValNew @poco, @mth, @batchid, @porbrecvddate, @apglco, @expjrnl,
					@porbpo, @porbpoitem, @porbbatchtranstype, @porbrecvdunits,
					----TK-07879
					@PORBPOItemLine,
					@jcum output, @jcunits output, @emum output, @emunits output, @stdum output,
					@stdunits output, @costopt output, @fixedunitcost output, @fixedecm output,
					@burdenyn output, @loctaxglacct output, @locmiscglacct output,
					@locvarianceglacct output, @intercoarglacct output, @intercoapglacct output,
					@taxphase output, @taxct output, @taxglacct output, @avgecm output,
					@errmsg output

    if @rcode <> 0
		begin
		select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
        goto PORB_error
    	end
    end
    
--select @taxaccrualacct = @glaccrualacct
   	
if @poitcomptype is not null
	begin
	if not exists (select 1 from bEMTY WITH (NOLOCK) where ComponentTypeCode = @poitcomptype)
		begin
		select @errortext = @errorstart + 'Invalid EM Component Code'
		goto PORB_error
		end
	end
   
if @porbbatchtranstype in ('C', 'D')     -- common validation for Change and Delete entries
	begin
    -- validate old JCCo, Job, Phase, and JC Cost Type
    select @oldjcum = @jcum, @oldjcunits = @jcunits
    if (@oldpoititemtype = 1) and
		(@porbrecvdunits <> @oldporbrecvdunits or @porbbatchtranstype = 'D')
        begin
        exec @rcode = bspPORBExpValJob @oldpoitposttoco, @oldpoitphasegroup, @oldpoitjob, @oldpoitphase, @oldpoitjcctype,
                 @oldpoitmatlgroup, @oldpoitmaterial, @oldpoitum, @oldporbrecvdunits, @oldjcum output,
                 @oldjcunits output, @errmsg output
    	if @rcode <> 0
			begin
     		select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
    		goto PORB_error
    	    end
        end
            
	-- validate old Work Order and Item
	if (@oldpoititemtype = 5) and (@porbbatchtranstype = 'D')
		begin
		exec @rcode = bspPORBExpValWO @oldpoitposttoco, @oldpoitwo, @oldpoitwoitem, @oldpoitequip,
			   @oldpoitcomptype, @oldpoitcomponent,@oldpoitemgroup, @oldpoitcostcode, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + isnull(@errmsg,'')
			goto PORB_error
			end
		end
   
  	-- validate EMCo, Equip, Cost Code, EM Cost Type, Component Type, and Component
    select @oldemum = @emum, @oldemunits = @emunits
    if (@oldpoititemtype in (4,5)) and
		(@porbrecvdunits <> @oldporbrecvdunits or @porbbatchtranstype = 'D')
        begin
        exec @rcode = bspPORBExpValEquip @oldpoitposttoco, @oldpoitequip, @oldpoitemgroup,
                   @oldpoitcostcode, @oldpoitemctype, @oldpoitcomponent, @oldpoitmatlgroup,
                   @oldpoitmaterial, @oldpoitum, @oldporbrecvdunits, @oldemum output,
                   @oldemunits output, @errmsg output
    	if @rcode <> 0
			begin
     		select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
    		goto PORB_error
    	    end
        end
            
    -- validate old IN Co#, Location, Material, and UM
    SELECT @oldstdum = @stdum, @oldstdunits = @stdunits 
    IF (@oldpoititemtype = 2) AND @porbbatchtranstype <> 'A' --(@porbrecvdunits <> @oldporbrecvdunits or @porbbatchtranstype = 'D') #140906
	BEGIN
        EXEC @rcode = bspPORBExpValInv @oldpoitposttoco, @oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial, @oldpoitum, @oldporbrecvdunits,
                   @oldstdum OUTPUT, @oldstdunits OUTPUT, @oldcostopt OUTPUT, @oldfixedunitcost OUTPUT,
                   @oldfixedecm OUTPUT, @oldburdenyn OUTPUT, @oldloctaxglacct OUTPUT, @oldlocmiscglacct OUTPUT,
                   @oldlocvarianceglacct OUTPUT,@oldavgecm OUTPUT, @errmsg OUTPUT
        IF @rcode <> 0
		BEGIN
     		SELECT @errortext = @errorstart + '- ' + isnull(@errmsg,'')
    		GOTO PORB_error
    	END
    END
	-- validate Expense Jrnl in old GL Co#
	if @oldpoitglco <> @apglco
		begin
		if not exists(select 1 from bGLJR WITH (NOLOCK) where GLCo = @oldpoitglco and Jrnl = @expjrnl)
			begin
			select @errortext = @errorstart + ' - Journal ' + isnull(@expjrnl,'') + ' is not valid in GL Co#' + convert(varchar(3),@poitglco)
			goto PORB_error
			end
		end

	-- validate old GL Co and Expense Month
	if @porbbatchtranstype = 'D'
		begin
		exec @rcode = bspHQBatchMonthVal @oldpoitglco, @mth, 'AP', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
			goto PORB_error
			end
		end

	-- validate old Posted GL Account
	if @porbbatchtranstype = 'D'
		begin
		select @accounttype = null
		if @oldpoititemtype = 1 select @accounttype = 'J' -- job
		if @oldpoititemtype = 2 select @accounttype = 'I' -- inventory
		if @oldpoititemtype = 3 select @accounttype = 'N' -- must be null
		if @oldpoititemtype in (4,5) select @accounttype = 'E' -- equipment
		----TK-09213
		IF @oldpoititemtype = 6 SET @accounttype = 'S' --Service or null
		exec @rcode = bspGLACfPostable @oldpoitglco, @oldpoitglacct, @accounttype, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- GL Account:' + isnull(@poitglacct,'') + ':  ' + isnull(@errmsg,'')
			goto PORB_error
			end
       end
           
	-- if old AP GL Co# <> 'Posted To' GL Co# get intercompany accounts
	select @oldintercoarglacct = @intercoarglacct, @oldintercoapglacct = @intercoapglacct
	if @oldpoitglco <> @apglco and (@porbbatchtranstype = 'D')
		begin
		select @oldintercoarglacct = ARGLAcct, @oldintercoapglacct = APGLAcct
		from bGLIA WITH (NOLOCK)
		where ARGLCo = @apglco and APGLCo = @oldpoitglco
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL. From:' +
			   convert(varchar(3),@apglco) + ' To: ' + convert(varchar(3),@poitglco)
			goto PORB_error
			end
			
		-- validate intercompany GL Accounts
		exec @rcode = bspGLACfPostable @apglco, @oldintercoarglacct, 'R', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- Intercompany AR Account:' + isnull(@oldintercoarglacct,'') + ':  ' + isnull(@errmsg,'')
			goto PORB_error
			end
		exec @rcode = bspGLACfPostable @oldpoitglco, @oldintercoapglacct, 'P', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- Intercompany AP Account:' + isnull(@oldintercoapglacct,'') + ':  ' + isnull(@errmsg,'')
			goto PORB_error
			end
		end		
		
    -- validate old Pay Type and get Payables GL Account
    select @oldapglacct = @glaccrualacct
	if @porbbatchtranstype = 'D'
		begin
        -- validate Pay Type GL Account
    	exec @rcode = bspGLACfPostable @apglco, @oldapglacct, 'P', @errmsg output
    	if @rcode <> 0
			begin
    	    select @errortext = @errorstart + '- GL Payables Account:' + isnull(@oldapglacct,'') + ':  ' + isnull(@errmsg,'')
  			goto PORB_error
        	end
        end

    -- validate old Tax Group and Tax code
	if @oldpoittaxcode is not null
		begin
		
        --select @oldtaxaccrualacct = @glaccrualacct
        -- Tax Phase and Cost Type
        if @oldpoititemtype = 1
			begin
            -- use 'posted' phase and cost type unless overridden by tax code
            if @oldtaxphase is null select @oldtaxphase = @oldpoitphase
            if @oldtaxct is null select @oldtaxct = @oldpoitjcctype
            select @oldtaxglacct = @oldpoitglacct     -- default is 'posted' account
            -- Tax may be redirected to another expense account
            if @oldtaxphase <> @oldpoitphase or @oldtaxct <> @oldpoitjcctype
    			begin
   				-- get GL Account for Tax Expense
            	exec @rcode = bspJCCAGlacctDflt @oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup, @oldtaxphase, @oldtaxct, 'N',
                          @oldtaxglacct output, @errmsg output
           	    if @rcode <> 0
   	 				begin
    	        	select @errortext = @errorstart + '- Tax GL Account ' + isnull(@errmsg,'')
       				goto PORB_error
                    end
                -- validate Tax Account
                exec @rcode = bspGLACfPostable @oldpoitglco, @oldtaxglacct, 'J', @errmsg output
    		    if @rcode <> 0
    	       		begin
    		        select @errortext = @errorstart + '- Tax GLAcct:' + isnull(@oldtaxglacct,'') + ':  ' + isnull(@errmsg,'')
                    goto PORB_error
    		        end
                end
            end
        end   
    end
   
update_audit:	-- add JC, EM, IN, and GL distributions
select @change = 'N'    -- flag indicating that changes have been made
if @porbbatchtranstype = 'C' and  (@porbrecvddate <> @oldporbrecvddate
              or isnull(@porbpo,'') <> isnull(@oldporbpo,'') or isnull(@porbpoitem,0) <> isnull(@porbpoitem,0)
              or isnull(@porbdesc,'') <> isnull(@oldporbdesc,'')
              or @porbrecvdunits <> @oldporbrecvdunits or @grossamt <> @oldgrossamt
              or @taxamt <> @oldtaxamt) select @change = 'Y'   -- something changed
   
-- 'Old' JC distributions
if @oldpoititemtype = 1 and (@porbbatchtranstype = 'D' or @change = 'Y')
	begin
	
	select @i = 0
OldJC_loop:

	select @totalcost = 0, @rnicost = 0, @remcmtdcost = 0, @oldpostedtaxbasis = 0, @oldpostedtaxamt = 0, @jcunitcost = 0, @rniunits = 0,
		@upunits = 0, @upjcunits = 0

	if @i = 0  -- Old Posted Amount (tax may be redirected so exclude it on this pass)
		begin
		select @factor = case @oldpoitorigecm when 'C' then 100 when 'M' then 1000 else 1 end
		select @totalcost = @oldgrossamt

		-- POs and SLs (except Backcharge Items) will update Remaining Committed Cost
		select @remcmtdcost = case when @oldpoitum = 'LS' then @oldgrossamt else (@oldporbrecvdunits * @oldpoitorigunitcost) / @factor end	--****Why recalculate?  Already done Line 420

		-- RNI only applies to PO Items flagged for receiving
		select @rniunits = @oldjcunits		-- will be 0.00 if 'LS'
		select @rnicost = @remcmtdcost		-- change to RNI Cost will equal change to Rem Cmtd Cost

		-- JC Unit Cost only calculated on this pass so include tax
		if @oldjcunits <> 0 select @jcunitcost = (@totalcost + @oldtaxamt) / @oldjcunits

		select @upphase = @oldpoitphase, @upjcctype = @oldpoitjcctype,
			@upglacct = @oldpoitglacct, @upum = @oldpoitum, @upunits = @oldporbrecvdunits, @upjcum = @oldjcum,
			@upjcunits = @oldjcunits, @upjcecm = 'E'		--, @uptaxbasis = 0, @uptaxamt = 0
		end
        
	if @i = 1  -- Tax amount
		begin
		select @oldpostedtaxbasis = @oldtaxbasis, 
			   @oldpostedtaxamt = @oldtaxamt,												
			   -- TK-15622 --
			   @totalcost = @oldpostedtaxamt - @oldgsttaxamt,	  -- *** JCCD.ActualCost & GL Expense  (May or may not include GST)
			   @remcmtdcost =  (@oldpostedtaxamt - @oldgsttaxamt) -- *** JCCD.RemainCmtdCost (May or may not include GST)
			   --@totalcost = case when @oldHQTXdebtGLAcct is null then @oldpostedtaxamt else @oldpostedtaxamt - @oldgsttaxamt end,	-- *** JCCD.ActualCost & GL Expense  (May or may not include GST)
			   --@remcmtdcost = case when @oldHQTXdebtGLAcct is null then @oldpostedtaxamt else @oldpostedtaxamt - @oldgsttaxamt end -- *** JCCD.RemainCmtdCost (May or may not include GST)

		-- RNI only applies to PO Items flagged for receiving
		select @rnicost = @remcmtdcost

		-- use old tax phase and cost type
		select @upphase = @oldtaxphase, @upjcctype = @oldtaxct, @upglacct = @oldtaxglacct, @upum = null,
			@upunits = 0, @upjcum = null, @upjcunits = 0, @upjcecm = null
		end

	-- Set Negative Dollar values for OLD transaction posting
	select @totalcost = (-1 * @totalcost), @upunits = (-1 * @upunits), @upjcunits = (-1 * @upjcunits),
		@oldpostedtaxbasis = (-1 * @oldpostedtaxbasis), @oldpostedtaxamt = (-1 * @oldpostedtaxamt),
		@oldgsttaxamt = (-1 * @oldgsttaxamt)

	-- add old PORJ entry
	if @totalcost <> 0 or @upunits <> 0 or @rniunits <> 0 or @rnicost <> 0 or @remcmtdcost <> 0
		BEGIN
		
		-- called for both GrossAmt loop and Tax loop.  
		-- TotalCost includes full Gross Amt (loop 1), followed by Tax Amt less GST in most cases (loop 2)
		-- RemainCommittedCost includes full Gross Amt (loop 1), followed by Tax Amt less GST Tax in most cases (loop 2)
		exec @rcode = bspPORBExpValJCInsert @poco, @mth, @batchid, @oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup,
			@upphase, @upjcctype, @batchseq, @apline, @porbpotrans, 0, @oldpohdvendorgroup, @oldpohdvendor,
			@oldporbpo, @oldporbpoitem, @oldpoitmatlgroup, @oldpoitmaterial,
			@oldporbdesc, @oldporbrecvddate, @oldporbreceiver#, @oldpoitglco, @upglacct, @upum, @upunits, @upjcum, @upjcunits,
			@jcunitcost, @upjcecm, @totalcost, @rniunits, @rnicost, @remcmtdcost, @oldpoittaxgroup,
			@oldpoittaxcode, @oldpoittaxtype, @oldpostedtaxbasis, @oldpostedtaxamt,
			----TK-07879
			@OldPORBPOItemLine
		end

	if @i = 0 -- APGL for Job Expense - Gross Amt
		BEGIN
		-- TotalCost includes full Gross Amt (loop 1)
		-- add old PORG entry - will make intercompany entries if needed
		if @totalcost <> 0
		exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @upglacct, @batchseq, @apline,
						0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
						@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#,
						@oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup, @upphase, @upjcctype,
						@oldpoitposttoco, @oldpoitequip, @oldpoitemgroup, @oldpoitcostcode,
						@oldpoitemctype, @oldpoitposttoco, @oldpoitloc, @oldpoitmatlgroup,
						@oldpoitmaterial, @totalcost, @apglco, @oldintercoarglacct, @oldintercoapglacct,
						@oldporbpo, @oldporbpoitem,
						----TK-07879
						@OldPORBPOItemLine			
						
		END
	
	if @i = 1 -- Tax Amt added to Job Expense - Sales or VAT
		BEGIN
		-- TotalCost is Tax Amt less GST Tax in most cases (loop 2)
		-- add old PORG entry - will make intercompany entries if needed
		if @totalcost <> 0
			BEGIN
			exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @upglacct, @batchseq, @apline,
						0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
						@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#,
						@oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup, @upphase, @upjcctype,
						@oldpoitposttoco, @oldpoitequip, @oldpoitemgroup, @oldpoitcostcode,
						@oldpoitemctype, @oldpoitposttoco, @oldpoitloc, @oldpoitmatlgroup,
						@oldpoitmaterial, @totalcost, @apglco, @oldintercoarglacct, @oldintercoapglacct,
						@oldporbpo, @oldporbpoitem,
						----TK-07879
						@OldPORBPOItemLine
			END

		-- GST Tax only - Tracked separately only when Debit Account is present
		-- add old PORG entry for GST tax portion. - Will typically get sent to different GL Acct
		-------------------------------------------------
		-- TK-15622 - purposely commented out - NO GST --
		-------------------------------------------------
		----if @oldgsttaxamt <> 0 and @oldHQTXdebtGLAcct is not null
		----	BEGIN				
		----	--PORG for GST Tax
		----	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @oldHQTXdebtGLAcct,
		----				@batchseq, @apline, 0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor,
		----				@oldsortname, @oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#,
		----				@oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup, @upphase, @upjcctype,
		----				@oldpoitposttoco, @oldpoitequip, @oldpoitemgroup, @oldpoitcostcode, @oldpoitemctype,
		----				@oldpoitposttoco, @oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial, @oldgsttaxamt,
		----				@apglco, @oldintercoarglacct, @oldintercoapglacct, @oldporbpo, @oldporbpoitem,
		----				----TK-07879
		----				@OldPORBPOItemLine	
		----	END
		END

	-- Reset Negative Dollar values to Positive for OLD transactions.  I believe the only one in the list that
	-- actually needs to be reset is @oldgsttaxamt.  The rest are just for good measure.
	select @totalcost = (-1 * @totalcost), @upunits = (-1 * @upunits), @upjcunits = (-1 * @upjcunits),
		@oldpostedtaxbasis = (-1 * @oldpostedtaxbasis), @oldpostedtaxamt = (-1 * @oldpostedtaxamt),
		@oldgsttaxamt = (-1 * @oldgsttaxamt)

    select @i = @i + 1
    if @i < 2 goto OldJC_loop
    end
   
-- 'New' JC distributions
--select 'Checking For New JC entries ' + convert(varchar(10),@poititemtype)
if @poititemtype = 1 and (@porbbatchtranstype = 'A' or @change = 'Y')
	begin
		
    select @i = 0
NewJC_loop:

    select @totalcost = 0, @rnicost = 0, @remcmtdcost = 0, @postedtaxbasis = 0, @postedtaxamt = 0, @jcunitcost = 0, @rniunits = 0,  
		@upunits = 0, @upjcunits = 0

    if @i = 0 -- Posted Amount (tax may be redirected so exclude it on this pass)
		begin
		select @factor = case @poitorigecm when 'C' then 100 when 'M' then 1000 else 1 end
		select @totalcost = @grossamt

        -- POs and SLs (except Backcharge Item) will update Remaining Committed Cost
		select @remcmtdcost = case when @poitum = 'LS' then -@grossamt else -(@porbrecvdunits * @poitorigunitcost) / @factor end	--****Why recalculate?  Already done Line 356

		-- RNI only applies to PO Items flagged for receiving
        select @rniunits = -@jcunits    -- will be 0.00 if 'LS'
   		select @rnicost = @remcmtdcost	-- change to RNI Cost will equal change to Rem Cmtd Cost

        -- JC Unit Cost only calculated on this pass so include tax
        if @jcunits <> 0 select @jcunitcost = (@totalcost + @taxamt) / @jcunits  

		-- use posted phase, cost type, etc.
        select @upphase = @poitphase, @upjcctype = @poitjcctype, @upglacct = @poitglacct, @upum = @poitum,
			@upunits = @porbrecvdunits, @upjcum = @jcum, @upjcunits = @jcunits, @upjcecm = 'E'		
        end

    if @i = 1  -- Tax amount
		begin
        select @postedtaxbasis = @taxbasis, 
			-- TK-15622 --
			@postedtaxamt = @taxamt,
			@totalcost = @postedtaxamt - @gsttaxamt,	  -- *** JCCD.ActualCost & GL Expense  (May or may not include GST)
			@remcmtdcost =  -(@postedtaxamt - @gsttaxamt) -- *** JCCD.RemainCmtdCost (May or may not include GST)
			--@postedtaxamt = @taxamt,												-- *** Calculated Tax Amount for JCCD.TaxBasis, JCCD.TaxAmount
			--@totalcost = case when @HQTXdebtGLAcct is null then @postedtaxamt else @postedtaxamt - @gsttaxamt end,	-- *** JCCD.ActualCost & GL Expense  (May or may not include GST)
			--@remcmtdcost = case when @HQTXdebtGLAcct is null then -@postedtaxamt else -(@postedtaxamt - @gsttaxamt) end -- *** JCCD.RemainCmtdCost (May or may not include GST)

        -- RNI only applies to PO Items flagged for receiving
		select @rnicost = @remcmtdcost

		-- use tax phase and cost type
		select @upphase = @taxphase, @upjcctype = @taxct, @upglacct = @taxglacct, @upum = null,
			@upunits = 0, @upjcum = null, @upjcunits = 0, @upjcecm = null   			
		end
			
	-- add new PORJ entry
	if @totalcost <> 0 or @upunits <> 0 or @rniunits <> 0 or @rnicost <> 0 or @remcmtdcost <> 0	
		BEGIN
				
		-- called for both GrossAmt loop and Tax loop.  
		-- TotalCost includes full Gross Amt (loop 1), followed by Tax Amt less GST in most cases (loop 2)
		-- RemainCommittedCost includes full Gross Amt (loop 1), followed by Tax Amt less GST Tax in most cases (loop 2)
		exec @rcode = bspPORBExpValJCInsert @poco, @mth, @batchid, @poitposttoco, @poitjob, @poitphasegroup, @upphase,
				@upjcctype, @batchseq, @apline, @porbpotrans, 1, @pohdvendorgroup, @pohdvendor,
				@porbpo, @porbpoitem, @poitmatlgroup, @poitmaterial, @porbdesc, @porbrecvddate, @porbreceiver#, @poitglco, @upglacct,
				@upum, @upunits, @upjcum, @upjcunits, @jcunitcost, @upjcecm, @totalcost, @rniunits, @rnicost,
				@remcmtdcost, @poittaxgroup, @poittaxcode, @poittaxtype, @postedtaxbasis, @postedtaxamt,
				----TK-07879
				@PORBPOItemLine													 			
		end
	
	if @i = 0 -- APGL for Job Expense - Gross Amt
		BEGIN
		-- TotalCost includes full Gross Amt (loop 1)
  		if @totalcost <> 0
			begin
			exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @upglacct, @batchseq, @apline, 1,
					@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname, @poititemtype,
					@porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob, @poitphasegroup,
					@upphase, @upjcctype, @poitposttoco, @poitequip, @poitemgroup, @poitcostcode,
					@poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial, @totalcost,
					@apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
					----TK-07879
					@PORBPOItemLine		
			end		
		END

	if @i = 1 -- Tax Amt added to Job Expense - Sales or VAT
		BEGIN
		-- TotalCost is Tax Amt less GST Tax in most cases (loop 2)
		if @totalcost <> 0
			BEGIN
			exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @upglacct, @batchseq, @apline, 1,
					@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname, @poititemtype,
					@porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob, @poitphasegroup,
					@upphase, @upjcctype, @poitposttoco, @poitequip, @poitemgroup, @poitcostcode,
					@poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial, @totalcost,
					@apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
					----TK-07879
					@PORBPOItemLine	
			END

		-- GST Tax only - Tracked separately only when Debit Account is present
		-------------------------------------------------
		-- TK-15622 - purposely commented out - NO GST --
		-------------------------------------------------		
		----if @gsttaxamt <> 0 and @HQTXdebtGLAcct is not null			--AND isnull(@HQTXdebtGLAcct,'') <> ''  --DC #130915
		----	BEGIN
		----	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco,@HQTXdebtGLAcct, @batchseq, @apline, 1,
		----			@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname, @poititemtype,
		----			@porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob, @poitphasegroup,
		----			@upphase, @upjcctype, @poitposttoco, @poitequip, @poitemgroup, @poitcostcode,
		----			@poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial, @gsttaxamt,
		----			@apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
		----			----TK-07879
		----			@PORBPOItemLine			
		----	END
		END
		
    select @i = @i + 1
    if @i < 2 goto NewJC_loop
    end
 
-- 'Old' EM distributions
if @oldpoititemtype in (4,5) and (@porbbatchtranstype = 'D' or @change = 'Y')
	begin
	-- set update amounts - TotalCost begins as GrossAmt + TaxAmt
	-- This is an extra step but helps with the visualization of this progression.
	select @totalcost = @oldgrossamt + @oldtaxamt --REM'D Issue #131487: (case isnull(@oldvalueadd,'N') when 'N' then @oldtaxamt else 0 end) -- DC #128289  @oldtaxamt
	--TK-17927
	SET @oldpostedcost = @totalcost - @oldgsttaxamt
	SET @oldpostedtaxamt = @oldtaxamt - @oldgsttaxamt
	--select @oldpostedcost = @totalcost - case when @oldHQTXdebtGLAcct is null then 0 else @oldgsttaxamt	end			-- Equip Distribution Cost & GL Expense  (Excludes GST tax)
	--select @oldpostedtaxamt = @oldtaxamt - case when @oldHQTXdebtGLAcct is null then 0 else @oldgsttaxamt end		-- Equip Distribution Tax	(PST only)

	-- Set Negative Dollar values for OLD transaction posting
	select @oldpostedcost = (-1 * @oldpostedcost), @oldtaxbasis = (-1 * @oldtaxbasis), @oldpostedtaxamt = (-1 * @oldpostedtaxamt),
		@oldporbrecvdunits = (-1 * @oldporbrecvdunits), @oldemunits = (-1 * @oldemunits), @oldgsttaxamt = (-1 * @oldgsttaxamt) 

	-- add old PORE entry
	if @oldpostedcost <> 0 or @oldporbrecvdunits <> 0
		begin
		exec @rcode = bspPORBExpValEMInsert @poco, @mth, @batchid, @oldpoitposttoco, @oldpoitequip, @oldpoitemgroup, @oldpoitcostcode,
					@oldpoitemctype, @batchseq, @apline, 0, @porbpotrans, @oldpohdvendorgroup,
					@oldpohdvendor, @oldporbrecvddate, @oldporbreceiver#, @oldporbpo, @oldporbpoitem,
					@oldpoitwo, @oldpoitwoitem, @oldpoitcomptype, @oldpoitcomponent, @oldpoitmatlgroup,
					@oldpoitmaterial, @oldporbdesc, @oldpoitglco, @oldpoitglacct, @oldpoitum,
					@oldporbrecvdunits, @oldpoitorigunitcost, @oldpoitorigecm, @oldemum,
					@oldemunits, @oldpostedcost, @oldpoittaxgroup, @oldpoittaxcode, @oldpoittaxtype,
					@oldtaxbasis, @oldpostedtaxamt,
					----TK-07879
					@OldPORBPOItemLine
		end

	--Post old GL Expense.  Does not include GST Tax		
    if @oldpostedcost <> 0
		begin
        exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @oldpoitglacct, @batchseq, @apline, 0,
					@porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
					@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#,
					@oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup, @oldpoitphase,   
					@oldpoitjcctype, @oldpoitposttoco, @oldpoitequip, @oldpoitemgroup,
					@oldpoitcostcode, @oldpoitemctype, @oldpoitposttoco, @oldpoitloc,
					@oldpoitmatlgroup, @oldpoitmaterial, @oldpostedcost, @apglco,
					@oldintercoarglacct, @oldintercoapglacct, @oldporbpo, @oldporbpoitem,
					----TK-07879
					@OldPORBPOItemLine
		end
			   
	-- post old GST portion of tax to GST Payables
	-------------------------------------------------
	-- TK-15622 - purposely commented out - NO GST --
	-------------------------------------------------
	----if @oldgsttaxamt <> 0 and @oldHQTXdebtGLAcct is not null
	----	BEGIN
	----       exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @oldHQTXdebtGLAcct, @batchseq, @apline, 0,
	----				@porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
	----				@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#, @oldpoitposttoco,
	----				@oldpoitjob, @oldpoitphasegroup, @oldpoitphase, @oldpoitjcctype, @oldpoitposttoco,
	----				@oldpoitequip, @oldpoitemgroup, @oldpoitcostcode, @oldpoitemctype, @oldpoitposttoco,
	----				@oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial, @oldgsttaxamt, @apglco,
	----				@oldintercoarglacct, @oldintercoapglacct, @oldporbpo, @oldporbpoitem,
	----				----TK-07879
	----				@OldPORBPOItemLine
	----	END	

	-- Reset Negative Dollar values for OLD transaction posting
	select @oldpostedcost = (-1 * @oldpostedcost), @oldtaxbasis = (-1 * @oldtaxbasis), @oldpostedtaxamt = (-1 * @oldpostedtaxamt),
		@oldporbrecvdunits = (-1 * @oldporbrecvdunits), @oldemunits = (-1 * @oldemunits), @oldgsttaxamt = (-1 * @oldgsttaxamt) 						
    end
 
-- 'New' EM distributions
if @poititemtype in (4,5) and (@porbbatchtranstype = 'A' or @change = 'Y')
	begin
	-- set update amounts - TotalCost begins as GrossAmt + TaxAmt
	-- This is an extra step but helps with the visualization of this progression.
	select @totalcost = @grossamt + @taxamt -- REM'D Issue #131487: + (case isnull(@valueadd,'N') when 'N' then @taxamt else 0 end) -- DC #128289  @taxamt 
	--TK-17927
	SET @postedcost = @totalcost - @gsttaxamt
	SET @postedtaxamt = @taxamt - @gsttaxamt
	--select @postedcost = @totalcost - case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end		-- Equip Distribution Cost & GL Expense  (Excludes GST tax)
	--select @postedtaxamt = @taxamt - case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end		-- Equip Distribution Tax	(PST only)

	-- add new PORE entry - Remove GST tax
	if @postedcost <> 0 or @porbrecvdunits <> 0	
		begin
		--Equip cost might be 0.00 (All GST tax) but we have units.  Post Equip Cost distribution of 0.00 value with units.
		exec @rcode = bspPORBExpValEMInsert @poco, @mth, @batchid, @poitposttoco, @poitequip,
					@poitemgroup, @poitcostcode, @poitemctype, @batchseq, @apline, 1, @porbpotrans, @pohdvendorgroup,
					@pohdvendor, @porbrecvddate, @porbreceiver#, @porbpo, @porbpoitem, @poitwo, @poitwoitem,
					@poitcomptype, @poitcomponent, @poitmatlgroup, @poitmaterial, @porbdesc, @poitglco,
					@poitglacct, @poitum, @porbrecvdunits, @poitorigunitcost, @poitorigecm, @emum, @emunits,
					@postedcost, @poittaxgroup, @poittaxcode, @poittaxtype, @taxbasis, @postedtaxamt,
					----TK-07879
					@PORBPOItemLine
		end

	--Post GL Expense.  Does not include GST Tax
	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @poitglacct, @batchseq, @apline, 1,
				@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname,
				@poititemtype, @porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob,
				@poitphasegroup, @poitphase, @poitjcctype, @poitposttoco, @poitequip, @poitemgroup,
				@poitcostcode, @poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial,
				@postedcost, @apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
				----TK-07879
				@PORBPOItemLine
		
	-- post GST portion of tax to GST Payables
	-------------------------------------------------
	-- TK-15622 - purposely commented out - NO GST --
	-------------------------------------------------
	----if @gsttaxamt <> 0 and @HQTXdebtGLAcct is not null
	----	BEGIN
	----	--select @HQTXdebtGLAcct = isnull(@HQTXdebtGLAcct,@poitglacct)
	----	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @HQTXdebtGLAcct, @batchseq, @apline, 1,
	----			@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname,
	----			@poititemtype, @porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob,
	----			@poitphasegroup, @poitphase, @poitjcctype, @poitposttoco, @poitequip, @poitemgroup,
	----			@poitcostcode, @poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial,
	----			@gsttaxamt, @apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
	----			----TK-07879
	----			@PORBPOItemLine
	----	END				
	end

-- 'Old' Expense distributions
--if @oldpoititemtype = 3 and (@porbbatchtranstype = 'D' or @change = 'Y')
if @oldpoititemtype in (3,6) and (@porbbatchtranstype = 'D' or @change = 'Y') --mark
	begin
	-- set update amounts
	select @totalcost = @oldgrossamt + @oldtaxamt --REM'D Issue #131487: (case isnull(@oldvalueadd,'N') when 'N' then @oldtaxamt else 0 end) -- DC #128289  @oldtaxamt
	--TK-17927
	SET @oldpostedcost = @totalcost - @oldgsttaxamt
	--select @oldpostedcost = @totalcost - case when @oldHQTXdebtGLAcct is null then 0 else @oldgsttaxamt end		-- GL Expense  (Excludes GST tax)

	-- Set Negative Dollar values for OLD transaction posting
	select @oldpostedcost = (-1 * @oldpostedcost), @oldgsttaxamt = (-1 * @oldgsttaxamt)

	--Post old GL Expense.  Does not include GST Tax
	-- add old APGL entry - will make intercompany entries if needed
	if @oldpostedcost <> 0
		BEGIN
		exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @oldpoitglacct,
					@batchseq, @apline, 0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
					@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#, @oldpoitposttoco,
					@oldpoitjob, @oldpoitphasegroup, @oldpoitphase, @oldpoitjcctype, @oldpoitposttoco,
					@oldpoitequip, @oldpoitemgroup, @oldpoitcostcode, @oldpoitemctype, @oldpoitposttoco,
					@oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial, @oldpostedcost, @apglco, @oldintercoarglacct,
					@oldintercoapglacct, @oldporbpo, @oldporbpoitem,
					----TK-07879
					@OldPORBPOItemLine
		
		IF @oldpoititemtype = 6
		BEGIN
			INSERT INTO dbo.vSMDetailTransaction 
				(IsReversing, Posted, HQBatchDistributionID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, 
				TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
			SELECT 
				1, 0, @HQBatchDistributionID,
				(SELECT SMWorkCompletedID FROM SMWorkCompleted WHERE SMCo = @OldSMCo AND WorkOrder = @OldSMWorkOrder AND WorkCompleted = @OldSMWorkCompleted), 
				vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, 5 /*Purchase line type*/,
				'C', @poco, @mth, @batchid, @oldpoitglco, @oldpoitglacct, @oldpostedcost
			FROM vSMWorkOrderScope 
			INNER JOIN vSMWorkOrder ON vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder
			WHERE vSMWorkOrderScope.SMCo = @OldSMCo AND vSMWorkOrderScope.WorkOrder = @OldSMWorkOrder AND vSMWorkOrderScope.Scope = @OldSMScope	
		END
		
		
		END			   
			   
	-- post old GST portion of tax to GST Payables
	-------------------------------------------------
	-- TK-15622 - purposely commented out - NO GST --
	-------------------------------------------------
	----if @oldgsttaxamt <> 0 and @oldHQTXdebtGLAcct is not null
	----	begin
	----	--select @oldHQTXdebtGLAcct = isnull(@oldHQTXdebtGLAcct,@oldpoitglacct)
	----	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @oldHQTXdebtGLAcct,
	----				@batchseq, @apline, 0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
	----				@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#, @oldpoitposttoco,
	----				@oldpoitjob, @oldpoitphasegroup, @oldpoitphase, @oldpoitjcctype, @oldpoitposttoco,
	----				@oldpoitequip, @oldpoitemgroup, @oldpoitcostcode, @oldpoitemctype, @oldpoitposttoco,
	----				@oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial, @oldgsttaxamt, @apglco, @oldintercoarglacct,
	----				@oldintercoapglacct, @oldporbpo, @oldporbpoitem,
	----				----TK-07879
	----				@OldPORBPOItemLine
	----	end

	-- Reset Negative Dollar values for OLD transaction posting
	select @oldpostedcost = (-1 * @oldpostedcost), @oldgsttaxamt = (-1 * @oldgsttaxamt)			   
	end
			
-- 'New' Expense distributions
	if @poititemtype in (3,6) and (@porbbatchtranstype = 'A' or @change = 'Y')
	begin
	-- set update amounts
	select @totalcost = @grossamt + @taxamt --REM'D Issue #131487: (case isnull(@valueadd,'N') when 'N' then @taxamt else 0 end) -- DC #128289  @taxamt 
	--TK-17927
	SET @postedcost = @totalcost - @gsttaxamt
	--select @postedcost = @totalcost - case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end		-- GL Expense  (Excludes GST tax)

	--Post GL Expense.  Does not include GST Tax
	-- add new PORG entry - will make intercompany entries if needed
	IF @postedcost <> 0
	BEGIN
		EXEC @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @poitglacct, @batchseq, @apline, 1,
					@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname,
					@poititemtype, @porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob,
					@poitphasegroup, @poitphase, @poitjcctype, @poitposttoco, @poitequip, @poitemgroup,
					@poitcostcode, @poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial,
					@postedcost, @apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
					----TK-07879
					@PORBPOItemLine

		--If the line is for SM then we need to capture how much will be posted to GL
		--We capture the GL entries in a table variable to later be copied to the GLEntryTransaction table
		--It is important that we put the first record as the entry that used the POIT GL Account
		IF @poititemtype = 6
		BEGIN
			EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'PO Receipt', @TransactionsShouldBalance = 0, @msg = @errortext OUTPUT
			
			IF @GLEntryID = -1
			BEGIN
				--Log error
				GOTO PORB_error
			END
			
			--If this sproc was called from APLB Validation then we should have all the batch info and the ap line
			--If this sproc was called from PORB Validation then we should have all the batch info and the trans if it is a change, but no apline
			INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, BatchSeq, Line, Trans, InterfacingCo)
			VALUES (@GLEntryID, @poco, @mth, @batchid, @batchseq, @apline, @porbpotrans, @poco)

			INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
			VALUES (@GLEntryID, 1, @poitglco, @poitglacct, @postedcost, dbo.vfDateOnly(), @TransDesc)

			INSERT dbo.vPORDGLEntry (GLEntryID, GLTransactionForPOItemLineAccount)
			VALUES (@GLEntryID, 1)
			
			
			INSERT INTO dbo.vSMDetailTransaction 
				(IsReversing, Posted, HQBatchDistributionID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, 
				TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
			SELECT 
				0, 0, @HQBatchDistributionID, 
				(SELECT SMWorkCompletedID FROM SMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @SMWorkOrder AND WorkCompleted = @SMWorkCompleted), 
				vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, 5 /*Purchase line type*/, 
				'C', @poco, @mth, @batchid, @poitglco, @poitglacct, @postedcost
			FROM vSMWorkOrderScope 
			INNER JOIN vSMWorkOrder ON vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder
			WHERE vSMWorkOrderScope.SMCo = @SMCo AND vSMWorkOrderScope.WorkOrder = @SMWorkOrder AND vSMWorkOrderScope.Scope = @SMScope	
		END
	END
			
	-- post GST portion of tax to GST Payables
	-------------------------------------------------
	-- TK-15622 - purposely commented out - NO GST --
	-------------------------------------------------
	----if @gsttaxamt <> 0 and @HQTXdebtGLAcct is not null
	----	begin
	----	--select @HQTXdebtGLAcct = isnull(@HQTXdebtGLAcct,@poitglacct)
	----	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @HQTXdebtGLAcct, @batchseq, @apline, 1,
	----			@porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname,
	----			@poititemtype, @porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco, @poitjob,
	----			@poitphasegroup, @poitphase, @poitjcctype, @poitposttoco, @poitequip, @poitemgroup,
	----			@poitcostcode, @poitemctype, @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial,
	----			@gsttaxamt, @apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
	----			----TK-07879
	----			@PORBPOItemLine
	----	end
	end
   
-- 'Old' IN distributions
if @oldpoititemtype = 2 and (@porbbatchtranstype = 'D' or @change = 'Y')
	begin		
		
	-- set update amounts
	select @totalcost = case when @oldburdenyn = 'Y' then @oldgrossamt + @oldtaxamt else @oldgrossamt END
	--TK-17927
	select @oldpostedcost = case when @oldburdenyn = 'Y' then (@totalcost - @oldgsttaxamt) else @oldgrossamt end
	select @oldpostedtaxamt = (@oldtaxamt - @oldgsttaxamt)
	--select @oldpostedcost = case when @oldburdenyn = 'Y' then (@totalcost - case when @oldHQTXdebtGLAcct is null then 0 else @oldgsttaxamt end) else @oldgrossamt end
	--select @oldpostedtaxamt = case when @oldHQTXdebtGLAcct is null then @oldtaxamt else (@oldtaxamt - @oldgsttaxamt) end

	select @stdtotalcost = @oldpostedcost												-- set inventory total equal to posted total
	select @unitcost = 0, @stdunitcost = 0, @stdecm = isnull(@oldavgecm,@avgecm)		/*'E'*/  
	select @i = case @oldpoitorigecm when 'C' then 100 when 'M' then 1000 else 1 end
	if @oldporbrecvdunits <> 0 select @unitcost = (@oldpostedcost / @oldporbrecvdunits) * @i  -- unit cost per posted u/m
	select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end 
	if @oldstdunits <> 0 select @stdunitcost = (@stdtotalcost / @oldstdunits) * @i		-- unit cost per std u/m --#29588
	if @oldcostopt = 3     -- standard unit cost method
		begin
		select @stdunitcost = @oldfixedunitcost, @stdecm = @oldfixedecm
		select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end
		select @stdtotalcost = (@stdunitcost * @oldstdunits) / @i						-- update IN using fixed unit cost
		end
			
	select @variance = @oldpostedcost - @stdtotalcost		-- difference will only exist if using std cost method

	-- Set Negative Dollar values for OLD transaction posting
	select @oldpostedcost = (-1 * @oldpostedcost), @stdtotalcost = (-1 * @stdtotalcost),
		@oldporbrecvdunits = (-1 * @oldporbrecvdunits), @oldstdunits = (-1 * @oldstdunits),
		@oldgrossamt = (-1 * @oldgrossamt), @oldpostedtaxamt = (-1 * @oldpostedtaxamt),
		@variance = (-1 * @variance), @oldgsttaxamt = (-1 * @oldgsttaxamt)

	-- Post Old Inventory Distribution Expense - Excludes GST tax
    -- add old PORN entry
    if @oldpostedcost <> 0 or @oldporbrecvdunits <> 0
		begin
        exec @rcode = bspPORBExpValINInsert @poco, @mth, @batchid, @oldpoitposttoco, @oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial,
					@batchseq, @apline, 0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor,
					@oldporbpo, @oldporbpoitem, @oldpoitglco, @oldpoitglacct, @oldpoitum,
					@oldporbrecvdunits, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#, @unitcost,
					@oldpoitorigecm, @oldpostedcost, @oldstdum, @oldstdunits, @stdunitcost, @stdecm,
					@stdtotalcost,
					----TK-07879
					@OldPORBPOItemLine
        end
 
	-- add old PORG entries - will make intercompany entries if needed
	select @i = 0
	OldINGL_loop:
	select @glamt = 0

	-- Inventory - GL Expense account is Standard Unit Cost or Gross Amount
	if @i = 0 select @glamt = case when @oldcostopt = 3 then @stdtotalcost else @oldpostedcost end, @upglacct = @oldpoitglacct

	-- Tax if Unit Cost is not burdened - GL Location Tax account is Full Tax Amount when Debit GLAcct not used
	-- or is PST Tax only when GST tracked separately					--#16892 - do taxamt GL distribution for all cost options
	if @i = 1 and @oldburdenyn = 'N' and @oldpostedtaxamt <> 0 
	begin
		exec @rcode = bspGLACfPostable @oldpoitglco, @oldloctaxglacct, 'I', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- Inventory Tax GL Account:' + isnull(@oldloctaxglacct,'') + ':  ' + isnull(@errmsg,'')
			goto PORB_error
			end
		select @glamt = @oldpostedtaxamt, @upglacct = @oldloctaxglacct				-- DC #128289 (-1 * @oldtaxamt), 
	end
		   
    -- Cost Variance if using Fixed Unit Cost
    if @i = 2 and @oldcostopt = 3 and @variance <> 0
		begin
        exec @rcode = bspGLACfPostable @oldpoitglco, @oldlocvarianceglacct, 'I', @errmsg output
    	if @rcode <> 0
			begin
    	    select @errortext = @errorstart + '- Inventory Cost Variance GL Account:' + isnull(@oldlocvarianceglacct,'') + ':  ' + isnull(@errmsg,'')
    	    goto PORB_error
    	    end
		select @glamt = @variance, @upglacct = @oldlocvarianceglacct
        end
            
    -------------------------------------------------
    -- TK-15622 - purposely commented out - NO GST --
    -------------------------------------------------
	--DC #128289
	--if @i = 3 and @oldgsttaxamt <> 0 and @oldHQTXdebtGLAcct is not null
	--	begin			
	--	select @glamt = @oldgsttaxamt, @upglacct = @oldHQTXdebtGLAcct
	--	end            
            
	if @glamt <> 0
		begin
		exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @oldpoitglco, @upglacct, @batchseq, @apline, 0,
				@porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
				@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#, @oldpoitposttoco, 
				@oldpoitjob, @oldpoitphasegroup, @oldpoitphase, @oldpoitjcctype, @oldpoitposttoco, @oldpoitequip,
				@oldpoitemgroup, @oldpoitcostcode, @oldpoitemctype, @oldpoitposttoco, @oldpoitloc,
				@oldpoitmatlgroup, @oldpoitmaterial, @glamt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
				@oldporbpo, @oldporbpoitem,
				----TK-07879
				@OldPORBPOItemLine
		end

	select @i = @i + 1
	if @i < 4 goto OldINGL_loop

	-- Reset Negative Dollar values for OLD transaction posting
	select @oldpostedcost = (-1 * @oldpostedcost), @stdtotalcost = (-1 * @stdtotalcost),
		@oldporbrecvdunits = (-1 * @oldporbrecvdunits), @oldstdunits = (-1 * @oldstdunits),
		@oldgrossamt = (-1 * @oldgrossamt), @oldpostedtaxamt = (-1 * @oldpostedtaxamt),
		@variance = (-1 * @variance), @oldgsttaxamt = (-1 * @oldgsttaxamt)
	end

-- 'New' IN distributions
if @poititemtype = 2 and (@porbbatchtranstype = 'A' or @change = 'Y')
	begin
	
	-- set update amounts
	select @totalcost = case when @burdenyn = 'Y' then @grossamt + @taxamt else @grossamt END
	--TK-17927
	select @postedcost = case when @burdenyn = 'Y' then (@totalcost - @gsttaxamt) else @grossamt end
	select @postedtaxamt = (@taxamt - @gsttaxamt)
	--select @postedcost = case when @burdenyn = 'Y' then (@totalcost - case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end) else @grossamt end
	--select @postedtaxamt = case when @HQTXdebtGLAcct is null then @taxamt else (@taxamt - @gsttaxamt) end
	
--SELECT @errortext = '@postedcost: ' + dbo.vfToString(@postedcost) + char(10) + 
--					'@burdenyn: ' + dbo.vfToString(@burdenyn) + char(10) + 
--					'@totalcost: ' + dbo.vfToString(@totalcost) + char(10) + 
--					'@gsttaxamt:' + dbo.vfToString(@gsttaxamt)  + char(10) +
--					'@grossamt:' + dbo.vfToString(@grossamt)  + char(10) +
--					'@postedtaxamt:' + dbo.vfToString(@postedtaxamt)  + char(10) +
--					'@taxamt:' + dbo.vfToString(@taxamt)  
--SET @rcode = 1
--goto PORB_error
	
	select @stdtotalcost = @postedcost												-- set inventory total equal to posted total
	select @unitcost = 0, @stdunitcost = 0, @stdecm = @avgecm /*'E'*/ -- #29558
	select @i = case @poitorigecm when 'C' then 100 when 'M' then 1000 else 1 end
	if @porbrecvdunits <> 0 select @unitcost = (@postedcost / @porbrecvdunits) * @i  -- unit cost per posted u/m
	select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end --#29558
	if @stdunits <> 0 select @stdunitcost = (@stdtotalcost / @stdunits) * @i  -- unit cost per std u/m --#29558
	if @costopt = 3     -- standard cost method
		begin
		select @stdunitcost = @fixedunitcost, @stdecm = @fixedecm
		select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end
		select @stdtotalcost = (@stdunitcost * @stdunits) / @i    -- update IN using fixed unit cost
		end

	select @variance = @postedcost - @stdtotalcost			-- difference will only exist if using std cost method

	-- Post Inventory Distribution Expense - Excludes GST tax
	-- add new PORN entry
	if @postedcost <> 0 or @porbrecvdunits <> 0
		begin
		exec @rcode = bspPORBExpValINInsert @poco, @mth, @batchid, @poitposttoco, @poitloc,
					@poitmatlgroup, @poitmaterial, @batchseq, @apline, 1, @porbpotrans, @pohdvendorgroup,
					@pohdvendor, @porbpo, @porbpoitem,  @poitglco, @poitglacct, @poitum, @porbrecvdunits,
					@porbdesc, @porbrecvddate, @porbreceiver#, @unitcost, @poitorigecm, @postedcost,
					@stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost,
					----TK-07879
					@PORBPOItemLine
		end

	-- add new PORG entries - will make intercompany entries if needed
	select @i = 0
	NewINGL_loop:
	select @glamt = 0

	-- Inventory
	if @i = 0 select @glamt = case when @costopt = 3 then @stdtotalcost else @postedcost end, @upglacct = @poitglacct	--@grossamt

	-- Tax if Unit Cost is not burdened - GL Location Tax account is Full Tax Amount when Debit GLAcct not used
	-- or is PST Tax only when GST tracked separately					--#16892 - do taxamt GL distribution for all cost options
	if @i = 1 and @burdenyn = 'N' and @postedtaxamt <> 0   -- @taxamt <> 0  DC #128289  
		begin
		exec @rcode = bspGLACfPostable @poitglco, @loctaxglacct, 'I', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- Inventory Tax GL Account:' + isnull(@loctaxglacct,'') + ':  ' + isnull(@errmsg,'')
			goto PORB_error
			end
		select @glamt = @postedtaxamt, @upglacct = @loctaxglacct		--@taxamt,  DC #128289
		end

	-- Cost Variance if using Fixed Unit Cost
	if @i = 2 and @costopt = 3 and @variance <> 0
		begin
		exec @rcode = bspGLACfPostable @poitglco, @locvarianceglacct, 'I', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- Inventory Cost Variance GL Account:' + isnull(@locvarianceglacct,'') + ':  ' + isnull(@errmsg,'')
			goto PORB_error
			end
		select @glamt = @variance, @upglacct = @locvarianceglacct
		end
			
    -------------------------------------------------
    -- TK-15622 - purposely commented out - NO GST --
    -------------------------------------------------
	--DC #128289
	--if @i = 3 and @gsttaxamt <> 0 and @HQTXdebtGLAcct is not null
	--	begin			
	--	select @glamt = @gsttaxamt, @upglacct = @HQTXdebtGLAcct
	--	end
			
	if @glamt <> 0
	exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @poitglco, @upglacct,
				@batchseq, @apline, 1, @porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname,
				@poititemtype, @porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco,
				@poitjob, @poitphasegroup, @poitphase, @poitjcctype, @poitposttoco, @poitequip,
				@poitemgroup, @poitcostcode, @poitemctype, @poitposttoco, @poitloc, @poitmatlgroup,
				@poitmaterial, @glamt, @apglco, @intercoarglacct, @intercoapglacct, @porbpo, @porbpoitem,
				----TK-07879
				@PORBPOItemLine

	select @i = @i + 1
	if @i < 4 goto NewINGL_loop
	end

-- Remaining 'Old' GL distributions
if @porbbatchtranstype = 'D' or @change = 'Y'
	begin
    select @i = 0

OldGL_loop:
	select @glamt = 0
    -- Posted Payable - include Sales Tax
    if @i = 0 select @glamt = (@oldgrossamt
	  + (case @oldpoittaxtype 
			when 1 then @oldtaxamt 
			-- TK-15622 --
			WHEN 3 THEN @oldtaxamt - @oldgsttaxamt
			--when 3 then @oldtaxamt				--@oldgsttaxamt --DC #128289
			else 0 end)), @upglacct = @oldapglacct
			
    -- Use Tax Accrual
    if @i = 1 select @glamt = case @oldpoittaxtype when 2 then @oldtaxamt else 0 end, @upglacct = @glaccrualacct--@oldtaxaccrualacct
 
    -- add old PORG entry - no intercompany entries will be needed
    if @glamt <> 0
		begin
		exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @apglco, @upglacct,
				@batchseq, @apline, 0, @porbpotrans, @oldpohdvendorgroup, @oldpohdvendor, @oldsortname,
				@oldpoititemtype, @oldporbdesc, @oldporbrecvddate, @oldporbreceiver#,
				@oldpoitposttoco, @oldpoitjob, @oldpoitphasegroup, @oldpoitphase, @oldpoitjcctype,
				@oldpoitposttoco, @oldpoitequip, @oldpoitemgroup, @oldpoitcostcode, @oldpoitemctype,
				@oldpoitposttoco, @oldpoitloc, @oldpoitmatlgroup, @oldpoitmaterial,@glamt,
				@apglco, @intercoarglacct, @intercoapglacct, @oldporbpo, @oldporbpoitem,
				----TK-07879
				@OldPORBPOItemLine
		end

    select @i = @i + 1
    if @i < 2 goto OldGL_loop	--5
    end
   
-- Remaining 'New' GL distributions
if @porbbatchtranstype = 'A' or @change = 'Y'
	begin
	select @i = 0
	NewGL_loop:	  

	select @glamt = 0

	-- Posted Payables Type
	if @i = 0 select @glamt = -1 * (@grossamt + 
		(case @poittaxtype 
			when 1 then @taxamt
			-- TK-15622 --
			WHEN 3 THEN @taxamt	- @gsttaxamt
			--when 3 then @taxamt		--@gsttaxamt --DC #128289
			else 0 end)), 
			@upglacct = @glaccrualacct

	-- Use Tax Accrual
	if @i = 1 select @glamt = -1 * (case @poittaxtype when 2 then @taxamt else 0 end), @upglacct = @glaccrualacct--@taxaccrualacct

	-- add new PORG entry - no intercompany entries will be needed
	if @glamt <> 0
		begin
		exec @rcode = bspPORBExpValGLInsert @poco, @mth, @batchid, @apglco,@upglacct,
				@batchseq, @apline, 1, @porbpotrans, @pohdvendorgroup, @pohdvendor, @sortname,
				@poititemtype, @porbdesc, @porbrecvddate, @porbreceiver#, @poitposttoco,
				@poitjob, @poitphasegroup, @poitphase, @poitjcctype, @poitposttoco, @poitequip,
				@poitemgroup, @poitcostcode, @poitemctype, @poitposttoco, @poitloc,
				@poitmatlgroup, @poitmaterial, @glamt, @apglco, @intercoarglacct, @intercoapglacct,
				@porbpo, @porbpoitem,
				----TK-07879
				@PORBPOItemLine
		end

	select @i = @i + 1
	if @i < 2 goto NewGL_loop  --DC #128289		--5
	end
   
PORB_error:     -- record the validation error and skip to the next line
if @rcode <> 0
	begin
	exec @rcode = bspHQBEInsert @poco, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end   
   
bspexit:
--print 'BSP Exit'
select @errmsg = @errmsg + char(13) + char(10) + '[bspPORBExpVal]'
return @rcode















GO
GRANT EXECUTE ON  [dbo].[bspPORBExpVal] TO [public]
GO
