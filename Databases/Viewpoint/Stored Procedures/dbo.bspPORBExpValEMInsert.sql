SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpValEMInsert    Script Date: 8/28/99 9:34:00 AM ******/
   
   CREATE procedure [dbo].[bspPORBExpValEMInsert]
   /***********************************************************
    * CREATED BY: DANF 04/23/01
    * MODIFIED By:	DC 3/9/09 #132611 - I get an error when I Validate PO  batch.
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				GF 08/22/2011 TK-07879 PO ITEM LINE
    *
    *
    * USAGE:
    * Called from bspPORBVal to update/insert EM distributions
    * into bPORE for an PO Receipt entry.
    *
    * INPUT PARAMETERS:
    *  @poco                   AP Company
    *  @mth                    Batch month
    *  @batchid                Batch ID#
    *  @emco                   Posted To EM Co#
    *  @equip                  Equipment
    *  @emgroup                EM Group
    *  @costcode               Cost Code
    *  @emctype                EM Cost Type
    *  @batchseq               Batch sequence
    *  @apline                 AP Line #
    *  @oldnew                 0 = old, 1 = new
    *  @aptrans                AP Transaction #
    *  @vendorgroup            Vendor Group
    *  @vendor                 Vendor #
    *  @apref                  AP Reference
    *  @transdesc              Transaction description
    *  @invdate                Invoice Date
    *  @po                     Purchase Order
    *  @poitem                 PO Item
    *  @wo                     Work Order
    *  @woitem                 Work Order Item
    *  @comptype               Component Type
    *  @component              Component
    *  @matlgroup              Material Group
    *  @matl                   Material
    *  @linedesc               Line description
    *  @glco                   JC GL Co#
    *  @glacct                 Job expense GL Account
    *  @um                     Posted unit of measure
    *  @units                  Posted units
    *  @unitcost               Unit Cost
    *  @ecm                    Unit Cost per E, C, or M
    *  @emum                   EM Unit of Measure
    *  @emunits                EM Units - 0 if posted u/m <> EM u/m
    *  @amt                    Actual Cost
    *  @taxgroup               Tax Group
    *  @taxcode                Tax Code
    *  @taxtype                Tax Type, null = no tax, 1 = sales, 2 = use
    *  @taxbasis               Tax Basis
    *  @taxamt                 Tax Amount
    *  @POItemLine				PO Item Line
    *
    * OUTPUT PARAMETERS
    *  none
    *
    * RETURN VALUE
    *  0                       success
    *  1                       failure
    *****************************************************/
     @poco bCompany, @mth bMonth, @batchid bBatchID, @emco bCompany, @equip bEquip,
     @emgroup bGroup, @costcode bCostCode, @emctype bEMCType, @batchseq int, @apline smallint,
     @oldnew tinyint,  @potrans bTrans, @vendorgroup bGroup, @vendor bVendor,
     @recdate bDate, @porbreceiver# varchar(20), @po varchar(30), @poitem bItem, @wo bWO, @woitem bItem,
     @comptype varchar(10), @component bEquip, @matlgroup bGroup, @matl bMatl, @porbdesc bDesc,
     @glco bCompany, @glacct bGLAcct, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM,
     @emum bUM, @emunits bUnits, @amt bDollar, @taxgroup bGroup, @taxcode bTaxCode,
     @taxtype tinyint, @taxbasis bDollar, @taxamt bDollar,
     ----TK-07879
     @POItemLine INT
   
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- update PORE EM Distributions
   update bPORE
   set TotalCost = TotalCost + @amt, TaxBasis = TaxBasis + @taxbasis, TaxAmt = TaxAmt + @taxamt
   where POCo = @poco and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equip = @equip
       and EMGroup = @emgroup and CostCode = @costcode and EMCType = @emctype
       and BatchSeq = @batchseq 
       and isnull(POTrans,'') = isnull(@potrans,'') and isnull(APLine,'') = isnull(@apline,'') and isnull(OldNew,'') = isnull(@oldnew,'')  --DC #132611
   if @@rowcount = 0
       insert bPORE (POCo, Mth, BatchId, EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, APLine, OldNew,
			VendorGroup, Vendor, POTrans,  PO, POItem, WO, WOItem,
			CompType, Component, MatlGroup, Material, Description, GLCo, GLAcct, UM, Units, UnitCost,
			ECM, EMUM, EMUnits, TotalCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt, Receiver#, RecDate,
			----TK-07879
			POItemLine)
       values(@poco, @mth, @batchid, @emco, @equip, @emgroup, @costcode, @emctype, @batchseq, @apline, @oldnew,
			@vendorgroup, @vendor, @potrans, @po, @poitem, @wo, @woitem,
			@comptype, @component, @matlgroup, @matl, @porbdesc, @glco, @glacct, @um, @units, @unitcost,
			@ecm, @emum, @emunits, @amt, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
			@porbreceiver#, @recdate,
			----TK-07879
			@POItemLine)

   
   bspexit:
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpValEMInsert] TO [public]
GO
