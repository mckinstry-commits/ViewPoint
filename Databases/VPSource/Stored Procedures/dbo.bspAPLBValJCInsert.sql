SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     proc [dbo].[bspAPLBValJCInsert]
/***********************************************************
* CREATED BY:	GG	06/23/1999
* MODIFIED By:	GG	03/08/0200	- Update RNICost if bAPJC entry already exists
*				DANF 05/10/2000	- Added isnull on @remcmtdcost
*				GG	06/20/2000	- Added parameters and update for tax columns
*				GR	11/21/2000	- changed datatype from bAPRef to bAPReference
*				JE	05/18/2001	- fixed Rem Committed Cost.
*				GH	12/11/2001	- Changed datatype bAPRef to use bAPReference Issue #15570
*				MV	03/04/2003	- #19926 - update/insert RemCmtdUnits, TotalCmtdUnits, TotalCmtdCost to bAPJC
*				MV	01/14/2005	- #21648 - suppress actuals in bAPJC if UpdateAPActualsYN='N' 
*				DANF 09/011/2006 - Wrapped begin end around if statement
*				DC	12/16/2009	- #122288 - Store Tax Rate in POIT
*				GP	06/28/2010	- #135813 change bSL to varchar(30) 
*				GF	08/04/2011	- TK-07144 EXPAND PO
*				CHS	08/10/2011	- TK-07620 - added POItemLine
*
* USAGE:
* Called from bspAPLBVal to update/insert JC distributions
* into bAPJC for an AP Transaction Entry batch.
*
* INPUT PARAMETERS:
*  @apco                     AP Company
*  @mth                    Batch month
*  @batchid                Batch ID#
*  @jcco                   Posted To JC Co#
*  @job                    Job
*  @phasegroup             Phase Group
*  @phase                  Phase
*  @jcctype                JC Cost Type
*  @batchseq               Batch sequence
*  @apline                 AP Line #
*  @oldnew                 0 = old, 1 = new
*  @aptrans                AP Transaction #
*  @vendorgroup            Vendor Group
*  @vendor                 Vendor #
*  @apref          AP Reference
*  @transdesc              Transaction description
*  @invdate                Invoice Date
*  @sl                     Subcontract
*  @slitem                 SL Item
*  @po                     Purchase Order
*  @poitem					PO Item
*  @POItemLine			   PO Item Line
*  @matlgroup              Material Group
*  @matl                   Material
*  @linedesc               Line description
*  @glco                   JC GL Co#
*  @glacct                 Job expense GL Account
*  @um                  Posted unit of measure
*  @units                  Posted units
*  @jcum                   JC Unit of Measure
*  @jcunits                JC Units - 0 if not convertable
*  @jcunitcost             JC Unit Cost
*  @ecm       JC Unit Cost per E, C, or M
*  @amt                    Actual Cost
*  @rniunits               Received n/Invoiced units
*  @rnicost                Received n/Invoiced costs
*  @remcmtdcost            Remaining committed costs
*  @taxgroup              Tax Group
*  @taxcode                Tax Code
*  @taxtype                Tax Type, null = no tax, 1 = sales, 2 = use
*  @taxbasis               Tax Basis
*  @taxamt                 Tax Amount
*	@remcmtdunits			 Remaining committed units
*	@totalcmtdunits		 Total committed units
*	@totalcmtdcost			 Total committed cost
*	 
* OUTPUT PARAMETERS
*  none
*
* RETURN VALUE
*  0                       success
*  1                       failure
*****************************************************/
      @apco bCompany, @mth bMonth, @batchid bBatchID, @jcco bCompany, @job bJob,
      @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @batchseq int, @apline smallint,
      @oldnew tinyint, @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor,  @apref bAPReference,
	  @transdesc bDesc, @invdate bDate, @sl varchar(30), @slitem bItem, @po VARCHAR(30), @poitem bItem,
      @POItemLine int, @matlgroup bGroup, @matl bMatl, @linedesc bDesc, @glco bCompany, @glacct bGLAcct,
      @um bUM, @units bUnits, @jcum bUM, @jcunits bUnits, @jcunitcost bUnitCost, @ecm bECM,
      @amt bDollar, @rniunits bUnits, @rnicost bDollar, @remcmtdcost bDollar, @taxgroup bGroup,
      @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxamt bDollar, @remcmtdunits bUnits,
      @totalcmtdunits bUnits, @totalcmtdcost bDollar,
      @totalcmtdtax bDollar, @remcmtdtax bDollar  --DC #122288
   
    as
   
    set nocount on
   
    declare @rcode int,@updateactuals bYN
   
    select @rcode = 0
   
    select @updateactuals = UpdateAPActualsYN from JCJM with (nolock) where JCCo=@jcco and Job=@job
   
    -- update AP JC Distributions
    update bAPJC
    set TotalCost = TotalCost + @amt, RNICost = RNICost + @rnicost,
   	 RemCmtdCost = isnull(RemCmtdCost,0) + isnull(@remcmtdcost,0),     -- Issue 13498
   	 RemCmtdUnits = isnull(RemCmtdUnits,0) + isnull(@remcmtdunits,0),	--19926 
        TotalCmtdUnits = isnull(TotalCmtdUnits,0) + isnull(@totalcmtdunits,0),
   	 TotalCmtdCost = isnull(TotalCmtdCost,0) + isnull(@totalcmtdcost,0),
   	 TaxBasis = TaxBasis + @taxbasis, TaxAmt = TaxAmt + @taxamt,
   	 TotalCmtdTax = TotalCmtdTax + @totalcmtdtax, RemCmtdTax = RemCmtdTax + @remcmtdtax  --DC #122288
    where APCo = @apco and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
        and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
        and BatchSeq = @batchseq and APLine = @apline and OldNew = @oldnew
   if @@rowcount = 0
		begin
        insert bAPJC (APCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, APLine, OldNew,
            APTrans, VendorGroup, Vendor, APRef, TransDesc, InvDate, SL, SLItem, PO, POItem, POItemLine, MatlGroup,
            Material, LineDesc, GLCo, GLAcct, UM, Units, JCUM, JCUnits, JCUnitCost, ECM, TotalCost,
            RNIUnits, RNICost, RemCmtdCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,RemCmtdUnits,
   			TotalCmtdUnits,TotalCmtdCost,
   			TotalCmtdTax, RemCmtdTax) --DC #122288
        values(@apco, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcctype, @batchseq, @apline, @oldnew,
            @aptrans, @vendorgroup, @vendor, @apref, @transdesc, @invdate, @sl, @slitem, @po, @poitem, @POItemLine, @matlgroup,
            @matl, @linedesc, @glco, @glacct, @um, @units, @jcum, 
   			case @updateactuals when 'Y' then @jcunits else 0 end, 
   			case @updateactuals when 'Y' then @jcunitcost else 0 end,@ecm, @amt,
            @rniunits, @rnicost, isnull(@remcmtdcost,0), @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
   			isnull(@remcmtdunits,0),isnull(@totalcmtdunits,0),isnull(@totalcmtdcost,0), 
   			isnull(@totalcmtdtax,0), isnull(@remcmtdtax,0))  --DC #122288
		end
   
    bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPLBValJCInsert] TO [public]
GO
