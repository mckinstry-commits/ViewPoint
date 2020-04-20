SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBValTrans    Script Date: 8/28/99 9:34:01 AM ******/
   CREATE  procedure [dbo].[bspAPLBValTrans]
   /***********************************************************
    * CREATED BY: GG 06/28/99
    * MODIFIED By:  kb 10/28/2 - issue #18878 - fix double quotes
    * 				MV 02/10/04 - #18769 Pay Category
    *				GP 6/28/10 - #135813 change bSL to varchar(30) 
    *				GF 08/04/2011 - TK-07144 EXPAND PO
    *				MH 08/09/11 - TK-07482 Replace MiscellaneousType with SMCostType
    *				MV 08/10/11 - TK-07621 AP project to use POItemLine
    *
    * USAGE:
    * Called from bspAPLBVal to validate that 'old' batch values
    * match existing AP Trans Line values.
    *
    *
    * INPUT PARAMETERS:
    *  @apco               AP Company
    *  @mth                Batch month
    *  @batchid            Batch ID#
    *  @batchseq           Batch sequence
    *  @aptrans            AP Transaction
    *  @apline             AP Trans Line to match
    *
    * OUTPUT PARAMETERS
    *    @errmsg           error message
    *
    * RETURN VALUE
    *    0                 success
    *    1                 failure
    *****************************************************/
     @apco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @aptrans bTrans,
     @apline smallint, @errmsg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int
   
   -- APLB declares
   declare @oldlinetype tinyint, @oldpo VARCHAR(30), @oldpoitem bItem, @OldPOItemLine INT, @olditemtype tinyint, @oldsl varchar(30), @oldslitem bItem,
   @oldjcco bCompany, @oldjob bJob, @oldphasegroup bGroup, @oldphase bPhase, @oldjcctype bJCCType, @oldemco bCompany,
   @oldwo bWO, @oldwoitem bItem, @oldequip bEquip, @oldemgroup bGroup, @oldcostcode bCostCode, @oldemctype bEMCType,
   @oldcomptype varchar(10), @oldcomponent bEquip, @oldinco bCompany, @oldloc bLoc, @oldmatlgroup bGroup,
   @oldmaterial bMatl, @oldglco bCompany, @oldglacct bGLAcct, @oldlinedesc bDesc, @oldum bUM, @oldunits bUnits,
   @oldunitcost bUnitCost, @oldecm bECM, @oldvendorgroup bGroup, @oldsupplier bVendor, @oldpaytype tinyint,
   @oldgrossamt bDollar, @oldmiscamt bDollar, @oldmiscyn bYN, @oldtaxgroup bGroup, @oldtaxcode bTaxCode,
   @oldtaxtype tinyint, @oldtaxbasis bDollar, @oldtaxamt bDollar, @oldretainage bDollar, @olddiscount bDollar,
   @oldburunitcost bUnitCost, @oldbecm bECM, @oldpaycategory int, 
   @oldsmco bCompany, @oldsmworkorder int, @oldsmscope int, @oldsmcosttype smallint, @oldSMStandardItem varchar(20)
   
   -- APTL declares
   declare @tllinetype tinyint, @tlpo VARCHAR(30), @tlpoitem bItem, @TLPOItemLine INT, @tlitemtype tinyint, @tlsl varchar(30), @tlslitem bItem,
   @tljcco bCompany, @tljob bJob, @tlphasegroup bGroup, @tlphase bPhase, @tljcctype bJCCType, @tlemco bCompany,
   @tlequip bEquip, @tlemgroup bGroup, @tlcostcode bCostCode, @tlemctype bEMCType, @tlcomptype varchar(10),
   @tlcomp bEquip, @tlinco bCompany, @tlloc bLoc, @tlmatlgroup bGroup, @tlmatl bMatl, @tlglco bCompany,
   @tlglacct bGLAcct, @tlum bUM, @tlunits bUnits, @tlunitcost bUnitCost, @tlecm bECM, @tlvendorgroup bGroup,
   @tlsupplier bVendor, @tlpaytype tinyint, @tlgrossamt bDollar, @tlmiscamt bDollar, @tlmiscyn bYN,
   @tltaxgroup bGroup, @tltaxcode bTaxCode, @tltaxtype tinyint,  @tltaxamt bDollar, @tlretainage bDollar,
   @tldisc bDollar, @tlburunitcost bUnitCost, @tlbecm bECM, @tlpaycategory int, @tlsmco bCompany,
   @tlsmworkorder int, @tlsmscope int, @tlsmcosttype smallint, @tlsmstandarditem varchar(20)
   
   select @rcode = 0
   
   -- get 'old' values from AP Line Batch
   select @oldlinetype = OldLineType, @oldpo = OldPO, @oldpoitem = OldPOItem, @OldPOItemLine = OldPOItemLine, @olditemtype = OldItemType,
       @oldsl = OldSL, @oldslitem = OldSLItem, @oldjcco = OldJCCo, @oldjob = OldJob, @oldphasegroup = OldPhaseGroup,
       @oldphase = OldPhase, @oldjcctype = OldJCCType, @oldemco = OldEMCo, @oldequip = OldEquip, @oldemgroup = OldEMGroup,
       @oldcostcode = OldCostCode, @oldemctype = OldEMCType, @oldcomptype = OldCompType, @oldcomponent = OldComponent,
       @oldinco = OldINCo, @oldloc = OldLoc, @oldmatlgroup = OldMatlGroup, @oldmaterial = OldMaterial, @oldglco = OldGLCo,
       @oldglacct = OldGLAcct, @oldum = OldUM, @oldunits = OldUnits, @oldunitcost = OldUnitCost, @oldecm = OldECM,
       @oldvendorgroup = OldVendorGroup, @oldsupplier = OldSupplier, @oldpaytype = OldPayType, @oldgrossamt = OldGrossAmt,
       @oldmiscamt = OldMiscAmt, @oldmiscyn = OldMiscYN, @oldtaxgroup = OldTaxGroup, @oldtaxcode = OldTaxCode,
       @oldtaxtype = OldTaxType, @oldtaxamt = OldTaxAmt, @oldretainage = OldRetainage, @olddiscount = OldDiscount,
       @oldburunitcost = OldBurUnitCost, @oldbecm = OldBECM, @oldpaycategory = OldPayCategory, @oldsmco = OldSMCo, 
       @oldsmworkorder = OldSMWorkOrder, @oldsmscope = OldScope, @oldsmcosttype = OldSMCostType, @oldSMStandardItem = OldSMStandardItem
   from bAPLB
   where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and APLine = @apline
   if @@rowcount = 0
       begin
       select @errmsg = ' Missing entry in AP Line Batch!', @rcode = 1
       goto bspexit
       end
   -- get existing values from AP Transaction Line
   select @tllinetype = LineType, @tlpo = PO, @tlpoitem = POItem, @TLPOItemLine = POItemLine, @tlitemtype = ItemType, @tlsl = SL,
       @tlslitem = SLItem, @tljcco = JCCo, @tljob = Job, @tlphasegroup = PhaseGroup, @tlphase = Phase,
       @tljcctype = JCCType, @tlemco = EMCo, @tlequip = Equip, @tlemgroup = EMGroup, @tlcostcode = CostCode,
       @tlemctype = EMCType, @tlcomptype = CompType, @tlcomp = Component, @tlinco = INCo, @tlloc = Loc,
       @tlmatlgroup = MatlGroup, @tlmatl = Material, @tlglco = GLCo, @tlglacct = GLAcct, @tlum = UM,
       @tlunits = Units, @tlunitcost = UnitCost, @tlecm = ECM, @tlvendorgroup = VendorGroup,
       @tlsupplier = Supplier, @tlpaytype = PayType, @tlgrossamt = GrossAmt, @tlmiscamt = MiscAmt,
       @tlmiscyn = MiscYN, @tltaxgroup = TaxGroup, @tltaxcode = TaxCode, @tltaxtype = TaxType,@tltaxamt = TaxAmt,
   	@tlretainage = Retainage, @tldisc = Discount, @tlburunitcost = BurUnitCost, @tlbecm = BECM,
   	@tlpaycategory = PayCategory, @tlsmco = SMCo, @tlsmworkorder = SMWorkOrder , @tlsmscope = Scope,
   	@tlsmcosttype = SMCostType, @tlsmstandarditem = SMStandardItem
   from bAPTL
   where APCo = @apco and Mth = @mth and APTrans = @aptrans and APLine = @apline
   if @@rowcount = 0
       begin
       select @errmsg = ' Missing Transaction Line.', @rcode = 1
       goto bspexit
       end
   -- compare 'old' batch values to existing line values
   if @tllinetype <> @oldlinetype or isnull(@tlpo,'') <> isnull(@oldpo,'') or isnull(@tlpoitem,0) <> isnull(@oldpoitem,0)
		OR ISNULL(@TLPOItemLine,0) <> ISNULL(@OldPOItemLine,0)
       or isnull(@tlsl,'') <> isnull(@oldsl,'') or isnull(@tlslitem,0) <> isnull(@oldslitem,0)
       or isnull(@tljcco,0) <> isnull(@oldjcco,0) or isnull(@tljob,'') <> isnull(@oldjob,'')
       or isnull(@tlphasegroup,0) <> isnull(@oldphasegroup,0) or isnull(@tlphase,'') <> isnull(@oldphase,'')
       or isnull(@tljcctype,0) <> isnull(@oldjcctype,0) or isnull(@tlemco,0) <> isnull(@oldemco,0)
       or isnull(@tlequip,'') <> isnull(@oldequip,'') or isnull(@tlemgroup,0) <> isnull(@oldemgroup,0)
       or isnull(@tlcostcode,'') <> isnull(@oldcostcode,'') or isnull(@tlemctype,0) <> isnull(@oldemctype,0)
       or isnull(@tlcomptype,'') <> isnull(@oldcomptype,'') or isnull(@tlcomp,'') <> isnull(@oldcomponent,'')
       or isnull(@tlinco,0) <> isnull(@oldinco,0) or isnull(@tlloc,'') <> isnull(@oldloc,'')
       or isnull(@tlmatlgroup,0) <> isnull(@oldmatlgroup,0) or isnull(@tlmatl,'') <> isnull(@oldmaterial,'')
   
       or @tlglco <> @oldglco or @tlglacct <> @oldglacct or isnull(@tlum,'') <> isnull(@oldum,'')
       or @tlunits <> @oldunits or @tlunitcost <> @oldunitcost or isnull(@tlecm,'') <> isnull(@oldecm,'')
       or isnull(@tlvendorgroup,0) <> isnull(@oldvendorgroup,0) or isnull(@tlsupplier,0) <> isnull(@oldsupplier,0)
       or @tlpaytype <> @oldpaytype or @tlgrossamt <> @oldgrossamt or @tlmiscamt <> @oldmiscamt
       or @tlmiscyn <> @oldmiscyn or isnull(@tltaxgroup,0) <> isnull(@oldtaxgroup,0)
       or isnull(@tltaxcode,'') <> isnull(@oldtaxcode,'') or isnull(@tltaxtype,0) <> isnull(@oldtaxtype,0)
       or @tltaxamt <> @oldtaxamt or @tlretainage <> @oldretainage or @tldisc <> @olddiscount
       or @tlburunitcost <> @oldburunitcost or isnull(@tlbecm,'') <> isnull(@oldbecm,'')
   	   or isnull(@tlpaycategory,0) <> isnull(@oldpaycategory,0)
   	   or isnull(@tlsmco, 0) <> isnull(@oldsmco, 0) or isnull(@tlsmworkorder,-1) <> isnull(@oldsmworkorder,-1)
   	   or isnull(@tlsmscope,-1) <> isnull(@oldsmscope,-1) or isnull(@tlsmcosttype,'') <> isnull(@oldsmcosttype,'')
   	   or isnull(@tlsmstandarditem,'') <> isnull(@oldSMStandardItem, '')
       begin
       select @errmsg = '- Batch information does not match existing Line.', @rcode = 1
       goto bspexit
       end
   
   bspexit:
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspAPLBValTrans] TO [public]
GO
