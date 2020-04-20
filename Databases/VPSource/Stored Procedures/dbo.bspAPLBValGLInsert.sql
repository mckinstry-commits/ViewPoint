SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPLBValGLInsert    Script Date: 8/28/99 9:34:00 AM ******/
   CREATE procedure [dbo].[bspAPLBValGLInsert]
   /***********************************************************
    * CREATED BY: GG 06/23/99
    * MODIFIED By: GR 11/21/00 - changed datatype from bAPRef to bAPReference
    *				GG 09/21/01 - #14461 - post 'use' tax accrual to expense GL Co#
    *
    * USAGE:
    * Called from bspAPLBVal to update/insert GL distributions
    * into bAPGL for an AP Transaction Entry batch.
    *
    * INPUT PARAMETERS:
    *  @apco                     AP Company
    *  @mth                    Batch month
    *  @batchid                Batch ID#
    *  @glco                   Posted To GL Co#
    *  @glacct                 GL Account - all distributions except Intercompany AP/AR
    *  @batchseq               Batch sequence
    *  @apline                 AP Line #
    *  @oldnew                 0 = old, 1 = new
    *  @aptrans                AP Transaction #
    *  @vendorgroup            Vendor Group
    *  @vendor                 Vendor #
    *  @sortname               Vendor Sort Name
    *  @invdate                Invoice Date
    *  @apref                  AP Reference
    *  @transdesc              Transaction description
    *  @linetype               AP Line type
    *  @polinetype             PO Item type
    *  @linedesc               Line description
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
    *	@usetaxamt				Use tax amount
    *	@taxaccrualacct			Tax Accrual GL Account
    *
    * OUTPUT PARAMETERS
    *  none
    *
    * RETURN VALUE
    *  0                       success
    *  1                       failure
    *****************************************************/
   @apco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @glco bCompany = null,
   @glacct bGLAcct = null, @batchseq int = null, @apline smallint = null, @oldnew tinyint = null,
   @aptrans bTrans = null, @vendorgroup bGroup = null, @vendor bVendor = null, @sortname varchar(15) = null,
   @invdate bDate = null, @apref bAPReference = null, @transdesc bDesc = null, @linetype tinyint = null,
   @polinetype tinyint = null, @linedesc bDesc = null, @jcco bCompany = null, @job bJob = null,
   @phasegroup bGroup = null, @phase bPhase = null, @jcctype bJCCType = null, @emco bCompany = null,
   @equip bEquip = null, @emgroup bGroup = null, @costcode bCostCode = null, @emctype bEMCType = null,
   @inco bCompany = null, @loc bLoc = null, @matlgroup bGroup = null, @matl bMatl = null, @amt bDollar = 0,
   @apglco bCompany = null, @intercoarglacct bGLAcct = null, @intercoapglacct bGLAcct = null,
   @usetaxamt bDollar = 0, @taxaccrualacct bGLAcct = null
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- Expense update to AP GL Distributions - 'posted to' GL Co#
   update bAPGL
   set TotalCost = TotalCost + @amt
   where APCo = @apco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
       and BatchSeq = @batchseq and APLine = @apline and OldNew = @oldnew
   if @@rowcount = 0
       insert bAPGL
       values(@apco, @mth, @batchid, @glco, @glacct, @batchseq, @apline, @oldnew, @aptrans, @vendorgroup,
           @vendor, @sortname, @invdate, @apref, @transdesc, @linetype, @polinetype, @linedesc, @jcco,
           @job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
           @loc, @matlgroup, @matl, @amt)
   
   -- Use Tax Accrual update to AP GL Distributions - 'posted to' GL Co#
   if @usetaxamt <> 0
   	begin
   	update bAPGL
   	set TotalCost = TotalCost - @usetaxamt
   	where APCo = @apco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @taxaccrualacct
       	and BatchSeq = @batchseq and APLine = @apline and OldNew = @oldnew
   	if @@rowcount = 0
       	insert bAPGL
       	values(@apco, @mth, @batchid, @glco, @taxaccrualacct, @batchseq, @apline, @oldnew, @aptrans, @vendorgroup,
           	@vendor, @sortname, @invdate, @apref, @transdesc, @linetype, @polinetype, @linedesc, @jcco,
           	@job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
           	@loc, @matlgroup, @matl, -@usetaxamt)
   	end
   
   -- if 'Posted to' and AP GL Co#s are not equal, update Intercompany distributions
   if @glco <> @apglco
       begin
       -- Intercompany Payables - Credit in 'posted to' GL Co#
       update bAPGL
       set TotalCost = TotalCost - (@amt - @usetaxamt)	-- use tax not included in interco entry
       where APCo = @apco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @intercoapglacct
           and BatchSeq = @batchseq and APLine = @apline and OldNew = @oldnew
       if @@rowcount = 0
           insert bAPGL
           values(@apco, @mth, @batchid, @glco, @intercoapglacct, @batchseq, @apline, @oldnew, @aptrans, @vendorgroup,
               @vendor, @sortname, @invdate, @apref, @transdesc, @linetype, @polinetype, @linedesc, @jcco,
               @job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
               @loc, @matlgroup, @matl, (-1 * (@amt - @usetaxamt)))
       -- Intercompany Receivables - Debit in AP GL Co#
       update bAPGL
       set TotalCost = TotalCost + (@amt - @usetaxamt)	-- use tax not included in interco entry
       where APCo = @apco and Mth = @mth and BatchId = @batchid and GLCo = @apglco and GLAcct = @intercoarglacct
           and BatchSeq = @batchseq and APLine = @apline and OldNew = @oldnew
       if @@rowcount = 0
           insert bAPGL
           values(@apco, @mth, @batchid, @apglco, @intercoarglacct, @batchseq, @apline, @oldnew, @aptrans, @vendorgroup,
               @vendor, @sortname, @invdate, @apref, @transdesc, @linetype, @polinetype, @linedesc, @jcco,
               @job, @phasegroup, @phase, @jcctype, @emco, @equip, @emgroup, @costcode, @emctype, @inco,
               @loc, @matlgroup, @matl, (@amt - @usetaxamt))
       end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPLBValGLInsert] TO [public]
GO
