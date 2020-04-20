SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBValEMInsert    Script Date: 8/28/99 9:34:00 AM ******/
   
   CREATE procedure [dbo].[bspAPLBValEMInsert]
/***********************************************************
* CREATED BY:	GG	06/23/1999
* MODIFIED By:	GG	06/20/2000	- Added parameters and update for tax columns
*               GR	11/21/2000	- changed datatype from bAPRef to bAPReference
*				GF	08/04/2011	- TK-07144 EXPAND PO
*				CHS	08/10/2011	- TK-07620 - added POItemLine
*
* USAGE:
* Called from bspAPLBVal to update/insert EM distributions
* into bAPEM for an AP Transaction Entry batch.
*
* INPUT PARAMETERS:
*  @apco                   AP Company
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
*  @POItemLine			   PO Item Line
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
*
* OUTPUT PARAMETERS
*  none
*
* RETURN VALUE
*  0                       success
*  1                       failure
*****************************************************/
     @apco bCompany, @mth bMonth, @batchid bBatchID, @emco bCompany, @equip bEquip,
     @emgroup bGroup, @costcode bCostCode, @emctype bEMCType, @batchseq int, @apline smallint,
     @oldnew tinyint, @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor,  @apref bAPReference,
     @transdesc bDesc, @invdate bDate, @po VARCHAR(30), @poitem bItem, @POItemLine int, @wo bWO, @woitem bItem,
     @comptype varchar(10), @component bEquip, @matlgroup bGroup, @matl bMatl, @linedesc bDesc,
     @glco bCompany, @glacct bGLAcct, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM,
     @emum bUM, @emunits bUnits, @amt bDollar, @taxgroup bGroup, @taxcode bTaxCode,
     @taxtype tinyint, @taxbasis bDollar, @taxamt bDollar
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- update AP EM Distributions
   update bAPEM
   set TotalCost = TotalCost + @amt, TaxBasis = TaxBasis + @taxbasis, TaxAmt = TaxAmt + @taxamt
   where APCo = @apco and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equip = @equip
       and EMGroup = @emgroup and CostCode = @costcode and EMCType = @emctype
       and BatchSeq = @batchseq and APLine = @apline and OldNew = @oldnew
   if @@rowcount = 0
       insert bAPEM (APCo, Mth, BatchId, EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, APLine, OldNew,
           APTrans, VendorGroup, Vendor, APRef, TransDesc, InvDate, PO, POItem, POItemLine, WO, WOItem,
           CompType, Component, MatlGroup, Material, LineDesc, GLCo, GLAcct, UM, Units, UnitCost,
           ECM, EMUM, EMUnits, TotalCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt)
       values(@apco, @mth, @batchid, @emco, @equip, @emgroup, @costcode, @emctype, @batchseq, @apline, @oldnew,
           @aptrans, @vendorgroup, @vendor, @apref, @transdesc, @invdate, @po, @poitem, @POItemLine, @wo, @woitem,
           @comptype, @component, @matlgroup, @matl, @linedesc, @glco, @glacct, @um, @units, @unitcost,
           @ecm, @emum, @emunits, @amt, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt)
   
   
   bspexit:
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPLBValEMInsert] TO [public]
GO
