SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpValGLInsert    Script Date: 8/28/99 9:34:00 AM ******/
   CREATE  procedure [dbo].[bspPORBExpValGLInsert]
   /***********************************************************
    * CREATED BY: DANF 04/23/01
    * MODIFIED By : DANF 02/20/03 - Issue 20294 - Add Column PO and POItem
    *				GF 07/27/2011 TK-07030
    *
    * USAGE:
    * Called from bspPORBVal to update/insert GL distributions
    * into bPORG for an PO Receiving Entry batch.
    *
    * INPUT PARAMETERS:
    *  @poco                     AP Company
    *  @mth                    Batch month
    *  @batchid                Batch ID#
    *  @glco                   Posted To GL Co#
    *  @glacct                 GL Account - all distributions except Intercompany AP/AR
    *  @batchseq               Batch sequence
    *  @potrans                PO Line #
    *  @oldnew                 0 = old, 1 = new
    *  @vendorgroup            Vendor Group
    *  @vendor                 Vendor #
    *  @polinetype             PO Item type
    *  @porbdesc               description
    *  @porbrecdate            receive date
    *  @porbreceiver           reciever number
    *  @jcco                   JC Co#
    *  @job                    Job
    *  @phasegroup             Phase Group
    *  @phase                  Phase
    *  @jcctype                JC Cost Type
    *  @emco                   EM Co#
    *  @equip                  Equipment
    *  @emgroup                EM Group
    *  @costcode               EM Cost Code
    *  @emctype                EM Cost Type
    *  @inco                   IN Co#
    *  @loc                    Location
    *  @matlgroup              Material Group
    *  @matl                   Material
    *  @amt                    Amount - passed as negative for credit, positive for debit
    *  @apglco                 AP GL Co#
    *  @intercoarglacct        Intercompany AR GL Account
    *  @intercoapglacct        Intercompany AP GL Account
    *  @po						PO number
    *  @poitem 				PO Item
    *  @POItemLine			PO Item Line
    *
    * OUTPUT PARAMETERS
    *  none
    *
    * RETURN VALUE
    *  0                       success
    *  1                       failure
    *****************************************************/
     @poco bCompany, @mth bMonth, @batchid bBatchID, @glco bCompany, @glacct bGLAcct,
     @batchseq int, @apline smallint, @oldnew tinyint, @potrans bTrans, @vendorgroup bGroup,
     @vendor bVendor, @sortname varchar(15),
     @polinetype tinyint, @porbdesc bDesc, @porbrecdate bDate, @porbreceiver varchar(20), @jcco bCompany, @job bJob,
     @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @emco bCompany, @equip bEquip,
     @emgroup bGroup, @costcode bCostCode, @emctype bEMCType, @inco bCompany, @loc bLoc,
     @matlgroup bGroup, @matl bMatl, @amt bDollar, @apglco bCompany, @intercoarglacct bGLAcct,
     @intercoapglacct bGLAcct, @po VARCHAR(30), @poitem bItem,
     @POItemLine INT = null
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- update PO GL Distributions
   update bPORG
   set TotalCost = TotalCost + isnull(@amt,0)
   where POCo = @poco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
       and BatchSeq = @batchseq 
       and isnull(POTrans,'') = isnull(@potrans,'') and isnull(APLine,'') = isnull(@apline,'') and isnull(OldNew,'') = isnull(@oldnew,'')  --DC #132611
   if @@rowcount = 0
       insert bPORG
       values(@poco, @mth, @batchid, @glco, @glacct, @batchseq, @apline, @oldnew, @potrans, @vendorgroup,
           @vendor, @sortname, @polinetype, @porbdesc, @porbrecdate, @porbreceiver, @jcco,
           @job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
           @loc, @matlgroup, @matl, isnull(@amt,0), @po, @poitem, @POItemLine)
   
   -- if 'Posted to' and AP GL Co#s are not equal, update Intercompany distributions
   if @glco <> @apglco
       begin
       -- Intercompany Payables - Credit in 'posted to' GL Co#
       update bPORG
       set TotalCost = TotalCost - isnull(@amt,0)
       where POCo = @poco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @intercoapglacct
           and BatchSeq = @batchseq 
           and isnull(POTrans,'') = isnull(@potrans,'') and isnull(APLine,'') = isnull(@apline,'') and isnull(OldNew,'') = isnull(@oldnew,'')  --DC #132611
       if @@rowcount = 0
           insert bPORG
           values(@poco, @mth, @batchid, @glco, @intercoapglacct, @batchseq, @apline, @oldnew, @potrans, @vendorgroup,
               @vendor, @sortname, @polinetype, @porbdesc, @porbrecdate, @porbreceiver, @jcco,
               @job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
        @loc, @matlgroup, @matl, isnull((-1 * @amt),0), @po, @poitem, @POItemLine)
       -- Intercompany Receivables - Debit in AP GL Co#
       update bPORG
       set TotalCost = TotalCost + isnull(@amt,0)
       where POCo = @poco and Mth = @mth and BatchId = @batchid and GLCo = @apglco and GLAcct = @intercoarglacct
           and BatchSeq = @batchseq 
           and isnull(POTrans,'') = isnull(@potrans,'') and isnull(APLine,'') = isnull(@apline,'') and isnull(OldNew,'') = isnull(@oldnew,'')  --DC #132611
       if @@rowcount = 0
           insert bPORG
           values(@poco, @mth, @batchid, @apglco, @intercoarglacct, @batchseq, @apline, @oldnew, @potrans, @vendorgroup,
               @vendor, @sortname, @polinetype, @porbdesc, @porbrecdate, @porbreceiver, @jcco,
               @job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
               @loc, @matlgroup, @matl, isnull(@amt,0), @po, @poitem, @POItemLine)
       end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPORBExpValGLInsert] TO [public]
GO
