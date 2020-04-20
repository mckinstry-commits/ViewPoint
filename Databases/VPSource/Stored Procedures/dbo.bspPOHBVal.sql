
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[bspPOHBVal]
/***********************************************************
* CREATED BY: SE   4/28/97
* MODIFIED By : kb 6/18/98
*		jre 6/7/99 - reformatted
*		GG 10/30/99 - cleanup - added validation
*		LM fixed issue #5792, interfacing a LS u/m on a PO Item
*		GR fixed issue #6507
*		GR 08/18/00 - corrected the UM Conversion factor for Inventory type items issue#10098
*		TV 03/05/01 - Validation for EM Component Codes
*		TV 05/01/01 -Was not backing out old transaction when it was changed. issue#12199
*		bc 06/12/01 - validate PO Status change.  issue 13733
*		GG 06/12/01 - fix ECM validation, must be null if um = LS
*		DANF 0814/01 - Correct Changed Item not creating new entries.
*		TV 08/16/01 - was trying back out old IN when old item was not IN
*		kb 9/18/1 - issue #14622
*		SR 06/25/02 - Issue #17715 - don't allow a new item to be added to a closed PO
*		DANF 09/05/02 - 17738 - Added Phase Group to bspJobTypeVal
*		MV 12/06/02 - #18808 - validate InvUnits and InvCosts = 0 for deleted items
*			and validate Status for deleted items
*		mv 02/27/03 - #19934 - if POIT changing from standing to regular PO, back out received units/costs
*		GF 03/31/03 - #20794 - set taxphase and taxcosttype to null before executing taxcode validation
*		GF 05/02/03 - #20794 - moved set for taxphase and costtype to before checking tax code is not null
*		GF 05/05/03 - #20794 - found that when tax code is removed from existing item, orig tax was set to 0.
*		GF 05/06/03 - #20794 - more. if not tax for existing item and tax then added to item the
*			orig tax was not being calculated. Hope this is last problem for this issue.
*		MV 05/22/04 - #19934 - rej 1 fix
*		DANF 07/16/2003  #21803 Do not allow change in Unit cost if Expensing PO's and units have been received.
*		MV 09/11/03 - #22433 - added parens to fix select statment logic for issue 21803 
*		MV 11/03/03 - #22843 - back out received forin bJCCD	  		
*		RT 12/04/03 - #23061 - use isnulls when concatenating message strings, added with (nolock)s.
*		MV 01/22/04 - #23557 - added 'and POItem=@poitem' to bPOIB update statement for issue 20794
*		MV 03/03/04 - #18769 - Pay Category and PayType validation / performance enhancements
*		ES 03/17/04 - #23730 - Per QA do not allow delete on items where there is an unapproved invoice (Same as SL)
*		MV 06/15/04 - #24810 - validate unique PO # in other open batches.  For imports.
*		MV 08/26/04 - #25417 - move Pay Type/PayCategory validation to bPOIT section.
*		MV 10/01/04 - #25656 - isnull wrap GLAcct for validation
*		MV 10/08/04 - #25606 - use POIT TotUnits/Cost,RemUnits/Cost to back out TotCmtd/RemCmtd from JCCD when PO changes
*		MV 04/11/05 - #28395 - when backing out totcmtd/remcmtd when tax is redirected take totunits * jcumconv
*		MV 10/06/05 = #30001 - break out cmtdremunits/cost/tax from current/orig for update to JCCD
*		MV 11/07/05 - #30290 - isnull wrap taxrate when item has no tax to prevent null taxamount
*		MV 11/14/05 - #30299 - changed @factor to smallint 
*		MV 12/21/05 - #119692 - use origecm from POIB to calc cmtdcost for update to JCCD
*		MV 06/01/06 - #121533 - use poitinvcost/units (not recvd) to calc RemainCmtdCost/Units for JCCD on changed PO. 
*		DC 04/01/08 - #127019 - Co input on grid does not validate, F4 or F5
*		DC 07/09/08	- #122903 - Allow pay types that are no assigned to any pay category
*		DC 8/4/08 - #128925 - PO International Sales Tax Modifications
*		DC 09/29/08 - #120803 - JCCD committed cost not updated w/ tax rate change
*		MV 12/11/08	- #131405 - when backing out JCCD remaining committed tax for changed or deleted items, if POIT.RemCost is 0 
*			hen do not add POIT.JCCmtdTax to RemCmtdCost (causes a negative balance in JCCD RemCmtdCost)
*		DC 03/20/09 - #132748 - PO Entry causing JC committed cost problem
*		TJL 04/06/09 - Issue #131504, JC Committed is incorrect when using GST TaxCode by itself.
*		TJL 04/06/09 - Issue #131500, When trans added back for Change, JC Committed not recognizing GST when reversing old value
*		DC 09/03/09 - #134351 - Adding SL with change order back into batch produces a JC Distribution
*		DC 09/15/09 - #135560 - Cmtd Cost wrong when editing existing PO
*		DC 09/28/09 - #122288 - Store tax rate in POIT
*				GF 09/28/2010 - issue #141349 better error messages (with PO)
*		MH 11/22/10 - #131640 - Changes to support SM integration.
*		ECV 01/13/11 -#131640 - Add validation of SMCo and SMWorkOrder to Batch Validation.
*		JVH 3/17/11 - #131640 - Changed POHB to allow for null vendors. Added check to make sure the vendor is supplied by time of validaiton.
*								This allows for SM to create a PO batch without knowing the vendor up front.
*		GF 7/27/2011 - TK-07144 changed to varchar(30)
*		GF 08/09/2011 - TK-07440 TK-07438 TK-07439
*		GF 10/20/2011 TK-09213 GL Sub Type for S - Service
*		DAN SO 12/15/2011 - TK-10950 - If PhaseGroup IS NULL for Item Type 1 (job) - get value from HQCO - update bPOIB
*       TRL 05/16/2012 - TK-14606 - Fixed changes that where committed by accident.
*		DAN SO 05/17/2012 - TK-14606 - Fixed error - @SMWorkOrder to @WorkOrder (vspSMWorkCompletedWorkOrderVal)
*		LG 08/23/12 - TK-16773 - Validated TaxCode redirect for SM Job Work Orders
*		ECV 01/09/13 - TK-20691 - Validate the GLCo and GLAccount for SM Job Work Order lines against values returned by Work Order Scope validation
*		LDG 02/08/13 - TFS-39356 Fixed validating Tax Phase and Tax Cost Type for linetype 6. Now uses correct SM Company, and SM Job when validating a SM Work Order Job. 
*		AJW 3/11/13 - TFS - 43398 Verify no PMPOCO's exist when deleting
*		SKA 04/02/13 - TFS-Bug-44151 Added logic to say when it is okay to post to a closed work order
*		JVH 4/29/13 - TFS-44860 Updated check to see if work completed is part of an invoice
*
* USAGE:
* Validates each entry in bPOHB and bPOIB for a selected batch - must be called
* prior to posting the batch.
*
* After initial Batch and PO checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors), bPOIA (PO JC Detail Audit), and bPOII(Inventory dist)
* entries are deleted.
*
* Creates a cursor on bPOHB to validate each entry individually, then a cursor on bPOIB for
* each item for the header record.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Job distributions added to bPOIA
* Inventory distributions added to bPOII
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*   @co        PO Company
*   @mth       Month of batch
*   @batchid   Batch ID to validate
*   @source    Source of data
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(255) output
as
set nocount on
 
declare @rcode int, @errortext varchar(255), @tablename char(20), @inuseby bVPUserName,
	@status tinyint, @opencursorPOHB tinyint, @opencursorPOIB tinyint, @acctype char(1),
	@hqmatl varchar(1), @oldhqmatl varchar(1), @itemcount int,@factor smallint,
	@deletecount int, @errorstart varchar(50), @cmtdunits bUnits, @cmtdcost bDollar,
	@pohbmth bMonth, @pohbbatchid bBatchID,@currentunits bUnits, @currenttax bDollar,
	@cmtdremunits bUnits, @cmtdremcost bDollar, @remunits bUnits,@remtax bDollar

-- Header declares
declare @transtype char(1), @po varchar(30), @seq int, @oldstdum bUM, @oldjcum bUM, @oldstocked char(1),
	@vendorgroup bGroup, @vendor bVendor, @jcum bUM, @jcumconv bUnitCost,  @umconv bUnitCost,
	@stdum bUM, @stdumconv bUnitCost, @oldvendorgroup bGroup, @oldjcumconv bUnitCost, @oldumconv bUnitCost, @inumconv bUnitCost,
	@oldvendor bVendor, @taxphase bPhase, @taxct bJCCType, @oldtaxphase bPhase, @oldtaxct bJCCType,
	@oldtaxjcum bUM, @taxjcum bUM, @holdcode bHoldCode, @active bYN, @payterms bPayTerms, @compgroup varchar(10)

/*item declares*/
declare @poitem bItem, @itemtranstype char(1), @itemtype tinyint,  @matlgroup bGroup, @material bMatl,
	@vendmatid varchar(30), @description bItemDesc, @um bUM, @recyn bYN, @posttoco bCompany,
	@loc bLoc, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @equip bEquip,
	@emgroup bGroup, @costcode bCostCode, @emctype bEMCType, @component bEquip, @comptype varchar(25),
	@wo bWO, @woitem bItem, @glco bCompany, @glacct bGLAcct, @taxgroup bGroup,
	@taxcode bTaxCode,@taxtype tinyint,  @origunits bUnits,
	@origunitcost bUnitCost, @origecm bECM, @origcost bDollar, @origtax bDollar, @poiborigtax bDollar,
	@olditemtype tinyint, @oldmatlgroup bGroup, @oldmaterial bMatl, @oldvendmatid varchar(30),
	@olddesc bItemDesc, @oldum bUM, @oldrecyn bYN, @oldposttoco bCompany,
	@oldloc bLoc, @oldjob bJob, @oldphasegroup bGroup, @oldphase bPhase,
	@oldjcctype bJCCType, @oldequip bEquip, @oldemgroup bGroup, @oldcostcode bCostCode, @oldemctype bEMCType,
	@oldwo bWO, @oldwoitem bItem, @oldcomponent bEquip, @oldglco bCompany, @oldglacct bGLAcct,
	@oldtaxgroup bGroup, @oldtaxcode bTaxCode, @oldtaxtype tinyint, @oldorigunits bUnits, @oldorigunitcost bUnitCost,
	@oldorigecm bECM, @oldorigcost bDollar, @oldorigtax bDollar, @reqnum varchar(20),
	@oldreqnum varchar(20), @poitreqnum varchar(20), @paytype tinyint, @paycategory integer

declare @activity tinyint, @poititemtype tinyint, @poitmatlgroup bGroup, @poitmaterial bMatl, @poitum bUM,
	@poitposttoco bCompany, @poitloc bLoc, @poitjob bJob, @poitphasegroup bGroup, @poitphase bPhase,
	@poitjcctype bJCCType, @poitequip bEquip, @poitcomponent bEquip, @poitemgroup bGroup, @poitcostcode bCostCode,
	@poitemctype bEMCType, @poitwo bWO, @poitwoitem bItem, @poitglco bCompany, @poitglacct bGLAcct,
	@poittaxgroup bGroup, @poittaxcode bTaxCode, @poitorigunits bUnits, @poitorigunitcost bUnitCost,
	@poitorigecm bECM, @poitorigcost bDollar, @poitorigtax bDollar, @poitcurunits bUnits,
	@poitcurunitcost bUnitCost, @poitcurecm bECM, @poitcurcost bDollar, @poitrecvdunits bUnits, @poitrecvdcost bDollar,
	@poitinvunits bUnits, @poitinvcost bDollar, @taxrate bRate, @reqdate bDate, @dateposted bDate, @poitinvtax bDollar,
	@poittotunits bUnits,@poittotcost bDollar, @poitremunits bUnits,@poitremcost bDollar, @poittottax bDollar,
	@poitremtax bDollar

--DC #128925
declare @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct, 
		@valueadd char(1), @gsttaxamt bDollar, @tempgsttaxamt bDollar, @psttaxamt bDollar,  
		@oldvalueadd char(1), @oldtaxrate bRate, @oldgstrate bRate,
		@oldHQTXdebtGLAcct bGLAcct, @oldreqdate bDate,
		@oldjccmtdtax bDollar,  --DC #120803
		@jccmtdtax bDollar, --DC #134351
		@oldjcremcmtdtax bDollar, -- #131504
		@jcremcmtdtax bDollar, --DC #122288
		@smcostaccount bGLAcct, @smglgo bCompany
	
-- Variables for SM #131640
DECLARE @smco bCompany, @smworkorder int, @smscope int, @smphasegroup bGroup, @smphase bPhase, @smjccosttype bJCCType,
				@oldsmco bCompany, @oldsmworkorder int, @oldsmscope int, @oldsmphasegroup bGroup, @oldsmphase bPhase, @oldsmjccosttype bJCCType, @smjob bJob, @oldsmjob bJob, @smjcco bCompany, @oldsmjcco bCompany

-- Variables for TFS Bug 44151
Declare @smworkorderclosedok bYN

---- TK
DECLARE @POITKeyID BIGINT, @LineItemsExist CHAR(1)

-- TK-10950 -- PhaseGroup Error variable
DECLARE @PGError tinyint	


select @rcode = 0, @dateposted = convert(varchar(11),getdate())

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'POHB', @errmsg output, @status output
if @rcode <> 0
	BEGIN
	select @errmsg = @errmsg, @rcode = 1
	GoTo bspexit
	END
if @status < 0 or @status > 3
	BEGIN
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	GoTo bspexit
	END
/* set HQ Batch status to 1 (validation in progress) */
Update bHQBC Set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	BEGIN
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	GoTo bspexit
	END

/* clear HQ Batch Errors */
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid

/* clear JC Distributions Audit */
delete bPOIA where POCo = @co and Mth = @mth and BatchId = @batchid

/* clear Inventory Distributions Audit */
delete bPOII where POCo = @co and Mth = @mth and BatchId = @batchid

/* declare cursor on PO Header Batch for validation */
declare bcPOHB cursor LOCAL FAST_FORWARD for
select BatchSeq, BatchTransType, PO, VendorGroup, Vendor, Status, HoldCode,
  PayTerms, CompGroup, OldVendorGroup, OldVendor
from bPOHB WITH (NOLOCK)
where Co = @co and Mth = @mth and BatchId = @batchid
 
open bcPOHB
select @opencursorPOHB = 1
 
POHB_loop:  -- loop through each entry in the batch
 
fetch next from bcPOHB into @seq, @transtype, @po, @vendorgroup, @vendor, @status, @holdcode,
	@payterms, @compgroup, @oldvendorgroup, @oldvendor

if @@fetch_status <> 0 goto POHB_end

----#141349
select @errorstart = 'PO: ' + ISNULL(@po,'') + ' Seq#' + convert(varchar(6),@seq)
 
--validate Transaction Type
if @transtype not in ('A','C','D')
	BEGIN
	select @errortext = @errorstart + ' - Invalid transaction type, must be ''A'',''C'', or ''D''.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto POHB_loop
	END
 
if @transtype = 'A'     -- validation specific to new POs
	BEGIN
	-- check for uniqueness among existing POs 
	if exists (select 1 from bPOHD WITH (NOLOCK) where POCo=@co and PO=@po)
		BEGIN
		select @errortext = @errorstart + ' - PO number already exists!'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- check for uniqueness in current batch
	if exists (select 1 from bPOHB WITH (NOLOCK) where Co=@co and Mth=@mth and BatchId=@batchid
		and  PO = @po and BatchSeq <> @seq)
		BEGIN
		select @errortext = @errorstart + ' - PO number already exists in this batch!'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- check for uniqueness in other open batches for imports - #24810
	select @pohbmth = Mth, @pohbbatchid = BatchId from bPOHB WITH (NOLOCK) 
	where Co=@co and (Mth<> @mth or BatchId<>@batchid)
		and  PO = @po
	if @@rowcount <> 0
		BEGIN
		select @errortext = @errorstart + ' - PO number already exists in Month: ' + convert(varchar(8), @pohbmth, 1) +
			' BatchId: ' + convert(varchar(10),@pohbbatchid)
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- all Items must be 'adds'
	if exists(select 1 from bPOIB WITH (NOLOCK) where Co = @co and Mth = @mth and BatchId = @batchid
		and BatchSeq = @seq and BatchTransType <> 'A')
		BEGIN
		select @errortext = @errorstart + ' - All Items on a new PO must be ''adds''!'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- validate Status
	if @status <> 0     -- open
		BEGIN
		select @errortext = @errorstart + ' - Status on new POs must be ''open''!'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	END 
 
if @transtype in ('A','C')    -- validation for Add and Change of PO Header
	BEGIN
	-- check for uniqueness in other open batches for imports - #24810
    select @pohbmth = Mth, @pohbbatchid = BatchId from bPOHB WITH (NOLOCK) where Co=@co and (Mth<> @mth or BatchId<>@batchid)
          and  PO = @po
	if @@rowcount <> 0
		BEGIN
		select @errortext = @errorstart + ' - PO number already exists in Month: ' + convert(varchar(8), @pohbmth, 1) +
			' BatchId: ' + convert(varchar(10),@pohbbatchid)
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- validate Vendor Group
	if not exists(select 1 from bHQGP WITH (NOLOCK) where Grp = @vendorgroup)
		BEGIN
		select @errortext = @errorstart + ' - Invalid Vendor Group: ' + convert(varchar(3),@vendorgroup)
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- validate Vendor
	IF @vendor IS NULL
	BEGIN
		SELECT @errortext = @errorstart + ' - Vendor must be supplied.'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 GOTO bspexit
		GOTO POHB_loop
	END
	select @active = ActiveYN
	from bAPVM WITH (NOLOCK)
	where VendorGroup = @vendorgroup and Vendor = @vendor
	if @@rowcount = 0
		BEGIN
		select @errortext = @errorstart + ' - Invalid Vendor: ' + convert(varchar(6),@vendor)
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	if @active = 'N'
		BEGIN
		select @errortext = @errorstart + ' - Inactive Vendor: ' + convert(varchar(6),@vendor)
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
	-- validate Hold Code - may be null
	if @holdcode is not null
		BEGIN
		if not exists(select 1 from bHQHC WITH (NOLOCK) where HoldCode = @holdcode)
		  BEGIN
		  select @errortext = @errorstart + ' - Invalid Hold Code ' + @holdcode
		  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		  if @rcode <> 0 goto bspexit
		  goto POHB_loop
		  END
		END
	-- validate Pay Terms - may be null
	if @payterms is not null
		BEGIN
		if not exists(select 1 from bHQPT WITH (NOLOCK) where PayTerms = @payterms)
			BEGIN
			select @errortext = @errorstart + ' - Invalid Payment Terms ' + @payterms
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POHB_loop
			END
		END
	-- validate Compliance Group - may be null
	if @compgroup is not null
		BEGIN
		if not exists(select 1 from bHQCG WITH (NOLOCK) where CompGroup = @compgroup)
			BEGIN
			select @errortext = @errorstart + ' - Invalid Compliance Group ' + @compgroup
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POHB_loop
			END
		END
	END -- validation for Add and Change of PO Header
 
if @transtype = 'C'     -- validation specific for change of PO Header
    BEGIN
    -- validate Status changes.  issue # 13733
    if exists(select 1
              from bPOIT WITH (NOLOCK)
              where POCo = @co and PO = @po and @status = 1 and UM = 'LS' and RecvdCost <> InvCost)
		BEGIN
        select @errortext = @errorstart + 'Completed POs require Received and Invoiced costs to be equal on all Lump Sum Items '
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        goto POHB_loop
		END

    if exists(select 1
              from bPOIT WITH (NOLOCK)
              where POCo = @co and PO = @po and @status = 1 and UM <> 'LS' and RecvdUnits <> InvUnits)
		BEGIN
        select @errortext = @errorstart + 'Completed POs require Received and Invoiced units to be equal on all unit based Items '
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        goto POHB_loop
        END
    END
 
if @transtype = 'D'     -- validation specific for Delete of PO Header
	BEGIN
    -- all Items in batch must be 'deletes'
    if exists(select 1 from bPOIB WITH (NOLOCK) where Co = @co and Mth = @mth and BatchId = @batchid
          and BatchSeq = @seq and BatchTransType <> 'D')
		BEGIN
		select @errortext = @errorstart + ' - Cannot delete a PO with ''add'' or ''change'' Items! '
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POHB_loop
		END
		-- make sure all Items have been added to batch
		select @itemcount = count(*) from bPOIT WITH (NOLOCK) where POCo = @co and PO = @po
		select @deletecount = count(*)
		from bPOIB WITH (NOLOCK)
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'D'
		if @itemcount <> @deletecount
			BEGIN
			select @errortext = @errorstart + ' - Cannot delete a PO unless all of its Items have been included in the batch!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POHB_loop
			END
		-- make sure no uninterfaced change orders exists to prevent FK error on delete
		if exists(select 1 from vPMPOCO where POCo = @co and PO = @po)
			begin
			select @errortext = @errorstart + ' - Cannot delete PO / PM PO Change Order exists!'
			+ ' PMCo:'+ dbo.vfToString(PMCo)+ ' Project:'+  dbo.vfToString(Project) + ' CO#'+dbo.vfToString(POCONum)
			from vPMPOCO where POCo = @co and PO = @po
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POHB_loop	
			end
	END
 
-- need to make sure tax is 0 if no tax code #20794
update bPOIB 
set OrigTax = 0, 
	JCCmtdTax = 0, JCRemCmtdTax = 0, TaxRate = 0, GSTRate = 0
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and TaxCode is null

-- create a cursor to validate all the Items for this PO
declare bcPOIB cursor LOCAL FAST_FORWARD for select POItem, BatchTransType,ItemType, MatlGroup, Material,
	Description, UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, ReqDate,
	Equip, CompType, Component, EMGroup, CostCode, EMCType, WO, WOItem, GLCo, GLAcct,
	TaxGroup, TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax,
	PayType, PayCategory,
	SMCo, SMWorkOrder, SMScope,SMPhaseGroup,SMPhase,SMJCCostType,
	OldItemType, OldMatlGroup, OldMaterial, OldDesc, OldUM, OldRecvYN, OldPostToCo,
	OldLoc, OldJob, OldPhaseGroup, OldPhase, OldJCCType,
	OldEquip, OldComponent, OldEMGroup, OldCostCode, OldEMCType, OldWO, OldWOItem,
	OldGLCo, OldGLAcct, OldTaxGroup, OldTaxCode, OldTaxType,
	OldOrigUnits, OldOrigUnitCost, OldOrigECM, OldOrigCost, OldOrigTax, RequisitionNum,
	OldRequisitionNum,
	OldReqDate,  --DC #128925
	OldJCCmtdTax,  --DC #120803
	OldJCRemCmtdTax, -- #131500
	JCCmtdTax, --DC #134351
	TaxRate, GSTRate, OldTaxRate, OldGSTRate, JCRemCmtdTax,  --DC #122288
	OldSMCo, OldSMWorkOrder, OldScope,OldSMPhaseGroup,OldSMPhase,OldSMJCCostType
from bPOIB WITH (NOLOCK)
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
 
open bcPOIB
select @opencursorPOIB = 1
	
POIB_loop:     -- get next Item
	fetch next from bcPOIB into @poitem, @itemtranstype, @itemtype, @matlgroup, @material,
		@description, @um, @recyn, @posttoco, @loc, @job, @phasegroup, @phase, @jcctype, @reqdate,
		@equip, @comptype, @component, @emgroup, @costcode, @emctype, @wo, @woitem, @glco, @glacct,
		@taxgroup, @taxcode, @taxtype, @origunits, @origunitcost, @origecm, @origcost, @poiborigtax,
		@paytype, @paycategory,
		@smco, @smworkorder, @smscope,	@smphasegroup,@smphase,@smjccosttype,
		@olditemtype, @oldmatlgroup, @oldmaterial, @olddesc, @oldum, @oldrecyn, @oldposttoco,
		@oldloc, @oldjob, @oldphasegroup, @oldphase, @oldjcctype,
		@oldequip, @oldcomponent, @oldemgroup, @oldcostcode, @oldemctype, @oldwo, @oldwoitem,
		@oldglco, @oldglacct, @oldtaxgroup, @oldtaxcode, @oldtaxtype,
		@oldorigunits, @oldorigunitcost, @oldorigecm, @oldorigcost, @oldorigtax, @reqnum,
		@oldreqnum,
		@oldreqdate,  --DC #128925
		@oldjccmtdtax,  --DC #120803
		@oldjcremcmtdtax, -- #131500
		@jccmtdtax,  --DC #134351
		@taxrate, @gstrate, @oldtaxrate, @oldgstrate, @jcremcmtdtax,  --DC #122288
		@oldsmco, @oldsmworkorder, @oldsmscope,@oldsmphasegroup,@oldsmphase,@oldsmjccosttype
	if @@fetch_status <> 0 goto POIB_end

	----------------------
	-- TK-10950 - START --
	-----------------------------------------------------------------------------------
	-- IF A JOB TYPE DOES NOT HAVE A PhaseGroup - ATTEMPT TO GET IT AND UPDATE bPOIB --
	-----------------------------------------------------------------------------------
	
	-- CHECK FOR JOB TYPE --
	IF @itemtype = 1 or @itemtype = 6
		BEGIN
			SET @PGError = 0
		
			-- CHECK FOR PhaseGroup --
			IF @phasegroup IS NULL
				BEGIN
					-- GET PhaseGroup --
					SELECT @phasegroup = PhaseGroup FROM bHQCO WHERE HQCo = @posttoco
					
					IF @@ROWCOUNT <> 1
						BEGIN
							SET @errortext = @errorstart + '- PhaseGroup for HQ Company ' + isnull(convert(varchar(3),@posttoco),'') + ' not found!'
							SET @PGError = 1
						END	
						
					ELSE
						BEGIN
							-- SET PhaseGroup IN bPOIB --
							UPDATE bPOIB 
							   SET PhaseGroup = @phasegroup
							 WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq 
							   AND POItem = @poitem
													
							IF @@ROWCOUNT <> 1
								BEGIN
									SET @errortext = @errorstart + '- not able to set PhaseGroup in bPOIB!'
									SET @PGError = 1
								END
						END
						
					-- CHECK ERROR --
					IF @PGError = 1
						BEGIN
							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
							if @rcode <> 0 goto bspexit
							goto POIB_loop
						END
				END
		END
	--------------------
	-- TK-10950 - END --
	--------------------

	--DC #132748
	--Reset tax varibles
	select @origtax = 0, @currenttax = 0, @gsttaxamt = 0, @psttaxamt = 0	
	----#141349
	select @errorstart = 'PO: ' + ISNULL(@po,'') + ' Seq#: ' + convert(varchar(6),@seq) + ' Item: ' + convert(varchar(6),@poitem) + ' '

	-- validate transaction type
	if @itemtranstype not in ('A','C','D')
		BEGIN
		select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto POIB_loop
		END
 
	if @itemtranstype = 'A'     -- validation specific to 'add' Items
		BEGIN
		if exists(select 1 from bPOIT WITH (NOLOCK) where POCo = @co and PO = @po and POItem = @poitem)
			BEGIN
			select @errortext = @errorstart + ' -  Item number already exists.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
		--Issue #17715
		if @status=2
			BEGIN
		 	select @errortext = @errorstart + ' -  Cannot add a new item to a closed PO.' 
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            goto POIB_loop
			END
		END
 
	-- DC  #128925
	-- need to calculate orig tax for existing item when tax code was null now not null
	if isnull(@taxcode,'') <> ''			
		BEGIN
		-- if @reqdate is null use today's date
		if isnull(@reqdate,'') = '' select @reqdate = @dateposted
		-- get Tax Rate
		select @pstrate = 0  --DC #122288

		--DC #122288
		exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @reqdate, @valueadd output, NULL, NULL, NULL, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output
			
		select @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)
				
		/*exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @reqdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
			null, null, @HQTXdebtGLAcct output, null, null,	null, @errmsg output*/

		if @rcode <> 0
			BEGIN
			select @errortext = @errorstart + ' - ' + @errmsg
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

		if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
			BEGIN
			-- We have an Intl VAT code being used as a Single Level Code
			if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
				BEGIN
				select @gstrate = @taxrate
				END
			END

		select @origtax = @origcost * @taxrate		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
		select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@origtax * @gstrate) / @taxrate else 0 end end			--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
		select @psttaxamt = case @valueadd when 'Y' then @origtax - @gsttaxamt else 0 end			--PST Tax Amount.  (Rounding errors to PST)

		END /* tax code validation*/
 			
	-- #21803 Do not allow change in Unit cost if Expensing PO's and units have been received.
	if 	@itemtranstype = 'C' and @um <> 'LS' and
		-- see if the Orig Unit cost has been changed
		(@origunitcost <> @oldorigunitcost) 
		BEGIN	
		-- Check to see if company is expensing Receipts
		if exists (select 1 from bPOCO WITH (NOLOCK)
				where POCo = @co and ReceiptUpdate = 'Y') and
				-- check the PO Item to see if it has been marked for receiving and units have been received
				exists (select 1 from bPOIT WITH (NOLOCK)
					where POCo = @co and PO = @po and
						POItem = @poitem and RecvYN = 'Y' and
						(RecvdUnits <> 0 or RecvdCost<>0))	--22433
			BEGIN
			-- check PO Expense Receipt Interface level
			if 	(@itemtype =1 and
				exists( select 1 from bPOCO WITH (NOLOCK)
						where POCo = @co and RecJCInterfacelvl > 0 )) or
				(@itemtype =2 and
				exists( select 1 from bPOCO WITH (NOLOCK)
						where POCo = @co and RecINInterfacelvl > 0 )) or
				(@itemtype =3 and
				exists( select 1 from bPOCO WITH (NOLOCK)
						where POCo = @co and GLRecExpInterfacelvl > 0 )) or
				((@itemtype =4 or @itemtype=5) and
				exists( select 1 from bPOCO WITH (NOLOCK)
						where POCo = @co and RecEMInterfacelvl > 0 ))
				BEGIN
				select @errortext = @errorstart + ' -  Original Unit Cost cannot be changed when expensing receipts and units have been received against this PO Item.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END -- End Error message
			END -- End if expensing reciepts

		-- Check to see if company is Not expensing Receipts
		if exists (select 1 from bPOCO WITH (NOLOCK)
			where POCo = @co and ReceiptUpdate = 'N') and
			-- check the PO Item to see if it has been marked for receiving and units have been received
			exists (select 1 from bPOIT WITH (NOLOCK)
				where POCo = @co and PO = @po and
				POItem = @poitem and RecvYN = 'Y' and
				(RecvdUnits <> 0 or RecvdCost<>0))	--22433
			BEGIN
			-- If a Job Costed Item do not allow change in unit cost
			if @itemtype =1 
				BEGIN
				select @errortext = @errorstart + ' -  Original Unit Cost cannot be changed when expensing receipts and units have been received against this PO Item.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			END -- END is Not expensing Receipts
		END
 
	if @itemtranstype in ('C','D')      -- validation specific to both 'change' and 'delete' Items
		BEGIN
		-- get current values from Item
		select @poititemtype = ItemType, @poitmatlgroup = MatlGroup, @poitmaterial = Material,
			@poitum = UM, @poitposttoco = PostToCo, @poitloc = Loc, @poitjob = Job, @poitphasegroup = PhaseGroup,
			@poitphase = Phase, @poitjcctype = JCCType, @poitequip = Equip, @poitcomponent = Component,
			@poitemgroup = EMGroup, @poitcostcode = CostCode, @poitemctype = EMCType, @poitwo = WO,
			@poitwoitem = WOItem, @poitglco = GLCo, @poitglacct = GLAcct, @poittaxgroup = TaxGroup,
			@poittaxcode = TaxCode, @poitorigunits = OrigUnits, @poitorigunitcost = OrigUnitCost,
			@poitorigecm = OrigECM, @poitorigcost = OrigCost, @poitorigtax = OrigTax, @poitcurunits = CurUnits,
			@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM, @poitcurcost = CurCost, @poitrecvdunits = RecvdUnits,
			@poitrecvdcost = RecvdCost, @poitinvunits = InvUnits, @poitinvcost = InvCost,@poitreqnum = RequisitionNum,
			@poitinvtax = InvTax, @poittotunits=TotalUnits, @poittotcost=TotalCost, @poitremunits=RemUnits,
			@poitremcost=RemCost, @poittottax=TotalTax, @poitremtax=RemTax,
		
			---- TK-07440 TK-07438 TK-07439
			@POITKeyID = KeyID
		from bPOIT WITH (NOLOCK)
		where POCo = @co and PO = @po and POItem = @poitem
		if @@rowcount = 0
			BEGIN
			select @errortext = @errorstart + ' - Invalid Item!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
			
        ---- TK-07440 TK-07438 TK-07439
        IF @itemtranstype = 'C'
			BEGIN
			SET @LineItemsExist = 'N'
			IF EXISTS(SELECT 1 FROM dbo.vPOItemLine WHERE POITKeyID = @POITKeyID AND POItemLine = 1)
				BEGIN
				SELECT  @poitcurunits = CurUnits, @poitcurcost = CurCost, @poitrecvdunits = RecvdUnits,
						@poitrecvdcost = RecvdCost, @poitinvunits = InvUnits, @poitinvcost = InvCost,
						@poitinvtax = InvTax, @poittotunits=TotalUnits, @poittotcost=TotalCost,
						@poitremunits=RemUnits, @poitremcost=RemCost, @poittottax=TotalTax,
						@poitremtax=RemTax
				FROM dbo.vPOItemLine
				WHERE POITKeyID = @POITKeyID
					AND POItemLine = 1
				END
			IF EXISTS(SELECT 1 FROM dbo.vPOItemLine WHERE POITKeyID = @POITKeyID AND POItemLine > 1)
				BEGIN
				SET @LineItemsExist = 'Y'
				END
			END

		if @poititemtype <> @olditemtype or @poitmatlgroup <> @oldmatlgroup
			or isnull(@poitmaterial,'') <> isnull(@oldmaterial,'') or @poitum <> @oldum
			or @poitposttoco <> @oldposttoco or isnull(@poitloc,'') <> isnull(@oldloc,'')
			or isnull(@poitjob,'') <> isnull(@oldjob,'') or isnull(@poitphasegroup,0) <> isnull(@oldphasegroup,0)
			or isnull(@poitphase,'') <> isnull(@oldphase,'') or isnull(@poitjcctype,0) <> isnull(@oldjcctype,0)
			or isnull(@poitequip,'') <> isnull(@oldequip,'') or isnull(@poitcomponent,'') <> isnull(@oldcomponent,'')
			or isnull(@poitemgroup,0) <> isnull(@oldemgroup,0) or isnull(@poitcostcode,'') <> isnull(@oldcostcode,'')
			or isnull(@poitemctype,0) <> isnull(@oldemctype,0) or isnull(@poitwo,'') <> isnull(@oldwo,'')
			or isnull(@poitwoitem,0) <> isnull(@oldwoitem,0) or @poitglco <> @oldglco or @poitglacct <> @oldglacct
			or isnull(@poittaxgroup,0) <> isnull(@oldtaxgroup,0) or isnull(@poittaxcode,'') <> isnull(@oldtaxcode,'')
			or @poitorigunits <> @oldorigunits or @poitorigunitcost <> @oldorigunitcost
			or isnull(@poitorigecm,'') <> isnull(@oldorigecm,'') or @poitorigcost <> @oldorigcost
			or  @poitorigtax <> @oldorigtax or @poitreqnum <> @oldreqnum
			BEGIN
			select @errortext = @errorstart + ' - ''Old'' batch values do not match current Item values!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
 
		-- validate some 'old' info to get values needed for update
 
		-- init old material values
		select @oldhqmatl = 'N', @oldstdum = null, @oldumconv = 0

		-- check for Material in HQ
		select @oldstocked = Stocked, @oldstdum = StdUM
		from bHQMT with (nolock)
		where MatlGroup = @oldmatlgroup and Material = @oldmaterial
		if @@rowcount = 1
			BEGIN
			select @oldhqmatl = 'Y'    -- setup in HQ Materials
			if @oldstdum = @oldum select @oldumconv = 1
			END

		-- if HQ Material, validate old UM and get unit of measure conversion
		if @oldhqmatl = 'Y' and @oldum <> @oldstdum
			BEGIN
			select @oldumconv = Conversion
			from bHQMU with (nolock)
			where MatlGroup = @oldmatlgroup and Material = @oldmaterial and UM = @oldum
			if @@rowcount=0
				Begin
				select @errortext = @errorstart + ' - Old UM:  ' + @oldum + ' is not setup for Material: ' + @oldmaterial
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			END

		-- get JC UM for old Job
		if @olditemtype = 1
			BEGIN
			exec @rcode = bspJobTypeVal @oldposttoco, @oldphasegroup, @oldjob, @oldphase, @oldjcctype, @oldjcum output, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- Old entries ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				END

			select @oldjcumconv = 0     -- conversion factor to JC UM
			if isnull(@oldjcum,'') = @oldum  select @oldjcumconv = 1

			if @oldhqmatl = 'Y' and @oldum <> isnull(@oldjcum,'')
				BEGIN
				exec @rcode = bspHQStdUMGet @oldmatlgroup, @oldmaterial, @oldjcum, @oldjcumconv output, @oldstdum output, @errmsg output
				if @rcode <> 0
					BEGIN
					select @errortext = @errorstart + '- Old entries ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					END
				if @oldjcumconv <> 0 select @oldjcumconv = @oldumconv / @oldjcumconv
				END
			END
 
		if @olditemtype = 2     -- Inventory type
			BEGIN
			exec @rcode = bspHQStdUMGet @oldmatlgroup, @oldmaterial, @oldum, @oldumconv output, @oldstdum output, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- Old entries ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				END
			END
			
		IF @olditemtype = 6 -- SM Work Order Type
		BEGIN
			-- Validate the SM Scope
			EXEC @rcode = vspSMWorkOrderScopeValForPO @SMCo = @oldsmco, @SMWorkOrder = @oldsmworkorder, @Scope = @oldsmscope, @JCCo = @oldsmjcco OUTPUT, @Job = @oldsmjob OUTPUT, @msg = @errmsg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SELECT @errortext = @errorstart + '- SMScope ' + dbo.vfToString(@oldsmscope) + ' for SMCo ' + dbo.vfToString(@oldsmco) + ' - SMWorkOrder ' + dbo.vfToString(@oldsmworkorder) + ': ' + @errmsg
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF (@rcode <> 0) GOTO bspexit
				GOTO POIB_loop
			END
			
			IF EXISTS(
				SELECT 1
				FROM dbo.vSMWorkCompletedPurchase
					INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompletedPurchase.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompletedPurchase.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompletedPurchase.WorkCompleted = vSMInvoiceDetail.WorkCompleted
					INNER JOIN dbo.vSMInvoice ON vSMInvoiceDetail.SMCo = vSMInvoice.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoice.Invoice
					INNER JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
				WHERE dbo.vSMWorkCompletedPurchase.POCo = @co AND dbo.vSMWorkCompletedPurchase.PO = @po AND dbo.vSMWorkCompletedPurchase.POItem = @poitem AND dbo.vSMWorkCompletedPurchase.POItemLine = 1)
			BEGIN
				SELECT @errortext = @errorstart + '- A customer invoice for work order: SMCo ' + dbo.vfToString(@oldsmco) + ' - WorkOrder ' + dbo.vfToString(@oldsmworkorder) + ' needs to be processed in order for the po item to be modified.'
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF (@rcode <> 0) GOTO bspexit
				GOTO POIB_loop
			END
		END
 
		-- issue #20794 - bogus tax phase cost type records into POIA for interface to JC
		set @oldtaxphase = null
		set @oldtaxct = null
		-- get old Tax code info
		if @oldtaxcode is not null
			BEGIN
			--select @oldtaxphase = null, @oldtaxct = null
			exec @rcode = bspPOTaxCodeVal @oldtaxgroup, @oldtaxcode, @oldtaxtype, @oldtaxphase output, @oldtaxct output, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- Old entries ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				END

			-- get old tax phase and cost type for Job types
			if @olditemtype = 1
				BEGIN
				if @oldtaxphase is null select @oldtaxphase = @oldphase
				if @oldtaxct is null select @oldtaxct = @oldjcctype 
				-- validate old Tax Phase and Cost Type
				exec @rcode = bspJobTypeVal @oldposttoco, @oldphasegroup, @oldjob, @oldtaxphase, @oldtaxct, @oldtaxjcum output, @errmsg output
				if @rcode <> 0
					BEGIN
					select @errortext = @errorstart + '- Tax ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					END
				END
			ELSE IF @olditemtype = 6 AND @oldsmjob IS NOT NULL
				BEGIN
				if @oldtaxphase is null select @oldtaxphase = @oldsmphase
				if @oldtaxct is null select @oldtaxct = @oldsmjccosttype
				-- validate old Tax Phase and Cost Type
				exec @rcode = bspJobTypeVal @oldsmjcco, @oldsmphasegroup, @oldsmjob, @oldtaxphase, @oldtaxct,@oldtaxjcum output, @errmsg output
				if @rcode <> 0
					BEGIN
					select @errortext = @errorstart + '- Tax ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					END
				END
			END
		END 
 
	if @itemtranstype = 'C'     -- validation specific to 'change' Items
		BEGIN
		-- Change to Orig Units only allowed if Original and Current Unit Costs are equal
		if (@origunits <> @oldorigunits)
			and (@poitorigunitcost <> @poitcurunitcost or isnull(@poitorigecm,'') <> isnull(@poitcurecm,''))
			BEGIN
			select @errortext = @errorstart + ' - Original Units can only be changed if Original and Current Unit Cost are equal!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

		-- Change to Orig Unit Cost only allowed if all Original and Current values are equal
		if (@origunitcost <> @oldorigunitcost or isnull(@origecm,'') <> isnull(@oldorigecm,''))
				AND (@poitorigunitcost <> @poitcurunitcost OR isnull(@poitorigecm,'') <> isnull(@poitcurecm,'')
				----TK-07440
				OR (@poitorigunits <> @poitcurunits AND @LineItemsExist = 'N'))
			BEGIN
			select @errortext = @errorstart + ' - Original Unit Cost can only be changed if Original and Current values equal!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
 
		-- check for Change Order, Receiving, or Invoice activity

		select @activity = 0    -- no activity
		if @poitorigunits <> @poitcurunits or @poitorigunitcost <> @poitcurunitcost or @poitorigcost <> @poitcurcost
			or @poitrecvdunits <> 0 or @poitrecvdcost <> 0 or @poitinvunits <> 0 or @poitinvcost <> 0 select @activity = 1
 
		if @activity = 1
			BEGIN
			if @itemtype <> @olditemtype
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists - cannot change Item Type!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if isnull(@material,'') <> isnull(@oldmaterial,'') and (@itemtype = 1 or @itemtype = 2)
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists - cannot change material!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if @um <> @oldum
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists - cannot change unit of measure!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if @recyn <> @oldrecyn  and (@poitrecvdunits <> @poitinvunits or @poitrecvdcost <> @poitinvcost)
				BEGIN
				select @errortext = @errorstart + ' - Received amounts do not match Invoiced - cannot change its receiving flag!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if @posttoco <> @oldposttoco
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists -  cannot change ''Posted to'' Company!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if isnull(@job,'')<>isnull(@oldjob,'') or isnull(@phase,'')<>isnull(@oldphase,'')
    			or isnull(@jcctype,0)<>isnull(@oldjcctype,0)
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists - cannot change Job, Phase, or Cost Type!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
    		if (isnull(@equip,'')<>isnull(@oldequip,'') or isnull(@costcode,'')<>isnull(@oldcostcode,'')
				or isnull(@emctype,0)<>isnull(@oldemctype,0) or isnull(@wo,'')<>isnull(@oldwo,'')
				or isnull(@woitem,0)<>isnull(@oldwoitem,0)) and (@poitinvunits<>0 or @poitinvcost<>0)
				BEGIN
				select @errortext = @errorstart + ' - Invoice activity exists - cannot change Equipment information!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if isnull(@loc,'')<>isnull(@oldloc,'')
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists - cannot change Location!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if isnull(@taxcode,'') <> isnull(@oldtaxcode,'')
				BEGIN
				select @errortext = @errorstart + ' - Change Order, Receiving, and/or Invoice activity exists - cannot change Tax Code!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			if isnull(@taxtype,0)<>isnull(@oldtaxtype,0) and (@poitinvunits<>0 or @poitinvcost<>0)
				BEGIN
				select @errortext = @errorstart + ' - Invoice activity exists - cannot change its Tax Type!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			END
		END
 
	if @itemtranstype in ('A','C')      -- validation for both 'add' and 'change' Items
		BEGIN
		 -- validate Item Type
		if @itemtype not in (1,2,3,4,5,6)
			BEGIN
			select @errortext = @errorstart + ' - Item Type must be 1, 2, 3, 4, 5 or 6'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
 
		-- init material defaults
		select @hqmatl = 'N', @stdum = null, @umconv = 0
 
		-- check for Material in HQ
		select @stdum = StdUM
		from bHQMT WITH (NOLOCK)
		where MatlGroup = @matlgroup and Material = @material
		if @@rowcount = 1
			BEGIN
			select @hqmatl = 'Y'    -- setup in HQ Materials
			if @stdum = @um select @umconv = 1
			END

		-- validate Unit of Measure
		if not exists(select 1 from bHQUM WITH (NOLOCK) where UM = @um)
			BEGIN
			select @errortext = @errorstart + ' - Invalid unit of measure: ' + @um
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

		-- if HQ Material, validate UM and get unit of measure conversion
		if @hqmatl = 'Y' and @um <> @stdum
			BEGIN
			select @umconv = Conversion
			from bHQMU WITH (NOLOCK)
			where MatlGroup = @matlgroup and Material = @material and UM = @um
			if @@rowcount=0
				BEGIN
				select @errortext = @errorstart + ' - UM:  ' + @um + ' is not setup for Material: ' + @material
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			END
 
		-- validate PayCategory  -  may be null	--#25417 moved PayType/PayCategory validation from header section.
		if @paycategory is not null
			BEGIN
			if not exists (select 1 from bAPPC WITH (NOLOCK) where APCo=@co and PayCategory=@paycategory)
				BEGIN
				select @errortext = @errorstart + ' - Invalid Pay Category ' + convert(varchar(10),@paycategory)
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
 				END
			END

		-- validate Pay Type - may be null
		if @paytype is not null
			BEGIN
			if not exists(select 1 from bAPPT WITH (NOLOCK) where APCo=@co and PayType=@paytype)
 				BEGIN
 				select @errortext = @errorstart + ' - Invalid Pay Type ' + convert(varchar(10),@paytype)
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
     			END
 			END

		--DC #122903
 		-- validate Pay Type is associated with Pay Category
		if @paycategory is not null and @paytype is not null
			BEGIN
			--DC #122903
			if not exists (select 1 from APPT Where APCo = @co and PayType = @paytype 
						and (PayCategory is null or PayCategory = @paycategory))
					/*if not exists (select 1 from bAPPC WITH (NOLOCK) where APCo=@co and PayCategory=@paycategory and
					(ExpPayType=@paytype or JobPayType=@paytype or SubPayType=@paytype or RetPayType=@paytype)) */
				BEGIN
				select @errortext = @errorstart + ' - Pay Type ' + convert(varchar(10),@paytype)
				+ ' not associated with Pay Category ' + convert(varchar(10), @paycategory)
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
 			END
 
		-- validation based on Item Type
		if @itemtype = 1    -- Job type
			BEGIN
			exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END

			-- set GL Account Type for validation
			select @acctype = 'J'

			-- determine conversion factor from posted UM to JC UM
			select @jcumconv = 0
			if isnull(@jcum,'') = @um select @jcumconv = 1

			if @hqmatl = 'Y' and isnull(@jcum,'') <> @um
				BEGIN
				exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
				if @rcode <> 0
					BEGIN
					select @errortext = @errorstart + '- JCUMConv:' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto POIB_loop
					END
				if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
				END

			--DC #127019
			if not exists(select 1 from bPOIB Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem	and PostToCo = JCCo)
				BEGIN
				Update bPOIB
				Set JCCo = PostToCo
				Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem
				END 
			END
				
		if @itemtype = 2        -- Inventory type
			BEGIN
			exec @rcode = bspPOInvTypeVal @posttoco, @loc, @matlgroup, @material, @um, @errmsg output
			if @rcode <> 0
			  BEGIN
			  select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
			  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			  if @rcode <> 0 goto bspexit
			  goto POIB_loop
			  END

			--DC #127019
			if not exists(select 1 from bPOIB Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem	and PostToCo = INCo)
				BEGIN
				Update bPOIB
				Set INCo = PostToCo
				Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem
				END 

			-- set GL Account Type for validation
			select @acctype = 'I'
			END

		if @itemtype = 3        -- Expense type
			BEGIN
			 -- set GL Account Type for validation
			select @acctype = 'N'
			END
 
			/*  ???bspPOEquipTypeVal does nothing, validates nothing and always returns Valid???*/
		if @itemtype = 4        -- Equipment type
			BEGIN
			exec @rcode = bspPOEquipTypeVal @posttoco, @equip, @emgroup, @costcode, @emctype, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END

			--DC #127019
			if not exists(select 1 from bPOIB Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem	and PostToCo = EMCo)
				BEGIN
				Update bPOIB
				Set EMCo = PostToCo
				Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem
				END 

			-- set GL Account Type for validation
			select @acctype = 'E'
			END
 
		if @itemtype = 5      -- EM Work Order type
			BEGIN

			exec @rcode = bspAPLBValWO @posttoco, @wo, @woitem, @equip, @comptype,
				@component, @emgroup, @costcode, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			-- set GL Account Type for validation
			select @acctype = 'E'

			--DC #127019
			if not exists(select 1 from bPOIB Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem	and PostToCo = EMCo)
				BEGIN
				Update bPOIB
				Set EMCo = PostToCo
				Where Co = @co and Mth = @mth and BatchId = @batchid and POItem = @poitem
				END 

			END
			
		IF (@itemtype = 6)  -- SM Work Order Type - Following Expense type for now.
		BEGIN
			-- Validate SM type fields
			SELECT @acctype = 'S'
			SELECT @smworkorderclosedok = --if add or change to a close work order then we cant allow those records to post
				CASE
					WHEN (@itemtranstype = 'C') and (@smco = @oldsmco) and (@smworkorder = @oldsmworkorder) and (@smscope = @oldsmscope) THEN 'Y'
					ELSE 'N'
				END
			
			-- Validate the SM Co
			IF NOT EXISTS(SELECT 1 FROM vSMCO WHERE SMCo = @smco)
			BEGIN
				SELECT @errortext = @errorstart + '- SMCo ' + dbo.vfToString(@smco) + ' is not a valid SM Company.'
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF (@rcode <> 0) GOTO bspexit
				GOTO POIB_loop
			END
				
			-- Validate the SM Work Order
			EXEC @rcode = vspSMWorkOrderValForPO @SMCo = @smco, @SMWorkOrder = @smworkorder, @ClosedOK = @smworkorderclosedok, @msg = @errmsg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SELECT @errortext = @errorstart + '- SMWorkOrder ' + dbo.vfToString(@smworkorder) + ' for SMCo ' + dbo.vfToString(@smco) + ': ' + @errmsg
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF (@rcode <> 0) GOTO bspexit
				GOTO POIB_loop
			END
			
			-- Validate the SM Scope
			EXEC @rcode = vspSMWorkOrderScopeValForPO @SMCo = @smco, @SMWorkOrder = @smworkorder, @Scope = @smscope, @GLCo = @smglgo OUTPUT, @CostAccount = @smcostaccount OUTPUT,@JCCo = @smjcco OUTPUT, @Job = @smjob OUTPUT, @msg = @errmsg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SELECT @errortext = @errorstart + '- SMScope ' + dbo.vfToString(@smscope) + ' for SMCo ' + dbo.vfToString(@smco) + ' - SMWorkOrder ' + dbo.vfToString(@smworkorder) + ': ' + @errmsg
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF (@rcode <> 0) GOTO bspexit
				GOTO POIB_loop
			END
			
			-- If the SM Work Completed record has not been created yet then validate that the GL Account on the PO Line is the same as returned by the Scope validation.
			IF NOT EXISTS(SELECT 1 FROM SMWorkCompleted WHERE SMCo=@smco AND WorkOrder=@smworkorder AND Scope=@smscope AND POCo=@co AND PONumber=@po AND POItem=@poitem)
			BEGIN
				IF NOT(@glco=@smglgo AND @glacct=@smcostaccount)
				BEGIN
					SELECT @errortext = @errorstart + '- SMScope ' + dbo.vfToString(@smscope) + ' for SMCo ' + dbo.vfToString(@smco) + ' - SMWorkOrder ' + dbo.vfToString(@smworkorder) + ': GL Co/GL Account on PO Item doesn''t match values from Work Order.  Clear the scope field and re-enter the scope to default the correct account.'
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
					IF (@rcode <> 0) GOTO bspexit
					GOTO POIB_loop
				END
			END

			-- Validate the SM Work Order related Job, is Job Closed, error out
			EXEC @rcode = vspSMWorkCompletedWorkOrderVal @SMCo = @smco, @WorkOrder = @smworkorder,  @IsCancelledOK='N',@msg = @errmsg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SELECT @errortext = @errorstart + '- SMScope ' + dbo.vfToString(@smscope) + ' for SMCo ' + dbo.vfToString(@smco) + ' - SMWorkOrder ' + dbo.vfToString(@smworkorder) + ': ' + @errmsg
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF (@rcode <> 0) GOTO bspexit
				GOTO POIB_loop
			END
		END			
 
		-- validation for all types
		exec @rcode = bspGLMonthVal @glco, @mth, @errmsg output
		if @rcode <> 0
			BEGIN
			select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			END

		-- validate GL Account
		exec @rcode = bspGLACfPostable @glco, @glacct, @acctype, @errmsg output
		if @rcode <> 0
			BEGIN
			select @errortext = @errorstart + '- GL Account: ' + isnull(@glacct,'') + ':  ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
 
		-- issue #20794 - bogus tax phase cost type records into POIA for interface to JC
		set @taxphase = null
		set @taxct = null
		-- validate Tax Code
		if @taxcode is not null
			BEGIN
			--select @taxphase = null, @taxct = null
			exec @rcode = bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
			if @rcode <> 0
				BEGIN
				select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			
			-- validate Tax Phase if Job Type
			if @itemtype = 1
				BEGIN
				if @taxphase is null select @taxphase = @phase
				if @taxct is null select @taxct = @jcctype

				-- validate Tax phase and Tax Cost Type
				exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @taxphase, @taxct, @taxjcum output, @errmsg output
				if @rcode <> 0
					BEGIN
					select @errortext = @errorstart + '- Tax ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto POIB_loop
					END
				END
			ELSE IF @itemtype = 6 AND @smjob IS NOT NULL
				BEGIN
				if @taxphase is null select @taxphase = @smphase
				if @taxct is null select @taxct = @smjccosttype

				-- validate Tax phase and Tax Cost Type
				exec @rcode = bspJobTypeVal @smjcco, @smphasegroup, @smjob, @taxphase, @taxct, @taxjcum output, @errmsg output
				if @rcode <> 0
					BEGIN
					select @errortext = @errorstart + '- Tax ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto POIB_loop
					END
				END
			END
 
		-- validate Lump Sum items
		if @um = 'LS' and (@origunits <> 0 or @origunitcost <> 0 or @origecm is not null)
			BEGIN
			select @errortext = @errorstart + ' - Lump Sum Items must have 0.00 Units and Unit Cost!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
 
		if @um <> 'LS'
			BEGIN
			if isnull(@origecm,'') not in ('E','C','M')
				BEGIN
				select @errortext = @errorstart + ' - ECM must be E, C, or M!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END

			if @origunits = 0 and @origunitcost = 0 and @origcost <> 0 --issue #16000
				BEGIN
				select @errortext = @errorstart + ' - Units and unit cost must be entered on items when TotalCost <> 0 and UM <> ''LS''!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto POIB_loop
				END
			END
		END
 
	if @itemtranstype = 'D'     -- validation specific for 'delete' Items
		BEGIN
 
		-- make sure values in bPOIB match bPOIT
		if @poititemtype <> @itemtype or @poitmatlgroup <> @matlgroup
			or isnull(@poitmaterial,'') <> isnull(@material,'') or @poitum <> @um
			or @poitposttoco <> @posttoco or isnull(@poitloc,'') <> isnull(@loc,'')
			or isnull(@poitjob,'') <> isnull(@job,'')
			or isnull(@poitphasegroup,0) <> isnull(@phasegroup,0)
			or isnull(@poitphase,'') <> isnull(@phase,'')
			or isnull(@poitjcctype,0) <> isnull(@jcctype,0)
			or isnull(@poitequip,'') <> isnull(@equip,'')
			or isnull(@poitcomponent,'') <> isnull(@component,'')
			or isnull(@poitemgroup,0) <> isnull(@emgroup,0)
			or isnull(@poitcostcode,'') <> isnull(@costcode,'')
			or isnull(@poitemctype,0) <> isnull(@emctype,0)
			or isnull(@poitwo,'') <> isnull(@wo,'')
			or isnull(@poitwoitem,0) <> isnull(@woitem,0)
			or @poitglco <> @glco or @poitglacct <> @glacct
			or isnull(@poittaxgroup,0) <> isnull(@taxgroup,0)
			or isnull(@poittaxcode,'') <> isnull(@taxcode,'')
			or @poitorigunits <> @origunits
			or @poitorigunitcost <> @origunitcost
			or isnull(@poitorigecm,'') <> isnull(@origecm,'')
			or @poitorigcost <> @origcost
			or @poitorigtax <> @poiborigtax
			or isnull(@poitreqnum,'') <> isnull(@reqnum,'')
			BEGIN
			select @errortext = @errorstart + ' - Batch values do not match current Item values!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

		-- check for Receipt Detail
		if exists(select 1 from bPORD WITH (NOLOCK) where POCo = @co and PO = @po and POItem = @poitem)
			BEGIN
			select @errortext = @errorstart + ' - Receipts detail exists for this PO Item!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

		-- check for Change Order Detail
		if exists(
		select 1 from bPOCD WITH (NOLOCK) where POCo = @co and PO = @po and POItem = @poitem)
			BEGIN
			select @errortext = @errorstart + ' - Change Order detail exists for this PO Item!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

 		-- check for open or pending PO	--#18808
 		if exists(select 1 from bPOHD WITH (NOLOCK) where POCo = @co and PO = @po and Status not in (0,3))
			BEGIN
			select @errortext = @errorstart + ' - Purchase Order must be Open or Pending - cannot delete item.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

 		-- check for invoiced units or costs - #18808 - removed the check for APTL	
 		if (@poitinvunits <> 0 or @poitinvcost <> 0)
			/*if exists(select * from bAPTL where APCo = @co and PO = @po and POItem = @poitem)
			or @poitinvunits <> 0 or @poitinvcost <> 0*/
			BEGIN
			select @errortext = @errorstart + ' - Cannot delete Item if Invoiced Units or Invoiced Cost not 0.00!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END

 		--Issue 23730 ES 03/09/04 - Check unapproved invoices as well
		if exists (select * from bAPUL where APCo = @co and PO = @po and POItem = @poitem)
			BEGIN
			declare @UIMth datetime, @UISeq smallint
			select top 1 @UIMth = UIMth, @UISeq = UISeq from bAPUL where APCo = @co and PO = @po and POItem = @poitem
			select @errortext = @errorstart + ' - Unapproved Invoice exists for PO Item: ' 
			+ isnull(convert(varchar(2), @poitem), '') + ' UI Month: ' + 
			isnull(convert(varchar(2),DATEPART(month, @UIMth)) + '/' +
			substring(convert(varchar(4),DATEPART(year, @UIMth)),3,4), '') + 
			', UI Seq: ' + isnull(convert(varchar(2), @UISeq), '') + ' -- Cannot delete PO Item!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto POIB_loop
			END
		END

	update_audit:       -- update JC and Inventory audit tables
	if @itemtranstype = 'C' and @posttoco = @oldposttoco
        and isnull(@job,'') = isnull(@oldjob,'')
		and isnull(@phase,'') = isnull(@oldphase,'')
        and isnull(@jcctype,0) = isnull(@oldjcctype,0)
        and @vendor = @oldvendor
        and isnull(@material,'') = isnull(@oldmaterial,'')
        and isnull(@loc,'') = isnull(@oldloc,'')
        and @um = @oldum
        and @origunits = @oldorigunits
        and @origcost = @oldorigcost
        and isnull(@origecm,'') = isnull(@oldorigecm,'')
        and isnull(@taxcode,'') = isnull(@oldtaxcode,'') 
		and isnull(@origtax,0) = isnull(@oldorigtax,0)  --DC #134351
		and isnull(@jccmtdtax,0) = isnull(@oldjccmtdtax,0) --DC #134351  
		and isnull(@jcremcmtdtax,0) = isnull(@oldjcremcmtdtax,0) --DC #122288		     
        goto POIB_loop  -- skip if no change
 
	if @itemtranstype in ('C','D')        -- old entries
		BEGIN
		if @olditemtype = 1      -- back out 'old' from JC				
				--and @poitorigunits=@poitcurunits and @poitorigcost=@poitcurcost
			BEGIN
 			if @oldtaxphase is null select @oldtaxphase = @oldphase
 			if @oldtaxct is null select @oldtaxct = @oldjcctype

			-- if tax is not redirected, add a single entry   
			if (isnull(@oldtaxphase,'')=isnull(@oldphase,'') and isnull(@oldtaxct,0)=isnull(@oldjcctype,0))
				BEGIN
				insert into bPOIA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
					BatchSeq, POItem, OldNew, PO, Description, VendorGroup, Vendor, MatlGroup,
					Material, UM, CurrentUnits, RemUnits, JCUM, CmtdUnits, CmtdCost, RemCmtdUnits, RemCost,
					TotalCmtdTax, RemCmtdTax)  --DC #122288
				values (@co, @mth, @batchid, @oldposttoco, @oldjob, @oldphasegroup, @oldphase, @oldjcctype,
					@seq, @poitem, 0, @po, @olddesc, @oldvendorgroup, @oldvendor, @oldmatlgroup,
					@oldmaterial, @oldum,
					(-1 * @poittotunits),(-1 * @poitremunits),@oldjcum,
					(-1 * (@poittotunits*@oldjcumconv)),
					(-1 * (@poittotcost + @oldjccmtdtax)),		--(-1 * (@poittotcost + @poittottax)),
					(-1 * (@poitremunits*@oldjcumconv)), 
					(-1 * (isnull(@poitremcost,0) + case @poitremcost when 0 then 0 else @oldjcremcmtdtax end )), --#131405
					(-1 * isnull(@oldjccmtdtax,0)), (-1 * isnull(@oldjcremcmtdtax,0)))  --DC #122288
				END
       		Else
          		BEGIN
				-- tax is redirected, add two entries
				if @oldorigtax <> 0 or @origtax <> 0     -- skip tax entry if 0 --#30001
					BEGIN
					insert into bPOIA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
						BatchSeq, POItem, OldNew, PO, Description, VendorGroup, Vendor, MatlGroup,
           				Material, UM, CurrentUnits,RemUnits, JCUM, CmtdUnits, CmtdCost, RemCmtdUnits, RemCost,
           				TotalCmtdTax, RemCmtdTax)  --DC #122288)
					values (@co, @mth, @batchid, @oldposttoco, @oldjob, @oldphasegroup, @oldtaxphase, @oldtaxct,
						@seq, @poitem, 0, @po, @olddesc, @oldvendorgroup, @oldvendor, @oldmatlgroup,
   						@oldmaterial, @oldum,0,0, @oldtaxjcum, 0,
   						(-1 * @oldjccmtdtax),0,				--(-1 * @poittottax),0, 
   						(-1 * case @poitremcost when 0 then 0 else @oldjcremcmtdtax end), --#131405
						(-1 * isnull(@oldjccmtdtax,0)), (-1 * isnull(@oldjcremcmtdtax,0)))  --DC #122288
					END
				-- add entry for posted Phase
				insert into bPOIA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
					BatchSeq, POItem, OldNew, PO, Description, VendorGroup, Vendor, MatlGroup,
 					Material, UM, CurrentUnits,RemUnits, JCUM,CmtdUnits,
					CmtdCost, RemCmtdUnits, RemCost,
					TotalCmtdTax, RemCmtdTax)  --DC #122288)
				values (@co, @mth, @batchid, @oldposttoco, @oldjob, @oldphasegroup, @oldphase, @oldjcctype,
					@seq, @poitem, 0, @po, @olddesc, @oldvendorgroup, @oldvendor, @oldmatlgroup,
					@oldmaterial, @oldum,
					(-1 * @poittotunits),(-1 * @poitremunits),@oldjcum,
					(-1 * (@poittotunits* @oldjcumconv)),
					(-1 * (@poittotcost)),
					(-1 * (@poitremunits * @oldjcumconv)),
					(-1 * (isnull(@poitremcost,0))), -- #28395 
					0,0) --DC #122288
												--(-1 * @oldorigunits), @oldjcum, (-1 * @oldorigunits * @oldjcumconv),(-1 * @oldorigcost)) -- #25606
				END
			END	


		if  @olditemtype = 2    -- back out 'old' Inventory entries
			BEGIN
			--get the UM Conversion from INMU if UM exists issue#10098 - GR 08/18/00
			select @inumconv=Conversion from bINMU WITH (NOLOCK)
			where INCo=@oldposttoco and Material=@oldmaterial and MatlGroup=@oldmatlgroup and Loc=@oldloc and UM=@oldum
			if @@rowcount=0 select @inumconv=@oldumconv
			--and @poitorigunits=@poitcurunits and @poitorigcost=@poitcurcost

			insert into bPOII (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq,
			  POItem, OldNew, PO, Description, VendorGroup, Vendor, UM, ChangeUnits, StdUM, OnOrder)
			values (@co, @mth, @batchid, @oldposttoco, @oldloc, @oldmatlgroup, @oldmaterial, @seq,
				@poitem, 0, @po, @olddesc, @oldvendorgroup, @oldvendor, @oldum, (-1 * @oldorigunits),
			  @oldstdum, (-1 * @oldorigunits * @inumconv))
			END
		END
 
          --if @itemtranstype in ('A','C')      -- new entries
  	 	 --A change Item is not a new item, was not backing out old transaction when it was changed 05/01/01 TV
	if @itemtranstype in ('A','C')
		BEGIN
		if @itemtype = 1        -- Job type
			BEGIN  
			--#25606 establish currentunits, currenttax for insert into bPOIA
			select @tempgsttaxamt = case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end
			select @currentunits = case @itemtranstype when 'A' then @origunits else
				(@poittotunits + (@origunits - @oldorigunits)) end			--Total may not be same as Orig.  We are changing original.  Add difference
			select @currenttax = case @itemtranstype when 'A' then (@origtax - @tempgsttaxamt) else		--Full TaxAmount - GST
				(@poittottax + ((@origtax - @tempgsttaxamt) - @oldjccmtdtax)) end	--Total may not be same as Orig.  We are changing original.  Add difference of
																				--this Trans (Full TaxAmt - GST) - old JC Tax Amt (oldCmtdTaxAmt, which does not include GST) to TotalTax

			-- NEW values are based upon Current values (Meaning based upon Total values in some cases where Total values are 
			-- different than the Original value that is being modified by this transaction change.  Therefore the NEW value
			-- is a composite of the Total value and the Changed value to this transaction.  The variables being set below take
			-- this into consideration but the end result is that we are setting NEW values into JC Distribution Table
			if @itemtranstype = 'C' 
				BEGIN
				if ((@um <> 'LS' and (@poitcurunits = 0 and @origunits > 0)) or (@um = 'LS' and (@poitcurcost = 0 and @origcost > 0)))
					-- when changing from a blanket PO to a regular, back out received units/costs #19934
					--#30001 use currentunits, currenttax instead of origunits, origtax
					BEGIN	
					-- Blanket PO (Having 0 Units and 0 Cost on original posted Transaction) is now being changed to
					-- a regular PO.  Therefore Current values are equal to the amounts in the existing POIB batch only
					-- since these same values in POIT are 0.00 at this moment.
					select @factor = case /*@poitcurecm*/ @origecm when 'C' then 100 when 'M' then 1000 else 1 end
					select  @currentunits = @origunits,													--#30001
							@cmtdunits = @origunits * @jcumconv,										--#30001
							@cmtdcost = case @um when 'LS' then @origcost else							--#30001
									(@origunits * @origunitcost)/@factor end, 
							@currenttax = @origtax - @tempgsttaxamt,										--#30001
									-- @origunits = @origunits - @poitrecvdunits, -- #22843
							@cmtdremunits = (@currentunits - @poitrecvdunits) * @jcumconv,				--#30001 (No POIT InvUnits because blanket PO ?)
							@cmtdremcost = case @um when 'LS' then (@origcost - @poitrecvdcost) else	--#30001
									((@currentunits - @poitrecvdunits)* @origunitcost)/@factor end,
							@remunits = @currentunits - @poitrecvdunits,								--#30001
							@remtax = ((@origtax - @tempgsttaxamt) - @poitinvtax)							--#30001 (No POIT RecvTax)
					END
		 		else
					BEGIN
					-- A Regular PO currently being changed uses @currentunits because this value factors in the 
					-- possibility that the Total amounts may not be the same as this transaction original value
					-- when it was first posted.  Therefore we use @currentunits rather than @origunits etc. (See above setting of @current...)
					select @factor = case /*@poitcurecm*/ @origecm when 'C' then 100 when 'M' then 1000 else 1 end
					select	@cmtdunits =  @currentunits  * @jcumconv,
							@cmtdcost = case @um when 'LS' then @poittotcost + (@origcost - @oldorigcost)  else--#30001
									(@currentunits * @origunitcost) /@factor end, 
								-- @cmtdcost = (@poittotcost + (@origcost - @oldorigcost)),						--#25606
							@cmtdremunits = (@currentunits - @poitinvunits) * @jcumconv,						--#30001   - #121444 changed from recvunits to invunits
							@cmtdremcost = case @um when 'LS' then (@cmtdcost - @poitinvcost) else				--#30001 - #121533 changed from reccost to invcost
										((@currentunits - @poitinvunits)* @origunitcost)/@factor end,			--#30001 - #121533 changed from recvunits to invunits
							@remunits = @currentunits - @poitinvunits,											--#30001						
							@remtax = (@cmtdremcost * @taxrate) - case when @taxrate = 0 then 0 else
								(case when @HQTXdebtGLAcct is null then 0 else (((@cmtdremcost * @taxrate) * @gstrate) / @taxrate) end) end,	--(TaxAmount - GST (calculated))  --#30001 (A change gets recalculated using NEW taxrate for NEW record to JCCD)
							@currenttax = (@cmtdcost * @taxrate) - case when @taxrate = 0 then 0 else
								(case when @HQTXdebtGLAcct is null then 0 else (((@cmtdcost * @taxrate) * @gstrate) / @taxrate) end) end		-- (TaxAmount - GST (calculated)) --#128925 (A change gets recalculated using NEW taxrate for NEW record to JCCD)
					END
				END  					
			else	-- ItemTransType = 'A'
				BEGIN
				select @cmtdunits = @origunits * @jcumconv,		--(@origunits represents this batch unit value
					@cmtdcost = @origcost,						--(@origcost represents this batch cost value
					@cmtdremunits = @origunits * @jcumconv,		--#30001
					@cmtdremcost = @origcost,					--#30001
					@remunits = @currentunits,					--#30001	(@currentunits = @origunits here, see above)
					@remtax = @currenttax 						--#30001	(@currenttax has already removed GST, see above)
				END

			-- add a single entry if tax is not redirected
			if @taxphase is null select @taxphase = @phase
			if @taxct is null select @taxct = @jcctype
			IF (isnull(@taxphase,'') = isnull(@phase,'') and isnull(@taxct,0) = isnull(@jcctype,0))
				BEGIN
				insert into bPOIA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
					BatchSeq, POItem, OldNew, PO, Description, VendorGroup, Vendor, MatlGroup,
					Material, UM,CurrentUnits, RemUnits, JCUM, CmtdUnits, CmtdCost, RemCmtdUnits, RemCost,
					TotalCmtdTax, RemCmtdTax)  --DC #122288
				values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype,
					@seq, @poitem, 1, @po, @description, @vendorgroup, @vendor, @matlgroup,
					@material, @um,@currentunits, @remunits,@jcum,@cmtdunits,(isnull(@cmtdcost,0) + isnull(@currenttax,0)),
					@cmtdremunits, (isnull(@cmtdremcost,0) + isnull(@remtax,0)),
					isnull(@currenttax,0), isnull(@remtax,0))  --DC #122288)								 
				END
			Else
       			Begin
				-- tax is redirected, add two entries
				if @currenttax <> 0 or @remtax <> 0				--@origtax <> 0
					BEGIN
					insert into bPOIA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
						BatchSeq, POItem, OldNew, PO, Description, VendorGroup, Vendor, MatlGroup,
						Material, UM, CurrentUnits, RemUnits, JCUM, CmtdUnits, CmtdCost, RemCmtdUnits, RemCost,
						TotalCmtdTax, RemCmtdTax)  --DC #122288)
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @taxphase, @taxct,
						@seq, @poitem, 1, @po, @description, @vendorgroup, @vendor, @matlgroup,
						@material, @um, 0, 0, @taxjcum, 0, @currenttax, 0,
						isnull(@remtax,0), --#25606							
						isnull(@currenttax,0), isnull(@remtax,0))  --DC #122288)
					END

				-- add entry for posted Phase
				insert into bPOIA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
					BatchSeq, POItem, OldNew, PO, Description, VendorGroup, Vendor, MatlGroup,
					Material, UM, CurrentUnits, RemUnits, JCUM, CmtdUnits, CmtdCost, RemCmtdUnits, RemCost,
					TotalCmtdTax, RemCmtdTax)  --DC #122288))
				values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype,
					@seq, @poitem, 1, @po, @description, @vendorgroup, @vendor, @matlgroup,
					@material, @um,@currentunits,@remunits,@jcum, @cmtdunits, @cmtdcost, @cmtdremunits, isnull(@cmtdremcost,0),
					0,0)
						--  @origunits, @jcum, @cmtdunits, @cmtdcost)--#25606
				END

			END	-- end Job type
 
			if @itemtype = 2        -- Inventory type
				--and (@itemtranstype='A' or (@poitorigunits=@poitcurunits and @poitorigcost=@poitcurcost))
				BEGIN
				--get the UM Conversion from INMU if UM exists issue#10098 GR 08/18/00
				select @inumconv=Conversion 
				from bINMU WITH (NOLOCK)
				where INCo=@posttoco and Material=@material and MatlGroup=@matlgroup and Loc=@loc and UM=@um
				if @@rowcount=0 select @inumconv=@umconv

				insert into bPOII (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq,
					POItem, OldNew, PO, Description, VendorGroup, Vendor, UM, ChangeUnits, StdUM, OnOrder)
				values (@co, @mth, @batchid, @posttoco, @loc, @matlgroup, @material, @seq,
					@poitem, 1, @po, @description, @vendorgroup, @vendor, @um, @origunits, @stdum, (@origunits * @inumconv))
				END
		END
	 
	goto POIB_loop  -- next Item
 
	POIB_end:
	close bcPOIB
	deallocate bcPOIB
	select @opencursorPOIB = 0
 
goto POHB_loop      -- next PO Header
 
POHB_end:
close bcPOHB
deallocate bcPOHB
select @opencursorPOHB = 0
 
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3  /* valid - ok to post */
if exists(select 1 from bHQBE WITH (NOLOCK) where Co = @co and Mth = @mth and BatchId = @batchid)
	BEGIN
	select @status = 2 /* validation errors */
	END

Update bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
	BEGIN
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	GoTo bspexit
	END

bspexit:
if @opencursorPOIB = 1
	BEGIN
	Close bcPOIB
	deallocate bcPOIB
	END
if @opencursorPOHB = 1
	BEGIN
	Close bcPOHB
	deallocate bcPOHB
	END

return @rcode











GO

GRANT EXECUTE ON  [dbo].[bspPOHBVal] TO [public]
GO
