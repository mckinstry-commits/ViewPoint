SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBValNew    Script Date: 8/28/99 9:36:40 AM ******/
   CREATE                         procedure [dbo].[bspAPLBValNew]
   /***********************************************************
    * CREATED BY: GG 06/30/99
    * MODIFIED By: GG  11/13/99 - Added output params to bspAPLBValPO and bspAPLBValSL
    *                             for Current Unit Cost and ECM
    *              kb 5/6/00 - added validation of tax phase/ct per issue #6584
    *              GG - 5/08/00 Fixed to pull Tax Rate and pass in back to bspAPLBVal
    *              GG - 5/24/00 Fixed
    *              GG - 06/06/00 - added validation for Expense Journal
    *              kb - 8/8/00 - shorten error msg used when validating job/taxphase/taxct, issue #9279
    *              danf - 05/14/01 - Added Update for Receiving
    *              GG - 07/26/01 - added pararmeter to bspAPLBValEquip for Component Type
    *				GG 09/21/01 - #14461 changed use tax validation and updates
    *              kb 1/29/2 - issue #15980
    *				MV 2/4/02 - issue14681 - removed @apcotaxgroup from input params. Commented out select @taxgroup
    *					from HQCO. 
    *              DANF/KATE 04/24/04 - issue 15980
    *              DANF 09/05/02 - 17738 - Added PhaseGroup to bspAPLBValJob & bspJobTypeVal & bspJCCAGlacctDflt
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *				MV 09/02/03 - #21978 - If APTL taxcode is null,use POIT TaxCode phase and ct. Performance enhancements
    *				MV 11/11/03 - #22947 - added @invdate to bspAPLBValPO params
    *				MV 02/09/04 - #23061 - isnull wrap err msg 
    *				ES 03/11/04 - #23061 more isnull wrapping
    *				MV 04/26/04 - #18769 - paycategory retainage paytype validation
    *				MV 06/21/04 - #24896 - check TaxCode overrides for phase and ct separately
    *				MV 01/06/05 - #26063 - validate taxgroup based on linetype and taxtype - for imports
    *				MV 08/02/05 - #29467 - comment out code for #26063 until issue #29462 is fixed. - 5A
    *				MV 08/09/05 - #29462 - taxgroup fixed in Unapproved - uncomment taxgroup validation code. - 5B
    *				MV 08/16/05 - #29558 - return AvgECM from bspAPLBValInv
    *				MV 11/08/05 - #30296 - only validate AP taxgroup for PO line types
    *				MV 06/04/08 - #128288 - return GST/PST taxrates, fields and debit GL Accts, PO/SLtaxrate,GSTrate
	*				MV 12/05/08 - #131313 - validate retainage info only if retainage <> 0
	*				MV 12/10/08 - #131385 - If taxcode is not null don't set phase = taxphase
	*				MV 10/26/09 - #136201 - Validate tax type for imports.
	*				MV 02/04/10 - #136500 - bspHQTaxRateGetAll return CrdRetgGSTGLAcct output param
	*				GP 6/28/10 - #135813 change bSL to varchar(30) 
	*				MH 11/20/10	- SM changes
	*				MH 03/20/11 - SM changes TK-02798
	*				GF 08/04/2011 - TK-07144 EXPAND PO
	*				MH 08/09/11 - TK-07482 Replaced MiscellaneousType with SMCostType
	*				MV 08/10/11 - TK-07621 - AP project to use POItemLine
	*			CHS	08/29/2011	- TK-07986 added parameters in call to bspPORBExpVal
	*				MV 10/25/11 - TK-09243 return @crdRetgGLAcctPST from bspHQTaxRateGetAll
	*				MB 10/15/12 - TK-18437 update so linetype 3 would not get set to S when
	*							it should be set to N.
	*				JB 12/10/12 - Fix to support SM PO receiving
	*
    * USAGE:
    * Called from bspAPLBVal to validate the current values in
    * Add and Changed lines.
    *
    * Errors in batch added to bHQBE
    *
    * INPUT PARAMETERS:
    *  @apco               AP Company
    *  @mth                Batch month
    *  @batchid            Batch ID#
    *  @batchseq           Batch sequence - a transaction
    *  @invdate            Invoice Date
    *  @apline             AP Line #
    *  @apglco             AP GL Company #
    *  @expjrnl            Expense Journal
    *  @pototyn            PO Invoice total option
    *  @sltotyn            SL Invoice total option
    *  @netamtopt          Net Amount subledger option
    *  @retpaytype         Retainage Pay Type
    *  @discoffglacct      Discount Offered GL Account
    *  @retholdcode        Retainage Hold Code
    *  @apcotaxgroup	AP Company Tax Group -- not needed when #14681 is complete
    *
    * OUTPUT PARAMETERS
    *  @recyn              PO Item Receiving option
    *  @slitemtype         SL Item type
    *  @jcum               JC Unit of Measure
    *  @jcunits            Units converted to JC UM
    *  @emum               EM Unit of Measure
    *  @emunits            Units converted to EM UM
    *  @stdum              Material Standard unit of mearsure
    *  @stdunits           Units converted to Std UM
    *  @costopt            IN Cost option
    *  @fixedunitcost      Fixed Unit Cost
    *  @fixedecm           ECM for Fixed Unit Cost
    *  @burdenyn           IN Burdened Unit Cost option
    *  @loctaxglacct       IN Tax GL Account
    *  @locmiscglacct      IN Misc/Freight GL Account
    *  @locvarianceglacct  IN Cost Variance GL Account
    *  @intercoarglacct    Intercompany AR GL Account
    *  @intercoapglacct    Intercompany AP GL Account
    *  @apglacct           Posted Pay Type GL Account
    *  @taxaccrualacct     Use Tax Accrual GL Account based on 'posted to' company
    *  @taxphase           Tax Phase
    *  @taxct              Tax JC Cost Type
    *  @taxglacct          Tax Expense GL Account
    *  @taxrate            Tax Rate
    *  @retglacct          Retainage Payable GL Account
    *  @curunitcost        PO or SL Item Current Unit Cost
    *  @curecm             Current Unit Cost per E, C, M
    *  @errmsg             error message
    *
    * RETURN VALUE
    *    0                 success
    *    1                 failure
    *****************************************************/
      @apco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @invdate bDate, @apline smallint, @apglco bCompany,
      @expjrnl bJrnl, @pototyn bYN, @sltotyn bYN, @netamtopt bYN,@retpaytype tinyint, @discoffglacct bGLAcct,
      @retholdcode bHoldCode, @HQBatchDistributionID bigint, @recyn bYN output, @slitemtype tinyint output, @jcum bUM output,
      @jcunits bUnits output, @emum bUM output, @emunits bUnits output, @stdum bUM output, @stdunits bUnits output,
      @costopt tinyint output, @fixedunitcost bUnitCost output, @fixedecm bECM output, @burdenyn bYN output,
      @loctaxglacct bGLAcct output, @locmiscglacct bGLAcct output, @locvarianceglacct bGLAcct output,
      @intercoarglacct bGLAcct output, @intercoapglacct bGLAcct output, @apglacct bGLAcct output,
      @taxaccrualacct bGLAcct output, @taxphase bPhase output, @taxct bJCCType output, @taxglacct bGLAcct output,
      @taxrate bRate output, @retglacct bGLAcct output, @curunitcost bUnitCost output, @curecm bECM output,
      @potaxrate bRate output, @avgecm bECM output, @valueadd char(1) output,@gstrate bRate output,
	  @pstrate bRate = null output,@dbtGLAcct bGLAcct output, @dbtRetgGLAcct bGLAcct output,@poGSTrate bRate output,
      @sltaxrate bRate output,@slGSTtaxrate bRate output, @crdRetgGLAcctGST bGLAcct output,@crdRetgGLAcctPST bGLAcct output,
      @errmsg varchar(255) output
   
     as
   
     set nocount on

DECLARE @PrintDebug bit
SET @PrintDebug=0  
   
     -- APLB declares
     declare @linetranstype char(1), @linetype tinyint, @po varchar(30), @poitem bItem, @POItemLine INT,@itemtype tinyint,
     @sl varchar(30), @slitem bItem, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType,
     @emco bCompany, @wo bWO, @woitem bItem, @equip bEquip, @emgroup bGroup, @costcode bCostCode, @emctype bEMCType,
     @comptype varchar(10), @component bEquip, @inco bCompany, @loc bLoc, @matlgroup bGroup, @matl bMatl,
     @glco bCompany, @glacct bGLAcct, @linedesc bDesc, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM,
     @suppliergroup bGroup, @supplier bVendor, @paytype tinyint, @grossamt bDollar, @miscamt bDollar, @miscyn bYN,
     @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxamt bDollar, @retainage bDollar,
     @discount bDollar, @burunitcost bUnitCost, @becm bECM, @pounits bUnits, @pogrossamt bDollar, @potaxgroup bGroup,
     @potaxcode bTaxCode, @paycategory int, @sltaxgroup bGroup, @sltaxcode bTaxCode, @smco bCompany, @smworkorder int,
     @smscope int, @smcosttype smallint 
   
     declare @rcode int, @accounttype char(1), @active bYN, @msg varchar(255), @receiptupdate bYN , @taxgroupval bGroup,
   	 @taxgroupco tinyint
   
     select @rcode = 0, @taxrate = 0
   
     -- get AP Line batch entry to validate
     select @linetranstype = BatchTransType, @linetype = LineType, @po = PO, @poitem = POItem, @POItemLine = POItemLine,
         @itemtype = ItemType, @sl = SL, @slitem = SLItem, @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup,
         @phase = Phase, @jcctype = JCCType, @emco = EMCo, @wo = WO, @woitem = WOItem, @equip = Equip,
         @emgroup = EMGroup, @costcode = CostCode, @emctype = EMCType, @comptype = CompType, @component = Component,
         @inco = INCo, @loc = Loc, @matlgroup = MatlGroup, @matl = Material, @glco = GLCo, @glacct = GLAcct,
         @linedesc = Description, @um = UM, @units = Units, @unitcost = UnitCost, @ecm = ECM, @suppliergroup = VendorGroup,
         @supplier = Supplier, @paytype = PayType, @grossamt = GrossAmt, @miscamt = MiscAmt, @miscyn = MiscYN,
         @taxgroup = TaxGroup, @taxcode = TaxCode, @taxtype = TaxType, @taxbasis = TaxBasis, @taxamt = TaxAmt,
         @retainage = Retainage, @discount = Discount, @burunitcost = BurUnitCost, @becm = BECM, @paycategory=PayCategory,
         @smco = SMCo, @smworkorder = SMWorkOrder, @smscope = Scope, @smcosttype = SMCostType
     from bAPLB WITH (NOLOCK)
     where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and APLine = @apline
     if @@rowcount <> 1
         begin
         select @errmsg = 'AP Line Batch entry is missing!', @rcode = 1
         goto bspexit
         end
   
     if @linetranstype not in ('A','C')
         begin
         select @errmsg = 'Must be (A) or (C) to validate with this procedure!', @rcode = 1
         goto bspexit
         end
     -- validate PO and Item
     if @linetype = 6    -- PO Type
         begin
         exec @rcode = bspAPLBValPO @apco, @mth, @batchid, @invdate, @po, @poitem, @POItemLine, @itemtype, @matl, @um, @jcco, @emco,
             @inco, @glco, @loc, @job, @phase, @jcctype, @equip, @costcode, @emctype, @comptype, @component, @wo,
             @woitem, @pototyn, @smco, @smworkorder, @smscope, @recyn output, @curunitcost output, @curecm output, @potaxrate output,@potaxcode output,
             @potaxgroup output,@poGSTrate output, @errmsg output
         if @rcode <> 0 goto bspexit

      -- get PO Company info
      select @receiptupdate = ReceiptUpdate
      from bPOCO WITH (NOLOCK) where POCo = @apco
      if @@rowcount = 0
        begin
        select @errmsg = ' Invalid PO Company!', @rcode = 1
        goto bspexit
        end
   
     If @receiptupdate = 'Y' and @recyn = 'Y'
        begin
         if @linetranstype = 'A'
           begin
             select @pounits = -1 * isnull(@units,0), @pogrossamt =  isnull(@grossamt,0) * -1
             exec @rcode = bspPORBExpVal @apco, @mth, @batchid, @batchseq, @apline, @linetranstype,
				null, @po, @poitem, @invdate, null, @linedesc, @pounits, @pogrossamt, 0, 0, null,
				null, null, null, null, null, null, null, null, null, null, 
				@POItemLine, null, @HQBatchDistributionID, @errmsg output
             if @rcode <> 0 goto bspexit
           end
   
        end
   
      end
     -- validate SL and Item
     if @linetype = 7        -- SL line type
         begin
         exec @rcode = bspAPLBValSL @apco, @mth, @batchid, @sl, @slitem, @jcco, @job, @phase, @jcctype, @um,
              @sltotyn, @slitemtype output, @curunitcost output,@sltaxgroup output, @sltaxcode output,
              @sltaxrate output,@slGSTtaxrate output, @errmsg output
      if @rcode <> 0 goto bspexit
         select @curecm = 'E'
         end
   
     -- validate JCCo, Job, Phase, and JC Cost Type
     if @linetype in (1,7) or (@linetype = 6 and @itemtype = 1)
         begin
         exec @rcode = bspAPLBValJob @jcco, @phasegroup, @job, @phase, @jcctype, @matlgroup, @matl, @um, @units, @jcum output,
             @jcunits output, @errmsg output
IF @PrintDebug=1 PRINT 'bspAPLBValNew A: '+@errmsg
         if @rcode <> 0 goto bspexit
         end
     -- validate Work Order and Item
     if @linetype = 5 or (@linetype = 6 and @itemtype = 5)
         begin
         exec @rcode = bspAPLBValWO @emco, @wo, @woitem, @equip, @comptype, @component, @emgroup,
             @costcode, @errmsg output
         if @rcode <> 0 goto bspexit
         end
     -- validate EMCo, Equip, Cost Code, EM Cost Type, Component Type, and Component
     if @linetype in (4,5) or (@linetype = 6 and @itemtype in (4,5))
         begin
         exec @rcode = bspAPLBValEquip @emco, @equip, @emgroup, @costcode, @emctype, @comptype, @component,
           @matlgroup, @matl, @um, @units, @emum output, @emunits output, @errmsg output
         if @rcode <> 0 goto bspexit
         end
     -- validate IN Co#, Location, Material, and UM
     if @linetype = 2 or (@linetype = 6 and @itemtype = 2)
        begin
      exec @rcode = bspAPLBValInv @inco, @loc, @matlgroup, @matl, @um, @units, @stdum output, @stdunits output,
             @costopt output, @fixedunitcost output, @fixedecm output, @burdenyn output, @loctaxglacct output,
             @locmiscglacct output, @locvarianceglacct output,@avgecm output, @errmsg output 
         if @rcode <> 0 goto bspexit
         end
         
     --TK-02798 Validate SM Line Type
     IF @linetype = 8
     BEGIN
		IF NOT EXISTS(SELECT 1 FROM SMWorkOrderScope WHERE SMCo = @smco and WorkOrder = @smworkorder and Scope = @smscope)
		BEGIN
			SELECT @errmsg = 'Invalid SM Work Order or SM Work Order Scope.'
			GOTO bspexit
		END
     END

     -- validate Expense Jrnl in 'posted to' GL Co#
     if @glco <> @apglco
        begin
        if not exists(select 1 from bGLJR WITH (NOLOCK) where GLCo = @glco and Jrnl = @expjrnl)
            begin
            select @errmsg = 'Journal ' + isnull(@expjrnl,'') + ' is not valid in GL Co#' + 
   			isnull(convert(varchar(3),@glco), ''), @rcode = 1  --#23061
            goto bspexit
            end
   	    end

     -- validate 'posted to' GL Co and Expense Month
     exec @rcode = bspHQBatchMonthVal @glco, @mth, 'AP',@errmsg output
     if @rcode <> 0 goto bspexit
   
     -- validate Posted GL Account
     select @accounttype = null
     if @linetype in (1,7) or (@linetype = 6 and @itemtype = 1) select @accounttype = 'J'    -- job
     if @linetype = 2 or (@linetype = 6 and @itemtype = 2) select @accounttype = 'I'          -- inventory
     if @linetype = 3 or (@linetype = 6 and (@itemtype = 3)) select @accounttype = 'N'         -- must be null  
     if @linetype in (4,5) or (@linetype = 6 and @itemtype in (4,5)) select @accounttype = 'E'   -- equipment
     --TK-02798
     IF @linetype = 8 or (@linetype = 6 and (@itemtype = 6)) SELECT @accounttype = 'S'
	 --END TK-02798    
     exec @rcode = bspGLACfPostable @glco, @glacct, @accounttype, @msg output
     if @rcode <> 0
         begin
       	 select @errmsg = 'GL Account:' + isnull(@glacct, '') + ':  ' + isnull(@msg,'') --#23061
       	 goto bspexit
       	 end

     -- if AP GL Co# <> 'Posted To' GL Co# get intercompany accounts
     if @glco <> @apglco
         begin
       	    select @intercoarglacct = ARGLAcct, @intercoapglacct = APGLAcct
             from bGLIA WITH (NOLOCK)
             where ARGLCo = @apglco and APGLCo = @glco
       	    if @@rowcount = 0
                begin
       		    select @errmsg = 'Intercompany Accounts not setup in GL. From:' +
   	            isnull(convert(varchar(3),@apglco), '') + ' To: ' + 
   		        isnull(convert(varchar(3),@glco), ''), @rcode = 1 --#23061
       		    goto bspexit
                end
       	    -- validate intercompany GL Accounts
             exec @rcode = bspGLACfPostable @apglco, @intercoarglacct, 'R', @msg output
             if @rcode <> 0
                begin
       	        select @errmsg = 'Intercompany AR Account:' + isnull(@intercoarglacct, '') + 
   			    ':  ' + isnull(@msg,''), @rcode = 1  --#23061
       	  	    goto bspexit
           	    end
       	    exec @rcode = bspGLACfPostable @glco, @intercoapglacct, 'P', @msg output
             if @rcode <> 0
        	    begin
       		    select @errmsg = 'Intercompany AP Account:' + isnull(@intercoapglacct, '') + 
   			    ':  ' + isnull(@msg,'')  --#23061
       		    goto bspexit
       		    end
         end

     -- validate UM
     if @um is not null
         begin
         if not exists(select 1 from bHQUM WITH (NOLOCK) where UM = @um)
             begin
             select @errmsg = 'Invalid Unit of Measure:' + isnull(@um, ''), @rcode = 1 --#23061
       	     goto bspexit
       	     end
         if @matl is not null
             begin
             select @stdum = StdUM from bHQMT WITH (NOLOCK) where MatlGroup = @matlgroup and Material = @matl
             if @@rowcount = 1 and @um <> @stdum
                 begin
                 if not exists(select 1 from bHQMU WITH (NOLOCK) where MatlGroup = @matlgroup and Material = @matl and UM = @um)
                     begin
                     select @errmsg = 'Invalid Unit of Measure for this Material:' + isnull(@matl, ''), @rcode = 1  --#23061
                     goto bspexit
       	             end
                 end
             end
         if @um = 'LS'
             begin
             if @units <> 0 or @unitcost <> 0 or @ecm is not null
                 begin
                 select @errmsg = 'Units, Unit Cost and ECM not allowed with LS', @rcode = 1
       	         goto bspexit
       	         end
             end
         end
     if @um <> 'LS' and @um is not null and @ecm not in('E', 'C', 'M')
         begin
       	select @errmsg = 'ECM must be E, C, or M!', @rcode = 1
        	goto bspexit
         end
     -- validate Supplier
     if @supplier is not null
         begin
         select @active = ActiveYN from bAPVM where VendorGroup = @suppliergroup and Vendor = @supplier
         if @@rowcount = 0 or @active = 'N'
             begin
             select @errmsg = 'Invalid or inactive Supplier:' + isnull(convert(varchar(10),@supplier), ''), @rcode = 1  
       	    goto bspexit
       	    end
         end
     -- validate Pay Type and get Payables GL Account
     select @apglacct = GLAcct from bAPPT where APCo = @apco and PayType = @paytype
     if @@rowcount = 0
         begin
         select @errmsg = 'Invalid Pay Type:' + isnull(convert(varchar(4),@paytype), ''), @rcode = 1  --#23061
       	goto bspexit
       	end
     -- validate Pay Type GL Account
     exec @rcode = bspGLACfPostable @apglco, @apglacct, 'P', @msg output
     if @rcode <> 0
         begin
       	select @errmsg = 'GL Payables Account:' + isnull(@apglacct, '') + ':  ' + isnull(@msg,''), @rcode = 1  --#23061
       	goto bspexit
       	end
   
       -- validate Tax Code
       if @taxcode is not null
   	    BEGIN
   	        --validate taxgroup based on linetype and taxtype for imports  
   	        if @linetype in (1,7) or (@linetype = 6 and @itemtype = 1)  -- job or SL
   	          begin
   		        select @taxgroupco = case @taxtype when 2 then @jcco else @apco end
   		        exec @rcode = bspHQTaxGrpGet  @taxgroupco, @taxgroupval output, @msg output
   		        if @rcode <> 0
   		        begin
   		  	        select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + isnull(@msg,''), @rcode = 1 
   	    	        goto bspexit
   		        end
   		        if @taxgroup <> @taxgroupval
   		          begin
   		            select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + ' is invalid. ', @rcode = 1 
   	    	        goto bspexit
   		          end
   	          end	
   	        if @linetype = 2 or (@linetype = 6 and @itemtype = 2) --Inventory	
   	         begin
   		        select @taxgroupco = case @taxtype when 2 then @inco else @apco end
   		        exec @rcode = bspHQTaxGrpGet @taxgroupco, @taxgroupval output, @msg output
   		        if @rcode <> 0
   		        begin
   		  	        select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + isnull(@msg,''), @rcode = 1 
   	    	        goto bspexit
   		        end
   		        if @taxgroup <> @taxgroupval
   		          begin
   		            select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + ' is invalid. ', @rcode = 1 
   	    	        goto bspexit
   		          end
   	          end
   	        if @linetype = 3 or (@linetype = 6 and (@itemtype in (3,6))) --Expense	--Mark SM Changes  TK-02798 Review this
   	         begin
   		        select @taxgroupco = case @taxtype when 2 then @glco else @apco end
   		        exec @rcode = bspHQTaxGrpGet @taxgroupco, @taxgroupval output, @msg output
   		        if @rcode <> 0
   		        begin
   		  	        select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + isnull(@msg,''), @rcode = 1 
   	    	        goto bspexit
   		        end
   		        if @taxgroup <> @taxgroupval
   		          begin
   		            select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + ' is invalid. ', @rcode = 1 
   	    	        goto bspexit
   		          end
   	          end
   	          	
   	        if @linetype in (4,5) or (@linetype = 6 and @itemtype in (4,5)) --Equip and WO
   	         begin
   		        select @taxgroupco = case @taxtype when 2 then @emco else @apco end
   		        exec @rcode = bspHQTaxGrpGet @taxgroupco, @taxgroupval output, @msg output
   		        if @rcode <> 0
   		        begin
   		  	        select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + isnull(@msg,''), @rcode = 1 
   	    	        goto bspexit
   		        end
   		        if @taxgroup <> @taxgroupval
   		          begin
   		            select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + ' is invalid. ', @rcode = 1 
   	    	        goto bspexit
   		          end
   	          end
	
		-- validate tax type for imports
		if @taxtype is not null and @taxtype not in (1,2,3)
		begin
		select @errmsg = 'Tax Type ' + isnull(convert(varchar(1),@taxtype), '') + ' is invalid.', @rcode = 1 
       	        goto bspexit
		end
    
   	    -- validate tax code
	    -- 128288 use bspHQTaxRateGetAll to return PST/GST taxrates and debit GLAccts 
   	    exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, null, @taxphase output,@taxct output, @msg output
	    exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @invdate, @valueadd output, @taxrate output, @gstrate output,
		    @pstrate output,null,null, @dbtGLAcct output,@dbtRetgGLAcct output,null, null, @crdRetgGLAcctGST output,
		    @crdRetgGLAcctPST output
           if @rcode <> 0
               begin
       	        select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + ' Tax Code: ' + 
   			        isnull(@taxcode, '') + ':  ' + isnull(@msg,''), @rcode = 1 
       	        goto bspexit
               end

        -- validate TaxType against ValueAdd - only TaxType 3 should have a Value Add tax code
            if (@taxtype <> 3 and @valueadd = 'Y') or (@taxtype = 3 and @valueadd = 'N')
            begin
	            select @errmsg = 'Tax Type is invalid for Tax Code: ' + 
   			        isnull(@taxcode, ''), @rcode = 1 
       	        goto bspexit
		    end
   	    -- get Use Tax Accrual Account
   	    if @taxtype = 2 and @taxamt <> 0
   		    begin
       	    select @taxaccrualacct = GLAcct
       	    from bHQTX
        	    where TaxGroup = @taxgroup and TaxCode = @taxcode	
   			    /*where TaxGroup = @uptaxgroup and TaxCode = @taxcode	-- should use 'posted to' Co# Tax Group*/
        	    if @@rowcount = 0
           	    begin
             	select @errmsg = 'Invalid Tax Code:' + isnull(@taxcode, ''), @rcode = 1 --#23061
       		    goto bspexit
             	end
   		    -- validate Use Tax Accrual GL Account in 'posted to' GL Co#
     		    exec @rcode = bspGLACfPostable @glco, @taxaccrualacct, 'N', @msg output
     		    if @rcode <> 0
         		begin
       		    select @errmsg = 'Use Tax Accrual Account:' + isnull(@apglacct, '') + 
   			    ':  ' + isnull(@msg,''), @rcode = 1  --#23061
       		    goto bspexit
       		    end
   		    end
   	    -- Tax Phase and Cost Type
           if @linetype in (1,7) or (@linetype = 6 and @itemtype = 1)
   		    begin
             -- use 'posted' phase and cost type unless overridden by tax code
             if @taxphase is null select @taxphase = @phase
             if @taxct is null select @taxct = @jcctype
             select @taxglacct = @glacct     -- default is 'posted' account

             if @taxphase <> @phase or @taxct <> @jcctype
   		        begin
	            -- get GL Account for Tax Expense
                     exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @taxphase, @taxct, 'N', @taxglacct output, @msg output
          	        if @rcode <> 0
  	 	                begin
   	        	        select @errmsg = 'Tax GL Account ' + isnull(@msg,''), @rcode = 1
                         goto bspexit
                         end
                     -- validate Tax Account
                     exec @rcode = bspGLACfPostable @glco, @taxglacct, 'J', @msg output
   		            if @rcode <> 0
   	       		        begin
   		                select @errmsg = 'Tax GL Account:' + isnull(@taxglacct, '') + ':  ' + isnull(@msg,''), @rcode = 1 --#23061
                         goto bspexit
   		                end
                     -- validate tax phase/cost type
                     exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @taxphase, @taxct,  @errmsg=@msg output
                     if @rcode <> 0
                        begin
                        select @errmsg ='Job/Tax Phase/CT not setup' + isnull(@msg,''), @rcode = 1
                        goto bspexit
                        end
                 end
             end
    	END -- end taxcode validation                                   
   
   if @taxcode is null 
        BEGIN
   	        if @linetype = 6 and @itemtype = 1 and @potaxgroup is not null and @potaxcode is not null	
   	        Begin
	        exec @rcode = bspHQTaxRateGet @potaxgroup, @potaxcode, @invdate, null, @taxphase output,@taxct output, @msg output
	        if @rcode <> 0
                begin
    	        select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@potaxgroup), '') + 
		        ' Tax Code: ' + isnull(@potaxcode, '') + ':  ' + isnull(@msg,''), @rcode = 1  
    	        goto bspexit
                end
            End

            if @linetype = 7 and @sltaxgroup is not null and @sltaxcode is not null	
            Begin
	        exec @rcode = bspHQTaxRateGet @sltaxgroup, @sltaxcode, @invdate, null, @taxphase output,@taxct output, @msg output
	        if @rcode <> 0
                begin
    	        select @errmsg = ' Tax Group:' + isnull(convert(varchar(3),@sltaxgroup), '') + 
		        ' Tax Code: ' + isnull(@sltaxcode, '') + ':  ' + isnull(@msg,''), @rcode = 1  
    	        goto bspexit
                end
            End

  	        if (@linetype = 6 and @itemtype = 1 and @potaxgroup is not null and @potaxcode is not null) or
				(@linetype = 7 and @sltaxgroup is not null and @sltaxcode is not null)
			begin	
				if @taxphase is null
					begin
					select @taxphase = @phase
					end
				if @taxct is null	
					begin
    				select @taxct = @jcctype
					end
				-- get GL Account for Tax Expense
				   exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @taxphase, @taxct, 'N', @taxglacct output, @msg output
      				if @rcode <> 0
 						begin
        				select @errmsg = 'Tax GL Account ' + isnull(@msg,''), @rcode = 1
						 goto bspexit
						 end
				   -- validate Tax Account
				   exec @rcode = bspGLACfPostable @glco, @taxglacct, 'J', @msg output
					if @rcode <> 0
       					begin
						select @errmsg = 'Tax GL Account:' + isnull(@taxglacct, '') + ':  ' + isnull(@msg,''), @rcode = 1 --#23061
						 goto bspexit
						end
					-- validate tax phase/cost type
				   exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @taxphase, @taxct,  @errmsg=@msg output
					 if @rcode <> 0
						begin
						select @errmsg ='Job/Tax Phase/CT not setup' + isnull(@msg,''), @rcode = 1
						goto bspexit
						end
				end
        END
--   	else
--   		begin
--       	select @taxphase = @phase
--       	select @taxct = @jcctype
--   		end
      
   
     -- validate Retainage info
     if @retainage <> 0
	 BEGIN
         begin
         exec @rcode = bspHQHoldCodeVal @retholdcode, @msg output
       	if @rcode <> 0
             begin
       	    select @errmsg = 'Retainage Hold Code : ' + isnull(@msg,''), @rcode = 1
       	    goto bspexit
       	    end
         end

       -- Retainage Payable Type
   	  if @paycategory is not null
   		begin
   		exec @rcode = bspAPPayTypeValForPayCategory @apco, @paycategory, @retpaytype, @retglacct output, @msg output 
   		if @rcode <> 0
       	    begin
       		select @errmsg = 'Retainage Pay Type: ' + isnull(convert(varchar(3), @retpaytype),'') 
   				+ ' ' + isnull(@msg,''), @rcode = 1
       		goto bspexit
       	    end
   		end
   	  else
   		begin
   		  exec @rcode = bspAPPayTypeVal @apco, @retpaytype, @retglacct output, @msg output
   		  if @rcode <> 0
   			    begin
   				select @errmsg = 'Retainage Pay Type:' + isnull(convert(varchar(3), @retpaytype),'') + ' ' + isnull(@msg,''), @rcode = 1
   				goto bspexit
   			    end
   		end

         -- Retainage Payable GL Account
       	exec @rcode = bspGLACfPostable @apglco, @retglacct, 'P', @msg output
         if @rcode <> 0
       		begin
       		select @errmsg = 'Retainage Payable GL Account:' + isnull(@retglacct, '') + 
   			':  ' + isnull(@msg,''), @rcode = 1  --#23061
       		goto bspexit
       		end
	 END

     -- validate Discount Offered GL Account
     if @discount <> 0 and @netamtopt = 'Y'   -- only used if interfacing net
         begin
         exec @rcode = bspGLACfPostable @apglco, @discoffglacct, 'N', @msg output
         if @rcode <> 0
             begin
             select @errmsg = 'Discount Offered GL Account:' + isnull(@discoffglacct, '') + 
   			':  ' + isnull(@msg,''), @rcode = 1  --#23061
             goto bspexit
             end
         end
   
     bspexit:
         return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspAPLBValNew] TO [public]
GO
