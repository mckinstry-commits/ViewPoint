SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpValINInsert    Script Date: 8/28/99 9:34:00 AM ******/
   
   CREATE procedure [dbo].[bspPORBExpValINInsert]
   /***********************************************************
    * CREATED BY: DANF 04/16/01
    * MODIFIED By : TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				GF 08/22/2011 TK-07879 PO ITEM LINE
    *
    *
    * USAGE:
    * Called from bspPORBVal to update/insert IN distributions
    * into bPORN for an PO Reciept Entry batch.
    *
    * INPUT PARAMETERS:
    *  @poco                   PO Company
    *  @mth                    Batch month
    *  @batchid                Batch ID#
    *  @inco                   Posted To IN Co#
    *  @loc                    Equipment
    *  @matlgroup              Material Group
    *  @matl                   Material
    *  @batchseq               Batch sequence
    *  @potrans                PO trasnactrion
    *  @oldnew                 0 = old, 1 = new
    *  @vendorgroup            Vendor Group
    *  @vendor                 Vendor #
    *  @po                     Purchase Order
    *  @poitem                 PO Item
    *  @desc                   description
    *  @recdate                receipt date
    *  @receiver#              receiver number
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
    *  @stdtotalcost            Total cost used to update Inventory - will be posted or extended std cost
    *  @POItemLine				PO Item Line
    *
    * OUTPUT PARAMETERS
    *  none
    *
    * RETURN VALUE
    *  0                       success
    *  1                       failure
    *****************************************************/
     @poco bCompany, @mth bMonth, @batchid bBatchID, @inco bCompany, @loc bLoc,
     @matlgroup bGroup, @matl bMatl, @batchseq int, @apline smallint, @oldnew tinyint,
     @potrans bTrans, @vendorgroup bGroup, @vendor bVendor,
     @po varchar(30), @poitem bItem, @glco bCompany, @glacct bGLAcct, @um bUM,
     @units bUnits, @porbdesc bDesc, @porbrecdate bDate, @porbreceiver varchar(20),
     @unitcost bUnitCost, @ecm bECM, @totalcost bDollar, @stdum bUM, @stdunits bUnits,
     @stdunitcost bUnitCost, @stdecm bECM, @stdtotalcost bDollar,
     ----TK-07879
     @POItemLine INT
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- update PO IN Distributions
   insert bPORN (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq, APLine, OldNew,
			VendorGroup, Vendor, POTrans, PO, POItem, Description, RecDate, Receiver#, GLCo, GLAcct,
			UM, Units, UnitCost, ECM, TotalCost, StdUM, StdUnits, StdECM, StdUnitCost, StdTotalCost,
			----TK-07879
			POItemLine)
   values(@poco, @mth, @batchid, @inco, @loc, @matlgroup, @matl, @batchseq, @apline, @oldnew,
			@vendorgroup, @vendor, @potrans, @po, @poitem, @porbdesc, @porbrecdate,  @porbreceiver,
			@glco, @glacct, @um, @units, @unitcost, @ecm, @totalcost, @stdum, @stdunits, @stdecm,
			@stdunitcost, @stdtotalcost,
			----TK-07879
			@POItemLine)



bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpValINInsert] TO [public]
GO
