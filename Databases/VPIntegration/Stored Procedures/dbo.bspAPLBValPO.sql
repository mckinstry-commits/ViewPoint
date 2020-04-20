SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBValPO    Script Date: 8/28/99 9:36:01 AM ******/
    CREATE        procedure [dbo].[bspAPLBValPO]
    /*********************************************
     * Created: GG 6/5/99
     * Modified: GG 6/22/99
     *           GG 11/13/99 - Added output params for Current Unit Cost and ECM
     *           kb 1/29/2 - issue #15980
     *              kb 10/28/2 - issue #18878 - fix double quotes
     *				MV 09/02/03 - #21978 return PO tax code, tax group, performance enhancements
     *				MV 11/11/03 - #22947 get taxrate from HQTX - can't calculate taxrate on a standing PO
     *				MV 12/08/03 - #23224 if no potaxcode, set @potaxrate = 0 - related to #22947
     *				MV 08/10/04 - #25032 - check inv amt against total PO, inv units against recvd units
     *              MV 07/09/08 - #128288 - return PO GST Tax Rate
	 *				MV 12/11/08 - #131385 - if taxcode is null don't zero out taxrate
	 *				MV 02/04/10 - #136500 - bspHQTaxRateGetAll added NULL output param
	 *				DC 04/02/10 - #138903 - AP Validation error - not returning an error when Tax Code is invalid
	 *				MH 11/20/10 - SM Changes
	 *				MH 03/20/11 - SM Changes TK-02796/ TK-02793
	 *				GF 08/03/11 - TK-07440 PO expanded.
	 *				MV 08/10/11 - TK-07621 AP project to use POItemLine
	 *				MV 10/25/11 - TK09243 added NULL output param to bspHQTaxRateGetAll
	 *
     * Usage:
     *  Called from the AP Transaction Batch validation procedure (bspAPLBVal)
     *  to validate PO Item information.
     *
     * Input:
     *  @apco          AP/PO Co#
     *  @mth           Batch month
     *  @batchid       Batch Id
     *  @po            PO
     *  @poitem        PO Item
     *  @itemtype      Item type (1 = Job, 2 = Inv, 3 = Exp, 4 = Equip, 5 = WO, 6 = SM)
     *  @material      Material
     *  @um            Unit of measure
     *  @jcco          JC Co# - Job item
     *  @emco          EM Co# - Equipment or WO item
     *  @inco          IN Co# - Inventory item
     *  @glco          GL Co# - Expense item
     *  @loc           Inventory Location
     *  @job           Job
     *  @phase         Phase
     *  @jcctype       JC Cost Type
     *  @equip         Equipment
     *  @costcode      EM Cost Code
     *  @emctype       EM Cost Type
     *  @comptype      EM Component Type
     *  @component     EM Component
     *  @wo            Work Order
     *  @woitem        Work Order Item
     *  @pototyn       Allow invoice amount to exceed item amount flag
   
     *
     * Output:
     *  @revyn             Receiving flag on PO Item
     *  @pocurunitcost     Item current unit cost
     *  @pocurecm          Current unit cost per E, C, M
     *  @errmsg            Error message
     *
     * Return:
     *  0           success
     *  1           error
     *************************************************/
   
        @apco bCompany, @mth bMonth, @batchid bBatchID,@invdate bDate, @po VARCHAR(30), @poitem bItem, @POItemLine INT, @itemtype tinyint,
        @material bMatl,@um bUM, @jcco bCompany, @emco bCompany, @inco bCompany, @glco bCompany, @loc bLoc, @job bJob, @phase bPhase,
        @jcctype bJCCType, @equip bEquip, @costcode bCostCode, @emctype bEMCType, @comptype varchar(10), @component bEquip,
        @wo bWO, @woitem bItem, @pototyn bYN, @smco bCompany, @smworkorder int, @smscope int, @recyn bYN output, @pocurunitcost bUnitCost output,
        @pocurecm bECM output,@potaxrate bRate output,@potaxcode bTaxCode output,@potaxgroup bGroup output,@poGSTrate bRate output, @errmsg varchar(255) output
    as
   
    set nocount on
   
    declare @rcode int, @postatus tinyint, @poinusemth bMonth, @poinusebatchid bBatchID, @poitemtype tinyint,
    @pomatl bMatl, @poum bUM, @poposttoco bCompany, @poloc bLoc, @pojob bJob, @pophase bPhase, @pojcct bJCCType,
    @poequip bEquip, @pocostcode bCostCode, @poemct bEMCType, @pocomptype varchar(10), @pocomp bEquip,
    @powo bWO, @powoitem bItem, @msg varchar(255), @poitemtotyn bYN, @invexceedrecvyn bYN,@dbtGLAcct bGLAcct,
	@po_smco bCompany, @po_smworkorder int, @po_smscope int
	
    select @rcode = 0, @potaxrate = 0
   
   -- get po validation flags from bAPCO
   select @poitemtotyn=POItemTotYN, @invexceedrecvyn=InvExceedRecvdYN from bAPCO where APCo=@apco
   
    -- validate PO Header
    select @postatus = Status, @poinusemth = InUseMth, @poinusebatchid = InUseBatchId
    from bPOHD WITH (NOLOCK)
    where POCo = @apco and PO = @po
    if @@rowcount = 0
        begin
        select @errmsg = ' Invalid PO: ' + @po, @rcode = 1
        goto bspexit
        end
    if @postatus <> 0   -- status must be open
        begin
        select @errmsg = ' PO: ' + @po + ' is not open!', @rcode = 1
        goto bspexit
      	end
    if @poinusemth <> @mth or @poinusebatchid <> @batchid
        begin
        select @errmsg = ' PO: ' + @po + ' is already in use by another batch!', @rcode = 1
        goto bspexit
      	end

    -- validate PO Item 
    select @pomatl = Material, @poum = UM, @recyn = RecvYN, 
        @pocurunitcost = CurUnitCost, @pocurecm = CurECM
    from dbo.bPOIT WITH (NOLOCK)
    where POCo = @apco and PO = @po and POItem = @poitem
    if @@rowcount = 0
        begin
        select @errmsg = ' Invalid PO: ' + @po + ' Item: ' + convert(varchar(6),@poitem), @rcode = 1
        goto bspexit
      	end
    -- validate PO Item Line
    SELECT @poitemtype = ItemType, @poposttoco = PostToCo,
        @poloc = Loc, @pojob = Job, @pophase = Phase, @pojcct = JCCType, @poequip = Equip, @pocostcode = CostCode,
        @poemct = EMCType, @pocomptype = CompType, @pocomp = Component, @powo = WO, @powoitem = WOItem,
        @potaxcode = TaxCode, @potaxgroup = TaxGroup, @po_smco = SMCo, @po_smworkorder = SMWorkOrder, @po_smscope = SMScope
    FROM dbo.vPOItemLine (NOLOCK)
    WHERE POCo = @apco AND PO = @po AND POItem = @poitem AND POItemLine=@POItemLine
    IF @@ROWCOUNT = 0
    BEGIN
        SELECT @errmsg = ' Invalid PO: ' + @po 
			+ ' Item: ' + CONVERT(VARCHAR(6),@poitem)
			+ ' Item Line: ' + CONVERT(VARCHAR(6), @POItemLine), @rcode = 1
        GOTO bspexit
    END
    -- match posted info with PO Item and Item Line
    if @poitemtype <> @itemtype or isnull(@pomatl,'') <> isnull(@material,'') or @poum <> isnull(@um,'')
        or @poposttoco <> case @itemtype when 1 then @jcco when 2 then @inco when 3 then @glco when 6 then @smco else @emco end  --mark add SM Type 6
        or isnull(@poloc,'') <> isnull(@loc,'') or isnull(@pojob,'') <> isnull(@job,'')
        or isnull(@pophase, '') <> isnull(@phase,'') or isnull(@pojcct, 0) <> isnull(@jcctype,0)
        or isnull(@poequip,'') <> isnull(@equip,'') or isnull(@pocostcode,'') <> isnull(@costcode,'')
        or isnull(@poemct,0) <> isnull(@emctype,0) or isnull(@pocomptype,'') <> isnull(@comptype,'')
        or isnull(@pocomp,'') <> isnull(@component,'') or isnull(@powo,'') <> isnull(@wo,'')
        or isnull(@powoitem,0) <> isnull(@woitem,0) or isnull(@po_smco,0) <> isnull(@smco,0) 
        or isnull(@po_smworkorder,0) <> isnull(@smworkorder, 0) 
        or isnull(@po_smscope,0) <> isnull(@smscope, 0)
        begin
        select @errmsg = ' Does not match setup information on PO: ' + @po 
			+ ' Item: ' + convert(varchar(6),@poitem)
			+ ' or Item Line: ' + CONVERT(VARCHAR(6), @POItemLine)
        select @rcode = 1
        goto bspexit
      	end
   
   /* #22947 - get taxrate */
   if @potaxgroup is not null and @potaxcode is not null
   	begin
    -- 128288 use bspHQTaxRateGetAll to return potaxrate, poGSTtaxrate, btGLAcct 
	exec @rcode = bspHQTaxRateGetAll @potaxgroup, @potaxcode, @invdate, null, @potaxrate output, @poGSTrate output,
		null,null,null, @dbtGLAcct output,null,null, null, NULL,NULL, @msg output  --DC #138903
--   	exec @rcode = bspHQTaxRateGet @potaxgroup,@potaxcode, @invdate,null,null,null,@msg output
   	if @rcode <> 0
           begin
      		select @errmsg = 'Purchase Orders Original Tax Code:  ' + @potaxcode + '- ' + isnull(@msg,''),@potaxrate = 0, @rcode = 1
      	  	goto bspexit
      		end
    end
        --if there is no debit GL Acct for GST then don't return a gst taxrate
        if @dbtGLAcct is null select @poGSTrate = 0
--   else
--   	    select @potaxrate = 0,@poGSTrate = 0	--131385
   
   
   
    -- check that invoiced total doesn't exceed total for item 
    if @pototyn = 'N' or @poitemtotyn = 'N' or @invexceedrecvyn = 'N'
        begin
        exec @rcode = bspAPPOItemTotalVal @apco, @mth, @batchid, @po, @poitem, @POItemLine, 'B', 0, null, null,null,@msg output
      	if @rcode <> 0
            begin
      		select @errmsg = '- ' + @msg, @rcode = 1
      	  	goto bspexit
      		end
        end
   
    bspexit:
        return @rcode






GO
GRANT EXECUTE ON  [dbo].[bspAPLBValPO] TO [public]
GO
