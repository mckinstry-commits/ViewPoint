SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_ValCashLines    Script Date: 8/28/99 9:36:04 AM ******/
CREATE procedure [dbo].[bspARBH1_ValCashLines]
/***********************************************************
* CREATED BY: 	 JRE 8/17/97
* MODIFIED By : JM 8/4/98 - Added null test for ApplyTrans in
*							else portion of 'check applied transaction' section
*			JM 8/17/98 - Added missing definitions for @oldAmount, @oldRetainage, @oldTaxBasis, and
*						 @oldTaxAmount in main select statement from bARBL
*			JM 8/18/98 - Issue #2749: Added insertion of @oldtransdate to ARBI.ActualDate in JCUpdate_Old section
*		 	JM 8/18/98 - Issue #2727: Changed value for @Retainage from - to + in insert statement in JCUpdate section;
*						changed values for @oldAmount and @oldRetainage from + to - in insert statement in
*						JCUpdate_Old section
*			JM 8/28/98 - Issue #2895: Added parameter to select statement around line 107 to include BatchSeq
*			JM 11/16/98 - Corrected ref to @artrans to @ARTrans in insert statements to bARBA;
*						added select stmt to pull SortName for same inserts from ARCM.
*			JRE 12/13/98 - no error if all amounts are zero
*      		GG 04/26/00 - removed references to MSCo and MSTrans
*     		bc 11/01/00 - added inter company GL processing
*      		GR 11/30/00 - Issue #11154: Removed the tax amount based on tax interface flag in JCCM
*                  		in JC Update
*      		bc 01/11/01 - changed sign of @oldPostAmount from - to + when @i= 2 and Retainage glacct = AR glacct
*			TJL 04/20/01 - Correct  negative 'taxlessamt' values to JCID and correct release retainage
*			          	( make neg retainage) in JCID from cash receipts payment
*			TJL 07/03/01 - I fear the original idea to not allow negative @taxlessamt (Amount Applied) to JCID was in error.  Users will post
*						negative amounts to offset balances and I must allow negative @taxlessamt to JCID afterall.
*			TJL 07/25/01 - Determine correct ARDiscountGLAcct based on if Location exists in bARBL  
*			TJL 09/17/01 - Issue #14610, If bARBL TaxAmount not 0.00 then check for presence of bARBL.TaxCode
*			TJL 11/12/01 - Issue #15154, If user Zero's/deletes an original 'On Account' line, error if applied lines exist against it.
*       	bc  01/30/02 - Issue # 16091
*			TJL 02/13/02 - Issue #14892, Rewrite GLAcct and InterCompany Processing
*			TJL 03/27/02 - Issue #16617, Discounts Amount not removed from Cash Sent to InterCo Cash Account.
*			TJL 04/01/02 - Issue #16734 + #13294, Add New Finance Chg column, correctly post FC's to GLAcct
*			TJL 04/16/02 - Issue #16468, Correct old 'CheckNo' update to bGLDT
*			TJL 04/22/02 - Issue #17077, Catch improper GLAcct SubTypes during GLAcct validation.
*			TJL 05/14/02 - Issue #17421, Dont Allow Line TaxAmount greater than Line ApplyAmt.
*			TJL 05/31/02 - Issue #17492, Relates to how we update GLAccts when they are the same.
*			TJL 07/31/02 - Issue #11219, Add 'TaxDisc Applied' column to grid for user input.
*			TJL 08/07/02 - Issue #18237, InterCompany Payables/Receivables to Multiple Accts, same Co.
*			TJL 02/19/03 - Issue #19998, Update ARBI(JCID) Description column on old/reversing entry.  Was NULL
*			TJL 08/08/03 - Issue #22087, Performance mods, add NoLocks
*			TJL 10/15/03 - Issue #22736, Correct validation for FinanceChg > Amount.  Add abs() function
*			TJL 02/06/03 - Issue #23005, Remove Tax/FinanceChg > Amount check.  No longer required.
*			TJL 02/26/07 - Issue #120561, Made adjustment pertaining to bHQCC Close Control entry handling
*		TJL 06/05/08 - Issue #128457,  ARCashReceipts International Sales Tax
*		TJL 06/02/09 - Issue #133750, Add ISNULL() function when retrieving dollar values from batch table (ARBL)
*		MV	02/04/10 - Issue #136500 - added NULL output param to bspHQTaxRateGetAll
*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*		MV	10/25/11 - TK-09243 - added NULL output param to bspHQTaxRateGetAll
*
* USAGE:
* 	Validates each entry in bARBL for a selected batch - called from bARBHCashVal
* 	Errors in batch added to bHQBE using bspHQBEInsert
* 	Job distributions added to
* 	CM distributions added to
* 	GL Account distributions added to
* 	GL debit and credit totals must balance.
* 	bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   BatchSeq    Batch Seq to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
   
@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output
as

set nocount on
   
declare @rcode int, @errortext varchar(255),@PostAmount bDollar, @oldPostAmount bDollar,
	@lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint, @accttype char(1),
	@itemcount int, @deletecount int, @errorstart varchar(50), @validcnt int,
	@isContractFlag bYN, @SortName varchar(15), @ActDate bDate,@BilledAmt int, @offsettingaccount bGLAcct,
	@paymentjrnl bJrnl, @glpaylvl int, @misccashjrnl bJrnl, @glmisccashlvl int,
	@AR_glco int, @fy bMonth, @RecTypeGLCo int, @errdetail varchar(60),
	@taxinterface bYN, @taxlessamt bDollar, @oldtaxlessamt bDollar, @chksubtype char(1)

/*Declare AR Header variables*/
declare @transtype char(1), @ARTransHD bTrans, @artranstype char(1), @CustGroupHD bGroup, @source bSource,
	@customer bCustomer, @JCCoHD bCompany, @ContractHD bContract, @custref varchar(10), @invoice char(10),
	@checkno char(10), @DescriptionHD bDesc, @transdate bDate, @duedate bDate, @discdate bDate,
	@checkdate bDate, @appliedmth bMonth, @appliedtrans bTrans, @cmco bCompany, @cmacct bCMAcct,
	@cmdeposit varchar(10), @creditamt bDollar, @payterms bPayTerms,
	@oldcustref char(20), @oldinvoice char(10), @oldcheckno char(10), @OldDescriptionHD bDesc,
	@oldtransdate bDate, @oldduedate bDate, @olddiscdate bDate, @oldcheckdate bDate, @oldcmco bCompany,
	@oldcmacct bCMAcct, @oldcmdeposit varchar(10), @oldcreditamt bDollar, @oldpayterms bPayTerms
   
/*Declare AR Line variables */
declare @ARLine smallint, @TransTypeLine char, @ARTrans bTrans,
	@RecType tinyint, @LineType char, @Description bDesc, @Line_GLCo bCompany, @GLAcct bGLAcct, @TaxGroup bGroup,
	@TaxCode bTaxCode, @Amount bDollar, @TaxBasis bDollar, @LineTaxAmount bDollar,@RetgPct bPct, @Retainage bDollar, @LineRetgTax bDollar,
	@DiscOffered bDollar, @LineTaxDisc bDollar, @DiscTaken bDollar, @ApplyMth bMonth, @ApplyTrans bTrans, @ApplyLine smallint,
	@JCCo bCompany, @Contract bContract, @ContractItem bContractItem, @ContractUnits bUnits, @Job bJob,
	@PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType, @UM bUM, @JobUnits bUnits, @JobHours bHrs, @INCo bCompany, @Loc bLoc,
	@MatlGroup bGroup, @Material bMatl, @UnitPrice bUnitCost, @ECM bECM, @MatlUnits bUnits, @FinanceChg bDollar,
	@CustJob varchar(10), @EMCo bCompany, @Equipment bEquip, @EMGroup bGroup, @CostCode bCostCode, @EMCType bEMCType,
	@oldRecType tinyint, @oldLineType char, @oldDescription bDesc, @oldGLAcct bGLAcct,
	@oldTaxGroup  bGroup, @oldTaxCode  bTaxCode, @oldAmount bDollar, @oldTaxBasis bDollar, @oldLineTaxAmount bDollar,
	@oldRetgPct bPct, @oldRetainage bDollar, @oldLineRetgTax bDollar, @oldDiscOffered bDollar, @oldLineTaxDisc bDollar, @oldDiscTaken bDollar,
	@oldApplyMth  bMonth, @oldApplyTrans bTrans, @oldApplyLine  smallint, @oldJCCo bCompany, @oldContract bContract,
	@oldItem bContractItem, @oldContractUnits bUnits, @oldJob bJob, @oldPhaseGroup  bGroup, @oldPhase  bPhase,
	@oldCostType bJCCType, @oldUM bUM, @oldJobUnits bUnits, @oldJobHours bHrs, @oldINCo bCompany, @oldLoc bLoc,
	@oldMatlGroup bGroup, @oldMaterial bMatl, @oldUnitPrice bUnitCost, @oldMatlUnits bUnits,
	@oldCustJob varchar, @oldEMGroup bGroup, @oldEMCo  bCompany, @oldEquipment bEquip,
	@oldCostCode bCostCode , @oldEMCType bEMCType, @oldFinanceChg bDollar
   
declare @ARGLCo bCompany, @GLARAcct bGLAcct, @GLRetainAcct bGLAcct, @GLDiscountAcct bGLAcct, @GLARFCRecvAcct bGLAcct,
	@LocGLDiscountAcct bGLAcct, @CMGLCo bCompany, @CMGLCash bGLAcct, @PostGLCo bCompany, @PostGLAcct bGLAcct,
	@oldARGLCo bCompany, @oldGLARAcct bGLAcct, @oldGLRetainAcct bGLAcct, @oldGLDiscountAcct bGLAcct, 
	@oldLocGLDiscountAcct bGLAcct, @oldCMGLCo bCompany, @oldCMGLCash bGLAcct, @oldPostGLCo bCompany,
	@oldPostGLAcct bGLAcct, @i tinyint, @compareICamt bDollar, @compareIColdamt bDollar,
	@oldGLARFCRecvAcct bGLAcct,
 	--International Sales Tax
	@taxrate bRate, @gstrate bRate, @pstrate bRate, @origtransdate bDate, @oldorigtransdate bDate,
	@HQTXcrdGLAcct bGLAcct, @HQTXcrdRetgGLAcct bGLAcct, @oldHQTXcrdGLAcct bGLAcct, @oldHQTXcrdRetgGLAcct bGLAcct, 
	@HQTXcrdGLAcctPST bGLAcct, @HQTXcrdRetgGLAcctPST bGLAcct, @oldHQTXcrdGLAcctPST bGLAcct, @oldHQTXcrdRetgGLAcctPST bGLAcct,
	@TaxAmount bDollar, @RetgTax bDollar, @TaxDisc bDollar, @TaxAmountPST bDollar, @RetgTaxPST bDollar,  @TaxDiscPST bDollar, 
	@oldTaxAmount bDollar, @oldRetgTax bDollar, @oldTaxDisc bDollar, @oldTaxAmountPST bDollar, @oldRetgTaxPST bDollar,
	@oldTaxDiscPST bDollar 

-- 	@HQTXGLAcct bGLAcct,  @oldHQTXGLAcct bGLAcct
  
declare @old varchar(30), @new varchar(30),
	@OldNew tinyint, @CustGroup  bGroup,
	@DistDate bDate, @oldDistDate bDate,@TmpCustomer varchar(15), @ReturnCustomer bCustomer,
	@ContractStatus int  

declare @LastContract bContract, @InterCompany tinyint, @numrows int
   
/* Get some company specific variables */
select @glpaylvl = GLPayLev, @glmisccashlvl = GLMiscCashLev
from ARCO with (nolock)
where ARCo = @co
   
select @transtype=TransType, @ARTransHD=ARTrans, @checkno=CheckNo,
	@source=Source, @artranstype=ARTransType, @CustGroupHD=CustGroup, @customer=Customer,
	@cmco=CMCo, @cmacct=CMAcct, @JCCoHD=JCCo, @ContractHD=Contract, @transdate=TransDate,
	@DescriptionHD=Description,
	@oldtransdate=oldTransDate, @oldcheckdate=oldCheckDate, @oldcmco=oldCMCo, @oldcmacct=oldCMAcct,
	@oldcmdeposit=oldCMDeposit, @oldcreditamt=oldCreditAmt, @oldcheckno=oldCheckNo,
	@OldDescriptionHD=oldDescription
from bARBH with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq = @batchseq
   
/* Get Cust SortName. */
select @SortName = SortName
from bARCM with (nolock)
where CustGroup = @CustGroupHD and Customer = @customer
   
/***************************************/
/* AR Line Batch loop for validation   */
/***************************************/

select @ARLine=Min(ARLine)
from bARBL with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
while @ARLine is not null
	BEGIN	-- Begin Line Loop
	select @TransTypeLine= TransType, @ARTrans=ARTrans , @RecType= RecType,
		@LineType=LineType, @Description= Description, @Line_GLCo=GLCo, @GLAcct=GLAcct,
		@TaxGroup=TaxGroup,@TaxCode= TaxCode, @Amount= isnull(Amount,0), @TaxBasis = isnull(TaxBasis,0),
		@LineTaxAmount = isnull(TaxAmount,0), @LineRetgTax = isnull(RetgTax,0), @RetgPct= isnull(RetgPct,0), 
		@Retainage= isnull(Retainage,0), @DiscOffered= isnull(DiscOffered,0), 
		@LineTaxDisc=isnull(TaxDisc,0), @DiscTaken=isnull(DiscTaken,0), @ApplyMth=ApplyMth, @ApplyTrans=ApplyTrans, @ApplyLine= ApplyLine,
		@JCCo= JCCo, @Contract=Contract, @ContractItem= Item, @ContractUnits=ContractUnits, @Job=Job,
		@PhaseGroup=PhaseGroup, @Phase=Phase, @CostType = CostType, @UM= UM, @JobUnits= isnull(JobUnits,0),
		@JobHours=isnull(JobHours,0), @INCo=INCo, @Loc=Loc, @MatlGroup=MatlGroup, @Material=Material,
		@UnitPrice=isnull(UnitPrice,0), @ECM=ECM, @MatlUnits=isnull(MatlUnits,0), @FinanceChg=isnull(FinanceChg,0),
		@oldRecType=oldRecType, @oldRetainage=isnull(oldRetainage,0), @oldLineTaxDisc=isnull(oldTaxDisc,0),
		@oldDiscTaken=isnull(oldDiscTaken,0), @oldApplyMth=oldApplyMth, @oldApplyTrans=oldApplyTrans, 
		@oldApplyLine=oldApplyLine, @oldJCCo=oldJCCo, @oldContract=oldContract,  @oldItem=oldItem,
		@oldContractUnits=isnull(oldContractUnits,0), @oldJob=oldJob, @oldPhaseGroup=oldPhaseGroup,
		@oldPhase=oldPhase, @oldCostType=oldCostType, @oldUM=oldUM, @oldJobUnits=isnull(oldJobUnits,0),
		@oldJobHours=isnull(oldJobHours,0), @oldINCo=oldINCo, @oldLoc=oldLoc, @oldAmount=isnull(oldAmount,0),
		@oldRetainage=isnull(oldRetainage,0), @oldTaxBasis=isnull(oldTaxBasis,0), @oldTaxGroup=oldTaxGroup,
		@oldTaxCode=oldTaxCode, @oldLineTaxAmount=isnull(oldTaxAmount,0), @oldLineRetgTax=isnull(oldRetgTax,0),
		@oldMatlGroup=oldMatlGroup, @oldMaterial=oldMaterial, @oldUnitPrice=isnull(oldUnitPrice,0),
		@oldMatlUnits=isnull(oldMatlUnits,0), @oldCustJob=oldCustJob,
		@oldEMGroup=oldEMGroup, @oldEMCo=oldEMCo, @oldEquipment=oldEquipment,
		@oldCostCode=oldCostCode, @oldEMCType=oldEMCType, @oldFinanceChg=isnull(oldFinanceChg,0),
		@oldDescription = oldDescription
	from bARBL with (nolock)
	where Co = @co and Mth = @mth and BatchId=@batchid and BatchSeq=@batchseq and ARLine=@ARLine

	/* Reset Line variables as needed here.  
	   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
	select @HQTXcrdGLAcct = null, @HQTXcrdRetgGLAcct = null, @HQTXcrdGLAcctPST = null, @HQTXcrdRetgGLAcctPST = null,
		@oldHQTXcrdGLAcct = null, @oldHQTXcrdRetgGLAcct = null, @oldHQTXcrdGLAcctPST = null, @oldHQTXcrdRetgGLAcctPST = null,
		@TaxAmount = 0,	@TaxAmountPST = 0, @RetgTax = 0, @RetgTaxPST = 0, @TaxDisc = 0, @TaxDiscPST = 0,
		@oldTaxAmount = 0,	@oldTaxAmountPST = 0, @oldRetgTax = 0, @oldRetgTaxPST = 0, @oldTaxDisc = 0, @oldTaxDiscPST = 0

	select @errorstart = 'Seq ' + convert(varchar(6),@batchseq) + ' Line ' + convert(varchar(6),@ARLine)+ ' '
   
	/*validate transactions action*/
	if @TransTypeLine<>'A' and @TransTypeLine <>'C' and @TransTypeLine <>'D'
		begin
		select @errortext = @errorstart + ' - Invalid transaction type, must be A, C, or D .'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		End
   
	/* check applied transaction */
	if exists(select top 1 1 from bARTL with (nolock) where ARCo=@co and Mth=@ApplyMth and ARTrans=@ApplyTrans and ARLine=@ApplyLine)
		begin
 		if @Amount<>0 or @LineTaxAmount<>0 or @Retainage<>0 or @DiscTaken<>0 or @LineTaxDisc<>0 or @FinanceChg<>0
   			begin
   			if not exists (select 1
 				from bARTL with (nolock)
    			where ARCo=@co and Mth=@ApplyMth and ARTrans=@ApplyTrans and ARLine=@ApplyLine and Mth=ApplyMth and
       				ARTrans=ApplyTrans and ARLine=ApplyLine and RecType=@RecType)
 				begin
 				select @errortext = @errorstart + ' - Apply To Trans does not match Invoice RT='+ isnull(Convert(varchar(2),@RecType),'')
 				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 				if @rcode <> 0 goto bspexit
 				end
   			end
 		end
	else
 		begin
		if @ApplyTrans is not null
			begin
			select @errortext = @errorstart + ' - Apply To Trans# ' + isnull(convert (varchar(8),@ApplyTrans),'') +
  					' Line ' + isnull(convert(varchar(6),@ApplyLine),'') + '  does not exist'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
 		end
   
	/* Issue #14610, If a TaxAmount is present, there must also be a TaxCode, else error. */
	/* At this point, a TaxCode would have been inserted into bARBL (by bspARAutoApplyLine), directly from bARTL if the original Trans contained one, 
	   therefore, we can test values coming from bARBL for this line. */
	if (isnull(@LineTaxAmount, 0) <> 0 or isnull(@LineRetgTax, 0) <> 0 or isnull(@LineTaxDisc, 0) <> 0) and @TaxCode is null
		begin
		select @errortext = @errorstart + ' - Orig Trans Mth  ' + isnull(Convert(varchar(12),@ApplyMth),'') + ' - Orig Trans# ' + 
				isnull(convert (varchar(8),@ApplyTrans),'') +  ' - Line ' + isnull(convert(varchar(6),@ApplyLine),'') + 
				'  must contain a TaxCode for this Payment.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end
   
	/* Prepare NEW variables for distribution of Tax amounts */
	if @TaxCode is not null
		begin
		/*Validate Tax Group */
		select count(*) from bHQCO with (nolock) where HQCo = @co  and TaxGroup = @TaxGroup
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' - Company: ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @TaxGroup),'') +': is invalid'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end

		/* Validate TaxCode by getting the accounts for the tax code */
		select @origtransdate = TransDate
		from bARTH
		where ARCo=@co and Mth=@ApplyMth and ARTrans=@ApplyTrans

		exec @rcode = bspHQTaxRateGetAll @TaxGroup, @TaxCode, @origtransdate, null, @taxrate output, @gstrate output, @pstrate output, 
			@HQTXcrdGLAcct output, @HQTXcrdRetgGLAcct output, null, null, @HQTXcrdGLAcctPST output, 
			@HQTXcrdRetgGLAcctPST output, NULL, NULL, @errmsg output

		if @rcode <> 0
			begin
			select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @TaxGroup),'')
			select @errortext = @errortext + ' - TaxCode : ' + isnull(@TaxCode,'') + ' - is not valid! - ' + @errmsg
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end

		if @pstrate = 0
			begin
			/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
			   In any case:
			   a)  @taxrate is the correct value.  
			   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
			   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
			--select @TaxAmount = @LineTaxAmount
			select @RetgTax = @LineRetgTax
			select @TaxDisc = @LineTaxDisc
			end
		else
			begin
			/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
			if @taxrate <> 0
				begin
				--select @TaxAmount = (@LineTaxAmount * @gstrate) / @taxrate		--GST TaxAmount
				--select @TaxAmountPST = @LineTaxAmount - @TaxAmount				--PST TaxAmount
				select @RetgTax = (@LineRetgTax * @gstrate) / @taxrate			--GST RetgTax
				select @RetgTaxPST = @LineRetgTax - @RetgTax					--PST RetgTax
				select @TaxDisc = (@LineTaxDisc * @gstrate) / @taxrate			--GST TaxDisc
				select @TaxDiscPST = @LineTaxDisc - @TaxDisc					--PST TaxDisc
				end
			end
		end
   
	/* get the accounts for the receivable type */
	select @ARGLCo=GLCo, @GLARAcct=GLARAcct, @GLRetainAcct=GLRetainAcct,
		@GLDiscountAcct=GLDiscountAcct, @GLARFCRecvAcct=GLARFCRecvAcct
	from bARRT with (nolock)
	where ARCo=@co and RecType=@RecType
	if @@rowcount=0
		begin
		select @errortext = @errorstart + ' - Receivable Type: ' + isnull(convert(varchar(3),@RecType),'') +': is invalid'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end
     
	/* get the alternative AR discount account if Location (Inventory Location from MS) is present */
	if @INCo is not null and @Loc is not null
		begin
		select @LocGLDiscountAcct = ARDiscountGLAcct
		from bINLM with (nolock)
		where bINLM.INCo = @INCo and bINLM.Loc = @Loc
		if @LocGLDiscountAcct is not null
   			begin
   			select @GLDiscountAcct = @LocGLDiscountAcct
   			end
      	end
   
	/* get the accounts for the cash management co */
	select @CMGLCo=bCMAC.GLCo, @CMGLCash=bCMAC.GLAcct
	from bCMAC with (nolock)
	where bCMAC.CMCo=@cmco and bCMAC.CMAcct=@cmacct
	if @@rowcount=0
		begin
		select @errortext = @errorstart + ' - CM Acct:' + isnull(convert(varchar(3),@cmacct),'') +': is invalid'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end
   
	if @TransTypeLine in ('C','D') /* for deletes and changes */
		begin
     	/* Issue #15154:  Before beginning the GLAcct processing, first test this line.  There is NO delete capability in PmtOnAcct form
         for transactions added back into a batch.  Users have been taught to Zero out the line and the Post Procedure will evaluate
         this and delete the line for the user.  If the line to be Zero'd/deleted has other lines applied to it, then we want to warn the user
         before this is caught by the btARTLd delete trigger during posting. It is a concern only on 'On Account' payments because of
         the many ways that customers tend to move an 'On Account' payment to an Invoice. */
     	If @Amount = 0 and @LineType = 'A'
       		begin
       		/* Do not allow a line to be deleted that has other lines applied to it.  This count will count all applied lines except
			   original transactions.  */
       		select @validcnt = count(*)
       		from bARTL with (nolock)
       		where ARCo = @co and ApplyMth = @mth and ApplyTrans = @ARTrans and ApplyLine = @ARLine
				and (ARTrans <> @ARTrans or Mth <> @mth or ARLine <> @ARLine)
       		if @validcnt <> 0
          		begin
   				select @errortext = @errorstart + ' of transaction ' + isnull(convert(varchar(10),@ARTrans),'') +
									' has other lines applied to it.  You may not delete this transaction!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
       			end
        	end
   
		/* Validate TaxCode by getting the accounts for the tax code */
		if @oldTaxCode is not null
			begin
			select @oldorigtransdate = TransDate
			from bARTH
			where ARCo=@co and Mth=@oldApplyMth and ARTrans=@oldApplyTrans

			exec @rcode = bspHQTaxRateGetAll @oldTaxGroup, @oldTaxCode, @oldorigtransdate, null, @taxrate output, @gstrate output, @pstrate output, 
				@oldHQTXcrdGLAcct output, @oldHQTXcrdRetgGLAcct output, null, null, @oldHQTXcrdGLAcctPST output, 
				@oldHQTXcrdRetgGLAcctPST output, NULL,NULL,@errmsg output

			if @rcode <> 0
				begin
				select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @oldTaxGroup),'')
				select @errortext = @errortext + ' - TaxCode : ' + isnull(@oldTaxCode,'') + ' - is not valid! - ' + @errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end

			if @pstrate = 0
				begin
				/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
				   In any case:
				   a)  @taxrate is the correct value.  
				   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
				   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
				--select @oldTaxAmount = @oldLineTaxAmount
				select @oldRetgTax = @oldLineRetgTax
				select @oldTaxDisc = @oldLineTaxDisc
				end
			else
				begin
				/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
				if @taxrate <> 0
					begin
					--select @oldTaxAmount = (@oldLineTaxAmount * @gstrate) / @taxrate		--GST TaxAmount
					--select @oldTaxAmountPST = @oldLineTaxAmount - @oldTaxAmount				--PST TaxAmount
					select @oldRetgTax = (@oldLineRetgTax * @gstrate) / @taxrate			--GST RetgTax
					select @oldRetgTaxPST = @oldLineRetgTax - @oldRetgTax					--PST RetgTax
					select @oldTaxDisc = (@oldLineTaxDisc * @gstrate) / @taxrate			--GST TaxDisc
					select @oldTaxDiscPST = @oldLineTaxDisc - @oldTaxDisc					--PST TaxDisc
					end
				end
			end /* tax code validation*/
   
     	/* get the accounts for the receivable type */
     	select @oldARGLCo=GLCo, @oldGLARAcct=GLARAcct, @oldGLRetainAcct=GLRetainAcct,
			@oldGLDiscountAcct=GLDiscountAcct, @oldGLARFCRecvAcct=GLARFCRecvAcct
     	from bARRT with (nolock)
     	where ARCo=@co and RecType=@oldRecType
     	if @@rowcount=0
       		begin
       		select @errortext = @errorstart + ' - Rec. Type:' + isnull(convert(varchar(3),@oldRecType),'') + ': is invalid'
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
       		end
    
     	/* get the alternative AR discount account if Location (Inventory Location from MS) is present */
     	if @oldINCo is not null and @oldLoc is not null
       		begin
       		select @oldLocGLDiscountAcct = ARDiscountGLAcct
       		from bINLM with (nolock)
       		where bINLM.INCo = @oldINCo and bINLM.Loc = @oldLoc
       		if @oldLocGLDiscountAcct is not null
   				begin
   				select @oldGLDiscountAcct = @oldLocGLDiscountAcct
   				end
      		end
   
     	/* get the accounts for the cash management co */
     	select @oldCMGLCo=bCMAC.GLCo, @oldCMGLCash=bCMAC.GLAcct
     	from bCMAC with (nolock)
     	where bCMAC.CMCo=@oldcmco and bCMAC.CMAcct=@oldcmacct
     	if @@rowcount=0
       		begin
       		select @errortext = @errorstart + ' - old CM Acct:' + isnull(convert(varchar(3),@oldcmacct),'') +': is invalid'
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
       		end
     	end
   
   select @i=1, @InterCompany = 10 /*set first intercompany account */
   while @i<=13
   		BEGIN  -- GLUpdate Begin
        /*Validate GL Accounts*/
		/* spin through each type of GL account, check it and write GL Amount */
   
		/****** new values *****/
		select @PostAmount=0, @oldPostAmount=0, @PostGLCo=null, @oldPostGLCo=null,
   			@compareICamt=0, @compareIColdamt=0, @chksubtype = 'N'
   
		/* AR Receivables Account */
		if @i=1 
   			begin
   			select @PostGLCo=@ARGLCo, @PostGLAcct=@GLARAcct, @PostAmount=-(IsNull(@Amount,0)-IsNull(@Retainage,0)-IsNull(@FinanceChg,0)),
   				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLARAcct, @oldPostAmount=(IsNull(@oldAmount,0)-IsNull(@oldRetainage,0)-IsNull(@oldFinanceChg,0)),
				@errdetail=' AR Receivables GLAcct'
	   
   			/* Need to declare proper GLAcct SubType */
   			select @chksubtype = 'R'
   			end
   
		/* AR Retainage Account */
		if @i=2 
   			begin
   			select @PostGLCo=@ARGLCo, @PostGLAcct=@GLRetainAcct, @PostAmount=IsNull(-@Retainage,0),
				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLRetainAcct, @oldPostAmount=IsNull(@oldRetainage,0),
				@errdetail=' AR Retainage GLAcct'
	   
   			/* Need to declare proper GLAcct SubType */
   			select @chksubtype = 'R'
   			end
   
       /* AR Discount taken */
       if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@GLDiscountAcct, @PostAmount=IsNull(@DiscTaken,0),
				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLDiscountAcct, @oldPostAmount=IsNull(-@oldDiscTaken,0),
				@errdetail=' AR Discount GLAcct'
   
       /* Cash account */
       if @i=4 
   			begin
   			select @PostGLCo=@CMGLCo, @PostGLAcct=@CMGLCash, @PostAmount=IsNull(@Amount,0)-IsNull(@DiscTaken,0)-IsNull(@LineTaxDisc,0),
				@oldPostGLCo=@oldCMGLCo, @oldPostGLAcct=@oldCMGLCash, @oldPostAmount=-(IsNull(@oldAmount,0)-IsNull(@oldDiscTaken,0)-IsNull(@oldLineTaxDisc,0)),
				@errdetail=' Cash GLAcct'
   
   			/* Need to declare proper GLAcct SubType */
   			select @chksubtype = 'C'
   			end
   
       /* AR FinanceChg Receivable Account */
       if @i=5 
   			begin
   			select @PostGLCo=@ARGLCo, @PostGLAcct=@GLARFCRecvAcct, @PostAmount=IsNull(-@FinanceChg,0),
				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLARFCRecvAcct, @oldPostAmount=IsNull(@oldFinanceChg,0),
				@errdetail=' AR FC Receivable GLAcct'
   
   			/* Need to declare proper GLAcct SubType */
   			select @chksubtype = 'R'
   			end
   
   		/* Tax Account:  Standard US or GST, combines Debit Tax Discounts with Credit Tax Payables from RetgTax */
   		if @i=6 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdGLAcct, @PostAmount=(isnull(@TaxDisc,0) - isnull(@RetgTax,0)),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdGLAcct, @oldPostAmount=-((isnull(@oldTaxDisc,0) - isnull(@oldRetgTax,0))),
			@errdetail = 'AR Tax Account'
   
   		/* Retainage Tax account.  Standard US or GST */
   		if @i=7 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount=isnull(@RetgTax,0),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdRetgGLAcct, @oldPostAmount=-(isnull(@oldRetgTax,0)),
			@errdetail = 'AR Retg Tax Account'

   		/* Tax Account PST:  PST, combines Debit Tax Discounts PST with Credit Tax Payables PST from RetgTax */
   		if @i=8 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdGLAcctPST, @PostAmount=(isnull(@TaxDiscPST,0) - isnull(@RetgTaxPST,0)),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdGLAcctPST, @oldPostAmount=-((isnull(@oldTaxDiscPST,0) - isnull(@oldRetgTaxPST,0))),
			@errdetail = 'AR Tax Account PST'

		/* Retainage Tax account.  PST */
   		if @i=9 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount=isnull(@RetgTaxPST,0),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdRetgGLAcctPST, @oldPostAmount=-(isnull(@oldRetgTaxPST,0)),
			@errdetail = 'AR Retg Tax Account PST'

   		/* If in 'Add' or 'Delete' mode and ARGL Company is the Same as the CMGL Company then
   		   skip all intercompany processing completely. */
   		if @i >= @InterCompany and @TransTypeLine in ('A', 'D') and @ARGLCo = @CMGLCo
   			begin
   			select @i = 13
   			goto GLUpdateEnd
   			end
   
   		/* Cross company requires 4 stages to accomodate 'C'hange mode as well as 'A'dd and 'D'elete */
   
		/* cross company part I  --  InterCompany Payables GLCo and GLAcct, retrieve OLD values */
   XCompany10:
		if @i=10 
     	  	begin
   			if @TransTypeLine = 'A' and @ARGLCo <> @CMGLCo goto XCompany11		-- There is no Old Inter-APGLCo
     	  	if @TransTypeLine = 'C' and @ARGLCo = @oldCMGLCo goto XCompany11	-- There is no Old Inter-APGLCo
   			select @oldPostGLCo = APGLCo, @oldPostGLAcct = APGLAcct, 
   				@oldPostAmount = (isnull(@oldAmount,0)-isnull(@oldDiscTaken,0)-isnull(@oldLineTaxDisc,0)), 
   				@compareICamt = (isnull(@Amount,0)-isnull(@DiscTaken,0)-isnull(@LineTaxDisc,0)),
				@errdetail='XREF GL Acct'
     	  	from bGLIA with (nolock)
         	where ARGLCo = @ARGLCo and APGLCo = @oldCMGLCo
   
    	  	if @@rowcount = 0
           		begin
           		select @errortext = 'Invalid cross company entry in GLIA. Must have Old PayableGLCo = '
            		+ isnull(convert(varchar(10),@oldCMGLCo),'') + ' - ' + isnull(@errmsg,'')
     	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
           		end
   			end
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @oldPostAmount = @compareICamt and @CMGLCo = @oldCMGLCo
   			select @oldPostAmount = 0
   
       /* cross company part II  --  InterCompany Payables GLCo and GLAcct, retrieve NEW values */
   XCompany11:
       if @i=11 	
     	  	begin
   			if @TransTypeLine = 'C' and @ARGLCo = @CMGLCo goto XCompany12	-- There is no NEW Inter-APGLCo
     	  	select @PostGLCo = APGLCo, @PostGLAcct = APGLAcct, 
     			@PostAmount = -(isnull(@Amount,0)-isnull(@DiscTaken,0)-isnull(@LineTaxDisc,0)), 
   				@compareIColdamt = -(isnull(@oldAmount,0)-isnull(@oldDiscTaken,0)-isnull(@oldLineTaxDisc,0)),
				@errdetail='XREF GL Acct'
     	  	from bGLIA with (nolock)
         	where ARGLCo = @ARGLCo and APGLCo= @CMGLCo
   
    	  	if @@rowcount = 0
           		begin
           		select @errortext = 'Invalid cross company entry in GLIA. Must have New PayableGLCo = '
            		+ isnull(convert(varchar(10),@CMGLCo),'') + ' - ' + isnull(@errmsg,'')
     	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
           		end
         	end
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @PostAmount = @compareIColdamt and @CMGLCo = @oldCMGLCo
   			select @PostAmount = 0
   
		/* cross company part III  --  InterCompany Receivables GLCo and GLAcct, retrieve OLD values */
   XCompany12:
       if @i=12 
     	  	begin
   			if @TransTypeLine = 'A' and @ARGLCo <> @CMGLCo goto XCompany13	-- There is no Old Inter-ARGLCo
     	  	if @TransTypeLine = 'C' and @ARGLCo = @oldCMGLCo goto XCompany13	-- There is no Old Inter-ARGLCo  	  	
   			select @oldPostGLCo = ARGLCo, @oldPostGLAcct = ARGLAcct,
               	@oldPostAmount = -(isnull(@oldAmount,0)-isnull(@oldDiscTaken,0)-isnull(@oldLineTaxDisc,0)), 
   				@compareICamt = -(isnull(@Amount,0)-isnull(@DiscTaken,0)-isnull(@LineTaxDisc,0)),
				@errdetail = 'XREF GL Acct'
     	  	from bGLIA with (nolock)
         	where ARGLCo = @ARGLCo and APGLCo = @oldCMGLCo  
   
         	if @@rowcount = 0
           		begin
           		select @errmsg = 'Invalid cross company entry in GLIA. Must have Old ReceivableGLCo = '
            		+ isnull(convert(varchar(10),@oldARGLCo),'') + ' -  ' + isnull(@errmsg,'')
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
           		end
     	  	end
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @oldPostAmount = @compareICamt and @CMGLCo = @oldCMGLCo
   			select @oldPostAmount = 0
   
		/* cross company part IV  --  InterCompany Receivables GLCo and GLAcct, retrieve NEW values */
   XCompany13:    
   		if @i=13 
     	  	begin
   			if @TransTypeLine = 'C' and @ARGLCo = @CMGLCo goto ARBAUpdate	-- There is no NEW Inter-ARGLCo
     	  	select @PostGLCo = ARGLCo, @PostGLAcct = ARGLAcct, 
     			@PostAmount = (isnull(@Amount,0)-isnull(@DiscTaken,0)-isnull(@LineTaxDisc,0)), 
   				@compareIColdamt = (isnull(@oldAmount,0)-isnull(@oldDiscTaken,0)-isnull(@oldLineTaxDisc,0)),
				@errdetail = 'XREF GL Acct'
     	  	from bGLIA with (nolock)
         	where ARGLCo = @ARGLCo and APGLCo= @CMGLCo
   
         	if @@rowcount = 0
           		begin
           		select @errmsg = 'Invalid cross company entry in GLIA. Must have New ReceivableGLCo = '
            		+ isnull(convert(varchar(10),@ARGLCo),'') + ' -  ' + isnull(@errmsg,'')
     	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
           		end
     	  	end  
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @PostAmount = @compareIColdamt and @CMGLCo = @oldCMGLCo
   			select @PostAmount = 0
   
      	/* dont create GL if old and new are the same */	
      	if @TransTypeLine='C' and @PostAmount=-IsNull(@oldPostAmount,0) and @PostGLCo=@oldPostGLCo and @PostGLAcct=@oldPostGLAcct
      	goto GLUpdateEnd
   
   ARBAUpdate:
       /*********  This 1st Update/Insert relates to OLD values during Change and Delete Modes *********/
   
       /* if intercompany then try to update the record so there is only one record per transfer */
       if @i>=@InterCompany and @TransTypeLine <> 'A'  
         	begin
         	update bARBA 
   		set Amount = Amount + isnull(@oldPostAmount,0)
         	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=0 and ARLine=@oldPostGLCo and OldNew = 0   /* yes we are using ARLine for the Xcompany */
   			and GLAcct=@oldPostGLAcct
         	if @@rowcount=1 select @oldPostAmount=0  /* set Amount to zero so we dont re-add the record*/
         	end

		/* if not intercompany then update a record if GLAccts are the same.  ARGLAcct, GLRetainAcct
		   and GLARFCRecvAcct may be the same account if user chooses */
		if @i < @InterCompany and @TransTypeLine <> 'A'
			begin
			update bARBA
			set Amount=Amount + isnull(@oldPostAmount,0)
 				where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @oldPostGLCo
  					and GLAcct = @oldPostGLAcct and BatchSeq = @batchseq and ARLine = @ARLine
				and OldNew = 0
			if @@rowcount=1 select @oldPostAmount=0	/* set Amount to zero so we dont't re-add the record */
			end
   
		/* For posting OLD values to all Accounts i=1 thru i=10 */
		if IsNull(@oldPostAmount,0) <> 0 and @TransTypeLine <> 'A' 
           begin
           exec @rcode = bspGLACfPostable @oldPostGLCo, @oldPostGLAcct, @chksubtype, @errmsg output
           if @rcode <> 0
				begin
				select @errortext = @errorstart + '- old ' + @errdetail +' -: ' + @oldPostGLAcct +': '+ @errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
           else
				begin
				insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, OldNew,
					BatchSeq, ARTrans, ARLine, ARTransType, Customer, SortName,CustGroup, CheckNo,
					Contract, ContractItem, ActDate, Description, Amount)
				values(@co, @mth, @batchid, @oldPostGLCo, @oldPostGLAcct, 0,
               		case when @i<@InterCompany then @batchseq else 0 end,
                  	case when @i<@InterCompany then @ARTrans else 0 end,
                  	case when @i<@InterCompany then @ARLine else @oldPostGLCo end,
                  	case when @i<@InterCompany then @artranstype else 'X' end,
                  	case when @i<@InterCompany then @customer else null end,
                 	case when @i<@InterCompany then @SortName else null end,
                  	case when @i<@InterCompany then @CustGroupHD else null end,
                  	case when @i<@InterCompany then @oldcheckno else null end,
                  	case when @i<@InterCompany then @oldContract else null end,
                  	case when @i<@InterCompany then @oldItem else null end,
                  	@transdate,
                  	case when @i<@InterCompany then @OldDescriptionHD else 'Inter-Company Transfer' end,
   					@oldPostAmount)
   
              	if @@rowcount = 0
               		begin
                  	select @errmsg = 'Unable to add AR Detail audit - ' + isnull(@errmsg,''), @rcode = 1
                  	GoTo bspexit
                  	end

				/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
				if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @oldPostGLCo)
   					begin
   					insert bHQCC (Co, Mth, BatchId, GLCo)
   					values (@co, @mth, @batchid, @oldPostGLCo)
   					end
               end
           end 
   
       /*********  This 2nd Update/Insert relates to NEW values during Add and Change Modes *********/
   
       /* if intercompany then try to update the record so there is only one record per transfer */
       if @i >= @InterCompany and @TransTypeLine <> 'D'
			begin
			update bARBA
			set Amount=Amount + @PostAmount
			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=0 and ARLine=@PostGLCo and OldNew = 1	/* yes we are using ARLine for the Xcompany */
           		and GLAcct = @PostGLAcct
   			if @@rowcount=1 select @PostAmount=0 	/* set Amount to zero so we don't re-add the record*/
			end
   
   		/* if not intercompany then update a record if GLAccts are the same.  ARGLAcct, GLRetainAcct
   		   and GLARFCRecvAcct may be the same account if user chooses */
   		if @i < @InterCompany and @TransTypeLine <> 'D'
   			begin
   			update bARBA
   			set Amount=Amount + @PostAmount
     			where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo
      				and GLAcct = @PostGLAcct and BatchSeq = @batchseq and ARLine = @ARLine
   				and OldNew = 1
   			if @@rowcount=1 select @PostAmount=0	/* set Amount to zero so we dont't re-add the record */
   			end 
   
		/* For posting NEW values to all Accounts i=1 thru i=10 */
		if IsNull(@PostAmount,0) <> 0 and (@TransTypeLine <> 'D') 
       		begin
			exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, @chksubtype, @errmsg output
			if @rcode <> 0
           		begin
				select @errortext = @errorstart + '- ' + @errdetail +' -: ' + @PostGLAcct +': '+ @errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   			else
               begin
               insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, OldNew,
					BatchSeq, ARTrans, ARLine, ARTransType, Customer, SortName,CustGroup, CheckNo,
					Contract, ContractItem, ActDate, Description, Amount)
               values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, 1,
               		case when @i<@InterCompany then @batchseq else 0 end,
                  	case when @i<@InterCompany then @ARTrans else 0 end,
                  	case when @i<@InterCompany then @ARLine else @PostGLCo end,
                  	case when @i<@InterCompany then @artranstype else 'X' end,
                  	case when @i<@InterCompany then @customer else null end,
                  	case when @i<@InterCompany then @SortName else null end,
                  	case when @i<@InterCompany then @CustGroupHD else null end,
                  	case when @i<@InterCompany then @checkno else null end,
                  	case when @i<@InterCompany then @Contract else null end,
                  	case when @i<@InterCompany then @ContractItem else null end,
                  	@transdate,
                  	case when @i<@InterCompany then @DescriptionHD else 'Inter-Company Transfer' end,
                  	@PostAmount)
   
              	if @@rowcount = 0
               		begin
                  	select @errmsg = 'Unable to add AR Detail audit - ' + isnull(@errmsg,''), @rcode = 1
                  	GoTo bspexit
                  	end

				/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
				if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   					begin
   					insert bHQCC (Co, Mth, BatchId, GLCo)
   					values (@co, @mth, @batchid, @PostGLCo)
   					end
               end
   			end
   
	GLUpdateEnd:
   	/* get next GL record */
   	select @i=@i+1, @errmsg=''
   	END		--GLUpdate End

	/* JC Update = insert into bARBI */
	--Get tax interface flag from contract master
	--to include tax amount based on flag GR 11/30/00 issue # 11154
	select @taxinterface=TaxInterface 
	from bJCCM with (nolock) 
	where JCCo=@JCCo and Contract=@Contract

	if IsNull(@Amount,0)=0 and IsNull(@Retainage,0)=0 goto JCUpdate_Old
	if @TransTypeLine='D' goto JCUpdate_Old
	if @JCCo is null and @Contract is null and @ContractItem is null goto JCUpdate_Old
	/* its ok to post cash if the Contract item is no longer on file */
	/* so don't validate JCCI */
	/* also Received amount is a positive figure while retainage should be neg */
	if exists(select top 1 1 from bJCCI with (nolock) where JCCo=@JCCo and Contract=@Contract and Item=@ContractItem)
   		begin
      	if @taxinterface='N'
       		begin
			select @taxlessamt = @Amount - (@LineTaxAmount + @LineRetgTax)
			end
		else
			begin
			select @taxlessamt = @Amount
			end
   
      	insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine,
			ARTrans, OldNew, CheckNo, RecvdAmt, Retainage, Description, ActualDate)
      	values(@co, @mth, @batchid, @JCCo, @Contract, @ContractItem, @batchseq, @ARLine, @ARTrans, 1, @checkno,
   	 		(@taxlessamt-@FinanceChg) /*@Amount*/,  
			case @taxinterface when 'Y' then -@Retainage else -(@Retainage - @LineRetgTax) end, 
			@Description, @transdate)
      	if @@rowcount = 0
         	begin
         	select @errmsg = @errorstart + ' Unable to add AR Contract audit', @rcode = 1
         	GoTo bspexit
         	end
      	end
   
   JCUpdate_Old:
	/* update old amounts to JC */
	if @taxinterface='N' 
		begin
		select @oldtaxlessamt=@oldAmount-(@oldLineTaxAmount + @oldLineRetgTax)
		end
	else 
		begin
		select @oldtaxlessamt=@oldAmount
		end

   if IsNull(@oldAmount,0)=0 and IsNull(@oldRetainage,0)=0 goto JCUpdate_End
   if @TransTypeLine='A' goto  JCUpdate_End
   if @oldJCCo is null and @oldContract is null and @oldItem is null goto JCUpdate_End
   if exists(select * from bJCCI where JCCo=@oldJCCo and Contract=@oldContract and Item=@oldItem)
		begin
      	insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine,
          	ARTrans, OldNew, CheckNo, RecvdAmt, Retainage, Description, ActualDate)
      	values(@co, @mth, @batchid, @oldJCCo, @oldContract, @oldItem, @batchseq, @ARLine,
          	@ARTrans, 0, @oldcheckno, -(@oldtaxlessamt-@FinanceChg) /*-@oldAmount*/, 
			case @taxinterface when 'Y' then @oldRetainage else @oldRetainage - @oldLineRetgTax end, 
			@oldDescription, @oldtransdate)
      	if @@rowcount = 0
     		begin
         	select @errmsg = @errorstart + ' Unable to add old AR Contract audit', @rcode = 1
         	GoTo bspexit
         	end
      	end
   
   JCUpdate_End:
   
	/*****************/
	/* get next line */
	/*****************/
	select @ARLine=Min(ARLine)
	from bARBL with (nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq and ARLine > @ARLine
	END		-- End Line Loop
   
bspexit:
	if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBH1_ValCashLines]'
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARBH1_ValCashLines] TO [public]
GO
