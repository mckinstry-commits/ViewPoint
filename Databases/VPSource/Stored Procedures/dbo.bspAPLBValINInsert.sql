SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBValINInsert    Script Date: 8/28/99 9:34:00 AM ******/
   
   CREATE procedure [dbo].[bspAPLBValINInsert]
/***********************************************************
* CREATED BY:	GG	06/23/1999
* MODIFIED By:	GG	06/16/2000	- modified for changes to bAPIN
*               GR	11/21/2000	- changed datatype from bAPRef to bAPReference
*				GF	08/04/2011	- TK-07144 EXPAND PO
*				CHS	08/10/2011	- TK-07620 - added POItemLine
*
* USAGE:
* Called from bspAPLBVal to update/insert IN distributions
* into bAPIN for an AP Transaction Entry batch.
*
* INPUT PARAMETERS:
*  @apco                   AP Company
*  @mth                    Batch month
*  @batchid                Batch ID#
*  @inco                   Posted To IN Co#
*  @loc                    Equipment
*  @matlgroup              Material Group
*  @matl                   Material
*  @batchseq               Batch sequence
*  @apline                 AP Line #
*  @oldnew                 0 = old, 1 = new
*  @aptrans                AP Transaction #
*  @vendorgroup            Vendor Group
*  @vendor                 Vendor #
*  @apref                  AP Reference
*  @invdate                Invoice Date
*  @po                     Purchase Order
*  @poitem                 PO Item
*  @POItemLine             PO Item Line
*  @linedesc               Line description
*  @glco                   JC GL Co#
*  @glacct                 Job expense GL Account
*  @um                     Posted unit of measure
*  @units                  Posted units
*  @unitcost               Posted Unit Cost - may include burden
*  @ecm                    Posted Unit Cost per E, C, or M
*  @totalcost              Posted total cost - may include burden
*  @stdum                  Standard unit of measure
*  @stdunits               Standard units - converted from posted units
*  @stdunitcost            Standard Unit Cost used to update Inventory - will be posted or standard
*  @stdecm                 Standard Unit Cost per E, C, or M
*  @stdtotalcost           Total cost used to update Inventory - will be posted or extended std cost
*
* OUTPUT PARAMETERS
*  none
*
* RETURN VALUE
*  0                       success
*  1                       failure
*****************************************************/
     @apco bCompany, @mth bMonth, @batchid bBatchID, @inco bCompany, @loc bLoc,
     @matlgroup bGroup, @matl bMatl, @batchseq int, @apline smallint, @oldnew tinyint,
     @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor,  @apref bAPReference, @transdesc bDesc, @invdate bDate,
     @po VARCHAR(30), @poitem bItem, @POItemLine int, @linedesc bDesc, @glco bCompany, @glacct bGLAcct, @um bUM,
     @units bUnits, @unitcost bUnitCost, @ecm bECM, @totalcost bDollar, @stdum bUM, @stdunits bUnits,
     @stdunitcost bUnitCost, @stdecm bECM, @stdtotalcost bDollar
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- update AP IN Distributions
   insert bAPIN (APCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq, APLine, OldNew,
       APTrans, VendorGroup, Vendor, APRef, InvDate, PO, POItem, POItemLine, LineDesc, GLCo, GLAcct,
       UM, Units, UnitCost, ECM, TotalCost, StdUM, StdUnits, StdECM, StdUnitCost, StdTotalCost)
   values(@apco, @mth, @batchid, @inco, @loc, @matlgroup, @matl, @batchseq, @apline, @oldnew,
       @aptrans, @vendorgroup, @vendor, @apref, @invdate, @po, @poitem, @POItemLine, @linedesc, @glco, @glacct,
       @um, @units, @unitcost, @ecm, @totalcost, @stdum, @stdunits, @stdecm, @stdunitcost, @stdtotalcost)
   
   bspexit:
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPLBValINInsert] TO [public]
GO
