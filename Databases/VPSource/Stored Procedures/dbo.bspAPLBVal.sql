
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[bspAPLBVal]
/***********************************************************
* CREATED: GG 07/07/99
* MODIFIED: GG 08/10/99 - Fixed GL distribution for old entries - subtract old retainage from old gross
*			GR 08/16/99 - Added comptype and component to bcAPLB cursor
*                         passed oldmatlgrp and oldmatl to bspAPLBValEquip
*			GG 11/13/99 - added output params to bspAPLBValNew, bspAPLBValPO, and bspAPLBValSL - used to
*							fix RecvdNInvcd and RemCmtd calculations
*           GG 12/06/99 - fixed calls to bspAPLBValPO and bspAPLBValSL
*           GG 03/03/00 - reverse sign on updates to remaining units and costs to JC
*           GG 03/06/00 - include tax in RNI Cost updates to JC if PO Item Recv = 'Y'
*           GR 04/13/00 - Added the validation for supplier if exists
*           GG 05/08/00 - Fixed RemCmtdCost and RNI Cost updates to bAPJC - use calculated tax
*           GG 06/06/00 - Added validtaion for Expense Journal
*           GG 06/16/00 - Modified for changes to bAPIN
*           GG 06/20/00 - Tax info updated to bAPJC and bAPEM
*           kb 8/20/00  - issue #10146 - valdating disc date, can't be null if discount <> 0
*           GH 08/22/00 - Added isnull to @remcmtdcost when checking to insert APJC record
*           GR 09/06/00 - issue# 10343 - fixed call to bspAPLBValJCInsert
*           GR 11/21/00 - changed datatype from bAPRef to bAPReference
*           GR 11/29/00 - Fixed issue# 11403
*           GG 12/11/00 - Fixed issue #11475, old tax backed out of wrong phase
*			TV 03/13/01 - Validate @CompType
*           DANF 05/14/01 - Added Update for expensed PO Receipts.
*           GG 05/23/01 - fixed GL distributions for old IN lines when using burdened unit cost
*           bc 07/25/01 - sent fuelcapum error into HQBE instead of throwing a msgbox during validation.
*           GG 07/27/01 - fixed 'old' IN GL distributions (#14131), moved EM CompType validation to bspAPLBValEquip
*		 	GG 08/27/01 - #14461 - pull tax accrual account using AP Co# tax group
*		 	GH 08/31/01 - Added isnull to @fueltype when validating fuel info, issue #14512
*		 	GH 09/18/01 - issue #14647 added @oldcomptype to bspAPLBValEquip call
*			GG 09/21/01 - #14461 changed use tax validation and updates, also removed EM fuel capacity
*							validation now performed in EM triggers (#14132)
*           kb 12/10/01 - issue #11857
*           allenn 01/21/02 - issue 14529 - added validation error when taxcode is null and taxamount<>0
*           kb 01/29/02 - issue #15980
*			MV 02/04/02 - issue 14681 removed @uptaxgroup, use @taxgroup or @oldtaxgroup from APLB. Removed 
*							@apcotaxgroup param for bspAPLBValNew.
*           danf 03/19/02 Fix PO Receipt Exp By adding Delete along with change  to correct removal of entry
*			MV 03/26/02 - #14164 validate changes to paid lines.
*			MV 04/19/02 - #16892 GL distributions of tax and misc costs for non burdened, non standard IN transactions
*							also made modifications to bspPORBExpVal for IN distributions.
*			MV 04/29/02 - #17041 GL distributions for freight/misc costs when costs are burdened but Inc=N (MiscYN=N)
*			kb 05/16/02 - issue #17041 - in delete section of this issue need to not multiply by -1
							cause we are backing out
*			DANF 09/05/02 - 17738 Added PhaseGroup to bspAPLBValJob & bspJCCAGlacctDflt
*			MV 10/15/02 - #18720 - validate the vendor against PO or SL vendor for PO or SL lines.
*			MV 10/22/02 - #19063 - Old JC Distributions - default to oldphase, oldjcctype, oldglacct if no tax  
*						    but remaining committed costs to back out.
*           kb 10/28/02 - issue #18878 - fix double quotes
*			MV 01/08/03 - #18720 - validate vendor against PO and SL lines in bAPTL
*			MV 03/04/03 - #19926 - remaining committed cost/units, total committed cost/units for Standing PO
*			MV 09/02/03 - #21978 - added 2 output params to bspAPLBValPO, performance enhancements 
*			MV 11/11/03 - #22947 - added @invdate to bspAPLBValPO params for HQTX taxrate
*			MV 12/01/03 - #22664 - don't include Misc Amt in Total Cmtd Cost for standing POs not flagged for receiving
*			MV 12/08/03 - #23224 - trap for null @potaxrate, @oldpotaxrate
*			MV 02/09/04 - #18769 - Pay Category / #23061 isnull wrap 
*			ES 03/11/04 - #23061 - isnull wraps
*			MV 04/26/04 - #18769 - oldpaycategory retpaytype validation
*			MV 05/26/05 - #28714 - calc RemCmtdCost for tax on POs for update to JCCD the same as PO calculates it
*			MV 08/16/05 - #29558 - Use AvgECM to calculate StdUnitCost for Inventory update to bAPIN
*			MV 09/15/05 - #29610 - update APJC with taxbasis even if taxamt=0
*			MV 11/11/05 - #30340 - isnull wrap @oldavgecm 
*			MV 01/25/06 - #120033 - 6X fix for 5X issue #119950
*			MV 06/15/06 - #120234 - 6X fix for 5X issue #120125
*			MV 02/13/07 - #		  - removed 'bspAPLBVal' from error msg
*			MV 06/06/08 - #128288 - VAT/GST tax in GL distributions
*			MV 09/11/08 - #129788 - don't updated APJC for tax if taxbasis <> 0 BUT taxcode is null
*			MV 12/01/08 - #131275 - fixed APGL distribution for Job with VAT that isn't PST or GST 
*			MV 12/09/08 - #131380 - related to #128288 - more VAT bug fixes
*			MV 12/10/08 - #131385 - related to #128288 - VAT bug fixes for PO and S
*			MV 12/11/08 - #131407 - related to #128288 - Use tax update to GL Distributions
*			MV 12/18/08 - #131503 - GST tax was doubling in GL Dist if no Debit GL Acct for taxcode
*			MV 05/05/09 - #30264  - if tax is redirected don't include tax amount in JC unit cost calc
*			MV 07/29/09 - #133959 - corrected backing out old retainage GLAcct and old DiscOffered GL Acct
*			MV 08/20/09 - #135211 - don't evaluate tax type on paid line unless there is a taxcode.
*			DC 12/15/09 - #122288 - Store Tax Rate in POIT
*			MV 12/16/09 - #136903 - Don't validate old retainage paytype if no retainage
*			DC 12/29/09 - #130175 - SLIT needs to match POIT
*			MV 02/09/10 - #136500 - GST taxbasis net retainage, break out retg GST payable
*			MV 03/29/10 - #134876 - use closed Job GL Acct if job status = 3 - hard closed when posting changed or deleted lines.
*			MV 05/18/10	- #134876 - post tax to closed Job GL Acct
*			MV 05/19/10 - #136500 - fixed calc to open payables
*			TJL 05/27/10 - #139910- GST not removed from EMCD.TaxAmount when AP Transaction gets Changed or Deleted
*			GP 06/28/10 - #135813 - change bSL to varchar(30)
*			MV 07/15/10 - #133107 - Check Reversal on Holdback GST Payables 
*			CHS	08/05/10 - #140813- error invoicing to a hard closed job.
*			MV 11/30/10 - #141846 - 1) Validate Tax Code Retg GST payables against APCO TaxBasisNetRetg flag,
*									2) use Retg GST Payables GL Acct only flag is checked.
*			MH 12/09/10 - #131640  - Changes to support SM.  Need to recognize PO Line Type 6 - SM Work Order.
*			EN 05/05/11 - TK-04672/- #143321 To resolve Missing GST credit when deleting transaction changed @pstrate to @oldpstrate
*			GF 08/04/11 - TK-07144 - EXPAND PO
*			MV 08/10/11 - TK-07621 - AP project to use POItemLine
*			CHS	08/29/11- TK-07986 - added parameters in call to bspPORBExpVal
*			MV 09/01/11 - TK-08150 - Retg GST GL Acct edge case
*			JVH 09/06/11- TK-08137 - Capture cost for PO Lines for transfering cost
*			MV 10/25/11 - TK-09243 - return @oldcrdRetgPSTGLAcct from bspHQTaxRateGetAll
*			MV 10/27/11 - TK-09245 - break out retainage PST tax into it's own payables GL Acct
*			JG 01/23/12 - TK-11971 - Added JCCostType and PhaseGroup
*			MV 01/31/12 - TK-11875 - On-Cost validation (SubjToOnCostYN, OnCostStatus)
*			TL 03/08/12 - TK-12858 - added code to update variables @oldsmservicesite and @oldsmtaxgroup
*			TL 03/19/12 - TK-13408 - fixed code for SM/JC TaxCode Phase/Cost Redirect
*			TL 04/16/12 - TK-13994 - Added code to update APSM.Phase from APBL.SMPhase/OLdPhase
*			TL 04/24/12 - TK-14135 - removed @smtaxgroup
*			MV 04/26/12 - TK-14041 - commented out On-Cost validation
*			MV 05/08/12 - TK-14683 - validate GST/PST taxcode GL accounts only if there is a taxcode on the line.
*			MV 05/15/12 - TK-14964 - validate GST/PST credit retg GL Acct only if there is retainage on the line.
*			LG 08/09/12 - TK-16873 - validates deleted AP Translation Entry for SM line type
*			MV 08/16/12 - TK-17202 - fix GST/PST distributions when the calculated Tax Amount is overidden. 
*			JB 12/10/12 - Fix to support SM PO receiving
*			JVH 04/01/13- TFS-43390 Modified check for sm gl accounts
*			MV 04/24/13 - TFS-48245 Changed/Deleted Job - fix calc for OldPST/OldGst where taxbasis is net of retg.
*           ECV 04/30/13- TFS-48164 Modified to create a Delete and Add record instead of a Change records when changing line types from a type of 8 SM to a type 6 PO subtype 6 SM, or when changing from type 6 PO subtype 6 SM to a type of 8 SM.
*			KK 06/11/13 - TFS-51899 Added code to reset the values that will be populated by bspHQTaxRateGetAll and bspHQTaxRateGet
*
* ** Note Any changes made in this bsp may also need to be changed in bspPORBExpVal --- DANF *
*
* USAGE:
* Called from bspAPHBVal to validate the lines of a Batch Sequence and
* create distributions in bAPJC, bAPEM, bAPIN, and/or bAPGL.
*
* Errors in batch added to bHQBE
*
* INPUT PARAMETERS:
*  @apco               AP Company
*  @mth                Batch month
*  @batchid            Batch ID#
*  @batchseq           Batch sequence - a transaction
*  @headertranstype    Header transaction type ('A','C','D')
*  @aptrans            AP Transaction # for type 'C' and 'D', null if 'A'
*  @vendorgroup        Vendor Group - current
*  @vendor             Vendor # - current
*  @sortname           Vendor Sort Name - current
*  @oldvendorgroup     Vendor Group - old
*  @oldvendor          Vendor # - old
*  @oldsortname        Vendor Sort Name = old
*  @apref              AP Reference - current
*  @oldapref           AP Reference - old
*  @transdesc          Transaction description - current
*  @oldtransdesc       Transaction description - old
*  @invdate            Invoice Date - current
*  @oldinvdate         Invoice Date - old
*
* OUTPUT PARAMETERS
*    @errmsg           error message
*
* RETURN VALUE
*    0                 success
*    1                 failure
*****************************************************/
	@apco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @headertranstype char(1),
	@aptrans bTrans, @vendorgroup bGroup, @vendor bVendor, @sortname varchar(15), @oldvendorgroup bGroup,
	@oldvendor bVendor, @oldsortname varchar(15), @apref bAPReference, @oldapref bAPReference,
	@transdesc bDesc, @oldtransdesc bDesc, @invdate bDate, @oldinvdate bDate, @errmsg varchar(255) output

  as
  
  set nocount on
  
	declare @rcode int, @openAPLB tinyint, @errorstart varchar(50), @errortext varchar(255), @recyn bYN,
	@jcum bUM, @jcunits bUnits, @emum bUM, @emunits bUnits, @stdum bUM, @stdunits bUnits, @costopt tinyint,
	@fixedunitcost bUnitCost, @fixedecm bECM, @burdenyn bYN, @loctaxglacct bGLAcct, @locmiscglacct bGLAcct,
	@locvarianceglacct bGLAcct, @accounttype char(1), @intercoarglacct bGLAcct, @intercoapglacct bGLAcct,
	@active bYN, @apglacct bGLAcct, @taxaccrualacct bGLAcct, @taxphase bPhase, @taxct bJCCType, @taxglacct bGLAcct,
	@retglacct bGLAcct, @oldrecyn bYN, @oldjcum bUM, @oldjcunits bUnits, @oldemum bUM, @oldemunits bUnits, @oldstdum bUM,
	@oldstdunits bUnits, @oldcostopt tinyint, @oldfixedunitcost bUnitCost, @oldfixedecm bECM, @oldburdenyn bYN,
	@oldloctaxglacct bGLAcct, @oldlocmiscglacct bGLAcct, @oldlocvarianceglacct bGLAcct, @oldintercoarglacct bGLAcct,
	@oldintercoapglacct bGLAcct, @oldapglacct bGLAcct,@oldtaxphase bPhase, @oldtaxct bJCCType, @oldtaxaccrualacct bGLAcct,
	@oldtaxglacct bGLAcct, @change char(1), @totalcost bDollar, @rniunits bUnits, @rnicost bDollar, @remcmtdcost bDollar,
	@jcunitcost bUnitCost, @slitemtype tinyint, @oldslitemtype tinyint, @u1 bUnitCost, @u2 bUnitCost, @c1 bDollar,
	@stdunitcost bUnitCost, @i smallint, @stdecm bECM, @variance bDollar, @upglacct bGLAcct, @glamt bDollar,
	@upphase bPhase, @upunits bUnits, @upjcctype bJCCType, @upum bUM, @upjcum bUM, @upjcunits bUnits, @upjcecm bECM,
	@uptaxbasis bDollar, @uptaxamt bDollar, @factor smallint, @oldcurunitcost bUnitCost, @oldcurecm bECM,
	@curunitcost bUnitCost, @curecm bECM, @taxrate bRate, @oldtaxrate bRate, @stdtotalcost bDollar, @unitcost bUnitCost,
	@c2 bDollar, @t1 bDollar, @t2 bDollar, @receiptupdate bYN, @pounits bUnits, @pogrossamt bDollar,
	@oldpounits bUnits, @oldpogrossamt bDollar, @apcotaxgroup bGroup, @usetaxamt bDollar, @remcmtdunits bUnits,
	@curcost bDollar, @curunits bUnits, @totalcmtdunits bUnits, @totalcmtdcost bDollar, @retpaytype tinyint,
	@discoffglacct bGLAcct, @posltaxbasis bDollar, @avgecm bECM, @oldavgecm bECM,@origunits bUnits, @origcost bDollar,
	@oldretpaytype tinyint, @oldretglacct bGLAcct, @olddiscoffglacct bGLAcct, @APHBCheckRevYN bYN, @smLineTypeChanged bit

	-- GST/PST declares
	declare @valueadd char(1), @gstrate bRate, @pstrate bRate, @dbtGLAcct bGLAcct, @dbtRetgGLAcct bGLAcct, @gstTaxAmt bDollar,
	@retgGstTaxAmt bDollar, @VATpstTaxAmt bDollar, @payTaxAmt bDollar, @retgTaxAmt bDollar, @retgPstTaxAmt bDollar, 
	@pstTaxAmt bDollar, @VATgstTaxAmt bDollar, @poGSTrate bRate, @oldvalueadd char(1), @oldgstrate bRate, @oldpstrate bRate, @olddbtGLAcct bGLAcct,
	@olddbtRetgGLAcct bGLAcct, @oldgstTaxAmt bDollar, @oldretgGstTaxAmt bDollar, @oldVATpstTaxAmt bDollar, @oldpayTaxAmt bDollar,
	@oldretgTaxAmt bDollar, @oldretgPstTaxAmt bDollar, @oldpstTaxAmt bDollar, @oldVATgstTaxAmt bDollar,@oldpoGSTrate bRate, @poslTaxAmt bDollar,
	@poslGSTtaxAmt bDollar, @oldposlTaxAmt bDollar,@oldposlGSTtaxAmt bDollar,@sltaxrate bRate,@slGSTrate bRate, @oldsltaxrate bRate,
	@oldslGSTrate bRate, @crdRetgGSTGLAcct bGLAcct, @oldcrdRetgGSTGLAcct bGLAcct, @crdRetgPSTGLAcct bGLAcct, @oldcrdRetgPSTGLAcct bGLAcct
			
  
	-- APCO declares
	declare @apglco bCompany, @expjrnl bJrnl, @pototyn bYN, @sltotyn bYN, @netamtopt bYN, @APretpaytype tinyint,
	@APdiscoffglacct bGLAcct, @retholdcode bHoldCode, @APCOTaxBasisNetRetg bYN

	-- APLB declares
	declare @apline smallint, @linetranstype char(1), @LineType tinyint, @po VARCHAR(30), @poitem bItem, @POItemLine INT,@itemtype tinyint,
	@sl varchar(30), @slitem bItem, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType,
	@emco bCompany, @wo bWO, @woitem bItem, @equip bEquip, @emgroup bGroup, @costcode bCostCode, @emctype bEMCType,
	@comptype varchar(10), @component bEquip, @inco bCompany, @loc bLoc, @matlgroup bGroup, @matl bMatl,
	@glco bCompany, @glacct bGLAcct, @linedesc bDesc, @um bUM, @apunits bUnits, @apunitcost bUnitCost, @ecm bECM,
	@suppliergroup bGroup, @supplier bVendor, @paytype tinyint, @grossamt bDollar, @miscamt bDollar, @miscyn bYN,
	@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxamt bDollar, @retainage bDollar,
	@discount bDollar, @burunitcost bUnitCost, @becm bECM, @oldlinetype tinyint, @oldpo VARCHAR(30), @oldpoitem bItem, @OldPOItemLine INT,
	@olditemtype tinyint, @oldsl varchar(30), @oldslitem bItem, @oldjcco bCompany, @oldjob bJob, @oldphasegroup bGroup,
	@oldphase bPhase, @oldjcctype bJCCType, @oldemco bCompany, @oldwo bWO, @oldwoitem bItem, @oldequip bEquip,
	@oldemgroup bGroup, @oldcostcode bCostCode, @oldemctype bEMCType, @oldcomptype varchar(10), @oldcomponent bEquip,
	@oldinco bCompany, @oldloc bLoc, @oldmatlgroup bGroup, @oldmatl bMatl, @oldglco bCompany, @oldglacct bGLAcct,
	@oldlinedesc bDesc, @oldum bUM, @oldunits bUnits, @oldunitcost bUnitCost, @oldecm bECM, @oldpaytype tinyint,
	@oldgrossamt bDollar, @oldmiscamt bDollar, @oldmiscyn bYN, @oldtaxgroup bGroup, @oldtaxcode bTaxCode,
	@oldtaxtype tinyint, @oldtaxbasis bDollar, @oldtaxamt bDollar, @oldretainage bDollar, @olddiscount bDollar,
	@oldburunitcost bUnitCost, @oldbecm bECM, @oldpotaxrate bRate, @potaxrate bRate, @linepaidyn bYN, @oldsupplier bVendor,
	@oldpotaxcode bTaxCode, @oldpotaxgroup bGroup, @paycategory int, @oldpaycategory int, @smco bCompany, @smworkorder int, 
	@scope int, @smcosttype smallint, @oldsmco bCompany, @oldsmworkorder int, @oldscope int, @oldsmcosttype smallint,
	@smjccosttype dbo.bJCCType, @oldsmjccosttype dbo.bJCCType, @smphasegroup dbo.bGroup, @oldsmphasegroup dbo.bGroup,
	@smphase dbo.bPhase, @oldsmphase dbo.bPhase,
	@SubjToOnCostYN bYN, @OldSubjToOnCostYN bYN, @smtaxcode bTaxCode, @smtaxgroup bGroup, @smtaxtype tinyint, 
	@smtaxrate bRate, @smtaxamt bDollar

	--APJC declares  --DC #122288
	declare @totalcmtdtax bDollar, @remcmtdtax bDollar

	--APSM declares
	DECLARE @oldsmlinedesc varchar(60), @oldsmservicesite varchar(20), @oldsmtype tinyint
	DECLARE @smlinedesc varchar(60),  @smservicesite varchar(20), @smtype tinyint,
	@aptlkeyid bigint, @smoldnew tinyint, @HQBatchDistributionID bigint, @HQBatchLineID bigint

	--Closed Job declares -- #134876
	declare @status tinyint, @contract bContract, @dept bDept,@closedGLAcct bGLAcct

	--PO Receipt Transfer declares
	DECLARE @GLEntryID bigint, @GLJobDetailDesc varchar(60), @GLInvDetailDesc varchar(60), @GLEquipDetailDesc varchar(60), @GLExpDetailDesc varchar(60), @GLExpTransDesc varchar(60), @TransactionDescription bTransDesc

	select @rcode = 0, @totalcmtdtax = 0, @remcmtdtax = 0 /*DC #122288*/, @errorstart = ''  --#23061	
  
	-- get AP Company info
	select @apglco = GLCo, @expjrnl = ExpJrnl, @pototyn = POTotYN, @sltotyn = SLTotYN, @netamtopt = NetAmtOpt,
	@APretpaytype = RetPayType, @APdiscoffglacct = DiscOffGLAcct, @retholdcode = RetHoldCode, @APCOTaxBasisNetRetg = TaxBasisNetRetgYN,
	@GLJobDetailDesc = GLJobDetailDesc, @GLInvDetailDesc = GLInvDetailDesc, @GLEquipDetailDesc = GLEquipDetailDesc, @GLExpDetailDesc = GLExpDetailDesc, @GLExpTransDesc = GLExpTransDesc
	from bAPCO WITH (NOLOCK) where APCo = @apco
	if @@rowcount = 0
	begin
		select @errmsg = 'Invalid AP Co#!', @rcode = 1
		goto bspexit
	end

	-- APHB info
	SELECT @APHBCheckRevYN = ChkRev	FROM dbo.APHB WHERE Co = @apco AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @batchseq
	
  -- create a cursor to validate each line within this transaction
	declare bcAPLB cursor LOCAL FAST_FORWARD for
	select APLine, BatchTransType, LineType, PO, POItem, POItemLine,ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType,
	EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType, CompType, Component,
	INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description, UM, Units, UnitCost, ECM,
	VendorGroup, Supplier, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
	Retainage, Discount, BurUnitCost, BECM,PayCategory,
	OldLineType, OldPO, OldPOItem, OldPOItemLine,OldItemType, OldSL, OldSLItem, OldJCCo, OldJob, OldPhaseGroup, OldPhase, OldJCCType,
	OldEMCo, OldWO, OldWOItem, OldEquip, OldEMGroup, OldCostCode, OldEMCType, OldCompType, OldComponent,
	OldINCo, OldLoc, OldMatlGroup, OldMaterial, OldGLCo, OldGLAcct, OldDesc, OldUM, OldUnits, OldUnitCost, OldECM,
	OldPayType, OldGrossAmt, OldMiscAmt, OldMiscYN, OldTaxGroup, OldTaxCode, OldTaxType, OldTaxBasis, OldTaxAmt,
	OldRetainage, OldDiscount, OldBurUnitCost, OldBECM, PaidYN, OldSupplier, OldPayCategory, SMCo, SMWorkOrder, Scope,
	SMCostType, OldSMCo, OldSMWorkOrder, OldScope, OldSMCostType, APTLKeyID, 
	SMJCCostType, OldSMJCCostType, SMPhaseGroup, OldSMPhaseGroup,SMPhase,OldSMPhase,OldSubjToOnCostYN, SubjToOnCostYN
	from bAPLB WITH (NOLOCK)
	where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
  
	open bcAPLB
	select @openAPLB = 1
  
APLB_loop:      -- loop through each line

	fetch next from bcAPLB into @apline, @linetranstype, @LineType, @po, @poitem, @POItemLine, @itemtype, @sl, @slitem,
	@jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup, @costcode,
	@emctype, @comptype, @component, @inco, @loc, @matlgroup, @matl, @glco, @glacct, @linedesc,
	@um, @apunits, @apunitcost, @ecm, @suppliergroup, @supplier, @paytype, @grossamt, @miscamt, @miscyn,
	@taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt, @retainage, @discount, @burunitcost, @becm, @paycategory,
	@oldlinetype, @oldpo, @oldpoitem, @OldPOItemLine, @olditemtype, @oldsl, @oldslitem, @oldjcco, @oldjob, @oldphasegroup,
	@oldphase, @oldjcctype, @oldemco, @oldwo, @oldwoitem, @oldequip, @oldemgroup, @oldcostcode, @oldemctype,
	@oldcomptype, @oldcomponent, @oldinco, @oldloc, @oldmatlgroup, @oldmatl, @oldglco, @oldglacct,
	@oldlinedesc, @oldum, @oldunits, @oldunitcost, @oldecm, @oldpaytype, @oldgrossamt, @oldmiscamt,
	@oldmiscyn, @oldtaxgroup, @oldtaxcode, @oldtaxtype, @oldtaxbasis, @oldtaxamt, @oldretainage,
	@olddiscount, @oldburunitcost, @oldbecm, @linepaidyn, @oldsupplier, @oldpaycategory,@smco, 
	@smworkorder, @scope, @smcosttype, @oldsmco, @oldsmworkorder, @oldscope, @oldsmcosttype, @aptlkeyid,
	@smjccosttype, @oldsmjccosttype, @smphasegroup, @oldsmphasegroup, @smphase,@oldsmphase,@OldSubjToOnCostYN, @SubjToOnCostYN
         
  	if @@fetch_status <> 0 goto bspexit
  
	select @errorstart = 'Seq#: ' + isnull(convert(varchar(6),@batchseq), '') + 
	' Line: ' + isnull(convert(varchar(6),@apline), '') + ' '  --#23061

	/* Reset some processing variables */
	select @payTaxAmt = 0,	@retgTaxAmt = 0,		@gstTaxAmt = 0,			@retgGstTaxAmt = 0,		@pstTaxAmt = 0, 
	@retgPstTaxAmt = 0, 	@VATgstTaxAmt = 0,		@VATpstTaxAmt = 0,		@oldpayTaxAmt = 0,		@oldretgTaxAmt = 0,		
	@oldgstTaxAmt = 0,		@oldretgGstTaxAmt = 0,	@oldpstTaxAmt = 0,		@oldretgPstTaxAmt = 0,	@oldVATgstTaxAmt = 0,	
	@oldVATpstTaxAmt = 0,	@poslTaxAmt = 0,		@poslGSTtaxAmt = 0,		@oldposlTaxAmt = 0,		@oldposlGSTtaxAmt = 0,
	-- Reset the values that will be "repopulated" by bspHQTaxRateGetAll and bspHQTaxRateGet
	@oldtaxrate = 0,		@oldgstrate = 0,		@oldpstrate = 0,	
	@oldvalueadd = NULL,	
	@olddbtGLAcct = NULL,
	@olddbtRetgGLAcct = NULL,	
	@oldcrdRetgGSTGLAcct = NULL,	
	@oldcrdRetgPSTGLAcct = NULL,	
	@oldtaxphase = NULL,	
	@oldtaxct = NULL

	/*Issue 14529*/
	-- check for Tax Code
	if @taxamt > 0 and @taxcode is null
	begin
		select @errortext = @errorstart + ' -  Tax Code missing where Tax Amount does not equal $0.00'
		goto APLB_error
	end
  
	--  validate Batch Transaction Type
	if @linetranstype not in ('A', 'C', 'D')
	begin
		select @errortext = @errorstart + ' -  Invalid transaction type, must be (A),(C), or (D).'
		goto APLB_error
	end

	if @headertranstype in ('A','D') and @linetranstype <> @headertranstype
	begin
		select @errortext = @errorstart + ' - Invalid transaction type, must match header.'
		goto APLB_error
	end

	-- validate Batch Transaction type delete 
	if @linetranstype = 'D' and @linepaidyn='Y'
	begin
		select @errortext = @errorstart + ' -  Cannot delete a paid line.'
		goto APLB_error
	end

	-- validate Line Type
	if @LineType < 1 or @LineType > 8
	begin
		select @errortext = @errorstart + ' Invalid Line Type!'
		goto APLB_error
	end

	--validate PayCategory
	if @paycategory is not null
	begin
		select @retpaytype=RetPayType, @discoffglacct=DiscOffGLAcct 
		from bAPPC with (nolock)
		where APCo=@apco and PayCategory=@paycategory
		if @@rowcount=0
		begin
			select @errortext = @errorstart + ' Invalid Pay Category!'
			goto APLB_error
		end
	end
	else
	begin
		select @retpaytype=@APretpaytype, @discoffglacct=@APdiscoffglacct
	end
	
	--Build out the description so that it can be saved off with
	--the GL Transaction Entries. Only currently used for SM Line types.
	SET @TransactionDescription = RTRIM(dbo.vfToString(CASE 
		--PO Lines need to be translated based on their item type
		CASE WHEN @LineType = 6 AND @itemtype = 6 THEN 8 /*The SMLineType the only line type that doesn't directly translate*/ WHEN @LineType = 6 THEN @itemtype ELSE @LineType END
			WHEN 1 THEN @GLJobDetailDesc		-- job
          	WHEN 2 THEN @GLInvDetailDesc		-- inventory
          	WHEN 3 THEN @GLExpDetailDesc		-- expense
          	WHEN 4 THEN @GLEquipDetailDesc		-- equipment
          	WHEN 5 THEN @GLEquipDetailDesc		-- work order - equipment
          	WHEN 7 THEN @GLJobDetailDesc		-- subcontract - job
          	WHEN 8 THEN @GLExpTransDesc			-- SM currently we don't have a transaction level description. This may need to change.
			ELSE @GLExpTransDesc END))

	SELECT
		@TransactionDescription = REPLACE(@TransactionDescription, 'InvDesc', dbo.vfToString(@transdesc)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Vendor#', dbo.vfToString(@vendor)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'SortName', dbo.vfToString(@sortname)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'APRef', dbo.vfToString(@apref)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'InvDate', dbo.vfToString(CONVERT(VARCHAR, @invdate, 107))),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Line', dbo.vfToString(@apline)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'LineDesc', dbo.vfToString(@linedesc)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Matl', dbo.vfToString(@matl)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'JCCo', dbo.vfToString(@jcco)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Job', dbo.vfToString(@job)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Phase', dbo.vfToString(@phase)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'JCCT', dbo.vfToString(@jcctype)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'INCo', dbo.vfToString(@inco)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Loc', dbo.vfToString(@loc)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'EMCo', dbo.vfToString(@emco)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Equip', dbo.vfToString(@equip)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'CostCode', dbo.vfToString(@costcode)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'EMCT', dbo.vfToString(@emctype))
		--We don't update the Trans# description since we don't know it yet. 
		--If it is in there at the time of posting we should put it in.

	--Retrieve the HQDistributionID created in bspAPHBVal
	EXEC @rcode = dbo.vspHQBatchDistributionGet @BatchCo = @apco, @BatchMth = @mth, @BatchId = @batchid, @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @errmsg OUTPUT
	IF @rcode <> 0
	BEGIN
		SELECT @errortext = @errorstart + '- ' + dbo.vfToString(@errmsg)
		GOTO APLB_error
	END
	
	SET @HQBatchLineID = NULL
	
	IF @oldlinetype = 8 OR @LineType = 8
	BEGIN
		--Currently detail is only associated with SM Work Completed and so if 
		--the new line is not going to be an SM line then the detail should be deleted
		--If ever it is changed so the detail is captured on the APTL record then the line
		--should no longer be marked as deleted so that it doens't end up deleting the detail.
		INSERT dbo.vHQBatchLine (Co, Mth, BatchId, Seq, Line, BatchTransType, HQDetailID)
		SELECT @apco, @mth, @batchid, @batchseq, @apline, CASE WHEN @LineType <> 8 THEN 'D' ELSE @linetranstype END, (SELECT CostDetailID FROM dbo.vSMWorkCompleted WHERE APTLKeyID = @aptlkeyid)
		
		SET @HQBatchLineID = SCOPE_IDENTITY()
	END

	if @linetranstype in ('A','C')  -- common validation for Add and Change entries
	begin
		exec @rcode = bspAPLBValNew @apco, @mth, @batchid, @batchseq, @invdate, @apline, @apglco, @expjrnl, @pototyn, @sltotyn,
		@netamtopt,@retpaytype, @discoffglacct, @retholdcode, @HQBatchDistributionID, @recyn output, @slitemtype output,
		@jcum output, @jcunits output, @emum output, @emunits output, @stdum output, @stdunits output,
		@costopt output, @fixedunitcost output, @fixedecm output, @burdenyn output, @loctaxglacct output,
		@locmiscglacct output, @locvarianceglacct output, @intercoarglacct output, @intercoapglacct output,
		@apglacct output, @taxaccrualacct output, @taxphase output, @taxct output, @taxglacct output, @taxrate output,
		@retglacct output, @curunitcost output, @curecm output, @potaxrate output, @avgecm output, @valueadd output,
		@gstrate output,@pstrate output,@dbtGLAcct output, @dbtRetgGLAcct output, @poGSTrate output,@sltaxrate output,
		@slGSTrate output, @crdRetgGSTGLAcct output, @crdRetgPSTGLAcct output, @errmsg output

		if @rcode <> 0
		begin
			select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
			goto APLB_error
		end
    
		/*DC #122288  Get POIT !Tax Rate
		I wasn't sure where else bspAPLBValPO gets called.  bspAPLBValNew does call bspAPLBValPO and I wasn't
		sure what else in AP calls bspAPLBValNew.  for issue #122288 I need to get the tax rate from POIT so 
		I just reset the same variables that was being used to the tax rate in POIT.  A future enhancement should 
		clean up bspAPLBValPO to return POIT Tax Rate.			  
		*/        	    
		if @LineType = 6
		BEGIN  
			SELECT @potaxrate = TaxRate, @poGSTrate = GSTRate
			FROM vPOItemLine (NOLOCK) 
			WHERE POCo=@apco AND PO=@po AND POItem=@poitem AND POItemLine=@POItemLine
			--bPOIT with (NOLOCK) where POCo = @apco and PO = @po and POItem = @poitem
		END
			  
		/*DC #130175  Get SLIT !Tax Rate
		I wasn't sure where else bspAPLBValSL gets called.  bspAPLBValNew does call bspAPLBValSL and I wasn't
		sure what else in AP calls bspAPLBValNew.  for issue #130175 I need to get the tax rate from SLIT so 
		I just reset the same variables that was being used to the tax rate in SLIT.  A future enhancement should 
		clean up bspAPLBValSL to return SLIT Tax Rate.			  
		*/        	    
		if @LineType = 7
		BEGIN  
			select @sltaxrate = TaxRate, @slGSTrate = GSTRate
			from bSLIT with (NOLOCK) where SLCo = @apco and SL = @sl and SLItem = @slitem
		END			          	    
        	 
        IF (@taxgroup iS NOT NULL) AND (@taxcode IS NOT NULL)
        BEGIN   
			-- validate GST Debit Tax GL Account if there is one
			IF @dbtGLAcct IS NOT NULL
			BEGIN
				EXEC @rcode = bspGLACfPostable @glco, @dbtGLAcct, null, @errmsg output
				IF @rcode <> 0
				BEGIN
					SELECT @errortext = @errorstart + '- Tax Code GST Expense GL Acct: ' + isnull(@dbtGLAcct, '') + 
					':  ' + isnull(@errmsg,'')  
					GOTO APLB_error
				END
				
				-- validate GST retainage Debit Tax GL Account
				IF @dbtRetgGLAcct IS NOT NULL
				BEGIN
					EXEC @rcode = bspGLACfPostable @glco, @dbtRetgGLAcct, null, @errmsg output
					IF @rcode <> 0
					BEGIN
						SELECT @errortext = @errorstart + '- Tax Code Retg GST Expense GL Acct: ' + isnull(@dbtRetgGLAcct, '') + 
						':  ' + isnull(@errmsg,'')  
						GOTO APLB_error
					END
				END
			END	-- end validation for GST GL Accts
		
			-- validate Credit Retainage GST GL Acct 
			IF @crdRetgGSTGLAcct IS NOT NULL
			BEGIN
				EXEC @rcode = bspGLACfPostable @glco, @crdRetgGSTGLAcct, NULL, @errmsg OUTPUT
				IF @rcode <> 0
				BEGIN
					SELECT @errortext = @errorstart + '- Tax Code GST Payable GL Acct: ' + ISNULL(@crdRetgGSTGLAcct, '') + 
					':  ' + isnull(@errmsg,'')  
					GOTO APLB_error
				END
			END
			ELSE 
			BEGIN
				-- IF APCO TaxBasisNetRetg flag is checked and there is retainage on the line, then a Tax Code Credit GST/PST Payable GL Acct is required
				IF @APCOTaxBasisNetRetg = 'Y' AND ISNULL(@retainage,0) <> 0
				BEGIN
					SELECT @errortext = @errorstart + '- when tax basis is net of retention/holdback, a Credit GL Ret/Hbk Tax Acct is required in the tax code.'   
					GOTO APLB_error
				END
			END
		
			-- validate Credit Retainage PST GL Acct 
			IF @crdRetgPSTGLAcct IS NOT NULL 
			BEGIN
				EXEC @rcode = bspGLACfPostable @glco, @crdRetgPSTGLAcct, NULL, @errmsg OUTPUT
				IF @rcode <> 0
				BEGIN
					SELECT @errortext = @errorstart + '- Tax Code PST Payable GL Acct: ' + ISNULL(@crdRetgPSTGLAcct, '') + 
					':  ' + isnull(@errmsg,'')  
					GOTO APLB_error
				END
			END
			ELSE 
			BEGIN
				-- IF APCO TaxBasisNetRetg flag is checked then a Tax Code PST Payable GL Acct is required
				IF @APCOTaxBasisNetRetg = 'Y' AND @pstrate <> 0 AND ISNULL(@retainage,0) <> 0
				BEGIN
					SELECT @errortext = @errorstart + '- when tax basis is net of retention/holdback, a Credit GL Ret/Hbk Tax Acct is required in the tax code.'   
					GOTO APLB_error
				END
			END
		END 
			
		--validate supplier if one exists issue 6335 
		if @supplier is not null
		begin
			if @vendor = @supplier
			begin
				select @errortext = @errorstart + 'Supplier # cannot be the same as the Invoice Vendor.'
				goto APLB_error
			end
			if @vendorgroup <> @suppliergroup
			begin
				select @errortext = @errorstart + 'Vendor Group for your Supplier and Vendor must be the same.'
				goto APLB_error
			end
			--check for valid supplier is done bspAPLBValNew
		end
  	end -- common validation for Add and Change entries
  
	-- validate vendor against PO or SL vendor - issue 18720
	if @headertranstype = 'C' and @LineType in (6,7)	-- validate vendor against PO and SL lines in bAPTL 
	begin
		exec @rcode = bspAPVendValPOSL @apco, @mth, @batchid, @batchseq,@vendor,'APEntry',0,@errmsg output
		if @rcode <> 0
		begin
			select @errortext = 'Seq#: ' + isnull(convert(varchar(6),@batchseq), '') +  isnull(@errmsg,'')
			goto APLB_error
		end
	end
	
	if @linetranstype in ('A','C')	-- validate vendor for PO and SL lines in bAPLB
	begin
		if @LineType = 6 --PO
		begin
			if exists(select top 1 1 from bPOHD WITH (NOLOCK) where POCo=@apco and PO=@po and Vendor <> @vendor)
			begin
				select @errortext = @errorstart + '- Vendor does not match PO vendor.' 
				goto APLB_error
			end
		end
		
  		if @LineType = 7 --SL
		begin
			if exists(select top 1 1 from bSLHD WITH (NOLOCK) where SLCo= @apco and SL=@sl and Vendor <> @vendor)
			begin
				select @errortext = @errorstart + '- Vendor does not match SL vendor.' 
				goto APLB_error
			end
		end
	end
	
   	if @linetranstype in ('C', 'D')     -- common validation for Change and Delete entries
    begin
		-- compare to existing AP Transaction Line
        exec @rcode = bspAPLBValTrans @apco, @mth, @batchid, @batchseq, @aptrans, @apline, @errmsg output
        if @rcode <> 0
        begin
			select @errortext = @errorstart + isnull(@errmsg,'')
            goto APLB_error
        end
		-- check for any Cleared Transaction Detail -- #14164 - allow paid transactions
		if exists(select top 1 1 from bAPTD WITH (NOLOCK) where APCo = @apco and Mth = @mth
		and APTrans = @aptrans and APLine = @apline and Status > 3)
		begin
			select @errortext = @errorstart + '- Some or all of this Line has been cleared.  Cannot change or delete.'
			goto APLB_error
		end
  
  		-- Validate paid lines, check that only allowable fields were changed.
  		if @linetranstype ='C' and @linepaidyn = 'Y'
		begin
  			if isnull(@um,'') <> isnull(@oldum,'')
  			or isnull(@apunits,0) <> isnull(@oldunits,0) or isnull(@apunitcost,0) <> isnull(@oldunitcost,0)
  			or isnull(@ecm,'') <> isnull(@oldecm,'')or isnull(@supplier,0) <> isnull(@oldsupplier,0)
  			or isnull(@paytype,0) <> isnull(@oldpaytype,0)or isnull(@grossamt,0) <> isnull(@oldgrossamt,0)
  			or isnull(@miscamt,0) <> isnull(@oldmiscamt,0)or isnull(@miscyn,'') <> isnull(@oldmiscyn,'')
  			or isnull(@taxcode,'') <> isnull(@oldtaxcode,'') or (@taxcode is not null and isnull(@taxtype,0) <> isnull(@oldtaxtype,0))
  			or isnull(@taxbasis,0) <> isnull(@oldtaxbasis,0)or isnull(@taxamt,0) <> isnull(@oldtaxamt,0)
  			or isnull(@retainage,0) <> isnull(@oldretainage,0)or isnull(@discount,0) <> isnull(@olddiscount,0)
  			begin
  				select @errortext = @errorstart + '- Cannot change some fields in paid lines.'
  				goto APLB_error
  			end
  			
  			-- if type is PO,cannot change any line fields
  			if @LineType = 6
  			begin
  				if isnull(@po,'' ) <> isnull(@oldpo,'') or isnull(@poitem,0) <> isnull(@oldpoitem,0) OR
  					ISNULL(@POItemLine,0) <> ISNULL(@OldPOItemLine,0)or
  					isnull(@linedesc,'') <> isnull(@oldlinedesc,'') or isnull(@glacct,'') <> isnull(@oldglacct,'')
  				begin
  					select @errortext = @errorstart + '- Cannot make any changes to paid PO lines.'
  	        		goto APLB_error
  				end
  	        end
  		
  			-- if type is SL, cannot make any changes
  			if @LineType = 7
  			begin
  				if isnull(@sl,'') <> isnull(@oldsl,'') or isnull(@slitem,0) <> isnull(@oldslitem,0)
  				or isnull(@linedesc,'') <> isnull(@oldlinedesc,'') or isnull(@glacct,'') <> isnull(@oldglacct,'')
  				begin
  					select @errortext = @errorstart + '- Cannot make any changes to paid SL lines.'
  	        		goto APLB_error
  	        	end 
  			end
  		end
  
		-- validate old PO and Item
		select @oldrecyn = @recyn

		if @oldlinetype = 6 --PO
		begin
			exec @rcode = bspAPLBValPO @apco, @mth, @batchid, @invdate, @oldpo, @oldpoitem, @OldPOItemLine,@olditemtype, @oldmatl,
			@oldum, @oldjcco, @oldemco, @oldinco, @oldglco, @oldloc, @oldjob, @oldphase, @oldjcctype,
			@oldequip, @oldcostcode, @oldemctype, @oldcomptype, @oldcomponent, @oldwo, @oldwoitem,
			@pototyn, @oldsmco, @oldsmworkorder, @oldscope, @oldrecyn output, @oldcurunitcost output, @oldcurecm output, @oldpotaxrate output,
			@oldpotaxcode output,@oldpotaxgroup output, @oldpoGSTrate output, @errmsg output
			
			if @rcode <> 0
			begin
				select @errortext = @errorstart + isnull(@errmsg,'')
				goto APLB_error
			end
  
			/*DC #122288  Get POIT !Tax Rate
			I wasn't sure where else bspAPLBValPO gets called.  bspAPLBValNew does call bspAPLBValPO and I wasn't
			sure what else in AP calls bspAPLBValNew.  for issue #122288 I need to get the tax rate from POIT so 
			I just reset the same variables that was being used to the tax rate in POIT.  A future enhancement should 
			clean up bspAPLBValPO to returne POIT Tax Rate.			  
			*/
			select @oldpotaxrate = TaxRate, @oldpoGSTrate = GSTRate
			FROM vPOItemLine (NOLOCK)
			WHERE POCo=@apco AND PO = @oldpo and POItem = @oldpoitem AND POItemLine = @OldPOItemLine
			--from bPOIT with (NOLOCK) where POCo = @apco and PO = @oldpo and POItem = @oldpoitem
			    
			-- get PO Company info
			select @receiptupdate = ReceiptUpdate
			from bPOCO WITH (NOLOCK) where POCo = @apco
			if @@rowcount = 0
			begin
				select @errmsg = ' Invalid PO Company!', @rcode = 1
				goto bspexit
			end
			
			if @receiptupdate = 'Y' and @oldrecyn = 'Y'
			begin
				if @linetranstype = 'C' OR @linetranstype = 'D'
				begin
					select @pounits = -1 * isnull(@apunits,0), @pogrossamt =  isnull(@grossamt,0) * -1
					select @oldpounits = -1 * isnull(@oldunits,0), @oldpogrossamt =  isnull(@oldgrossamt,0) * -1

					exec @rcode = bspPORBExpVal @apco, @mth, @batchid, @batchseq, @apline, @linetranstype, null,
					@po, @poitem, @invdate, null, @linedesc, @pounits, @pogrossamt, 0, 0, null,
					@oldpo, @oldpoitem,@oldinvdate, null, @oldlinedesc, @oldpounits, @oldpogrossamt, null,
					null, null, @POItemLine, @OldPOItemLine, @HQBatchDistributionID, @errmsg output
					if @rcode <> 0 goto bspexit
				end
				else
				begin
					select @oldpounits = isnull(@oldunits,0), @oldpogrossamt =  isnull(@oldgrossamt,0)
					exec @rcode = bspPORBExpVal @apco, @mth, @batchid, @batchseq, @apline, @linetranstype, null,
					null, null, null, null, null, 0, 0, 0, 0, null, @oldpo, @oldpoitem, @oldinvdate, null,
					@oldlinedesc, @oldpounits, @oldpogrossamt, null, null, null, 
					@POItemLine, @OldPOItemLine, @HQBatchDistributionID, @errmsg output
					if @rcode <> 0 goto bspexit
				end
			end 
		end -- End PO
  
		-- validate old SL and Item
		if @oldlinetype = 7
		begin
			exec @rcode = bspAPLBValSL @apco, @mth, @batchid, @oldsl, @oldslitem, @oldjcco, @oldjob,
			@oldphase, @oldjcctype, @oldum, @sltotyn, @oldslitemtype output, @oldcurunitcost output,
			null,null,@oldsltaxrate output,@oldslGSTrate output, @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
				goto APLB_error
			end

			/*DC #130175  Get SLIT !Tax Rate
			I wasn't sure where else bspAPLBValSL gets called.  bspAPLBValNew does call bspAPLBValSL and I wasn't
			sure what else in AP calls bspAPLBValNew.  for issue #130175 I need to get the tax rate from SLIT so 
			I just reset the same variables that was being used to the tax rate in SLIT.  A future enhancement should 
			clean up bspAPLBValSL to returne SLIT Tax Rate.			  
			*/
			
			select @oldsltaxrate = TaxRate, @oldslGSTrate = GSTRate
			from bSLIT with (NOLOCK) where SLCo = @apco and SL = @oldsl and SLItem = @oldslitem

		end
		
		-- validate old JCCo, Job, Phase, and JC Cost Type
		select @oldjcum = @jcum, @oldjcunits = @jcunits
		if (@oldlinetype in (1,7) or (@oldlinetype = 6 and @olditemtype = 1)) and
		(isnull(@jcco,0) <> @oldjcco or isnull(@job,'') <> @oldjob or isnull(@phase,'') <> @oldphase
		or isnull(@jcctype,0) <> @oldjcctype or isnull(@matl,'') <> isnull(@oldmatl,'')
		or isnull(@um,'') <> isnull(@oldum,'') or @apunits <> @oldunits or @linetranstype = 'D')
		begin
			exec @rcode = bspAPLBValJob @oldjcco, @oldphasegroup, @oldjob, @oldphase, @oldjcctype, @oldmatlgroup, @oldmatl,
			@oldum, @oldunits, @oldjcum output, @oldjcunits output, @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
				goto APLB_error
			end
		end
		
		-- validate old Work Order and Item
		if (@oldlinetype = 5 or (@oldlinetype = 6 and @olditemtype = 5)) and
		(isnull(@emco,0) <> @oldemco or isnull(@wo,'') <> @oldwo or isnull(@woitem,0) <> @oldwoitem or @linetranstype = 'D')
		begin
			exec @rcode = bspAPLBValWO @oldemco, @oldwo, @oldwoitem, @oldequip, @oldcomptype, @oldcomponent,
			@oldemgroup, @oldcostcode, @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + isnull(@errmsg,'')
				goto APLB_error
			end
		end
		
      	-- validate EMCo, Equip, Cost Code, EM Cost Type, Component Type, and Component
        select @oldemum = @emum, @oldemunits = @emunits
  
		if (@oldlinetype in (4,5) or (@oldlinetype = 6 and @olditemtype in (4,5))) and
		(isnull(@emco,0) <> @oldemco or isnull(@equip,'') <> @oldequip or isnull(@costcode,'') <> @oldcostcode
		or isnull(@emctype,0) <> @oldemctype or isnull(@comptype,'') <> isnull(@oldcomptype,'')
		or isnull(@component,'') <> isnull(@oldcomponent,'') or isnull(@um,'') <> isnull(@oldum,'')
		or @apunits <> @oldunits or @linetranstype = 'D')
		begin
			exec @rcode = bspAPLBValEquip @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype,
			@comptype, @oldcomponent,@oldmatlgroup, @oldmatl, @oldum, @oldunits, @oldemum output,
			@oldemunits output, @errmsg output
		
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- ' +isnull(@errmsg,'')
				goto APLB_error
			end
		end
		
		-- validate old IN Co#, Location, Material, and UM
		select @oldstdum = @stdum, @oldstdunits = @stdunits, @oldcostopt = @costopt,
		@oldfixedunitcost = @fixedunitcost, @oldfixedecm = @fixedecm, @oldburdenyn = @burdenyn,
		@oldloctaxglacct = @loctaxglacct, @oldlocmiscglacct = @locmiscglacct,
		@oldlocvarianceglacct = @locvarianceglacct

		if (@oldlinetype = 2 or (@oldlinetype = 6 and @olditemtype = 2)) and (isnull(@inco,0) <> @oldinco
		or isnull(@loc,'') <> @oldloc or isnull(@matl,'') <> @oldmatl or isnull(@um,'') <> @oldum
		or @apunits <> @oldunits or @linetranstype = 'D')
		begin
			exec @rcode = bspAPLBValInv @oldinco, @oldloc, @oldmatlgroup, @oldmatl, @oldum, @oldunits,
			@oldstdum output, @oldstdunits output, @oldcostopt output, @oldfixedunitcost output,
			@oldfixedecm output, @oldburdenyn output, @oldloctaxglacct output, @oldlocmiscglacct output,
			@oldlocvarianceglacct output, @oldavgecm output, @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- ' +isnull(@errmsg,'')
				goto APLB_error
			end
		end
		
		-- validate Expense Jrnl in old GL Co#
		if @oldglco <> @apglco
		begin
			if not exists(select top 1 1 from bGLJR WITH (NOLOCK) where GLCo = @oldglco and Jrnl = @expjrnl)
			begin
				select @errortext = @errorstart + ' - Journal ' + isnull(@expjrnl, '') + 
				' is not valid in GL Co#' + isnull(convert(varchar(3),@oldglco), '')  --#23061
				goto APLB_error
			end
		end
		
		-- validate old GL Co and Expense Month
		if @oldglco <> @glco or @linetranstype = 'D'
		begin
			exec @rcode = bspHQBatchMonthVal @oldglco, @mth, 'AP', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
				goto APLB_error
			end
		end
              
		-- validate old Posted GL Account
		if @oldglco <> @glco or @oldglacct <> @glacct or @linetranstype = 'D'
		begin
			select @accounttype = null
			if @oldlinetype in (1,7) or (@oldlinetype = 6 and @olditemtype = 1) select @accounttype = 'J'    -- job
			if @oldlinetype = 2 or (@oldlinetype = 6 and @olditemtype = 2) select @accounttype = 'I'          -- inventory
			if @oldlinetype = 3 or (@oldlinetype = 6 and @olditemtype = 3) select @accounttype = 'N'         -- must be null
			if @oldlinetype in (4,5) or (@oldlinetype = 6 and @olditemtype in (4,5)) select @accounttype = 'E'   -- equipment
			if @oldlinetype = 8 or (@oldlinetype = 6 and @olditemtype = 6) select @accounttype = 'S'   -- service
			
			exec @rcode = bspGLACfPostable @oldglco, @oldglacct, @accounttype, @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- GL Account:' + isnull(@oldglacct, '') + ':  ' + isnull(@errmsg,'')  --#23061
				goto APLB_error
			end
		end
		
		-- if old AP GL Co# <> 'Posted To' GL Co# get intercompany accounts
		select @oldintercoarglacct = @intercoarglacct, @oldintercoapglacct = @intercoapglacct
		if @oldglco <> @apglco and (@oldglco <> @glco or @linetranstype = 'D')
		begin
			select @oldintercoarglacct = ARGLAcct, @oldintercoapglacct = APGLAcct
			from bGLIA WITH (NOLOCK)
			where ARGLCo = @apglco and APGLCo = @oldglco
			if @@rowcount = 0
			begin
				select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL. From:' +
				isnull(convert(varchar(3),@apglco), '') + ' To: ' + 
				isnull(convert(varchar(3),@oldglco), '')  --#23061
				goto APLB_error
			end
		
			-- validate intercompany GL Accounts
			exec @rcode = bspGLACfPostable @apglco, @oldintercoarglacct, 'R', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Intercompany AR Account:' + isnull(@oldintercoarglacct, '') + 
				':  ' + isnull(@errmsg,'')  --#23061
				goto APLB_error
			end
			exec @rcode = bspGLACfPostable @oldglco, @oldintercoapglacct, 'P', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Intercompany AP Account:' + isnull(@oldintercoapglacct, '') + 
				':  ' + isnull(@errmsg,'')   --#23061
				goto APLB_error
			end
		end
		
		-- validate old Pay Type and get Payables GL Account
		select @oldapglacct = @apglacct
		if @oldpaytype <> @paytype or @linetranstype = 'D'
		begin
			select @oldapglacct = GLAcct from bAPPT where APCo = @apco and PayType = @oldpaytype
			if @@rowcount = 0
			begin
				select @errortext = @errorstart + '- Invalid Pay Type:' + isnull(convert(varchar(4),@oldpaytype), '')  --#23061
				goto APLB_error
			end
			-- validate Pay Type GL Account
			exec @rcode = bspGLACfPostable @apglco, @oldapglacct, 'P', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- GL Payables Account:' + isnull(@oldapglacct, '') + 
				':  ' + isnull(@errmsg,'')  --#23061
				goto APLB_error
			end
		end
		
		-- validate old Tax Group and Tax code
		IF (@oldtaxgroup IS NOT NULL) AND (@oldtaxcode IS NOT NULL)
		BEGIN
			--use bspHQTaxRateGetAll to return old GST/PST taxrates and old gl accounts 
			EXEC @rcode = bspHQTaxRateGetAll @oldtaxgroup, @oldtaxcode, @oldinvdate, @oldvalueadd output, @oldtaxrate output,
			@oldgstrate output, @oldpstrate output,null,null, @olddbtGLAcct output,
			@olddbtRetgGLAcct output,null, null,@oldcrdRetgGSTGLAcct output,@oldcrdRetgPSTGLAcct output
			 
			-- use bspHQTaxRateGet to get old taxphase and old taxct
			EXEC @rcode = bspHQTaxRateGet @oldtaxgroup, @oldtaxcode, @oldinvdate, null, @oldtaxphase output,
			@oldtaxct output, @errmsg output
			IF @rcode <> 0
			BEGIN
				SELECT @errortext = @errorstart + ' - Tax Group: ' + isnull(convert(varchar(3),@oldtaxgroup), '') + 
				'- Tax Code: ' + isnull(@oldtaxcode, '') + ':  ' + isnull(@errmsg,'')  --#23061
				GOTO APLB_error
			END
			
			-- validate TaxType against ValueAdd - only TaxType 3 should have a Value Add tax code
			IF (@oldtaxtype <> 3 and isnull(@oldvalueadd,'N') = 'Y') or (@oldtaxtype = 3 and isnull(@oldvalueadd,'N') = 'N')
			BEGIN
				SELECT @errortext = @errorstart + ' - Tax Type: ' + isnull(convert(varchar(3),@oldtaxtype), '') + 
				' is invalid with Tax Code: ' + isnull(@oldtaxcode, '') 
				GOTO APLB_error
			END
			 
			IF @olddbtGLAcct IS NOT NULL
			BEGIN
				EXEC @rcode = bspGLACfPostable @oldglco, @olddbtGLAcct, null, @errmsg output
				IF @rcode <> 0
				BEGIN
					SELECT @errortext = @errorstart + '- Tax Code GST Expense GL Acct:' + isnull(@olddbtGLAcct, '') + 
					':  ' + isnull(@errmsg,'')  
					GOTO APLB_error
				END
				-- validate GST retainage Debit Tax GL Account
				IF @olddbtRetgGLAcct IS NOT NULL
				BEGIN
					EXEC @rcode = bspGLACfPostable @oldglco, @olddbtRetgGLAcct, null, @errmsg output
					IF @rcode <> 0
					BEGIN
						SELECT @errortext = @errorstart + '- Tax Code Retg GST Expense GL Acct:' + isnull(@olddbtRetgGLAcct, '') + 
						':  ' + isnull(@errmsg,'')  
						GOTO APLB_error
					END
				END
				
				-- validate old GST Credit Payable
				IF @oldcrdRetgGSTGLAcct IS NOT NULL
				BEGIN
					EXEC @rcode = bspGLACfPostable @oldglco, @oldcrdRetgGSTGLAcct, null, @errmsg output
					IF @rcode <> 0
					BEGIN
						SELECT @errortext = @errorstart + '- Tax Code GST Payable GL Acct:' + ISNULL(@oldcrdRetgGSTGLAcct, '') + 
						':  ' + isnull(@errmsg,'')  
						GOTO APLB_error
					END
				END
				ELSE -- IF APCO TaxBasisNetRetg flag is checked then Credit Retainage GST GL Acct cannot be null
				BEGIN
					IF @APCOTaxBasisNetRetg = 'Y' AND ISNULL(@oldretainage,0) <> 0
					BEGIN
						SELECT @errortext = @errorstart + '- when tax basis is net of retention/holdback, a Credit GL Ret/Hbk Tax Acct is required in the tax code.'   
						GOTO APLB_error
					END
				END
				
				-- validate PST Credit Payable
				IF @oldcrdRetgPSTGLAcct IS NOT NULL 
				BEGIN
					EXEC @rcode = bspGLACfPostable @oldglco, @oldcrdRetgGSTGLAcct, NULL, @errmsg output
					IF @rcode <> 0
					BEGIN
						SELECT @errortext = @errorstart + '- Tax Code PST Payable GL Acct:' + ISNULL(@oldcrdRetgGSTGLAcct, '') + 
						':  ' + isnull(@errmsg,'')  
						GOTO APLB_error
					END
				END
				ELSE -- IF APCO TaxBasisNetRetg flag is checked then Credit Retainage PST GL Acct cannot be null
				BEGIN
					IF @APCOTaxBasisNetRetg = 'Y' AND ISNULL(@oldpstrate,0) <> 0 AND ISNULL(@oldretainage,0) <> 0
					BEGIN
						SELECT @errortext = @errorstart + '- when tax basis is net of retention/holdback, a Credit GL Ret/Hbk Tax Acct is required in the tax code.'   
						GOTO APLB_error
					END
				END

			END	
			
			-- get old Tax Accrual Account
			if @oldtaxtype = 2 and @oldtaxamt <> 0
			begin
				select @oldtaxaccrualacct = GLAcct
				from bHQTX WITH (NOLOCK)
				where TaxGroup = @oldtaxgroup and TaxCode = @oldtaxcode	-- use 'posted to' Tax Group
				if @@rowcount = 0
				begin
					select @errortext = @errorstart + '- Invalid Tax Code:' + isnull(@oldtaxcode, '')  --#23061
					goto APLB_error
				end
				-- validate Use Tax Accrual GL Account
				exec @rcode = bspGLACfPostable @glco, @oldtaxaccrualacct, 'N', @errmsg output
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Use Tax Accrual Account:' + isnull(@oldtaxaccrualacct, '') +
					':  ' + isnull(@errmsg,'')	--#23061
					goto APLB_error
				end
			end
			-- Tax Phase and Cost Type
			if @oldlinetype in (1,7) or (@oldlinetype = 6 and @olditemtype = 1)  
			begin
				-- use 'posted' phase and cost type unless overridden by tax code
				if @oldtaxphase is null select @oldtaxphase = @oldphase
				if @oldtaxct is null select @oldtaxct = @oldjcctype
				select @oldtaxglacct = @oldglacct     -- default is 'posted' account
				-- Tax may be redirected to another expense account
				if @oldtaxphase <> @oldphase or @oldtaxct <> @oldjcctype
				begin
					-- get GL Account for Tax Expense
					exec @rcode = bspJCCAGlacctDflt @oldjcco, @oldjob, @oldphasegroup, @oldtaxphase, @oldtaxct, 'N',
					@oldtaxglacct output, @errmsg output
					if @rcode <> 0
					begin
						select @errortext = @errorstart + '- Tax Expense GL Acct ' + isnull(@errmsg,'')
						goto APLB_error
					end
					-- validate Tax Account
					exec @rcode = bspGLACfPostable @oldglco, @oldtaxglacct, 'J', @errmsg output
					if @rcode <> 0
					begin
						select @errortext = @errorstart + '- Tax Expense GL Acct:' + isnull(@oldtaxglacct, '') + 
						':  ' + isnull(@errmsg,'')  --#23061
						goto APLB_error
					end
				end
			end
		end  --@oldtaxcode is not null
		
		if @oldtaxcode is null 
		begin
			/* Get taxphase and taxct for committed cost.  If APTL has no taxcode but POIT or SLIT does, use PO or SL tax phase,
			ct, glacct from bspAPLBValNew - #21978, #128288 SL now has tax codes so account for redirected tax */
			if (@oldlinetype = 6 and @olditemtype = 1) or @oldlinetype = 7
			begin
				select @oldtaxphase = @taxphase
				select @oldtaxct = @taxct
				select @oldtaxglacct = @taxglacct
				-- use 'posted' phase and cost type unless overridden by tax code
				if @oldtaxphase is null select @oldtaxphase = @oldphase
				if @oldtaxct is null select @oldtaxct = @oldjcctype
				if @oldtaxglacct is null select @oldtaxglacct = @oldglacct  -- default is 'posted' account
				-- Tax may be redirected to another expense account
				if @oldtaxphase <> @oldphase or @oldtaxct <> @oldjcctype
				begin
					-- get GL Account for Tax Expense
					exec @rcode = bspJCCAGlacctDflt @oldjcco, @oldjob, @oldphasegroup, @oldtaxphase, @oldtaxct, 'N',
					@oldtaxglacct output, @errmsg output
					if @rcode <> 0
					begin
						select @errortext = @errorstart + '- Tax Expense GL Acct ' + isnull(@errmsg,'')
						goto APLB_error
					end
					-- validate Tax Account
					exec @rcode = bspGLACfPostable @oldglco, @oldtaxglacct, 'J', @errmsg output
					if @rcode <> 0
					begin
						select @errortext = @errorstart + '- Tax Expense GL Acct:' + 
						isnull(@oldtaxglacct, '') + ':  ' + isnull(@errmsg,'')  --#23061
						goto APLB_error
					end
				end	
			end
		end
  
		-- validate Retainage info 
		if @oldretainage <> 0 and (@retainage = 0 or @linetranstype = 'D')
		begin
			exec @rcode = bspHQHoldCodeVal @retholdcode, @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + 'Retainage Hold Code : ' + isnull(@errmsg,'')
				goto APLB_error
			end
		end
		
		--validate Old PayCategory
		if @oldpaycategory is not null
		BEGIN
			-- Old Retainage Payable Type
			select @oldretpaytype=RetPayType, @olddiscoffglacct=DiscOffGLAcct from bAPPC with (nolock)
			where APCo=@apco and PayCategory=@oldpaycategory
			if @@rowcount=0
			begin
				select @errortext = @errorstart + ' Invalid Old Pay Category!'
				goto APLB_error
			end
			-- Old Retainage Payable GL Account
			if @oldretainage <> 0 
			begin
				exec @rcode=bspAPPayTypeValForPayCategory @apco, @oldpaycategory, @oldretpaytype, @oldretglacct output, @errmsg output
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Retainage Pay Type:' + 
					isnull(convert(varchar(3), @retpaytype), '') + ':  ' + isnull(@errmsg,'') 
					goto APLB_error
				end
				exec @rcode = bspGLACfPostable @apglco, @oldretglacct, 'P', @errmsg output 
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Retainage Payable GL Account:' + isnull(@oldretglacct, '') + 
					':  ' + isnull(@errmsg,'')  
					goto APLB_error
				end
			end
		END
		else
		begin
			-- Retainage Payable GL Account
			select @oldretpaytype=@APretpaytype, @olddiscoffglacct=@APdiscoffglacct
			if @oldretainage <> 0 
			begin
				exec @rcode=bspAPPayTypeVal @apco, @oldretpaytype, @oldretglacct output, @errmsg output
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Retainage Pay Type:' + 
					isnull(convert(varchar(3), @oldretpaytype), '') + ':  ' + isnull(@errmsg,'')  --#23061
					goto APLB_error
				end
				exec @rcode = bspGLACfPostable @apglco, @oldretglacct, 'P', @errmsg output
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Retainage Payable GL Account:' + isnull(@oldretglacct, '') + 
					':  ' + isnull(@errmsg,'')  --#23061
					goto APLB_error
				end
			end
		end
  
		-- validate Old Discount Offered GL Account
		if (@olddiscount <> 0 and @netamtopt = 'Y') and (@discount = 0 or @linetranstype = 'D')
		begin
			exec @rcode = bspGLACfPostable @apglco, @olddiscoffglacct, 'N', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Discount offered GLAcct:' + 
				isnull(@discoffglacct, '') + ':  ' + isnull(@errmsg,'')  
				goto APLB_error
			end
		end
	end	-- common validation for Change and Delete entries
  
	-- validate that if there is a discount that a discount date has been entered #10146 kb
	if @discount <> 0 and exists(select 1 from bAPHB WITH (NOLOCK) where Co = @apco and Mth = @mth
	and BatchId = @batchid and BatchSeq = @batchseq and DiscDate is null)
	begin
		select @errortext = @errorstart + '- Discount date is required if discounts are used.'
		goto APLB_error
	end
	
	
  
update_audit:	-- add JC, EM, IN, and GL distributions
	select @change = 'N'    -- flag indicating that changes have been made
	if @linetranstype = 'C' and (@vendor <> @oldvendor or isnull(@apref,'') <> isnull(@oldapref,'')
		or isnull(@transdesc,'') <> isnull(@oldtransdesc,'') or @invdate <> @oldinvdate
		or isnull(@po,'') <> isnull(@oldpo,'') or isnull(@poitem,0) <> isnull(@oldpoitem,0) OR ISNULL(@POItemLine,0) <> ISNULL(@OldPOItemLine,0)
		or isnull(@sl,'') <> isnull(@oldsl,'') or isnull(@slitem,0) <> isnull(@oldslitem,0)
		or isnull(@jcco,0) <> isnull(@oldjcco,0) or isnull(@job,'') <> isnull(@oldjob,'')
		or isnull(@phase,'') <> isnull(@oldphase,'') or isnull(@jcctype,0) <> isnull(@oldjcctype,0)
		or isnull(@emco,0) <> isnull(@oldemco,0) or isnull(@wo,'') <> isnull(@oldwo,'')
		or isnull(@woitem,0) <> isnull(@oldwoitem,0) or isnull(@equip,'') <> isnull(@oldequip,'')
		or isnull(@costcode,'') <> isnull(@oldcostcode,'') or isnull(@emctype,0) <> isnull(@oldemctype,0)
		or isnull(@comptype,'') <> isnull(@oldcomptype,'') or isnull(@component,'') <> isnull(@oldcomponent,'')
		or isnull(@inco,0) <> isnull(@oldinco,0) or isnull(@loc,'') <> isnull(@oldloc,'')
		or isnull(@matl,'') <> isnull(@oldmatl,'') or @glco <> @oldglco or @glacct <> @oldglacct
		or isnull(@linedesc,'') <> isnull(@oldlinedesc,'') or isnull(@um,'') <> isnull(@oldum,'')
		or @apunits <> @oldunits or @paytype <> @oldpaytype or @grossamt <> @oldgrossamt
		or @miscamt <> @oldmiscamt or @oldmiscyn <> @miscyn or isnull(@taxcode,'') <> isnull(@oldtaxcode,'')
		or isnull(@taxtype,99) <> isnull(@oldtaxtype,99) or @taxamt <> @oldtaxamt 
		or @retainage <> @oldretainage or @discount <> @olddiscount
		or isnull(@paycategory,0) <> isnull(@oldpaycategory,0)
		or isnull(@smco, 0) <> isnull(@oldsmco, 0) or isnull(@smworkorder,-1) <> isnull(@oldsmworkorder,-1)
   	    or isnull(@scope,-1) <> isnull(@oldscope,-1) or isnull(@oldsmcosttype,'') <> isnull(@oldsmcosttype,'')
   	    OR ISNULL(@smjccosttype,'') <> ISNULL(@oldsmjccosttype,'') OR ISNULL(@smphasegroup,'') <> ISNULL(@oldsmphasegroup,'') OR ISNULL(@smphase,'') <> ISNULL(@oldsmphase,'')
   	    OR ISNULL(@OldSubjToOnCostYN,'') <> ISNULL(@SubjToOnCostYN,''))

   	    BEGIN
			select @change = 'Y'   -- something changed
		END
  
  	-- 'Old' JC distributions
    if (@oldlinetype in (1,7) or (@oldlinetype = 6 and @olditemtype = 1)) and (@linetranstype = 'D' or @change = 'Y')
    begin
		-- If job closed get closed job gl account - #134876 
		select @status=JobStatus,@contract=Contract from bJCJM where JCCo=@oldjcco and Job=@oldjob
		if @status = 3 -- Old Job is hard closed
		begin
			-- get the department
			select @dept = Department from bJCCM where JCCo=@oldjcco and Contract=@contract
			-- get closed GLAcct from phase in Dept override 
			select @closedGLAcct = null
			select @closedGLAcct=ClosedExpAcct from bJCDO where JCCo=@oldjcco and Department=@dept 
			and PhaseGroup=@oldphasegroup and Phase=@oldphase
			if @closedGLAcct is not null
			begin
				exec @rcode = bspGLACfPostable @oldglco, @closedGLAcct, 'J', @errmsg output
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Closed GL Account:' + isnull(@closedGLAcct, '') + ':  ' + isnull(@errmsg,'')  
					goto APLB_error
				end
				else
				begin
					select @oldglacct = @closedGLAcct
					select @oldtaxglacct = NULL
				end
			end
			else -- get closed GLAcct from Costtype  
			begin
				select @closedGLAcct=ClosedExpAcct from bJCDC where JCCo=@oldjcco and Department=@dept
				and PhaseGroup=@oldphasegroup and CostType=@oldjcctype
				if @closedGLAcct is not null 
				begin
					exec @rcode = bspGLACfPostable @oldglco, @closedGLAcct, 'J', @errmsg output
					if @rcode <> 0
					begin
						select @errortext = @errorstart + '- Closed GL Account:' + isnull(@closedGLAcct, '') + ':  ' + isnull(@errmsg,'')  
						goto APLB_error
					end
					else
					begin
						select @oldglacct = @closedGLAcct
						select @oldtaxglacct = NULL
					end
				end
				else
				begin
					-- no Gl Acct set up for closed job
					select @errortext = @errorstart + ' Missing closed GL Acct for Job: ' + isnull(@oldjob,'') + ' Phase: ' 
					+ isnull(@oldphase,'') + ' CT: ' + isnull(convert(varchar(5),@oldjcctype),'')
					goto APLB_error
				end
			end 
		end -- end @status = 3
		
		IF ISNULL(@oldvalueadd,'N') = 'N'
		BEGIN
			SELECT @oldpayTaxAmt = @oldtaxamt
		END
		
		/* Breakout and establish all VAT related tax amounts. */
		IF ISNULL(@oldvalueadd,'N') = 'Y'
		BEGIN
			IF @oldpstrate = 0
			BEGIN
				/* When @oldpstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				IF  isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @APHBCheckRevYN = 'Y' --#136500/#133107 Check Reversal
				BEGIN
					-- GST tax basis is not net of retainage - calculate on full gross
					SELECT @oldretgTaxAmt = @oldretainage * @oldtaxrate --TK-17202 case @oldgrossamt when 0 then 0 else (@oldretainage/@oldgrossamt) * @oldtaxamt end
					SELECT @oldpayTaxAmt = @oldtaxamt - @oldretgTaxAmt
					SELECT @oldgstTaxAmt = @oldpayTaxAmt
					SELECT @oldretgGstTaxAmt = @oldretgTaxAmt
					SELECT @oldVATgstTaxAmt = @oldgstTaxAmt + @oldretgGstTaxAmt
					SELECT @oldVATpstTaxAmt = 0
				END
				ELSE  -- GST tax basis is net of retainage 
				BEGIN
					SELECT @oldretgGstTaxAmt = @oldretainage * @oldtaxrate --TK-17202 case @oldgrossamt when 0 then 0 else (@oldgrossamt * @oldtaxrate) * (@oldretainage/@oldgrossamt) end 
					SELECT @oldgstTaxAmt = @oldtaxamt -- GST was calculated on taxbasis net retainage in the form
					SELECT @oldVATgstTaxAmt = @oldgstTaxAmt 
					SELECT @oldVATpstTaxAmt = 0
					SELECT @oldpayTaxAmt = 0
				END
			END
			ELSE
			BEGIN
			-- PST/GST tax basis is not net of retainage - calculate on full gross
				IF  isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @APHBCheckRevYN = 'Y' --#136500/#133107 Check Reversal
				BEGIN
					SELECT @oldretgTaxAmt = @oldretainage * @oldtaxrate --TK-17202 case @oldgrossamt when 0 then 0 else (@oldretainage/@oldgrossamt) * @oldtaxamt end
					SELECT @oldpayTaxAmt = @oldtaxamt - @oldretgTaxAmt
					SELECT @oldgstTaxAmt = case @oldtaxrate when 0 then 0 else (@oldpayTaxAmt * @oldgstrate) / @oldtaxrate end	
					SELECT @oldpstTaxAmt = @oldpayTaxAmt - @oldgstTaxAmt	
					SELECT @oldretgGstTaxAmt = case @oldtaxrate when 0 then 0 else (@oldretgTaxAmt * @oldgstrate) / @oldtaxrate end
					SELECT @oldretgPstTaxAmt = @oldretgTaxAmt - @oldretgGstTaxAmt
					SELECT @oldVATgstTaxAmt = @oldgstTaxAmt + @oldretgGstTaxAmt
					SELECT @oldVATpstTaxAmt = @oldpstTaxAmt + @oldretgPstTaxAmt
				END
				ELSE
				BEGIN
					-- PST and GST tax basis is net of retainage
					SELECT @oldretgGstTaxAmt = (@oldretainage * @oldgstrate)		-- retainage GST tax 
					SELECT @oldretgPstTaxAmt = (@oldretainage * @oldpstrate)		-- retainage PST tax 
					SELECT @oldretgTaxAmt = (@oldretainage * @oldtaxrate)			-- total retainage tax
					SELECT @oldgstTaxAmt = @oldtaxbasis * @oldgstrate				-- open GST tax
					SELECT @oldpstTaxAmt = @oldtaxamt - @oldgstTaxAmt 				-- open PST tax 
					SELECT @oldVATgstTaxAmt = @oldgstTaxAmt + @oldretgGstTaxAmt		-- total of open + retainage GST tax
					SELECT @oldVATpstTaxAmt = @oldpstTaxAmt + @oldretgPstTaxAmt		-- total of open + retainage PST tax
				END
			END
			/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC Expense GL Acct
			then include the GST portion of tax in the Job Expense acct */
			IF @olddbtGLAcct IS NULL
			BEGIN
				SELECT @oldpayTaxAmt= @oldVATpstTaxAmt + @oldVATgstTaxAmt
				SELECT @oldVATgstTaxAmt = 0
			END  
			ELSE
			BEGIN
				SELECT @oldpayTaxAmt = @oldVATpstTaxAmt
			END
		END

		SELECT @i = 0
OldJC_loop:

		select @remcmtdcost = 0, @jcunitcost = 0, @rniunits = 0, @rnicost = 0, @remcmtdunits = 0,
		@totalcmtdunits = 0, @totalcmtdcost = 0,
		@totalcmtdtax = 0, @remcmtdtax = 0  --DC #122288
		if @i = 0  -- Old Posted Amount (tax may be redirected so exclude it on this pass)
		begin
			if @oldlinetype = 7 select @oldcurecm = 'E'
			select @factor = case @oldcurecm when 'C' then 100 when 'M' then 1000 else 1 end
			-- old total cost may include misc amt if paid to vendor, less discount if net option is used
			select @totalcost = @oldgrossamt + (case @oldmiscyn when'Y' then @oldmiscamt else 0 end) - (case @netamtopt when 'Y' then @olddiscount else 0 end)
			-- POs will update Remaining Committed Cost, Units
			
			if @oldlinetype = 6 
			begin
				SELECT @origunits=OrigUnits, @origcost=OrigCost, @curunits = CurUnits, @curcost = CurCost
				--select @origunits=OrigUnits, @origcost=OrigCost, @curunits = CurUnits, @curcost = CurCost from bPOIT
				--select @curunits = CurUnits, @curcost = CurCost from bPOIT
				FROM vPOItemLine
				WHERE POCo = @apco AND PO = @oldpo AND POItem = @oldpoitem AND POItemLine = @OldPOItemLine
				if (@origunits = 0 and @curunits = 0) and (@origcost = 0 and @curcost=0) and @oldrecyn = 'N' -- standing PO w/o receiving
				--if @curunits = 0 and @curcost=0 and @oldrecyn = 'N' -- 19926 standing PO not flagged for rcvng
				begin
					select @remcmtdcost = 0 --Total cost - invoiced cost = remaining cmtd cost
					select @remcmtdunits = 0 --total units - invoiced units = remaining cmtd units
					select @totalcmtdunits = @oldjcunits -- Received units + BO units = total cmtd units
					select @totalcmtdcost = @oldgrossamt	-- Received cost + BO cost = total cmtd cost
				end
				else	-- Regular PO or standing PO flagged for receiving
				begin
					select @remcmtdcost = case when @oldum = 'LS' then @oldgrossamt	else (@oldunits * @oldcurunitcost) / @factor end
					select @remcmtdunits = @oldjcunits    -- will be 0.00 if 'LS'
					select @totalcmtdunits = 0
					select @totalcmtdcost = 0
				end
			end
			
			if @oldlinetype = 7 and @oldslitemtype <> 3
			-- SLs (except Backcharge Item) will update Remaining Committed Cost
			begin
				select @remcmtdcost = case when @oldum = 'LS' then @oldgrossamt	else (@oldunits * @oldcurunitcost) / @factor end
				select @remcmtdunits = @oldjcunits   -- #19926 - will be 0.00 if 'LS'
			end
			-- RNI only applies to PO Items flagged for receiving
			if @oldlinetype = 6 and @oldrecyn = 'Y'
			begin
				select @rniunits = @oldjcunits   -- will be 0.00 if 'LS'
				select @rnicost = @remcmtdcost -- change to RNI Cost will equal change to Rem Cmtd Cost
			end
			
			-- JC Unit Cost only calculated on this pass so include tax unless tax is being redirected --30264
			if @oldjcunits <> 0 
			begin
				if isnull(@oldtaxphase, @oldphase) <> @oldphase or isnull(@oldtaxct,@oldjcctype) <> @oldjcctype
				begin
					select @jcunitcost = (@totalcost / @oldjcunits)
				end
				else
				begin
					select @jcunitcost = (@totalcost + @oldpayTaxAmt) / @oldjcunits
				end
			end

			-- reverse sign on totalcost and jc units, use old posted phase, cost type, etc.
			select @totalcost = (-1 * @totalcost), @upphase = @oldphase, @upjcctype = @oldjcctype,
			@upglacct = @oldglacct, @upum = @oldum, @upunits = (-1 * @oldunits), @upjcum = @oldjcum,
			@upjcunits = (-1 * @oldjcunits), @upjcecm = 'E', @uptaxbasis = 0, @uptaxamt = 0,
			@usetaxamt = 0, @totalcmtdunits = (-1 * @totalcmtdunits), @totalcmtdcost=(-1 * @totalcmtdcost)
		end
		
		if @i = 1  -- Tax amount (included as part of total cost)
		begin
			select @totalcost = (-1 * @oldpayTaxAmt), @uptaxbasis = (-1 * @oldtaxbasis), @uptaxamt = (-1 * @oldpayTaxAmt)
			
			-- update Remaining Committed Cost with tax for PO
			if @oldlinetype = 6
			begin
				if @curunits = 0 and @curcost=0 and @oldrecyn = 'N' -- 19926 standing PO not flagged for recvng
				begin
					select @remcmtdcost = 0
					select @totalcmtdcost = @totalcost 
				end
				else
				begin
					select @posltaxbasis = (@oldunits * @oldcurunitcost)/@factor -- 28714	
					select @oldposlTaxAmt= case when @um = 'LS' then (@oldgrossamt * isnull(@oldpotaxrate,0)) else (@posltaxbasis * @oldpotaxrate) end
					--calculate remaining commited cost for tax
					if @olddbtGLAcct is null
					begin
						select @remcmtdcost = (@oldposlTaxAmt)
						select @remcmtdtax = (@oldposlTaxAmt) --DC #122288
					end
					else
					begin
						if @oldpoGSTrate = 0 select @oldpoGSTrate=@oldpotaxrate
						--calculate GST portion of po tax to back out of remaining commited tax cost
						select @oldposlGSTtaxAmt = case @oldpotaxrate when 0 then 0 else (@oldposlTaxAmt * @oldpoGSTrate) / @oldpotaxrate end
						select @remcmtdcost = (@oldposlTaxAmt - @oldposlGSTtaxAmt)
						select @remcmtdtax = (@oldposlTaxAmt - @oldposlGSTtaxAmt)  --DC #122288
					end
				end
			end
			
			if @oldlinetype = 7 and @oldslitemtype <> 3
			begin
				select @posltaxbasis = (@oldunits * @oldcurunitcost)/@factor -- 28714
				select @oldposlTaxAmt= case when @um = 'LS' then (@oldgrossamt * isnull(@oldsltaxrate,0)) else (@posltaxbasis * @oldsltaxrate) end

				--calculate remaining commited cost for tax
				if @olddbtGLAcct is null
				begin
					select @remcmtdcost = (@oldposlTaxAmt)
					select @remcmtdtax = (@oldposlTaxAmt)  --DC #122288
				end
				else
				begin
					-- if GSTrate is 0 then taxcode is GST only, set GSTrate to sltaxrate
					if @oldslGSTrate = 0 select @oldslGSTrate = @oldsltaxrate
					--calculate GST portion of po tax to back out of remaining commited tax cost
					select @oldposlGSTtaxAmt = case @oldsltaxrate when 0 then 0 else (@oldposlTaxAmt * @oldslGSTrate) / @oldsltaxrate end
					select @remcmtdcost = (@oldposlTaxAmt - @oldposlGSTtaxAmt)
					select @remcmtdtax = (@oldposlTaxAmt - @oldposlGSTtaxAmt)  --DC #122288
				end
			end

			-- RNI only applies to PO Items flagged for receiving
			if @oldlinetype = 6 and @oldrecyn = 'Y' select @rnicost = isnull(@remcmtdcost,0)
			-- Old tax phase and cost type	- #19063
			select @upphase = case when @oldtaxphase is not null then @oldtaxphase else @upphase end,
			@upjcctype = case when @oldtaxct is not null then @oldtaxct else @upjcctype end,
			@upglacct = case when @oldtaxglacct is not null then @oldtaxglacct else @upglacct end,
			/*select @upphase = @oldtaxphase, @upjcctype = @oldtaxct, @upglacct = @oldtaxglacct,*/
			@upum = null,@upunits = 0, @upjcum = null, @upjcunits = 0, @upjcecm = null
			-- include Use Tax on this pass to add GL Accrual distribution
			select @usetaxamt = case @oldtaxtype when 2 then (-1 * @oldtaxamt) else 0 end
		end
		
		-- add old APJC entry
		if ((@totalcost <> 0) or (@i = 1 and @uptaxbasis <> 0 and @oldtaxcode is not null)) 
		or @upunits <> 0 or @rniunits <> 0 or isnull(@rnicost,0) <> 0
		or isnull(@remcmtdcost,0) <> 0 or isnull(@totalcmtdcost,0) <> 0
		exec @rcode = bspAPLBValJCInsert @apco, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup,
		@upphase, @upjcctype, @batchseq, @apline, 0, @aptrans, @oldvendorgroup, @oldvendor,
		@oldapref, @oldtransdesc, @oldinvdate, @oldsl, @oldslitem, @oldpo, @oldpoitem, @OldPOItemLine, @oldmatlgroup,
		@oldmatl, @oldlinedesc, @oldglco, @upglacct, @upum, @upunits, @upjcum, @upjcunits,
		@jcunitcost, @upjcecm, @totalcost, @rniunits, @rnicost, @remcmtdcost, @oldtaxgroup,
		@oldtaxcode, @oldtaxtype, @uptaxbasis, @uptaxamt, @remcmtdunits, @totalcmtdunits, @totalcmtdcost,
		@totalcmtdtax, @remcmtdtax  --DC #122288
		 --add old APGL entry - will make intercompany entries if needed

		if @totalcost <> 0 or @usetaxamt <> 0 or @oldVATgstTaxAmt <> 0 OR @oldretgGstTaxAmt <> 0 --TK-08150
		begin
			if @i = 0 -- APGL for Job Expense - Gross Amt 
			begin
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @upglacct, @batchseq, @apline,
				0, @aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
				@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @totalcost, @apglco, @oldintercoarglacct, @oldintercoapglacct,
				@usetaxamt, @oldtaxaccrualacct
			end
			
			if @i = 1 
			begin
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @upglacct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
				@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @totalcost, @apglco, @oldintercoarglacct, @oldintercoapglacct,
				@usetaxamt, @oldtaxaccrualacct	
				-- retainage GST is broken out 
				if @olddbtRetgGLAcct is not null and @oldretainage <> 0		
				begin
					IF @oldgstTaxAmt <> 0 --133107
					BEGIN
						select @oldgstTaxAmt = (-1 * @oldgstTaxAmt)
						--APGL for GST Tax
						exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtGLAcct, @batchseq, @apline, 0,
						@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
						@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
						@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
						@oldmatlgroup, @oldmatl, @oldgstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
						0, @oldtaxaccrualacct
					END 
					IF @oldretgGstTaxAmt <> 0 --133107
					BEGIN
						SELECT @oldretgGstTaxAmt = (-1 * @oldretgGstTaxAmt)
						--APGL for retgGST Tax
						exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtRetgGLAcct, @batchseq, @apline, 0,
						@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
						@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
						@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
						@oldmatlgroup, @oldmatl, @oldretgGstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
						0, @oldtaxaccrualacct
					END
				end
				
				-- retainage GST is not broken out but GST is or retg GST is broken out but there is no retainage #131275
				if (@olddbtRetgGLAcct is null and @olddbtGLAcct is not null ) or (@olddbtRetgGLAcct is not null and @oldretainage = 0) 
				begin
					--APGL for GST Tax
					select @oldVATgstTaxAmt = (-1 * @oldVATgstTaxAmt)
					select @olddbtGLAcct = isnull(@olddbtGLAcct,@upglacct) 
					exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtGLAcct, @batchseq, @apline, 0,
					@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
					@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
					@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
					@oldmatlgroup, @oldmatl, @oldVATgstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
					0, @oldtaxaccrualacct
				end
			end
		end
		
		select @i = @i + 1
        if @i < 2 goto OldJC_loop
  	end
  	
 	-- 'New' JC distributions
	if (@LineType in (1,7) or (@LineType = 6 and @itemtype = 1)) and (@linetranstype = 'A' or @change = 'Y')
	begin
		-- If job is closed get closed job gl account - #134876
		select @status=JobStatus,@contract=Contract from bJCJM where JCCo=@jcco and Job=@job
		if @status = 3 -- Job is hard closed
		begin
			-- get the department
			select @dept = Department from bJCCM where JCCo=@jcco and Contract=@contract
			-- get closed GLAcct from phase in Dept override 
			select @closedGLAcct = null
			select @closedGLAcct=ClosedExpAcct from bJCDO where JCCo=@jcco and Department=@dept 
			and PhaseGroup=@phasegroup and Phase=@phase
			if @closedGLAcct is not null
			begin
				exec @rcode = bspGLACfPostable @glco, @closedGLAcct, 'J', @errmsg output
				if @rcode <> 0
				begin
					select @errortext = @errorstart + '- Closed GL Account:' + isnull(@closedGLAcct, '') + ':  ' + isnull(@errmsg,'')  
					goto APLB_error
				end
				else
				begin
					select @glacct = @closedGLAcct
					select @taxglacct = @closedGLAcct
				end
			end
			else -- get closed GLAcct from Costtype  
			begin
				select @closedGLAcct=ClosedExpAcct from bJCDC where JCCo=@jcco and Department=@dept
				and PhaseGroup=@phasegroup and CostType=@jcctype
				if @closedGLAcct is not null 
				begin
					exec @rcode = bspGLACfPostable @glco, @closedGLAcct, 'J', @errmsg output
					if @rcode <> 0
					begin
						select @errortext = @errorstart + '- Closed GL Account:' + isnull(@closedGLAcct, '') + ':  ' + isnull(@errmsg,'')  
						goto APLB_error
					end
					else
					begin
						select @glacct = @closedGLAcct
						select @taxglacct = @closedGLAcct
					end
				end
				else
				begin
					-- no Gl Acct set up for closed job
					select @errortext = @errorstart + ' Missing closed GL Acct for Job: ' + isnull(@job,'') + ' Phase: ' 
					+ isnull(@phase,'') + ' CT: ' + isnull(convert(varchar(5),@jcctype),'')
					goto APLB_error
				end
			end 
		end -- end @status = 3

		/*Break out PST/GST tax amount before doing distributions. */
		if isnull(@valueadd,'N') = 'N'
		begin
			select @payTaxAmt = @taxamt
		end
		/* Breakout and establish all VAT related tax amounts. */
		if isnull(@valueadd,'N') = 'Y'
		begin
			if @pstrate = 0
			begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				if  isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @APHBCheckRevYN = 'Y' --#136500/#133107 Check Reversal
				begin
					-- GST tax basis is not net of retainage - calculate on full gross
					select @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
					select @payTaxAmt = @taxamt - @retgTaxAmt
					select @gstTaxAmt = @payTaxAmt
					select @retgGstTaxAmt = @retgTaxAmt
					select @VATgstTaxAmt = @gstTaxAmt + @retgGstTaxAmt
					select @VATpstTaxAmt = 0
				end
				else  -- GST tax basis is net of retainage 
				begin
					select @retgGstTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@grossamt * @taxrate) * (@retainage/@grossamt) end
					select @gstTaxAmt =  @taxamt  
					select @VATgstTaxAmt = @gstTaxAmt 
					select @VATpstTaxAmt = 0
					select @payTaxAmt = 0
				end
			end
			else
			begin
			-- PST/GST tax basis is not net of retainage - calculate on full gross
				IF  isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @APHBCheckRevYN = 'Y' --#136500/#133107 Check Reversal
				BEGIN
					select @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
					select @payTaxAmt = @taxamt - @retgTaxAmt
					select @gstTaxAmt = case @taxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @taxrate end	
					select @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
					select @retgGstTaxAmt = case @taxrate when 0 then 0 else (@retgTaxAmt * @gstrate) / @taxrate end
					select @retgPstTaxAmt = @retgTaxAmt - @retgGstTaxAmt
					select @VATgstTaxAmt = @gstTaxAmt + @retgGstTaxAmt
					select @VATpstTaxAmt = @pstTaxAmt + @retgPstTaxAmt
				END
				ELSE
				BEGIN
					-- PST and GST tax basis is net of retainage
					SELECT @retgGstTaxAmt = (@retainage * @gstrate)		-- retainage GST tax 
					SELECT @retgPstTaxAmt = (@retainage * @pstrate)		-- retainage PST tax 
					SELECT @retgTaxAmt = (@retainage * @taxrate)		-- total retainage tax
					SELECT @gstTaxAmt = case @taxrate when 0 then 0 else (@taxamt * @gstrate) / @taxrate end --@taxbasis * @gstrate			-- open GST tax
					SELECT @pstTaxAmt = @taxamt - @gstTaxAmt --TK-17202 @taxbasis * @pstrate			-- open PST tax 
					SELECT @VATgstTaxAmt = @gstTaxAmt + @retgGstTaxAmt	-- total of open + retainage GST tax
					SELECT @VATpstTaxAmt = @pstTaxAmt + @retgPstTaxAmt	-- total of open + retainage PST tax
				END
			end

			
			/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
			for credit then include the GST portion of tax with the PST portion (same as Sales tax) */
			if @dbtGLAcct is null
			begin
				select @payTaxAmt= @VATpstTaxAmt + @VATgstTaxAmt
				select @VATgstTaxAmt = 0
			end  
			else
			begin
				select @payTaxAmt = @VATpstTaxAmt
			end
		end
		
        select @i = 0	-- make two passes, 1 for the gross amount and 1 for tax
NewJC_loop:
		select @remcmtdcost = 0, @jcunitcost = 0, @rniunits = 0, @rnicost = 0, @remcmtdunits = 0,
		@totalcmtdunits = 0, @totalcmtdcost = 0,
		@totalcmtdtax = 0, @remcmtdtax = 0  --DC #122288
		if @i = 0 -- Posted Amount (tax may be redirected so exclude it on this pass)
		begin
			if @LineType = 7 select @curecm = 'E'
			select @factor = case @curecm when 'C' then 100 when 'M' then 1000 else 1 end
			-- total cost may include misc amt if paid to vendor, less discount if net option is used
			select @totalcost = @grossamt + (case @miscyn when'Y' then @miscamt else 0 end)	- (case @netamtopt when 'Y' then @discount else 0 end)
			-- POs will update Remaining Committed Cost, Units
			if @LineType = 6 
			begin
				SELECT @origunits=OrigUnits, @origcost=OrigCost, @curunits = CurUnits, @curcost = CurCost
				FROM vPOItemLine
				--select @origunits=OrigUnits, @origcost=OrigCost, @curunits = CurUnits, @curcost = CurCost from bPOIT
				--select @curunits = CurUnits, @curcost = CurCost from bPOIT
				WHERE POCo = @apco AND PO = @po AND POItem = @poitem AND POItemLine = @POItemLine
				if (@origunits = 0 and @curunits = 0) and (@origcost = 0 and @curcost=0) and @recyn = 'N' -- standing PO w/o receiving
				--if @curunits = 0 and @curcost=0 and @recyn = 'N' 
				begin
					select @remcmtdcost = 0 --Total cost - invoiced cost = remaining cmtd cost
					select @remcmtdunits = 0 --total units - invoiced units = remaining cmtd units
					select @totalcmtdunits = @jcunits -- Received units + BO units = total cmtd units
					select @totalcmtdcost = @grossamt	-- Received cost + BO cost = total cmtd cost
				end
				else	-- regular PO or standing PO flagged for receiving
				begin
					select @remcmtdcost = case when @um = 'LS' then -@grossamt else -(@apunits * @curunitcost) / @factor end
					select @remcmtdunits = -@jcunits    -- will be 0.00 if 'LS'
					select @totalcmtdunits = 0
					select @totalcmtdcost = 0
				end
			end
			
			if @LineType = 7 and @slitemtype <> 3
			-- SLs (except Backcharge Item) will update Remaining Committed Cost
			begin
				select @remcmtdcost = case when @um = 'LS' then -@grossamt else -(@apunits * @curunitcost) / @factor end
				select @remcmtdunits = -@jcunits   -- #19926 - will be 0.00 if 'LS'
			end
			
			-- RNI only applies to PO Items flagged for receiving
			if @LineType = 6 and @recyn = 'Y'
			begin
				select @rniunits = -@jcunits    -- will be 0.00 if 'LS'
				select @rnicost = @remcmtdcost	-- change to RNI Cost will equal change to Rem Cmtd Cost
			end
			
			-- JC Unit Cost only calculated on this pass so include tax unless tax is being redirected --30264
			if @jcunits <> 0 
			begin
				if isnull(@taxphase, @phase) <> @phase or isnull(@taxct,@jcctype) <> @jcctype
				begin
					select @jcunitcost = (@totalcost / @jcunits)
				end
				else
				begin
					select @jcunitcost = (@totalcost + @payTaxAmt) / @jcunits
				end
			end
			
			-- use posted phase, cost type, etc.
			select @upphase = @phase, @upjcctype = @jcctype, @upglacct = @glacct, @upum = @um,
			@upunits = @apunits, @upjcum = @jcum, @upjcunits = @jcunits, @upjcecm = 'E',
			@uptaxbasis = 0, @uptaxamt = 0, @usetaxamt = 0
		end
		
		if @i = 1 -- Tax amount
		begin
			select @totalcost = @payTaxAmt, @uptaxbasis = @taxbasis, @uptaxamt = @payTaxAmt,@remcmtdunits = 0 
			select @factor = case @curecm when 'C' then 100 when 'M' then 1000 else 1 end
			-- update Remaining Commited Cost with tax for POs 
			if @LineType = 6
			begin
				if @curunits = 0 and @curcost=0 and @recyn = 'N' -- blanket PO not flagged for recvng
				begin
					select @remcmtdcost = 0
					select @totalcmtdcost = @totalcost 
				end
				else	-- reg PO or standing PO flagged for receiving
				begin
					select @posltaxbasis = (@apunits * @curunitcost)/@factor -- 28714
					select @poslTaxAmt= case when @um = 'LS' then (@grossamt * isnull(@potaxrate,0)) else (@posltaxbasis * @potaxrate) end
					--calculate remaining commited cost for tax
					if @dbtGLAcct is not null
					begin
						-- if this is a GST only taxcode @polGSTrate will be 0, set it to @potaxrate
						if @poGSTrate = 0 select @poGSTrate = @potaxrate
						--calculate GST portion of po tax to back out of remaining commited cost
						select @poslGSTtaxAmt = case @potaxrate when 0 then 0 else (@poslTaxAmt * @poGSTrate) / @potaxrate end
						select @remcmtdcost = -(@poslTaxAmt - @poslGSTtaxAmt)
						select @remcmtdtax = -(@poslTaxAmt - @poslGSTtaxAmt) --DC #122288
					end
					else
					begin
						select @remcmtdcost = -(@poslTaxAmt)
						select @remcmtdtax = -(@poslTaxAmt) --DC #122288
					end
				end
			end
			
			-- update Remaining Committed Cost with tax for SL
			if @LineType = 7 and @slitemtype <> 3
			begin
				select @posltaxbasis = (@apunits * @curunitcost)/@factor -- 28714
				select @poslTaxAmt= case when @um = 'LS' then (@grossamt * isnull(@sltaxrate,0)) else (@posltaxbasis * @sltaxrate) end
				--calculate remaining commited cost for tax
			
				if @dbtGLAcct is not null
				begin
					-- if this is a GST only taxcode @slGSTrate will be 0, set it to @sltaxrate
					if @slGSTrate = 0 select @slGSTrate = @sltaxrate
					--calculate GST portion of sl tax to back out of remaining commited cost
					select @poslGSTtaxAmt = case @sltaxrate when 0 then 0 else (@poslTaxAmt * @slGSTrate) / @sltaxrate end
					select @remcmtdcost = -(@poslTaxAmt - @poslGSTtaxAmt)
					select @remcmtdtax = -(@poslTaxAmt - @poslGSTtaxAmt) --DC #122288
				end
				else
				begin
					select @remcmtdcost = -(@poslTaxAmt)
					select @remcmtdtax = -(@poslTaxAmt)  --DC #122288
				end
			end
			
			-- RNI only applies to PO Items flagged for receiving
			if @LineType = 6 and @recyn = 'Y'
			begin
				select @rnicost = isnull(@remcmtdcost,0)
			end
			
			-- Tax phase and cost type
			select @upphase = @taxphase, @upjcctype = @taxct, @upglacct = @taxglacct, @upum = null,
			@upunits = 0, @upjcum = null, @upjcunits = 0, @upjcecm = null
			-- include Use Tax on this pass to add GL Accrual distribution
			select @usetaxamt = case @taxtype when 2 then @taxamt else 0 end
		end
		
		-- add new APJC entry
		IF ((@totalcost <> 0) or (@i = 1 and @uptaxbasis <> 0 and @taxcode is not null)) /*#29610*/
			or @upunits <> 0 or @rniunits <> 0 or isnull(@rnicost,0) <> 0 
			or isnull(@remcmtdcost,0) <> 0 or isnull(@totalcmtdcost,0) <> 0
		BEGIN
				exec @rcode = bspAPLBValJCInsert @apco, @mth, @batchid, @jcco, @job, @phasegroup, @upphase,
				@upjcctype, @batchseq, @apline, 1, @aptrans, @vendorgroup, @vendor, @apref, @transdesc,
				@invdate, @sl, @slitem, @po, @poitem, @POItemLine, @matlgroup, @matl, @linedesc, @glco, @upglacct,
				@upum, @upunits, @upjcum, @upjcunits, @jcunitcost, @upjcecm, @totalcost, @rniunits, @rnicost,
				@remcmtdcost, @taxgroup, @taxcode, @taxtype, @uptaxbasis, @uptaxamt, @remcmtdunits, @totalcmtdunits,
				@totalcmtdcost,@totalcmtdtax, @remcmtdtax  --DC #122288
		END
		
		-- add new APGL entry - will make intercompany entries if needed
		if @totalcost <> 0 or @usetaxamt <> 0 or @VATgstTaxAmt <> 0 OR @retgGstTaxAmt <> 0 --TK-08150
		begin
			if @i = 0 -- APGL for Job Expense - Gross Amt 
			begin
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @upglacct, @batchseq, @apline, 1,
				@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
				@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
				@emctype, @inco, @loc, @matlgroup, @matl, @totalcost, @apglco, @intercoarglacct, @intercoapglacct,
				@usetaxamt, @taxaccrualacct
			end
			
			if @i = 1 
			begin
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @upglacct, @batchseq, @apline, 1,
				@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
				@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
				@emctype, @inco, @loc, @matlgroup, @matl, @totalcost, @apglco, @intercoarglacct, @intercoapglacct,
				@usetaxamt, @taxaccrualacct	

				-- retainage GST is broken out 
				if @dbtRetgGLAcct is not null and @retainage <> 0 
				begin
					IF @gstTaxAmt <> 0 --133107
					BEGIN
						--APGL for GST Tax
						exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @dbtGLAcct, @batchseq, @apline, 1,
						@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
						@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
						@emctype, @inco, @loc, @matlgroup, @matl, @gstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
						0, @taxaccrualacct
					END

					IF @retgGstTaxAmt <> 0 --133107
					BEGIN
						--APGL for retgGST Tax
						exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @dbtRetgGLAcct, @batchseq, @apline, 1,
						@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
						@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
						@emctype, @inco, @loc, @matlgroup, @matl, @retgGstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
						0, @taxaccrualacct
					END
				end

				-- retainage GST is not broken out but GST is or retg GST is broken out but there is no retainage #131275
				if (@dbtRetgGLAcct is null and @dbtGLAcct is not null ) or (@dbtRetgGLAcct is not null and @retainage = 0) 
				begin
					--APGL for GST Tax
					/* if the user set up a ValueAdd taxcode with a GST rate but is not tracking the GST in an ITC account
					for credit then send the GST portion of tax to the Expense acct */
					select @dbtGLAcct = isnull(@dbtGLAcct,@upglacct)
					exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco,@dbtGLAcct,
					@batchseq, @apline, 1,@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType,
					@itemtype,@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
					@emctype, @inco, @loc, @matlgroup, @matl, @VATgstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
					0, @taxaccrualacct
				end
			end
		end
		
		select @i = @i + 1
		if @i < 2 goto NewJC_loop
		
	end  --End New JC Distributions

	-- 'Old' EM distributions
	if (@oldlinetype in (4,5) or (@oldlinetype = 6 and @olditemtype in (4,5)))	and (@linetranstype = 'D' or @change = 'Y')
	begin
		if isnull(@oldvalueadd,'N') = 'N'
		begin
			select @oldpayTaxAmt = @oldtaxamt
		end

		/* Breakout and establish all VAT related tax amounts. */
		if isnull(@oldvalueadd,'N') = 'Y'
		begin
			if @oldpstrate = 0
			begin
				/* When @oldpstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @oldpayTaxAmt = @oldtaxamt 
				select @oldgstTaxAmt = @oldpayTaxAmt
				select @oldVATgstTaxAmt = @oldgstTaxAmt 
				select @oldVATpstTaxAmt = 0
			end
			else
			begin
				select @oldpayTaxAmt = @oldtaxamt 
				select @oldgstTaxAmt = case @oldtaxrate when 0 then 0 else (@oldpayTaxAmt * @oldgstrate) / @oldtaxrate end	
				select @oldpstTaxAmt = @oldpayTaxAmt - @oldgstTaxAmt
				select @oldVATgstTaxAmt =  @oldgstTaxAmt
				select @oldVATpstTaxAmt =  @oldpstTaxAmt
			end		

			/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC Expense GL Acct
			then include the GST portion of tax in the Inventory Expense acct */
			if @olddbtGLAcct is null
			begin
				select @oldpayTaxAmt= @oldVATpstTaxAmt + @oldVATgstTaxAmt
				select @oldVATgstTaxAmt = 0
			end  
			else
			begin
				select @oldpayTaxAmt = @oldVATpstTaxAmt
			end
		end
		
		-- set update amounts
		select @totalcost = @oldgrossamt + @oldpayTaxAmt + (case @oldmiscyn when'Y' then @oldmiscamt else 0 end)
		- (case @netamtopt when 'Y' then @olddiscount else 0 end)
		select @c1 = (-1 * @totalcost)
		select @usetaxamt = case @oldtaxtype when 2 then (-1 * @oldtaxamt) else 0 end
		-- add old APEM entry
		if @totalcost <> 0 or @oldunits <> 0
		begin
			select @u1 = (-1 * @oldunits), @u2 = (-1 * @oldemunits),		-- reverse sign for old entry
			@t1 = (-1 * @oldtaxbasis), @t2 = (-1 * @oldpayTaxAmt)	-- Issue #139910, Out --> @t2 = (-1 * @oldtaxamt)   
			--select @usetaxamt = case @oldtaxtype when 2 then (-1 * @oldtaxamt) else 0 end
			exec @rcode = bspAPLBValEMInsert @apco, @mth, @batchid, @oldemco, @oldequip, @oldemgroup, @oldcostcode,
			@oldemctype, @batchseq, @apline, 0, @aptrans, @oldvendorgroup, @oldvendor, @oldapref, @oldtransdesc,
			@oldinvdate, @oldpo, @oldpoitem, @OldPOItemLine, @oldwo, @oldwoitem, @oldcomptype, @oldcomponent, @oldmatlgroup,
			@oldmatl, @oldlinedesc, @oldglco, @oldglacct, @oldum, @u1, @oldunitcost, @oldecm,
			@oldemum, @u2, @c1, @oldtaxgroup, @oldtaxcode, @oldtaxtype, @t1, @t2
		end
		
		-- add old APGL entry - will make intercompany entries if needed
		if @totalcost <> 0 or @usetaxamt <> 0
		begin
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @oldglacct, @batchseq, @apline, 0,
			@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
			@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
			@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
			@oldmatlgroup, @oldmatl, @c1, @apglco, @oldintercoarglacct, @oldintercoapglacct,
			@usetaxamt, @oldtaxaccrualacct
			-- post GST portion of tax to GST Payables
			if @oldVATgstTaxAmt <> 0 
			begin
				select @oldVATgstTaxAmt = (-1 * (@oldVATgstTaxAmt))
				--APGL for GST Tax
				/* if the user set up a ValueAdd GST taxcode but is not tracking the GST in an ITC account
				for credit then send the GST portion of tax to the Expense acct */
				select @olddbtGLAcct = isnull(@olddbtGLAcct,@oldglacct)
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtGLAcct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
				@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @oldVATgstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
				@usetaxamt, @oldtaxaccrualacct
			end
		end
	end
  
	-- 'New' EM distributions
	if (@LineType in (4,5) or (@LineType = 6 and @itemtype in (4,5))) and (@linetranstype = 'A' or @change = 'Y')
	begin
		/* Sales or Use Tax. */
		if isnull(@valueadd,'N') = 'N'
		begin
			select @payTaxAmt = @taxamt
		end
		/* Breakout and establish all VAT related tax amounts. */
		if isnull(@valueadd,'N') = 'Y'
		begin
			if @pstrate = 0
			begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @payTaxAmt = @taxamt 
				select @gstTaxAmt = @payTaxAmt
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = 0
			end
			else
			begin
				select @payTaxAmt = @taxamt 
				select @gstTaxAmt = case @taxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @taxrate end	
				select @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = @pstTaxAmt
			end
			/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
			for credit then include the GST portion of tax with PST */
			if @dbtGLAcct is null
			begin
				select @payTaxAmt= @VATpstTaxAmt + @VATgstTaxAmt
				select @VATgstTaxAmt = 0
			end  
			else
			begin
				select @payTaxAmt = @VATpstTaxAmt
			end
		end
		
		-- set update amounts
		select @totalcost = @grossamt + @payTaxAmt + (case @miscyn when 'Y' then @miscamt else 0 end) - (case @netamtopt when 'Y' then @discount else 0 end)
		select @usetaxamt = case @taxtype when 2 then @taxamt else 0 end
		-- add new APEM entry
		
		if @totalcost <> 0 or @apunits <> 0
		BEGIN
			exec @rcode = bspAPLBValEMInsert @apco, @mth, @batchid, @emco, @equip, @emgroup, @costcode,
			@emctype, @batchseq, @apline, 1, @aptrans, @vendorgroup, @vendor, @apref, @transdesc,
			@invdate, @po, @poitem, @POItemLine, @wo, @woitem, @comptype, @component, @matlgroup,
			@matl, @linedesc, @glco, @glacct, @um, @apunits, @apunitcost, @ecm,
			@emum, @emunits, @totalcost, @taxgroup, @taxcode, @taxtype, @taxbasis, @payTaxAmt
		END
		
		-- add new APGL entry - will make intercompany entries if needed
		if @totalcost <> 0 or @usetaxamt <> 0
		begin
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @glacct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @totalcost, @apglco, @intercoarglacct, @intercoapglacct,
			@usetaxamt, @taxaccrualacct

			-- post GST portion of tax to GST Payables
			if isnull(@VATgstTaxAmt,0) <> 0  
			begin
				--APGL for GST Tax
				/* if the user set up a ValueAdd GST taxcode but is not tracking the GST in an ITC account
				for credit then send the GST portion of tax to the Expense acct */
				select @dbtGLAcct = isnull(@dbtGLAcct,@glacct)
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @dbtGLAcct, @batchseq, @apline, 1,
				@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
				@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
				@emctype, @inco, @loc, @matlgroup, @matl, @VATgstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
				@usetaxamt, @taxaccrualacct
			end
		end
	end

--Old SM

	IF (@oldlinetype = 8 or (@oldlinetype = 6 and @olditemtype = 6)) and (@linetranstype = 'D' or @change = 'Y')
	BEGIN
		-- AP Type 6 (PO) -> SM Type 5 (Purchase), AP Type 8 (SM) -> SM Type 3 (Misc)
		SELECT @oldsmtype = CASE @oldlinetype WHEN 6 THEN 5 WHEN 8 THEN 3 END, @smoldnew = 0

		IF ((@LineType = 8 and (@oldlinetype = 6 and @olditemtype = 6)) or (@oldlinetype = 8 and (@LineType = 6 and @itemtype = 6)))
		BEGIN
			SET @smLineTypeChanged = 1
		END
		ELSE
		BEGIN
			SET @smLineTypeChanged = 0
		END

		IF @smLineTypeChanged = 1 or (isnull(@smco, 0) <> isnull(@oldsmco, 0) or isnull(@smworkorder,-1) <> isnull(@oldsmworkorder,-1) or isnull(@scope,-1) <> isnull(@oldscope,-1))
		BEGIN
			--If this is a change transaction and we have changed the SMCompany or Work Order treat this side
			--of the transaction as a delete.  
			SELECT @linetranstype = 'D'
		END

		SELECT
			@oldpayTaxAmt = @oldtaxamt,
			@usetaxamt = CASE @oldtaxtype WHEN 2 THEN (-1 * @oldpayTaxAmt) ELSE 0 END

		/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
		then there is no need to break out the GST amount */
		IF @oldvalueadd = 'Y' AND @olddbtGLAcct IS NOT NULL
		BEGIN
			SELECT
				@oldgstTaxAmt = 
					CASE
						--If the PST rate is 0 then the tax amount is all GST
						WHEN @oldpstrate = 0 THEN @oldpayTaxAmt 
						WHEN @oldtaxrate <> 0 THEN (@oldpayTaxAmt *  @oldgstrate) / @oldtaxrate ELSE 0 
					END,
				@oldpayTaxAmt = @oldpayTaxAmt - @oldgstTaxAmt,
				-- reverse sign for old entries
				@oldgstTaxAmt = -@oldgstTaxAmt

			IF @oldgstTaxAmt <> 0
			BEGIN
				EXEC @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtGLAcct, @batchseq, @apline, 0,
					@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
					@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
					@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
					@oldmatlgroup, @oldmatl, @oldgstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
					@usetaxamt, @oldtaxaccrualacct
			END
		END

		-- set update amounts
		SELECT @totalcost = @oldgrossamt + @oldpayTaxAmt + (CASE @oldmiscyn WHEN 'Y' THEN @oldmiscamt ELSE 0 END) 
		- (CASE @netamtopt WHEN 'Y' THEN @olddiscount ELSE 0 END)
		SELECT @totalcost = (@totalcost * -1)

		IF @oldlinetype = 6
		BEGIN
			INSERT dbo.vPOItemLineDistribution (HQBatchDistributionID, POCo, PO, POItem, POItemLine, InvUnits, InvCost, InvTaxBasis, InvDirectExpenseTax, InvTotalCost)
			VALUES (@HQBatchDistributionID, @apco, @oldpo, @oldpoitem, @OldPOItemLine, -@oldunits, -@oldgrossamt, -@oldtaxbasis, -@oldpayTaxAmt, @totalcost)
		END

		SELECT @smlinedesc = isnull(@matl,'') + isnull(@linedesc,'')
	
		SELECT @oldsmservicesite = ServiceSite FROM dbo.SMWorkOrder WHERE SMCo=@oldsmco and WorkOrder=@oldsmworkorder
		
		/* Validate Workorder Scope and get Scope related defaults */
		EXEC @rcode = vspSMWorkCompletedScopeVal @SMCo=@oldsmco, @WorkOrder=@oldsmworkorder, @Scope=@oldscope,
			@LineType=@oldsmtype, @AllowProvisional='Y', @SMCostType=@oldsmcosttype, @msg=@errortext OUTPUT
		IF (@rcode=1)
		BEGIN
			set @errortext = 'Scope validation: ' + @errortext
			GOTO APLB_error
		END

		exec @rcode = vspAPLBValSMInsert @apco, @mth, @batchid, @batchseq, @oldlinetype, @aptrans, @aptlkeyid, @apline, @oldsmco, 
		@oldsmservicesite, @oldsmworkorder, @oldscope, @oldsmtype, @oldsmcosttype, @oldsmjccosttype, @oldsmphasegroup, @oldsmphase,
		@oldpo, @oldpoitem, @OldPOItemLine, @oldinvdate, @oldum, 
		@oldunits, @oldunitcost, @oldgrossamt, @totalcost, NULL,
		@oldsmlinedesc, @oldglco, @oldglacct, @smoldnew, @oldmiscyn, @oldmiscamt, @linetranstype, NULL, NULL, NULL
		
		IF @rcode <> 0
		BEGIN
			SELECT @errortext = @errorstart + ' - ' + 'Unable to create SM distribution.'
			GOTO APLB_error
		END

		INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchLineID, HQBatchDistributionID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID)
		SELECT 1 IsReversing, 0 IsPosted, @HQBatchLineID, @HQBatchDistributionID, @oldsmtype, 'C'/*C for cost*/, @apco, @mth, @batchid, @oldglco, @oldglacct, @totalcost,
			CASE @oldlinetype 
				WHEN 6 THEN (SELECT vSMWorkCompleted.SMWorkCompletedID FROM dbo.vPOItemLine INNER JOIN dbo.vSMWorkCompleted ON vPOItemLine.SMCo = vSMWorkCompleted.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkCompleted.WorkOrder AND vPOItemLine.SMWorkCompleted = vSMWorkCompleted.WorkCompleted WHERE vPOItemLine.POCo = @apco AND  vPOItemLine.PO = @oldpo AND  vPOItemLine.POItem = @oldpoitem AND  vPOItemLine.POItemLine = @OldPOItemLine)
				WHEN 8 THEN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompleted WHERE APTLKeyID = @aptlkeyid)
			END,
			(SELECT SMWorkOrderScopeID FROM dbo.vSMWorkOrderScope WHERE SMCo = @oldsmco AND WorkOrder = @oldsmworkorder AND Scope = @oldscope),
			(SELECT SMWorkOrderID FROM dbo.vSMWorkOrder WHERE SMCo = @oldsmco AND WorkOrder = @oldsmworkorder)

		exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @oldglacct, @batchseq, @apline, @smoldnew,
		@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
		@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
		@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
		@oldmatlgroup, @oldmatl, @totalcost, @apglco, @oldintercoarglacct, @oldintercoapglacct,
		@usetaxamt, @oldtaxaccrualacct
	END
	
--New SM
	IF ((@LineType = 8 or (@LineType = 6 and @itemtype = 6)) and (@linetranstype = 'A' or @change = 'Y'))
	BEGIN
		SELECT @smoldnew = 1
		
		IF @LineType = 8
		BEGIN
			SELECT @smtype = 3
			
			IF EXISTS(SELECT 1 FROM dbo.vfSMGetAccountingTreatment(@smco, @smworkorder, @scope, 'M', @smcosttype) WHERE dbo.vfIsEqual(GLCo, @glco) = 0 OR dbo.vfIsEqual(CurrentCostGLAcct, @glacct) = 0)
			BEGIN
				SELECT @errortext = @errorstart + ' - ' + 'The gl account assigned to the line doesn''t match the account that will be given the work completed line. Clear the scope field and re-enter the scope to default the correct account.'
				GOTO APLB_error
			END

			IF ((@LineType = 8 and (@oldlinetype = 6 and @olditemtype = 6)) or (@oldlinetype = 8 and (@LineType = 6 and @itemtype = 6)))
			BEGIN
				SET @smLineTypeChanged = 1
			END
			ELSE
			BEGIN
				SET @smLineTypeChanged = 0
			END

			IF @smLineTypeChanged = 1 OR (isnull(@smco, 0) <> isnull(@oldsmco, 0) or isnull(@smworkorder,-1) <> isnull(@oldsmworkorder,-1) or isnull(@scope,-1) <> isnull(@oldscope,-1))
			BEGIN
				--If this is a change transaction and we have changed the SMCompany or Work Order treat this side
				--of the transaction as a new add.  
				SELECT @linetranstype = 'A' --, @aptlkeyid = null
			END
		END
		ELSE
		BEGIN
			SELECT @smtype = 5
		END
		
		----Validate Work Order
		exec @rcode = vspAPLBValSM @smco, @smworkorder, @scope, @smcosttype, @smjccosttype, @smphasegroup, @smphase, @smtype, @invdate, @aptlkeyid, @taxgroup, @taxcode,
			@smservicesite OUTPUT, @smtaxtype OUTPUT, @smtaxgroup OUTPUT, @smtaxcode OUTPUT, @smtaxrate OUTPUT, @errmsg OUTPUT
		IF @rcode <> 0
		BEGIN
			SELECT @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
			GOTO APLB_error
		END

		SELECT
			@payTaxAmt = @taxamt,
			@usetaxamt = CASE @taxtype WHEN 2 THEN @payTaxAmt ELSE 0 END

		/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
		then there is no need to break out the GST amount */
		IF @valueadd = 'Y' AND @dbtGLAcct IS NOT NULL
		BEGIN
			SELECT
				@gstTaxAmt = 
					CASE
						--If the PST rate is 0 then the tax amount is all GST
						WHEN @pstrate = 0 THEN @payTaxAmt 
						WHEN @taxrate <> 0 THEN (@payTaxAmt * @gstrate) / @taxrate ELSE 0 
					END,
				@payTaxAmt = @payTaxAmt - @gstTaxAmt

			IF @gstTaxAmt <> 0
			BEGIN
				EXEC @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @dbtGLAcct, @batchseq, @apline, 1,
					@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
					@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
					@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
					@matlgroup, @matl, @gstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
					@usetaxamt, @taxaccrualacct
			END
		END

		-- set update amounts
		select @totalcost = @grossamt + @payTaxAmt + (case @miscyn when 'Y' then @miscamt else 0 end)
		 - (case @netamtopt when 'Y' then @discount else 0 end)

		SELECT @smlinedesc = isnull(@matl,'') + isnull(@linedesc,'')

		--The tax rate should be null unless a tax amount should be able to be calculated for a misc line
		select @smtaxamt = @totalcost*@smtaxrate
		
		exec @rcode = vspAPLBValSMInsert @apco, @mth, @batchid, @batchseq, @LineType, @aptrans, @aptlkeyid, 
		@apline, @smco, @smservicesite, @smworkorder, @scope, @smtype, @smcosttype, @smjccosttype, @smphasegroup,@smphase,
		@po, @poitem, @POItemLine,
		@invdate, @um, @apunits, @apunitcost, @grossamt, @totalcost, @smtaxgroup,  
		@smlinedesc, @glco, @glacct, @smoldnew, @miscyn, @miscamt, @linetranstype, @smtaxcode, @smtaxamt, @smtaxtype
		
		IF @rcode <> 0
		BEGIN
			SELECT @errortext = @errorstart + ' - ' + 'Unable to create SM distribution.'
			GOTO APLB_error
		END
				
		IF @LineType = 6
		BEGIN
			INSERT dbo.vPOItemLineDistribution (HQBatchDistributionID, POCo, PO, POItem, POItemLine, InvUnits, InvCost, InvTaxBasis, InvDirectExpenseTax, InvTotalCost)
			VALUES (@HQBatchDistributionID, @apco, @po, @poitem, @POItemLine, @apunits, @grossamt, @taxbasis, @payTaxAmt, @totalcost)
		END

		INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchLineID, HQBatchDistributionID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID)
		SELECT 0 IsReversing, 0 IsPosted, @HQBatchLineID, @HQBatchDistributionID, @smtype, 'C'/*C for cost*/, @apco, @mth, @batchid, @glco, @glacct, @totalcost,
			--WorkCompleted may already exist for an add record when the work order or scope changes.
			CASE
				WHEN @LineType = 6 THEN (SELECT vSMWorkCompleted.SMWorkCompletedID FROM dbo.vPOItemLine INNER JOIN dbo.vSMWorkCompleted ON vPOItemLine.SMCo = vSMWorkCompleted.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkCompleted.WorkOrder AND vPOItemLine.SMWorkCompleted = vSMWorkCompleted.WorkCompleted WHERE  vPOItemLine.POCo = @apco AND  vPOItemLine.PO = @po AND  vPOItemLine.POItem = @poitem AND  vPOItemLine.POItemLine = @POItemLine) 
				WHEN @linetranstype = 'C' AND @LineType = 8 THEN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompleted WHERE APTLKeyID = @aptlkeyid)
			END,
			(SELECT SMWorkOrderScopeID FROM dbo.vSMWorkOrderScope WHERE SMCo = @smco AND WorkOrder = @smworkorder AND Scope = @scope),
			(SELECT SMWorkOrderID FROM dbo.vSMWorkOrder WHERE SMCo = @smco AND WorkOrder = @smworkorder)
	
		EXEC @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @glacct, @batchseq, @apline, 1,
		@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
		@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
		@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
		@matlgroup, @matl, @totalcost, @apglco, @intercoarglacct, @intercoapglacct,
		@usetaxamt, @taxaccrualacct

		EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'AP Entry', @TransactionsShouldBalance = 0, @msg = @errortext OUTPUT
	
		IF @GLEntryID = -1
		BEGIN
			--Log error
			GOTO APLB_error
		END
		
		INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, BatchSeq, Line, Trans, InterfacingCo)
		VALUES (@GLEntryID, @apco, @mth, @batchid, @batchseq, @apline, @aptrans, @apco)

		INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
		VALUES (@GLEntryID, 1, @glco, @glacct, @totalcost, dbo.vfDateOnly(), @TransactionDescription)
		
		INSERT dbo.vAPTLGLEntry (GLEntryID, GLTransactionForAPTransactionLineAccount)
		VALUES (@GLEntryID, 1)
	
	END

	-- 'Old' Expense distributions  (SM is using Expense type distributions) - 131640
	if (@oldlinetype = 3 or (@oldlinetype = 6 and @olditemtype = 3)) and (@linetranstype = 'D' or @change = 'Y')
	--if (@oldlinetype = 3 or (@oldlinetype = 6 and @olditemtype in (3,6))) and (@linetranstype = 'D' or @change = 'Y')  --<-- TK-02798 revert to original.  SM will have its own.
	begin
		-- set update amounts
		select @totalcost = @oldgrossamt + (case isnull(@oldvalueadd,'N') when 'N' then @oldtaxamt else 0 end) 
		+ (case @oldmiscyn when'Y' then @oldmiscamt else 0 end)
		- (case @netamtopt when 'Y' then @olddiscount else 0 end)
		select @c1 = (-1 * @totalcost)  -- reverse sign for old amount
		select @usetaxamt = case @oldtaxtype when 2 then (-1 * @oldtaxamt) else 0 end
		-- add old APGL entry - will make intercompany entries if needed
		if @totalcost <> 0 or @usetaxamt <> 0
		BEGIN
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @oldglacct, @batchseq, @apline, 0,
			@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
			@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
			@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
			@oldmatlgroup, @oldmatl, @c1, @apglco, @oldintercoarglacct, @oldintercoapglacct,
			@usetaxamt, @oldtaxaccrualacct
		END
		
		-- add APGL entry for old PST/GST tax 
		if isnull(@oldvalueadd,'N') = 'Y' -- VAT value added tax
		begin
			/* Breakout and establish all VAT related tax amounts now. */
			if @oldpstrate = 0 --TK-04672/#143321 changed @pstrate to @oldpstrate
			begin
				/* When @oldpstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @oldpayTaxAmt = @oldtaxamt 
				select @oldgstTaxAmt = @oldpayTaxAmt
				select @oldVATgstTaxAmt = @oldgstTaxAmt 
				select @oldVATpstTaxAmt = 0
			end
			else
			begin
				select @oldpayTaxAmt = @oldtaxamt 
				select @oldgstTaxAmt = case @oldtaxrate when 0 then 0 else (@oldpayTaxAmt * @oldgstrate) / @oldtaxrate end	
				select @oldpstTaxAmt = @oldpayTaxAmt - @oldgstTaxAmt	
				-- reverse sign for old entries
				select @oldVATgstTaxAmt = @oldgstTaxAmt 
				select @oldVATpstTaxAmt = @oldpstTaxAmt 
			end	
				
			-- reverse the sign
			select @oldVATgstTaxAmt = (-1 * @oldVATgstTaxAmt)
			select @oldVATpstTaxAmt = (-1 * @oldVATpstTaxAmt)
			-- post non-GST portion of tax to AP Payables
			if @oldVATpstTaxAmt <> 0
			begin
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @oldglacct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
				@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @oldVATpstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
				@usetaxamt, @oldtaxaccrualacct
			end

			-- post GST portion of tax to GST Payables
			if @oldVATgstTaxAmt <> 0 
			begin
				--APGL for GST Tax
				/* if the user set up a ValueAdd GST taxcode but is not tracking the GST in an ITC account
				for credit then send the GST portion of tax to the Expense acct */
				select @olddbtGLAcct = isnull(@olddbtGLAcct,@oldglacct)
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtGLAcct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype,@oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @upphase,
				@upjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @oldVATgstTaxAmt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
				@usetaxamt, @oldtaxaccrualacct
			end
		end
	end --End 'Old' Expense distributions

	-- 'New' Expense distributions (SM is using Expense type distributions)  131640
	if (@LineType = 3 or (@LineType = 6 and @itemtype = 3)) and (@linetranstype = 'A' or @change = 'Y')
	--if (@LineType = 3 or (@LineType = 6 and @itemtype in(3,6))) and (@linetranstype = 'A' or @change = 'Y') --<-- TK-02798 revert to original.  SM will have its own.
	begin
		-- set update amounts
		select @totalcost = @grossamt + (case isnull(@valueadd,'N') when 'N' then @taxamt else 0 end)
		+ (case @miscyn when'Y' then @miscamt else 0 end)
		- (case @netamtopt when 'Y' then @discount else 0 end)
		select @usetaxamt = case @taxtype when 2 then @taxamt else 0 end
		-- add new APGL entry - will make intercompany entries if needed
		if @totalcost <> 0 or @usetaxamt <> 0
		BEGIN
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @glacct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @totalcost, @apglco, @intercoarglacct, @intercoapglacct,
			@usetaxamt, @taxaccrualacct
		END
		
		-- add new APGL entry for PST/GST tax 
		if isnull(@valueadd,'N') = 'Y' -- VAT value added tax
		begin	
			/* Breakout and establish all VAT related tax amounts now. */
			if @pstrate = 0
			begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @payTaxAmt = @taxamt 
				select @gstTaxAmt = @payTaxAmt
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = 0
			end
			else
			begin
				select @payTaxAmt = @taxamt 
				select @gstTaxAmt = case @taxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @taxrate end	
				select @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = @pstTaxAmt 
			end

			-- post non-GST portion of tax to AP Payables
			if @VATpstTaxAmt <> 0
			begin
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @glacct, @batchseq, @apline, 1,
				@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
				@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
				@emctype, @inco, @loc, @matlgroup, @matl, @VATpstTaxAmt, @apglco,@intercoarglacct,
				@intercoapglacct,@usetaxamt, @taxaccrualacct
			end

			-- post GST portion of tax to GST Payables
			if @VATgstTaxAmt <> 0 
			begin
				--APGL for GST Tax
				/* if the user set up a ValueAdd GST taxcode but is not tracking the GST in an ITC account
				for credit then send the GST portion of tax to the Expense acct */
				select @dbtGLAcct = isnull(@dbtGLAcct,@glacct)
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @dbtGLAcct, @batchseq, @apline, 1,
				@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc, @LineType, @itemtype,
				@linedesc, @jcco, @job, @phasegroup, @upphase, @upjcctype, @emco, @equip, @emgroup, @costcode,
				@emctype, @inco, @loc, @matlgroup, @matl, @VATgstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
				@usetaxamt, @taxaccrualacct
			end
		end
	end
  
	-- 'Old' IN distributions
	if (@oldlinetype = 2 or (@oldlinetype = 6 and @olditemtype = 2)) and (@linetranstype = 'D' or @change = 'Y')
	begin
		/*Because tax amount is included with the gross if costs are burdened we need to calculate now how much of the total tax amount 
		should be added to gross (if burdened).  If the taxcode is not value added (Sales or Use) then include all the tax amount. 
		If it is a value added taxcode determine the PST and GST portions. The PST portion will be added to the gross if burdenend
		but the GST should not unless the taxcode is set up as value added with GST BUT they are not tracking the GST portion in an
		ITC expense account(@dbtGLAcct is snull) then the GST portion should be treated as Sales and included in the tax amount added
		to gross for burdened costs. */
		/* Sales or Use Tax. */
		if isnull(@oldvalueadd,'N') = 'N'
		begin
			select @oldpayTaxAmt = @oldtaxamt
		end
		/* Breakout and establish all VAT related tax amounts. */
		if isnull(@oldvalueadd,'N') = 'Y'
		begin
			if @oldpstrate = 0
			begin
				/* When @oldpstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @oldpayTaxAmt = @oldtaxamt 
				select @oldgstTaxAmt = @oldpayTaxAmt
				select @oldVATgstTaxAmt = @oldgstTaxAmt 
				select @oldVATpstTaxAmt = 0
			end
			else
			begin
				select @oldpayTaxAmt = @oldtaxamt 
				select @oldgstTaxAmt = case @oldtaxrate when 0 then 0 else (@oldpayTaxAmt * @oldgstrate) / @oldtaxrate end	
				select @oldpstTaxAmt = @oldpayTaxAmt - @oldgstTaxAmt
				select @oldVATgstTaxAmt =  @oldgstTaxAmt
				select @oldVATpstTaxAmt =  @oldpstTaxAmt
			end		
			
			/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC Expense GL Acct
			then include the GST portion of tax in the Inventory Expense acct */
			if @olddbtGLAcct is null
			begin
				select @oldpayTaxAmt= @oldVATpstTaxAmt + @oldVATgstTaxAmt
				select @oldVATgstTaxAmt = 0
			end  
			else
			begin
				select @oldpayTaxAmt = @oldVATpstTaxAmt
			end
		end
		
		-- set update amounts
		select @totalcost = 0
		select @totalcost = @oldgrossamt - (case @netamtopt when 'Y' then isnull(@olddiscount,0) else 0 end)
		if @oldburdenyn = 'Y' select @totalcost = isnull(@totalcost,0) + isnull(@oldpayTaxAmt,0) +  isnull(@oldmiscamt,0) 
		select @stdtotalcost = @totalcost  -- set inventory total equal to posted total
		select @unitcost = 0, @stdunitcost = 0, @stdecm = isnull(@oldavgecm,@avgecm) /*'E'*/ -- #29558
		select @i = case @oldecm when 'C' then 100 when 'M' then 1000 else 1 end
		if @oldunits <> 0 select @unitcost = (@totalcost / @oldunits) * @i  -- unit cost per posted u/m
		select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end -- #29558
		if @oldstdunits <> 0 select @stdunitcost = (@stdtotalcost / @oldstdunits) * @i -- unit cost per std u/m --#29558
		
		if @oldcostopt = 3     -- standard unit cost method
		begin
			select @stdunitcost = @oldfixedunitcost, @stdecm = @oldfixedecm
			select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end
			select @stdtotalcost = (@stdunitcost * @oldstdunits) / @i    -- update IN using fixed unit cost
		end

		select @variance = @totalcost - @stdtotalcost  -- difference will only exist if using std cost method
		-- add old APIN entry
		if @totalcost <> 0 or @oldunits <> 0
		begin
			select @u1 = (-1 * @oldunits), @u2 = (-1 * @oldstdunits)
			select @c1 = (-1 * @totalcost), @c2 = (-1 * @stdtotalcost) -- reverse sign for old entries
			exec @rcode = bspAPLBValINInsert @apco, @mth, @batchid, @oldinco, @oldloc, @oldmatlgroup, @oldmatl,
			@batchseq, @apline, 0, @aptrans, @oldvendorgroup, @oldvendor, @oldapref, @oldtransdesc,
			@oldinvdate, @oldpo, @oldpoitem, @OldPOItemLine, @oldlinedesc, @oldglco, @oldglacct, @oldum, @u1, @unitcost,
			@oldecm, @c1, @oldstdum, @u2, @stdunitcost, @stdecm, @c2
		end

		-- add old APGL entries - will make intercompany entries if needed
		select @i = 0
OldINGL_loop:
		select @glamt = 0, @usetaxamt = 0
		-- Inventory
		if @i = 0
		begin
			select @glamt = (-1 * @stdtotalcost), @upglacct = @oldglacct
			if @oldtaxtype = 2 select @usetaxamt = (-1 * @oldtaxamt) -- handle use tax on first pass
		end

		-- Tax if Unit Cost is not burdened - #16892- do tax GL distribution for all non burdened cost options
		if @i = 1 and @oldburdenyn = 'N' /*and @oldcostopt <> 3 */ and @oldtaxamt <> 0
		begin
			exec @rcode = bspGLACfPostable @oldglco, @oldloctaxglacct, 'I', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Inventory Tax GL Account:' + 
				isnull(@oldloctaxglacct, '') + ':  ' + isnull(@errmsg,'')  
				goto APLB_error
			end
			select @glamt = (-1 * @oldpayTaxAmt /*@oldtaxamt*/), @upglacct = @oldloctaxglacct
		end

		-- Misc Amount if Unit Cost is not burdened - #16892 do miscamt GL distribution for all non burdened cost options
		if @i = 2 and @oldburdenyn = 'N' /*and @oldcostopt <> 3 */ and @oldmiscamt <> 0 and @oldmiscyn = 'Y'
		begin
			exec @rcode = bspGLACfPostable @oldglco, @oldlocmiscglacct, 'I', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Inventory Freight/Misc GL Account:' + 
				isnull(@oldlocmiscglacct, '') + ':  ' + isnull(@errmsg,'') 
				goto APLB_error
			end
			select @glamt = (-1 * @oldmiscamt), @upglacct = @oldlocmiscglacct
		end

		-- Cost Variance if using Fixed Unit Cost
		if @i = 3 and @oldcostopt = 3 and @variance <> 0
		begin
			exec @rcode = bspGLACfPostable @oldglco, @oldlocvarianceglacct, 'I', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Inventory Cost Variance GL Account:' + 
				isnull(@oldlocvarianceglacct, '') + ':  ' + isnull(@errmsg,'')  
				goto APLB_error
			end
			select @glamt = (-1 * @variance), @upglacct = @oldlocvarianceglacct
		end
		
		if @glamt <> 0 or @usetaxamt <> 0
		BEGIN
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @upglacct, @batchseq, @apline, 0,
			@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
			@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
			@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
			@oldmatlgroup, @oldmatl, @glamt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
			@usetaxamt, @oldtaxaccrualacct
		END
		
		select @i = @i + 1
		if @i < 4 goto OldINGL_loop

		/* post GST portion of tax to GST Payables - this is separate from burdened and unburdened GL expensing */
		if isnull(@oldvalueadd,'N')='Y' and @olddbtGLAcct is not null and isnull(@oldVATgstTaxAmt,0) <> 0
		begin
			select @glamt = (-1 * @oldVATgstTaxAmt)
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @oldglco, @olddbtGLAcct, @batchseq, @apline, 0,
			@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
			@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
			@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
			@oldmatlgroup, @oldmatl, @glamt, @apglco, @oldintercoarglacct, @oldintercoapglacct,
			@usetaxamt, @oldtaxaccrualacct
		end
	end  -- End 'Old' IN distributions

	-- 'New' IN distributions
	if (@LineType = 2 or (@LineType = 6 and @itemtype = 2)) and (@linetranstype = 'A' or @change = 'Y')
	begin
		/*Because tax amount is included with the gross if costs are burdened we need to calculate now how much of the total tax amount 
		should be added to gross (if burdened).  If the taxcode is not value added then include all the tax amount. 
		If it is a value added taxcode determine the PST and GST portions. The PST portion will be added to the gross if burdenend
		the GST should not unless the taxcode is set up as value added with GST BUT they are not tracking the GST portion in an
		ITC expense account then the GST portion should be treated as Sales and included in the tax amount added to gross for
		burdened costs. */
		/* Sales or Use Tax. */
		if isnull(@valueadd,'N') = 'N'
		begin
			select @payTaxAmt = @taxamt
		end
		/* Breakout and establish all VAT related tax amounts. */
		if isnull(@valueadd,'N') = 'Y'
		begin
			if @pstrate = 0
			begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @payTaxAmt = @taxamt 
				select @gstTaxAmt = @payTaxAmt
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = 0
			end
			else
			begin
				select @payTaxAmt = @taxamt 
				select @gstTaxAmt = case @taxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @taxrate end	
				select @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = @pstTaxAmt
			end
			/* if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
			for credit then send the GST portion of tax to the Expense acct */
			if @dbtGLAcct is null
			begin
				select @payTaxAmt= @VATpstTaxAmt + @VATgstTaxAmt
				select @VATgstTaxAmt = 0
			end  
			else
			begin
				select @payTaxAmt = @VATpstTaxAmt
			end
		end
		
		-- set update amounts
		select @totalcost = @grossamt - (case @netamtopt when 'Y' then @discount else 0 end)
		if @burdenyn = 'Y' select @totalcost = (@totalcost + isnull(@payTaxAmt,0) + isnull(@miscamt,0))
		select @stdtotalcost = @totalcost  -- set inventory total equal to posted total
		select @unitcost = 0, @stdunitcost = 0, @stdecm = @avgecm 
		select @i = case @ecm when 'C' then 100 when 'M' then 1000 else 1 end
		if @apunits <> 0 select @unitcost = (@totalcost / @apunits) * @i  -- unit cost per posted u/m
		select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end --#29558
		if @stdunits <> 0 select @stdunitcost = (@stdtotalcost / @stdunits) * @i -- unit cost per std u/m --#29558
		
		if @costopt = 3     -- standard cost method
		begin
			select @stdunitcost = @fixedunitcost, @stdecm = @fixedecm
			select @i = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end
			select @stdtotalcost = (@stdunitcost * @stdunits) / @i    -- update IN using fixed unit cost
		end
		
		select @variance = @totalcost - @stdtotalcost  -- difference will only exist if using std cost method

		-- add new APIN entry
		if @apunits <> 0 or @totalcost <> 0
		BEGIN
			exec @rcode = bspAPLBValINInsert @apco, @mth, @batchid, @inco, @loc, @matlgroup, @matl,
			@batchseq, @apline, 1, @aptrans, @vendorgroup, @vendor, @apref, @transdesc,
			@invdate, @po, @poitem, @POItemLine, @linedesc, @glco, @glacct, @um, @apunits, @unitcost, @ecm,
			@totalcost, @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost
		END
		
		-- add new APGL entries - will make intercompany entries if needed
		select @i = 0
NewINGL_loop:

		select @glamt = 0, @usetaxamt = 0
		-- Inventory
		if @i = 0
		begin
			select @glamt = @stdtotalcost, @upglacct = @glacct
			if @taxtype = 2 select @usetaxamt = @taxamt -- handle use tax on first pass
		end

		-- Tax if Unit Cost is not Burdened - #16892 do taxamt GL distribution for all non burdened cost options
		if @i = 1 and @burdenyn = 'N' /*and @costopt <> 3 */ and @taxamt <> 0
		begin
			exec @rcode = bspGLACfPostable @glco, @loctaxglacct, 'I', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Inventory Tax GL Account:' + isnull(@loctaxglacct, '') + ':  ' + isnull(@errmsg,'')  
				goto APLB_error
			end
			
			select @glamt = @payTaxAmt /*@taxamt*/, @upglacct = @loctaxglacct
		end
		
		-- Misc Amount if Unit Cost is not burdened - #16892 do miscamt GL distribution for all non burdened cost options 
		if @i = 2 and @burdenyn = 'N' /*and @oldcostopt <> 3 */ and @miscamt <> 0 and @miscyn = 'Y'
		begin
			exec @rcode = bspGLACfPostable @glco, @locmiscglacct, 'I', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Inventory Freight/Misc GL Account:' + 
				isnull(@locmiscglacct,'') + ':  ' + isnull(@errmsg,'')
				goto APLB_error
			end
			select @glamt = @miscamt, @upglacct = @locmiscglacct
		end

		-- Variance if using Fixed Unit Cost
		if @i = 3 and @costopt = 3 and @variance <> 0
		begin
			exec @rcode = bspGLACfPostable @glco, @locvarianceglacct, 'I', @errmsg output
			if @rcode <> 0
			begin
				select @errortext = @errorstart + '- Inventory Cost Variance GL Account:' + isnull(@locvarianceglacct, '') + ':  ' + isnull(@errmsg,'')  --#23061
				goto APLB_error
			end
			select @glamt = @variance, @upglacct = @locvarianceglacct
		end
		
		if @glamt <> 0 or @usetaxamt <> 0
		begin
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @upglacct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @glamt, @apglco, @intercoarglacct, @intercoapglacct,
			@usetaxamt, @taxaccrualacct
		end
		
		select @i = @i + 1
		if @i < 4 goto NewINGL_loop
		/* post GST portion of tax to GST Payables - this is separate from burdened and unburdened GL expensing */
		if isnull(@valueadd,'N')='Y' and @dbtGLAcct is not null and @VATgstTaxAmt <> 0
		begin
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @glco, @dbtGLAcct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @VATgstTaxAmt, @apglco, @intercoarglacct, @intercoapglacct,
			@usetaxamt, @taxaccrualacct
		end
	end  --'New' IN distributions
  
	-- Remaining 'Old' GL distributions
	IF @linetranstype = 'D' or @change = 'Y'
	BEGIN -- BEGIN Old GL distributions
		select @i = 0
OldGL_loop:
		select @glamt = 0
		-- Old Discount Offered (if Net to Subledgers)
		if @i = 0 and @netamtopt = 'Y' select @glamt = (-1 * @olddiscount), @upglacct = @olddiscoffglacct
		-- Posted Payable - include Misc if paid to Vendor, and Sales Tax
		if @i = 1
		BEGIN -- begin posted payables
			-- Sales Tax - retainage is not broken out in Payables posting
			if isnull(@oldvalueadd,'N') = 'N'
			BEGIN
				SELECT @glamt = (
									@oldgrossamt 
									+ (case @oldmiscyn when 'Y' then @oldmiscamt else 0 end)
									+ (case @oldtaxtype when 1 then @oldtaxamt else 0 end) 
									- @oldretainage
								)
				SELECT @upglacct = @oldapglacct
			END 
	
			-- VAT Tax - retainage tax may be broken out in Payables posting
			IF ISNULL(@oldvalueadd,'N') = 'Y' 
			BEGIN
				IF isnull(@APCOTaxBasisNetRetg, 'N') = 'N' OR @APHBCheckRevYN = 'Y' 
				BEGIN
					-- Tax basis is NOT net of retg so back out Retg GST from the tax amount
					SELECT @oldretgTaxAmt = @oldretainage * @oldtaxrate
					SELECT @glamt = (
										@oldgrossamt 
										+ (CASE @oldmiscyn WHEN 'Y' THEN @oldmiscamt ELSE 0 END)
										+ (@oldtaxamt - CASE @olddbtRetgGLAcct WHEN NULL THEN 0 ELSE @oldretgTaxAmt END)
										- @oldretainage
									 )
				END
				ELSE
				BEGIN

					-- Tax basis IS net of retg so tax amount is already minus the retg GST 
					SELECT @glamt = (
										@oldgrossamt 
										+ (case @oldmiscyn when 'Y' then @oldmiscamt else 0 end)
										+ @oldtaxamt 
										- @oldretainage
									)
				END
				SELECT @upglacct = @oldapglacct
			END
		END	-- end posted payables	

		-- Retainage Payable
		if @i = 2
		BEGIN -- retainage payables
			-- retainage does not include GST tax
			if isnull(@oldvalueadd,'N') = 'N' select @glamt = @oldretainage, @upglacct = @oldretglacct
			-- retainage includes GST tax
			if isnull(@oldvalueadd,'N') = 'Y'
			BEGIN
			IF @oldretainage <> 0
			BEGIN
				IF isnull(@APCOTaxBasisNetRetg, 'N') = 'N' 
				BEGIN
					-- Tax basis is NOT net of retainage.   
					SELECT @oldretgTaxAmt = @oldretainage * @oldtaxrate
					SELECT @glamt = (
										@oldretainage 
										+ CASE @olddbtRetgGLAcct WHEN NULL THEN 0 ELSE @oldretgTaxAmt END
									)
					SELECT @upglacct = @oldretglacct
				END
				ELSE 
				BEGIN
					-- Tax basis IS net of retainage so tax amount is already minus the retg PST/GST tax.
					SELECT @glamt = (
										@oldretainage 
									 )
					SELECT @upglacct = @oldretglacct
				END
			END 
			ELSE -- retainage = 0
			BEGIN
				-- If there is no retainage then taxamt is all open payables
				SELECT @glamt = (@oldretainage)
				SELECT @upglacct = @oldretglacct
			END
			END
		END -- retainage payables	
		
			-- #17041 add offsetting credit to the IN Misc GL acct for burdened costs when Inc(freight)='N' (miscyn=N).
			if @i = 3 and (@oldlinetype = 2 or (@oldlinetype = 6 and @olditemtype = 2)) and @oldburdenyn='Y' and @oldmiscyn='N'
			begin
				select @glamt = @oldmiscamt, @upglacct = @oldlocmiscglacct
			end

			-- add old APGL entry - no intercompany entries will be needed
			if @glamt <> 0
			BEGIN
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @apglco, @upglacct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
				@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @glamt, @apglco, @intercoarglacct, @intercoapglacct, 0, null
			END
			
			-- Retainage PST Tax is broken out into its own payables acct - TK-09243
			IF @i = 2 AND @oldcrdRetgPSTGLAcct IS NOT NULL AND @APCOTaxBasisNetRetg = 'Y' AND @oldretgPstTaxAmt <> 0 -- TK-09243
			BEGIN
				select @glamt = @oldretgPstTaxAmt,@upglacct = @oldcrdRetgPSTGLAcct
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @apglco, @upglacct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
				@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @glamt, @apglco, @intercoarglacct, @intercoapglacct, 0, null
			END
			
			-- CA Holdback GST is broken out into its own payables acct - #136500/#141846
			IF @i = 2 AND @oldcrdRetgGSTGLAcct IS NOT NULL AND @APCOTaxBasisNetRetg = 'Y' AND @oldretgGstTaxAmt <> 0 -- #133107
			begin
				select @glamt = (-1 * @oldretgGstTaxAmt),@upglacct = @oldcrdRetgGSTGLAcct
				exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @apglco, @upglacct, @batchseq, @apline, 0,
				@aptrans, @oldvendorgroup, @oldvendor, @oldsortname, @oldinvdate, @oldapref, @oldtransdesc,
				@oldlinetype, @olditemtype, @oldlinedesc, @oldjcco, @oldjob, @oldphasegroup, @oldphase,
				@oldjcctype, @oldemco, @oldequip, @oldemgroup, @oldcostcode, @oldemctype, @oldinco, @oldloc,
				@oldmatlgroup, @oldmatl, @glamt, @apglco, @intercoarglacct, @intercoapglacct, 0, null
			end


			select @i = @i + 1
			if @i < 4 goto OldGL_loop
		end

		 --Remaining 'New' GL distributions
		if @linetranstype = 'A' or @change = 'Y'
		begin
		select @i = 0

NewGL_loop:
		select @glamt = 0
		-- Discount entry needed in AP GL Co# if updating Net to subledgers
		if @i = 0 and @netamtopt = 'Y' select @glamt = @discount, @upglacct = @discoffglacct
		-- Posted Payables Type - include Misc (if paid to Vendor) and Tax either Sales or VAT
		if @i = 1 
		begin
			-- Sales Tax - retainage is not broken out in Payables posting
			if isnull(@valueadd,'N') = 'N'
			BEGIN
				SELECT @glamt = -1 * (
										@grossamt 
										+ (case @miscyn when 'Y' then @miscamt else 0 end)
										+ (case @taxtype when 1 then @taxamt else 0 end) 
										- @retainage
									 )
				SELECT @upglacct = @apglacct
			END 
	
			-- VAT Tax - retainage tax may be broken out in Payables posting
			IF ISNULL(@valueadd,'N') = 'Y' 
			BEGIN

				BEGIN
					IF isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @APHBCheckRevYN = 'Y' --#136500/#133107 Check Reversal
					BEGIN
						-- Tax basis is NOT net of retg so back out Retg tax amount
						SELECT  @retgTaxAmt = @retainage * @taxrate
						SELECT @glamt = -1 * (
												@grossamt 
												+ (CASE @miscyn WHEN 'Y' THEN @miscamt ELSE 0 END)
												+ (@taxamt - CASE @dbtRetgGLAcct WHEN NULL THEN 0 ELSE @retgTaxAmt END)
												- @retainage
											 )
					END
					ELSE
					BEGIN
						-- Tax basis IS net of retg so tax amount is already minus the retg tax 
						SELECT @glamt = -1 * (
												@grossamt 
												+ (case @miscyn when 'Y' then @miscamt else 0 end)
												+ @taxamt 
												- @retainage
											  )
					END
				END
				SELECT @upglacct = @apglacct
			END
		end
		
		-- Retainage Payable
		if @i = 2
		begin
			-- retainage does not include GST tax
			if isnull(@valueadd,'N') = 'N' select @glamt = (-1 * @retainage), @upglacct = @retglacct
			-- retainage includes GST tax
			IF isnull(@valueadd,'N') = 'Y'
			BEGIN
				IF @retainage <> 0
				BEGIN
					IF isnull(@APCOTaxBasisNetRetg, 'N') = 'N' 
					BEGIN
						-- Tax basis is NOT net of retg - backout tax amt.   
						SELECT  @retgTaxAmt = @retainage * @taxrate
						SELECT @glamt = -1 * (
												@retainage 
												+ CASE @dbtRetgGLAcct WHEN NULL THEN 0 ELSE @retgTaxAmt END
											 )
						SELECT @upglacct = @retglacct
					END
					ELSE 
					BEGIN
						-- Tax basis IS net of retg so tax amount is already minus the retg PST/GST tax.
						SELECT @glamt = -1 * (@retainage)
						SELECT @upglacct = @retglacct
					END
				END 
				ELSE -- retainage = 0
				BEGIN
					-- If there is no retainage then taxamt is all open payables
					SELECT @glamt = -1 * (@retainage)
					SELECT @upglacct = @retglacct
				END
			END	
		end
		
		-- #17041 add offsetting credit to the IN Misc GL acct for burdened costs when include freight = 'N'.
		if @i = 3 and (@LineType = 2 or (@LineType = 6 and @itemtype = 2)) and @burdenyn='Y' and @miscyn='N'
		begin
			select @glamt = -1 * @miscamt, @upglacct = @locmiscglacct
		end

		-- add new APGL entry - no intercompany entries will be needed
		if @glamt <> 0
		BEGIN
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @apglco, @upglacct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @glamt, @apglco, @intercoarglacct, @intercoapglacct, 0, null
		END

		-- Retainage PST Tax is broken out into its own payables acct - TK-09243
		IF @i = 2 AND @crdRetgPSTGLAcct IS NOT NULL AND @APCOTaxBasisNetRetg = 'Y' AND @retgPstTaxAmt <> 0 -- TK-09243
		BEGIN
			select @glamt = -1 * (@retgPstTaxAmt),@upglacct = @crdRetgPSTGLAcct
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @apglco, @upglacct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @glamt, @apglco, @intercoarglacct, @intercoapglacct, 0, null
		END

		-- Retainage GST Tax is broken out into its own payables acct - #136500/#141846
		IF @i = 2 AND @crdRetgGSTGLAcct IS NOT NULL AND @APCOTaxBasisNetRetg = 'Y' AND @retgGstTaxAmt <> 0 -- #133107
		begin
			select @glamt = -1 * (@retgGstTaxAmt),@upglacct = @crdRetgGSTGLAcct
			exec @rcode = bspAPLBValGLInsert @apco, @mth, @batchid, @apglco, @upglacct, @batchseq, @apline, 1,
			@aptrans, @vendorgroup, @vendor, @sortname, @invdate, @apref, @transdesc,
			@LineType, @itemtype, @linedesc, @jcco, @job, @phasegroup, @phase,
			@jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco, @loc,
			@matlgroup, @matl, @glamt, @apglco, @intercoarglacct, @intercoapglacct, 0, null
		end

		select @i = @i + 1
		if @i < 4 goto NewGL_loop
	end

goto APLB_loop  -- next Line
  
APLB_error:     -- record the validation error and skip to the next line
	exec @rcode = bspHQBEInsert @apco, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto APLB_loop
  
bspexit:
	if @openAPLB = 1
	begin
		close bcAPLB
		deallocate bcAPLB
	end

	select @errmsg = isnull(@errmsg,'') + char(13) + char(10) --+ '[bspAPLBVal]'
	return @rcode
GO


GRANT EXECUTE ON  [dbo].[bspAPLBVal] TO [public]
GO
