SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpValJCInsert    Script Date: 8/28/99 9:34:00 AM ******/   
    CREATE   procedure [dbo].[bspPORBExpValJCInsert]
    /***********************************************************
     * CREATED BY: DANF 04/16/01
     * MODIFIED By : MV 01/14/05 - #21648 - suppress actuals in bAPJC if UpdateAPActualsYN='N'
     *				DC 3/9/09 - #132611 - I get an error when I Validate PO  batch.
     *				DC 12/11/09 - #122288 - Store Tax rate in POIT
     *				GF 01/18/2011 - issue #142887 only validate tax code when one exists
     *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
     *				GF 08/22/2011 TK-07879 PO ITEM LINE
     *
     *
     * USAGE:
     * Called from bspPORBVal to update/insert JC distributions
     * into bPORJ for an PO receipt Entry batch.
     *
     * INPUT PARAMETERS:
     *  @poco                   PO Company
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
     *  @apref                  AP Reference
     *  @po                     Purchase Order
     *  @poitem                 PO Item
     *  @matlgroup              Material Group
     *  @matl                   Material
     *  @porbdesc               Description
     *  @porbrecdate            Reciept Date
     *  @porbrecevier           Receiver Number
     *  @glco                   JC GL Co#
     *  @glacct                 Job expense GL Account
     *  @um                     Posted unit of measure
     *  @units                  Posted units
     *  @jcum                   JC Unit of Measure
     *  @jcunits                JC Units - 0 if not convertable
     *  @jcunitcost             JC Unit Cost
     *  @ecm                    JC Unit Cost per E, C, or M
     *  @amt                    Actual Cost
     *  @rniunits               Received n/Invoiced units
     *  @rnicost                Received n/Invoiced costs
     *  @remcmtdcost            Remaining committed costs
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
      @poco bCompany, @mth bMonth, @batchid bBatchID, @jcco bCompany, @job bJob,
      @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @batchseq int, @apline smallint, @potrans bTrans,
      @oldnew tinyint, @vendorgroup bGroup, @vendor bVendor,
      @po varchar(30), @poitem bItem, @matlgroup bGroup, @matl bMatl,
      @porbdesc bDesc, @porbrecdate bDate, @porbrecevier varchar(20), @glco bCompany, @glacct bGLAcct,
      @um bUM, @units bUnits, @jcum bUM, @jcunits bUnits, @jcunitcost bUnitCost, @ecm bECM,
      @amt bDollar, @rniunits bUnits, @rnicost bDollar, @remcmtdcost bDollar, @taxgroup bGroup,
      @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxamt bDollar,
      ----TK-07879
      @POItemLine INT
      
    as
   
    set nocount on
   
   
    declare @rcode int,@updateactuals bYN,
		@poitremcmtdtax bDollar, @dateposted bDate, @HQTXdebtGLAcct bGLAcct, @errmsg varchar(255)  --DC #122288
   
    select @rcode = 0,
   	@dateposted = convert(varchar(11),getdate()) --DC #128289
    
	-- if @reqdate is null use today's date
	if isnull(@porbrecdate,'') = '' select @porbrecdate = @dateposted
    
	-- validate tax code if there is one #142887
	if ISNULL(@taxcode,'') <> ''
		BEGIN
		exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @porbrecdate, NULL, NULL, NULL, NULL, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output				
		END
	
	----JCJM
    select @updateactuals = UpdateAPActualsYN
    from dbo.bJCJM
	where JCCo=@jcco
		AND Job=@job
		
	----POItemLine TK-07879
	SET @poitremcmtdtax = 0
    select @poitremcmtdtax = -((case when @HQTXdebtGLAcct is null then TaxRate else TaxRate-GSTRate end) * @taxbasis)
    from dbo.POItemLine 
    WHERE POCo = @poco
		AND PO = @po
		AND POItem = @poitem
		AND POItemLine = @POItemLine
		----POIT with (nolock) where POCo = @poco and PO = @po
   
   
    ---- update PO JC Distributions
    update bPORJ
    set TotalCost = TotalCost + @amt, RNICost = RNICost + isnull(@rnicost,0), RemCmtdCost = RemCmtdCost + isnull(@remcmtdcost,0),
        TaxBasis = TaxBasis + @taxbasis, TaxAmt = TaxAmt + @taxamt,
        RemCmtdTax = @poitremcmtdtax  --DC #122288
    where POCo = @poco and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
        and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
        and BatchSeq = @batchseq 
        and isnull(POTrans,'') = isnull(@potrans,'') and isnull(APLine,'') = isnull(@apline,'') and isnull(OldNew,'') = isnull(@oldnew,'')  --DC #132611
   if @@rowcount = 0
        insert bPORJ (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, APLine, OldNew, POTrans,
            VendorGroup, Vendor, PO, POItem, MatlGroup, Material, Description, RecDate, Receiver#,
            GLCo, GLAcct, UM, Units, JCUM, JCUnits, JCUnitCost, ECM, TotalCost,
            --DC #122288
            RNIUnits, RNICost, RemCmtdCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt, RemCmtdTax,
            ----TK-07879
            POItemLine)  
        values(@poco, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcctype, @batchseq, @apline, @oldnew, @potrans,
            @vendorgroup, @vendor, @po, @poitem, @matlgroup, @matl, @porbdesc, @porbrecdate, @porbrecevier,
            @glco, @glacct, @um, @units, @jcum,
   		 case @updateactuals when 'Y' then @jcunits else 0 end, 
   		 case @updateactuals when 'Y' then @jcunitcost else 0 end, @ecm, @amt,
            @rniunits, isnull(@rnicost,0), isnull(@remcmtdcost,0),
            --DC #122288
            @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt, @poitremcmtdtax,
            ----TK-07879
            @POItemLine)

   
    bspexit:
        return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpValJCInsert] TO [public]
GO
