SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBHVal    Script Date: 8/28/99 9:36:06 AM ******/
CREATE procedure [dbo].[bspARBHVal]
/************************************************************************************
* CREATED BY:	CJW 5/10/97
* MODIFIED By :	GG 04/22/99     (SQL 7.0)
*			bc 07/16/99  added @AmtChange in GL dist. for when only the sign of a value has changed
*       	bc 09/01/99  check to make sure a line that is being deleted does not have transactions applied to it
*                        that are not marked as delete.
*           GR 03/07/00  added the check to see whether misc dist lines are marked for deletion when
*                        transtype is 'D'
*           GG 04/26/00  removed references to MSCo and MSTrans
*	        bc 08/17/00 - added restriction to the ARBI section to not process write off transactions
*           bc 10/26/00 - if ContractUnits <> 0 then ARBI should be updated even if Amount = 0 and Retainage = 0.
*           bc 11/28/00 - write out an error if no records exist in ARBL for a given ARBH record
*           bc 11/30/00 - correct inter-company posting
*           bc 02/28/01 - added validation of payment terms
*			TJL  03/12/01  - added validation of ReasonCode
*           bc  05/29/01 - added validation from btARTLi about the batch line needing to match
*                         the info from the original invoice line for certain types of transactions
*	        gh  07/03/01 - do not validate UM on line level if artranstype=('A','C','W') Issue #13893
*			TJL 07/20/01 - Allow Adjustments, credits and writeoffs for LineType 'R' Released Retainage Invoices
*			TJL 07/24/01 - Error to log if all lines are not marked to Delete when user deletes invoice header.
*			TJL 07/31/01 - Per above mod, UM should also validate if LineType = ('J'ob or 'E'quip) and ARTransType = 'M'isc Cash Receipt
*			TJL 08/28/01 - Allow Detail LineType changes on Adjustments and Credits per Issue #13448
*			TJL 09/24/01 - Issue #14610,  Minor change to Compare orig TaxGroup and TaxCode for 'A' and 'W' as well as 'C' types.
*           TJL 10/02/01 - Issue #13104, Supercedes Issue #13448, Remove all LineType validation completely
*           bc  10/12/01 - Issue #14900 Fixed the code that creates the Dummy ARTL record for new Lines on an Adjustment transaction.
*			TJL 11/28/01 - Issue #14449, Validate the existence of DueDate and TransDate on original Invoice.
*			TJL 01/28/02 - Issue #16038 & 14610, If bARBL TaxAmount not 0.00 then check for presence of bARBL.TaxCode
*			TJL 02/06/02 - Issue #15875,  On transtype 'D', changes to checking for Apply Transactions.  See issue for Explanation.
*			TJL 02/14/02 - Issue #16285, Rewrite GLAcct and Inter-Company Processing.
*			TJL 04/08/02 - Issue #15759, Add GLARFCRecvAcct to GL Account processing.
*			TJL 04/16/02 - Issue #16468, Correct Description and Invoice Posting to GLDT Description field
*			TJL 04/16/02 - Issue #16126, Do not allow posting if Invoice string is empty
*			TJL 04/18/02 - Issue #16905, Catch improper GLAcct SubTypes during GLAcct validation.
*			TJL 04/18/02 - Issue #16097, Check that if posting revenue to a JC InterCompany, that InterCompany SubLedger is open.
*			TJL 04/25/02 - Issue #16468, Related to correctly updateing GLDT for Interface Lvl 2 (Transaction)
*			TJL 04/29/02 - Issue #16669, Correct update ARTrans in ARBM from ARBH for 'C' type Transactions when 'A'dding a MiscDist
*			TJL 04/29/02 - Issue #16431, Keep Tax Liability with ARCo rather than sending to JCCo during Intercompany GL
*			TJL 05/02/02 - Issue #16830, Under special circumstances, Revenue Acct may be same as AR Receivables Acct
*			TJL 05/31/02 - Issue #17492, Relates to how we update GLAccts when they are the same.
*			TJL 08/07/02 - Issue #18237, InterCompany Payables/Receivables to Multiple Accts, same Co.
*			TJL 02/19/03 - Issue #20369, If Form GLAcct is NULL, send error to HQBE
*			TJL 02/19/03 - Issue #19998, Update ARBI(JCID) if TransDate is changed
*			TJL 07/01/03 - Issue #21610, Validate change in RecType at the header level
*			TJL 07/15/03 - Issue #21835, Validate TaxCode.  Was not throwing (was missing) the error message
*			TJL 08/08/03 - Issue #22087, Performance Mods, Add NoLocks
*			TJL 09/24/03 - Issue #22509, ARInvoice Entry Lines GLAcct may not be NULL
*			GWC 03/11/04 - Issue #23960, Validate change in Contract at the header level
*			TJL 06/27/05 - Issue #29151, Correct Issue #26044
*			TJL 09/12/06 - Issue #120018, Corrected when Invalid TaxCode on Lines after first line not caught during validation
*			GG 09/25/06 - Issue #122561, @RecType validation
*			TJL 02/26/07 - Issue #120561, Made adjustment pertaining to bHQCC Close Control entry handling
*			TJL 10/11/07 - Issue #125729, Add INCo, Loc to validation of same against original transaction line
*			TJL 10/26/07 - Issue #123134, Do not allow ALL Lines to be deleted when the Invoice header is still set for Change 
*			TJL 06/02/08 - Issue #128286, ARInvoiceEntry International Sales Tax
*			TJL 11/05/08 - Issue #123056, Validate GL Fiscal Yr for Intercompany JC GLCo
*			TJL 11/13/08 - Issue #128095, Update JCID when only the GLAcct changes on the line
*			TJL 03/03/09 - Issue #132528, Invoice batch Trigger error during validation.  Cannot insert NULL into ARBI.JCCo
*			TJL 06/30/09 - Issue #121350, Create original ARTL lines for an Adjustment during post rather than during validation
*			TJL 07/17/09 - Issue #23618, When Contract is Final Closed, Rev changes need to be posted to Closed Rev Accounts
*			TJL 07/22/09 - Issue #130964, Auto generate Misc Distributions base on AR Customer setup.
*			TJL 11/13/09 - Issue #136580, Functionally NO CHANGE.  Only removed & added remarks.
*			MV	02/04/10 - Issue #136500 - bspHQTaxRateGetAll added NULL output param.
*			AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*			MV	10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param.
*			
*
* USAGE:  Used to validate invoices in bARBH.  Spins through headers and lines.
* Creates distributions for Job Cost, Inventory, Misc Distributions, General Ledger.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Job distributions added to bARBI
* Inventory distributions added to b
* GL Account distributions added to bARBA
* Cross company GL in bGLIA
* GL debit and credit totals must balance.
* bHQ
******************************************************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @source char(10), @errmsg varchar(255) output
as
   
set nocount on

/* Declare working variables */
declare @rcode int, @errortext varchar(255), @tablename char(20), @seq int,
  	@inuseby bVPUserName, @status tinyint, @opencursorARBL tinyint, @opencursorARBH tinyint, @opencursorARBM TINYINT,
  	@lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint, @accttype char(1),
  	@itemcount int, @deletecount int, @addchangecount int, @errorstart varchar(50), @chksubtype char(1),
  	@isContractFlag bYN, @SortName varchar(15), @actdate bDate,@BilledAmt int, @GLARAcct bGLAcct,
  	@invjrnl bJrnl, @glinvoicelvl int, @AR_glco int, @fy bMonth, @RecTypeGLCo int, @PostGLCo bCompany,
  	@PostAmount bDollar, @PostGLAcct bGLAcct, @oldPostGLCo bCompany, @oldPostAmount bDollar,@oldPostGLAcct bGLAcct,
  	@i int, @CMGLCo bCompany, @CMGLCash bGLAcct, @oldCMGLCo bCompany, @oldCMGLCash bGLAcct, 
  	@GLRevAcct bGLAcct, @oldGLRevAcct bGLAcct, @tmpCo bCompany, @count int, @errorAccount varchar(25),
 	@UpdateTax bYN, @AmtChange bYN, @InterCompany int, @compareICamt bDollar, @compareIColdamt bDollar,
	@GLARFCRecvAcct bGLAcct, @oldGLARFCRecvAcct bGLAcct, @GLARFCWoffAcct bGLAcct, @oldGLARFCWoffAcct bGLAcct,
	@JCGLCo bCompany, @oldJCGLCo bCompany, @JCsubclosed bMonth, @oldJCsubclosed bMonth, 
	@miscdistdfltvalue bDollar,
	--International Sales Tax
	@taxrate bRate, @gstrate bRate, @pstrate bRate, 
	@HQTXcrdGLAcct bGLAcct, @HQTXcrdRetgGLAcct bGLAcct, @oldHQTXcrdGLAcct bGLAcct, @oldHQTXcrdRetgGLAcct bGLAcct, 
	@HQTXcrdGLAcctPST bGLAcct, @HQTXcrdRetgGLAcctPST bGLAcct, @oldHQTXcrdGLAcctPST bGLAcct, @oldHQTXcrdRetgGLAcctPST bGLAcct,
	@TaxAmount bDollar, @RetgTax bDollar, @TaxAmountPST bDollar, @RetgTaxPST bDollar, 
	@oldTaxAmount bDollar, @oldRetgTax bDollar, @oldTaxAmountPST bDollar, @oldRetgTaxPST bDollar,
	@GLDetlDesc varchar(60)

--@HQTXGLAcct bGLAcct, @oldHQTXGLAcct bGLAcct, 
  
/*Declare AR Header variables*/
declare @transtype char(1), @ARTransHD bTrans, @artranstype char(1), @custgroup bGroup, @ARGLCo bCompany,@oldARGLCo bCompany,
  	@GLRetainAcct bGLAcct, @GLDiscountAcct bGLAcct, @oldGLARAcct bGLAcct,@oldGLRetainAcct bGLAcct, @oldGLDiscountAcct bGLAcct, 
	@customer bCustomer, @hrectype tinyint, @JCCoHD bCompany, @ContractHD bContract,
  	@custref varchar(10), @invoice char(10),@checkno char(10), @transdesc bDesc, @transdate bDate, @duedate bDate,
  	@discdate bDate,
  	@checkdate bDate, @appliedmth bMonth, @appliedtrans bTrans, @cmco bCompany, @cmacct bCMAcct,
  	@cmdeposit varchar(10), @creditamt bDollar, @payterms bPayTerms,
  	@oldcustref char(20), @oldinvoice char(10), @oldcheckno char(10), @oldreasoncode bReasonCode, @reasoncode bReasonCode,
  	@oldtransdate bDate, @oldduedate bDate, @olddiscdate bDate, @oldcheckdate bDate, @oldcmco bCompany,
  	@oldcmacct bCMAcct, @oldcmdeposit varchar(10), @oldcreditamt bDollar, @oldpayterms bPayTerms, @changed bYN,
	@oldtransdesc bDesc, @holdrectype tinyint, @holdjcco bCompany, @holdcontract bContract 
   
/*Declare AR Line variables */
declare @BatchSeq int, @ARLine smallint, @TransTypeLine char, @ARTrans bTrans,
  	@RecType tinyint, @LineType char, @Line_GLCo bCompany, @TaxGroup bGroup,
  	@TaxCode bTaxCode, @Amount bDollar, @TaxBasis bDollar, @LineTaxAmount bDollar, @RetgPct bPct, @Retainage bDollar, @LineRetgTax bDollar,
  	@DiscOffered bDollar, @TaxDisc bDollar, @DiscTaken bDollar, @FinanceChg bDollar,
	@ApplyMth bMonth, @ApplyTrans bTrans, @ApplyLine smallint, @LineDesc bDesc,
  	@JCCo bCompany, @Contract bContract, @ContractItem bContractItem, @ContractUnits bUnits, @Job bJob,
  	@PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType, @UM bUM, @JobUnits bUnits, @JobHours bHrs, @INCo bCompany, @Loc bLoc,
  	@MatlGroup bGroup, @Material bMatl, @UnitPrice bUnitCost, @ECM bECM, @MatlUnits bUnits,
  	@CustJob varchar(10), @EMCo bCompany, @Equipment bEquip, @EMGroup bGroup, @CostCode bCostCode, @EMCType bEMCType,
  	@oldRecType tinyint, @oldLineType char, @oldLineDesc bDesc,@oldLine_GLCo  bCompany, 
 	@oldTaxGroup  bGroup, @oldTaxCode  bTaxCode, @oldAmount bDollar, @oldTaxBasis bDollar, @oldLineTaxAmount bDollar,
  	@oldRetgPct bPct, @oldRetainage bDollar, @oldLineRetgTax bDollar, @oldDiscOffered bDollar, @oldDiscTaken bDollar, @oldFinanceChg bDollar,
  	@oldApplyMth  bMonth, @oldApplyTrans bTrans, @oldApplyLine  smallint, @oldJCCo bCompany, @oldContract bContract,
  	@oldItem bContractItem, @oldContractUnits bUnits, @oldJob bJob, @oldPhaseGroup  bGroup, @oldPhase  bPhase,
  	@oldCostType bJCCType, @oldUM bUM, @oldJobUnits bUnits, @oldJobHours bHrs, @oldINCo bCompany, @oldLoc bLoc,
  	@oldMatlGroup bGroup, @oldMaterial bMatl, @oldUnitPrice bUnitCost, @oldMatlUnits bUnits,
  	@oldCustJob varchar (10), @oldEMGroup bGroup, @oldEquipment bEquip,
  	@oldCostCode bCostCode , @oldEMCType bEMCType, @oldECM bECM, @CompanyForVal bCompany, 
	@errorTrans bTrans,
	@SMTransDesc varchar(60), @GLEntryID bigint, @HQBatchDistributionID bigint, @SMWorkCompletedID bigint, @IsReversing bit
   
/*Declare Misc Dist Variables*/
declare @old varchar(30), @new varchar(30),@key varchar(30),
	@MiscDistCode char(10), @OldNew tinyint, 
	@DistDate bDate, @oldDistDate bDate, @ReturnCustomer bCustomer,
  	@ContractStatus int, @tmpGLAcct bGLAcct, @pum bUM, @deptdead bDept, @custdead bCustomer, @retgdead bPct,
  	@startmthdead bMonth, @MiscDistOnInvYN bYN, @contractmiscdistcode char(10), @custmiscdistcode char(10), @miscdistcodedflt char(10),
  	@mdcdescription bDesc
   
/* set open cursor flags to false */
select @opencursorARBH = 0, @opencursorARBL = 0, @opencursorARBM = 0

/* validate source */
if @source not in ('AR Invoice','SM Invoice')
	begin
	select @errmsg = @source + ' is invalid', @rcode = 1
	goto bspexit
	end

EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = @source, @TableName = 'ARBH', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @errmsg OUTPUT
IF @rcode <> 0 RETURN @rcode

/* clear JC Distributions Audit */
delete bARBI where ARCo = @co and Mth = @mth and BatchId = @batchid

/* clear GL Distribution list */
delete bARBA where Co = @co and Mth = @mth and BatchId = @batchid

/* clear GL Entries created for SM */
DELETE vGLEntry
FROM dbo.vGLEntryBatch
	INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
WHERE vGLEntryBatch.Co = @co AND vGLEntryBatch.Mth = @mth AND vGLEntryBatch.BatchId = @batchid

/* clear and refresh HQCC entries */
/* Removed per Issue #120561:  Because of the possibility of JC Cross Company GL Revenue values,
   this is better handled later in the procedure while inserting into GL distribution table itself. 
   Also clearing bHQCC, at this point, clears the initial record set by the bARBL insert trigger. */
--delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
--insert into bHQCC(Co, Mth, BatchId, GLCo)
--select distinct Co, Mth, BatchId, GLCo 
--from bARBL with (nolock)
--where Co=@co and Mth=@mth and BatchId=@batchid

/* get some company specific variables and do some validation*/
/* need to validate GLFY and GLJR if gl is going to be updated*/
select @invjrnl = InvoiceJrnl, @glinvoicelvl = GLInvLev, @AR_glco = GLCo, @GLDetlDesc = RTRIM(GLInvDetailDesc)
from ARCO with (nolock)
where ARCo = @co
if @glinvoicelvl > 0
	begin
	exec @rcode = bspGLJrnlVal @AR_glco, @invjrnl, @errmsg output
	if @rcode <> 0 or @invjrnl is null
   		begin
  	    select @errortext = 'Invalid Journal - A valid journal must be setup in AR Company.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	    if @rcode <> 0 goto bspexit
		end

	/* validate Fiscal Year of ARCo */
	select @fy = FYEMO 
	from bGLFY with (nolock)
	where GLCo = @AR_glco and @mth >= BeginMth and @mth <= FYEMO
	if @@rowcount = 0
		begin
  	    select @errortext = 'Must first add Fiscal Year'
  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	    if @rcode <> 0 goto bspexit
  	    end
   
	/* NEED TO WORK ON THIS
	if @adj = 'Y' and @mth <> @fy
		begin
		select @errortext = @errorhdr + 'Adjustment entries must be made in a Fiscal Year ending month'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end
	*/
	end
   
/* declare cursor on AR Header Batch for validation */
declare bcARBH cursor local fast_forward for 
select BatchSeq, TransType, ARTrans, Invoice, Source, ARTransType, CustGroup, Customer, RecType,
	JCCo, Contract, TransDate, DueDate, AppliedMth, AppliedTrans, CMCo, CMAcct, CMDeposit, PayTerms, Description,
 	oldCustRef, oldInvoice, oldCheckNo, oldDescription, oldTransDate, oldDueDate,
  	oldDiscDate, oldCheckDate, oldCMCo, oldCMAcct, oldCMDeposit, oldCreditAmt, oldPayTerms,
	ReasonCode, oldReasonCode, oldRecType, oldJCCo, oldContract 
from bARBH with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
   
/* open cursor */
open bcARBH
/* set open cursor flag to true */
select @opencursorARBH = 1
/* get rows out of ARBH*/
get_next_bcARBH:
fetch next from bcARBH into @seq, @transtype, @ARTransHD, @invoice, @source, @artranstype, @custgroup, @customer, @hrectype,
	@JCCoHD, @ContractHD, @transdate, @duedate, @appliedmth, @appliedtrans, @cmco, @cmacct, @cmdeposit, @payterms,
	@transdesc,
	@oldcustref, @oldinvoice, @oldcheckno, @oldtransdesc,
	@oldtransdate, @oldduedate, @olddiscdate, @oldcheckdate, @oldcmco, @oldcmacct, @oldcmdeposit,
	@oldcreditamt, @oldpayterms, @reasoncode, @oldreasoncode, @holdrectype, @holdjcco, @holdcontract
   
/*Loop through all rows */
while (@@fetch_status = 0)
   	Begin  /* Begin ARBH Loop */
	select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
	select @isContractFlag = case when @ContractHD is null then 'N' else 'Y' end
	
	/* Reset some variables */
	select @miscdistcodedflt = null, @custmiscdistcode = null, @contractmiscdistcode = null, @mdcdescription = null

	if @transtype<>'A' and @transtype<>'C' and @transtype <>'D'
  		begin
  		select @errortext = @errorstart + ' - invalid transaction type, must be A, C, or D.'
  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	    if @rcode <> 0 goto bspexit
  	    end

	/* validation specific to ADD type AR header*/
	if @transtype = 'A'
  		begin
  		/* all old values must be null if a new transaction */
  		if @oldcustref is not null or @oldinvoice is not null or @oldcheckno is not null or
  			@oldtransdesc is not null or @oldtransdate is not null or @oldduedate is not null or
  			@olddiscdate  is not null or @oldcheckdate is not null or @oldcmco is not null or
  			@oldcmacct is not null or @oldcmdeposit  is not null or
  			@oldcreditamt is not null or @oldpayterms is not null or @oldreasoncode is not null
  			begin
       		select @errortext =@errorstart + ' - Old entries in batch must be null for Add type entries.'
  			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  			if @rcode<>0 goto bspexit
  			end
  		end

	/* validation specific to ADD or CHANGE type AR header */
	if @transtype = 'C' or @transtype = 'A'
  		begin
  	    /*Validate apply to transaction if necessary */
  	    if @artranstype in ('A','W','C')
  			begin
  		    if @appliedmth > @mth
  				begin
  		       	select @errortext = @errorstart + ' - Invalid apply to month ' + isnull(convert(varchar(20),@appliedmth),'')
  		       	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		       	goto bspexit
				end
  	        end

  	    /*validate customer*/
		exec @rcode = bspARCustomerVal @custgroup, @customer, NULL, @ReturnCustomer output, @errmsg output
  	   	if @rcode = 0
  	        begin
  		   	/*get SortName*/
  	 	  	select @SortName = m.SortName, @MiscDistOnInvYN = MiscOnInv, @custmiscdistcode = MiscDistCode 
  	 	  	from bARCM m with (nolock)
  	 	  	where m.CustGroup = @custgroup and m.Customer = @customer
  	        end
		else
  	        begin
  	        select @errortext = @errorstart + '- Customer ' + isnull(convert(varchar(10),@customer),'') + ' is not a valid customer!'
  	  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		    if @rcode <> 0 goto bspexit
  	        end
   
 		/* validate Invoice Number must not be null */
 		if isnull(@invoice,'') = '' and isnull(@artranstype, '') <> 'W'
    		begin
    		select @errortext = @errorstart + ' - Invoice number must not be null!'
    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    		goto bspexit
         	end
   
       -- validate payment terms
       if @payterms is not null and not exists (select 1 from bHQPT with (nolock) where PayTerms = @payterms)
			begin
  	        select @errortext = @errorstart + '- Payment Terms ' + isnull(convert(varchar(10),@payterms),'') + ' is not valid!'
  	  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		    if @rcode <> 0 goto bspexit
			end
   
  	    if @isContractFlag='Y' /* If a contract is present */
  	        begin
  		    /*validate JCCo*/
  	        exec @rcode = bspJCCompanyVal @JCCoHD, @errmsg output
  		    if @rcode <> 0
  		    	begin
  		       	select @errortext = @errorstart + '- JCCo:' + isnull(convert(varchar(3),@JCCoHD),'') +': ' + isnull(@errmsg,'')
  		       	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		       	if @rcode <> 0 goto bspexit
  		       	end

  		    select @errmsg = NULL
  		    /*validate Contract*/
  		   	exec @rcode = bspJCContractVal @JCCoHD, @ContractHD, @ContractStatus output, @deptdead output, @custdead output, @retgdead output, @startmthdead output, @msg=@errmsg output
  		   	if @rcode <> 0
  		       	begin
  		       	select @errortext = @errorstart + '- Contract:' + isnull(@ContractHD,'') +': '+ isnull(@errmsg,'')
  		       	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		       	if @rcode <> 0 goto bspexit
  	           	end
   			
      		select @UpdateTax = TaxInterface, @contractmiscdistcode = MiscDistCode
   			from bJCCM m with (nolock)
   			where m.JCCo = @JCCoHD and m.Contract = @ContractHD
	  
      		select @errmsg = NULL
   
   			/* If InterCompany JC, Validate JCCo Last SubLedger ClosedDate */
			select @JCGLCo = GLCo
			from bJCCO with (nolock)
			where JCCo = @JCCoHD

			select @JCsubclosed = LastMthSubClsd, @maxopen = MaxOpen 
			from bGLCO with (nolock)
			where GLCo = @JCGLCo
			if @mth <= @JCsubclosed or @mth > dateadd(month, @maxopen, @JCsubclosed)
				begin
 	   			select @errortext = @errorstart + ' - JC GLCo ' + isnull(convert(varchar(3),@JCGLCo),'') + ' subledger has been closed'
				select @errortext = @errortext + ' through month ' + isnull(convert(varchar(8), @JCsubclosed, 1),'') + '!'
 	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 				if @rcode <> 0 goto bspexit 
				end

			/* validate Fiscal Year of JCCo */
			select @fy = FYEMO 
			from bGLFY with (nolock)
			where GLCo = @JCGLCo and @mth >= BeginMth and @mth <= FYEMO
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + 'Must first add Fiscal Year for JC GLCo ' + isnull(convert(varchar(3),@JCGLCo),'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   
			if @transtype = 'C' and isnull(@holdjcco,0) <> @JCCoHD
   				begin
   				select @oldJCGLCo = GLCo
   				from bJCCO
   				where JCCo = @holdjcco
   			
   				select @oldJCsubclosed = LastMthSubClsd, @maxopen = MaxOpen 
   				from bGLCO
   				where GLCo = @oldJCGLCo
   
   				if @mth <= @oldJCsubclosed or @mth > dateadd(month, @maxopen, @oldJCsubclosed)
   					begin
     	   			select @errortext = @errorstart + ' -  Old JC GLCo ' + convert(varchar(3),@oldJCGLCo) + ' subledger has been closed'
   					select @errortext = @errortext + ' through month ' + convert(varchar(8), @oldJCsubclosed, 1) + '!'
     	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit 
   					end

				/* validate Fiscal Year of old JCCo */
				select @fy = FYEMO 
				from bGLFY with (nolock)
				where GLCo = @oldJCGLCo and @mth >= BeginMth and @mth <= FYEMO
				if @@rowcount = 0
					begin
					select @errortext = @errorstart + 'Must first add Fiscal Year for JC GLCo ' + isnull(convert(varchar(3),@oldJCGLCo),'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
   				end 
   
      		end /* jcco - contract val */
   		
   		-- Validate TransDate and DueDate.
   		if @artranstype = 'I'	-- TransDate and DueDate may not be NULL for original invoice
   			begin
   			if isnull(@transdate, '') = '' or isnull(@duedate, '') = ''
   				begin
   				select @errortext = @errorstart + '- Invoice Date and Due Date may not be NULL on an original invoice! ' + isnull(@errmsg,'')
  		       	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		       	if @rcode <> 0 goto bspexit
  	           	end
   			end
   		else		-- TransDate may not be NULL for Adjustment, Credit or Writeoff
   			begin
   			if isnull(@transdate, '') = ''
   				begin
   				select @errortext = @errorstart + '- Invoice Date may not be NULL! ' + isnull(@errmsg,'')
  		       	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  		       	if @rcode <> 0 goto bspexit
  	           	end
   			end 
   
		end /* Add or Change Val */
   
	/* validation specific to CHANGE type AR header*/
	if @transtype = 'C'
		begin
		/* Do not allow ALL Lines to be deleted when the Invoice header is still set for Change */ 
		select @addchangecount = count(*)
		from bARBL with (nolock)
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and TransType in ('A', 'C')
		if  @addchangecount = 0
			begin
	        select @errortext = @errorstart + ' - In order to change an invoice, at least one line set for Add or Change must exist! '
	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	        if @rcode <> 0 goto bspexit
			end

		/* Need to check to see if there are any transactions applied to the one we are trying to change.
		   You may only change RecType on 'I' type invoices using the ARInvoiceEntry program!
		   You will never be allowed to change RecType on original FinanceChg Invoices or original
		   Released Retg Invoices because 'F' & 'R' ARTransTypes may also be applied (Not original) 
		   transactions. */
		if @hrectype <> @holdrectype
			and (exists (select top 1 1 from bARTH h with (nolock)
					join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
					where l.ARCo = @co and l.ApplyMth = @mth and l.ApplyTrans = @ARTransHD 
						and h.ARTransType not in ('I'))
				or exists (select top 1 1 from bARBH bh with (nolock)
					join bARBL bl with (nolock) on bh.Co = bl.Co and bh.Mth = bl.Mth 
						and bh.BatchId = bl.BatchId and bh.BatchSeq = bl.BatchSeq
					where bl.Co = @co and bl.ApplyMth = @mth and bl.ApplyTrans = @ARTransHD 
						and bh.ARTransType not in ('I')))
      			begin
				select @errortext = @errorstart + ' - Transaction - ' + isnull(convert(varchar(40),@ARTransHD),'') + 
					' - has other transactions applied to it.  You may not change RecType! '
 				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 				if @rcode <> 0 goto bspexit
 				end
   
   		/*validate that the Contract has not been modified for Change transaction types*/
   		if ISNULL(@holdcontract,'') <> ISNULL(@ContractHD,'') OR ISNULL(@holdjcco,0) <> ISNULL(@JCCoHD,0)
   			begin
   			select @errortext = @errorstart + '- JCCo: ' + isnull(convert(varchar(3),@holdjcco),0) + ' Contract: ' + 
   				isnull(@holdcontract,'') + ': has been changed to JCCo: ' + isnull(convert(varchar(3),@JCCoHD),0) + 
   				' Contract: ' + isnull(@ContractHD,'') +
   				'. Contracts cannot be changed.'
   			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			if @rcode <> 0 goto bspexit
   		    end
   		end /* Change Val */
   
	/* validation specific to DELETE type AR header*/
	if @transtype = 'D'
		begin
		/* Need to check to see if there are any transactions applied to the one we are trying to delete.
		   You may only delete 'I' applied transactions using the ARInvoiceEntry program! (Others not displayed
		   in "Add Transactions" lookup and cannot be added to ARInvoiceEntry batch.) Only the original 
		   Invoice transaction will contain ARTransType 'I' at this point. */
 	   	if (exists (select top 1 1 from bARTH h with (nolock)
				join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
				where l.ARCo = @co and l.ApplyMth = @mth and l.ApplyTrans = @ARTransHD 
					and h.ARTransType not in ('I'))
			or exists (select top 1 1 from bARBH bh with (nolock)
				join bARBL bl with (nolock) on bh.Co = bl.Co and bh.Mth = bl.Mth 
					and bh.BatchId = bl.BatchId and bh.BatchSeq = bl.BatchSeq
				where bl.Co = @co and bl.ApplyMth = @mth and bl.ApplyTrans = @ARTransHD 
					and bh.ARTransType not in ('I')))
      		begin
			select @errortext = @errorstart + ' - Transaction - ' + isnull(convert(varchar(40),@ARTransHD),'') + 
				' - has other transactions applied to it that must first be removed. Cannot delete! '
 	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 	        if @rcode <> 0 goto bspexit
 	        end
   
		if @isContractFlag='Y' /* If a contract is present */
      		begin
			/* cannot change the header jcco or contract on a transaction pulled into a batch so we do not need an 'old' variable */
			select @UpdateTax = TaxInterface, @ContractStatus = ContractStatus 
   			from bJCCM m with (nolock)
   			where m.JCCo = @JCCoHD and m.Contract = @ContractHD
   		
   			/* If InterCompany JC, Validate JCCo Last SubLedger ClosedDate */
			select @oldJCGLCo = GLCo
			from bJCCO
			where JCCo = @holdjcco
		
			select @oldJCsubclosed = LastMthSubClsd, @maxopen = MaxOpen 
			from bGLCO
			where GLCo = @oldJCGLCo

			if @mth <= @oldJCsubclosed or @mth > dateadd(month, @maxopen, @oldJCsubclosed)
				begin
 	   				select @errortext = @errorstart + ' -  Old JC GLCo ' + convert(varchar(3),@oldJCGLCo) + ' subledger has been closed'
				select @errortext = @errortext + ' through month ' + convert(varchar(8), @oldJCsubclosed, 1) + '!'
 	 				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 					if @rcode <> 0 goto bspexit 
				end

			/* validate Fiscal Year of old JCCo */
			select @fy = FYEMO 
			from bGLFY with (nolock)
			where GLCo = @oldJCGLCo and @mth >= BeginMth and @mth <= FYEMO
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + 'Must first add Fiscal Year for JC GLCo ' + isnull(convert(varchar(3),@oldJCGLCo),'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   			end
   
		/* To delete invoice header, all invoice lines must be marked for delete  -  Issue# 13980 */
		select @itemcount = count(*) 
   		from bARTL with (nolock)
   		where ARCo=@co and Mth = @mth and ARTrans=@ARTransHD
   
		select @deletecount= count(*)
		from bARBL with (nolock)
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and TransType='D'
		if @itemcount <> @deletecount
  	    	begin
  	        select @errortext = @errorstart + ' - In order to delete an AR Invoice, all Invoice lines must be in the current batch and marked for delete! '
  	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	        if @rcode <> 0 goto bspexit
  	       	end
   
		select @deletecount = count(*)
		from bARBL with (nolock)
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and TransType<>'D'
		if  @deletecount <> 0
			begin
	        select @errortext = @errorstart + ' - In order to delete an invoice you cannot have any Add or Change lines! '
	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	        if @rcode <> 0 goto bspexit
			end
   
		/* Check whether misc dist are marked for deletion, if exists, added this as per issue 6560 */
		if exists(select top 1 1 from bARBM with (nolock)
              where Co = @co and Mth = @mth and ARTrans = @ARTransHD and TransType <> 'D')
       		begin
			select @errortext= @errorstart + 'Misc Distributions exist - not marked for deletion'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	       	if @rcode <> 0 goto bspexit
			end
   
		end /* Delete validation */
   
	/* Validation for all lines associated to this AR Transaction */
	declare bcARBL cursor local fast_forward for 
   	select ARLine, TransType, ARTrans, RecType, LineType, Description, GLCo, GLAcct,
      	    	TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered, TaxDisc, DiscTaken,
      	    	FinanceChg, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, ContractUnits, Job,
      	    	PhaseGroup, Phase, CostType, UM, JobUnits, JobHours, INCo, Loc, MatlGroup,
      	   		Material, UnitPrice, ECM, MatlUnits,
      	    	oldRecType, oldLineType, oldDescription, oldGLCo, oldGLAcct,
      	    	oldTaxGroup, oldTaxCode, oldAmount, oldTaxBasis, oldTaxAmount, oldRetgTax, oldRetgPct, oldRetainage, oldDiscOffered, oldDiscTaken,
      	    	oldFinanceChg, oldApplyMth, oldApplyTrans, oldApplyLine, oldJCCo, oldContract, oldItem, oldContractUnits, oldJob,
      	    	oldPhaseGroup, oldPhase, oldCostType, oldUM, oldJobUnits, oldJobHours, oldINCo, oldLoc, oldMatlGroup,
      	    	oldMaterial, oldUnitPrice, oldECM, oldMatlUnits
	from bARBL with (nolock)
   	where Co = @co and Mth = @mth and BatchId=@batchid and BatchSeq=@seq
   
	/* open cursor for line */
	open bcARBL
	/* set appropiate cursor flag */
	select @opencursorARBL = 1
	/*get first row (line)*/
get_next_bcARBL:
   	fetch next from bcARBL into
      	    	@ARLine, @TransTypeLine, @ARTrans, @RecType, @LineType, @LineDesc, @Line_GLCo, @GLRevAcct, @TaxGroup,
      	    	@TaxCode, @Amount, @TaxBasis , @LineTaxAmount, @LineRetgTax, @RetgPct, @Retainage, @DiscOffered, @TaxDisc, @DiscTaken, @FinanceChg,
   				@ApplyMth, @ApplyTrans, @ApplyLine, @JCCo, @Contract, @ContractItem, @ContractUnits, @Job,
      	    	@PhaseGroup, @Phase, @CostType , @UM, @JobUnits, @JobHours, @INCo, @Loc,
      	    	@MatlGroup, @Material, @UnitPrice, @ECM, @MatlUnits,
      	    	@oldRecType, @oldLineType, @oldLineDesc,
      	    	@oldLine_GLCo, @oldGLRevAcct, @oldTaxGroup, @oldTaxCode, @oldAmount, @oldTaxBasis, @oldLineTaxAmount, @oldLineRetgTax, @oldRetgPct, @oldRetainage, @oldDiscOffered,
      	    	@oldDiscTaken, @oldFinanceChg, @oldApplyMth, @oldApplyTrans, @oldApplyLine, @oldJCCo, @oldContract, @oldItem, @oldContractUnits, @oldJob,
      	    	@oldPhaseGroup, @oldPhase, @oldCostType, @oldUM, @oldJobUnits, @oldJobHours, @oldINCo, @oldLoc,	@oldMatlGroup,
      	    	@oldMaterial, @oldUnitPrice, @oldECM, @oldMatlUnits
	while (@@fetch_status = 0)
		Begin /* Begin ARBL Loop - Spin through the Lines */
		select @errorstart = 'Seq' + convert (varchar(6),@seq) + ' Item ' + convert(varchar(6),@ARLine)+ ' '
   
		/* Reset Line variables as needed here.  
 		   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
		select @HQTXcrdGLAcct = null, @HQTXcrdRetgGLAcct = null, @HQTXcrdGLAcctPST = null, @HQTXcrdRetgGLAcctPST = null,
			@oldHQTXcrdGLAcct = null, @oldHQTXcrdRetgGLAcct = null, @oldHQTXcrdGLAcctPST = null, @oldHQTXcrdRetgGLAcctPST = null,
			@TaxAmount = 0,	@TaxAmountPST = 0, @RetgTax = 0, @RetgTaxPST = 0,
			@oldTaxAmount = 0,	@oldTaxAmountPST = 0, @oldRetgTax = 0, @oldRetgTaxPST = 0

   		/* USER input for GLAcct may never be NULL.  There are conditions where a NULL value could sneak
   		   by validation (ie. TotalAmt and TaxAmount are equal or TotalAmt = 0.00) and would result in
   		   a trigger error.  Validation will prevent this although, Form input should also prevent this. */
   		if isnull(@GLRevAcct, '') = '' 
   	    	begin
   	       	select @errortext = @errorstart + ': Line GLAcct Input may not be NULL.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	       	goto bspexit
   	       	end		
   
   		/* ApplyMth and ApplyTrans must exist in batch for Adjustments, Credits, and WriteOffs.  They wont
   		   be present in batch, at this time, if this is a New Invoice Transaction. */
		if (isnull(@ApplyMth,'')= '' or isnull(@ApplyTrans,-99) = -99) and @artranstype <> 'I'
           	begin
           exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           end

--		if @artranstype in ('C', 'W')
--           	begin
--			select @Amount = -(@Amount)
--			select @oldAmount = -(@oldAmount)
--			select @Retainage = -(@Retainage)
--			select @oldRetainage = -(@oldRetainage)
--			select @TaxAmount = -(@TaxAmount)
--			select @RetgTax = -(@RetgTax)
--			select @oldTaxAmount = -(@oldTaxAmount)
--			select @oldRetgTax = -(@oldRetgTax)
--			select @ContractUnits = -(@ContractUnits)
--   			select @FinanceChg = -(@FinanceChg)
--   			select @oldFinanceChg = -(@oldFinanceChg)
--			end
   
       	select @CompanyForVal = @co
  	   	if @JCCo is not null
			begin
  	        select @CompanyForVal = @JCCo
  	        end
   
  	    /*validate transactions action*/
  	    if @TransTypeLine<>'A' and @TransTypeLine <>'C' and @TransTypeLine <>'D'
  	    	begin
  	        select @errortext = @errorstart + ' - Invalid transaction type, must be A, C, or D.'
  	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
  	        end
   
   	   	/*Validate Receivable Type*/
       	exec @rcode = bspRecTypeVal @co, @RecType, @errmsg output
 	   	--if isnull(@RecType,0) = 0 select @rcode = 1	-- #122561 - commented out line
   	   	if @rcode <> 0
			begin
			select @errortext = @errorstart + '- Receivable Type:' + isnull(convert(varchar(3),@RecType),'') + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <>0 goto bspexit
			end

		/* get the accounts for the receivable type*/
		select @ARGLCo = GLCo, @GLARAcct=GLARAcct, @GLRetainAcct=GLRetainAcct, @GLDiscountAcct = GLDiscountAcct,
			@GLARFCRecvAcct=GLARFCRecvAcct, @GLARFCWoffAcct=GLFCWriteOffAcct
		from bARRT with (nolock)
		where ARCo = @co and RecType = @RecType
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' Receivable Type:' + isnull(convert(varchar(3),@RecType),'') + ': is invalid'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <>0 goto bspexit
			end
   
		/*validation specific to Add type transactions, or Change type transactions */
		if @TransTypeLine = 'A' or @TransTypeLine = 'C'
			begin 
			/* Validate LineType */
			if @LineType not in ('M','C','O','F','R')
   				begin
				select @errortext = @errorstart + ' - LineType is Invalid or is null, must be M, C, O, R or F.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   
			/* Issue #14610 & 16038, Validate if a TaxAmount is present, 
			   there must also be a TaxCode, else error. */
			if (isnull(@LineTaxAmount, 0) <> 0 or isnull(@LineRetgTax, 0) <> 0) and @TaxCode is null
				begin
				select @errortext = @errorstart + 'Line ' + isnull(convert(varchar(6),@ARLine),'') + 
					' must contain a TaxCode when tax amounts are not 0.00.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   
			/*Validate Tax Group if there is a tax code */
			if @TaxCode is not null
				begin
				if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @CompanyForVal  and TaxGroup = @TaxGroup)
   					begin
					select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @TaxGroup),'')
					select @errortext = @errorstart + ' - is not valid!'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
				end
   
			/* Validate TaxCode by getting the accounts for the tax code */
			if @TaxCode is not null
				begin
				exec @rcode = bspHQTaxRateGetAll @TaxGroup, @TaxCode, @transdate, null, @taxrate output, @gstrate output, @pstrate output, 
					@HQTXcrdGLAcct output, @HQTXcrdRetgGLAcct output, null, null, @HQTXcrdGLAcctPST output, 
					@HQTXcrdRetgGLAcctPST output,NULL,NULL, @errmsg output

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
					select @TaxAmount = @LineTaxAmount
					select @RetgTax = @LineRetgTax
					end
				else
					begin
					/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
					if @taxrate <> 0
						begin
						select @TaxAmount = (@LineTaxAmount * @gstrate) / @taxrate		--GST TaxAmount
						select @TaxAmountPST = @LineTaxAmount - @TaxAmount				--PST TaxAmount
						select @RetgTax = (@LineRetgTax * @gstrate) / @taxrate			--GST RetgTax
						select @RetgTaxPST = @LineRetgTax - @RetgTax					--PST RetgTax
						end
					end
				end /* tax code validation*/
   
			if @artranstype in ('C', 'W')
           		begin
				select @Amount = -(@Amount)
				select @Retainage = -(@Retainage)
				select @TaxAmount = -(@TaxAmount)
				select @TaxAmountPST = -(@TaxAmountPST)
				select @RetgTax = -(@RetgTax)
				select @RetgTaxPST = -(@RetgTaxPST)
   				select @FinanceChg = -(@FinanceChg)
				select @ContractUnits = -(@ContractUnits)
				select @LineTaxAmount = -(@LineTaxAmount)
				select @LineRetgTax = -(@LineRetgTax)
				end

   			/* Line RecType must match Header RecType */
   			if @RecType <> @hrectype
   				begin
   				select @errortext = @errorstart + ' - Header RecType and Line RecType are not the same.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
   				end
   
			if @artranstype not in ('I','M','F','R') and @ApplyLine is not null  /* If an Adjust, Credit, Writeoff or Payment */
				begin
				/* First check that this adjustment line information is same as original transactions */
				if not exists (select 1
						from bARTL with (nolock)
						where ARCo = @co AND Mth=@ApplyMth AND ARTrans=@ApplyTrans AND ARLine=@ApplyLine
							and RecType=@RecType
							and IsNull(JCCo,0)=IsNull(@JCCo,0) AND IsNull(Contract,'')=IsNull(@Contract,'')	--For DataType Security
							and IsNull(INCo,0)=IsNull(@INCo,0) AND IsNull(Loc,'')=IsNull(@Loc,'')			--For DataType Security
							and ((@artranstype in ('P'))													--Mod Per Issue #14610
								or (@artranstype in ('A','C','W') and IsNull(@TaxGroup,0)=IsNull(TaxGroup,0)--TaxGroup must always be same, Orig = Applied
									and IsNull(TaxCode,'') = IsNull(@TaxCode,IsNull(TaxCode,'')))))			--If Applied TaxCode exists, must be equal to Orig.  If Applied empty, Orig can be anything (??)
					begin
					select @errortext = @errorstart + ' - Information does not match the Original Invoice Line'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
				end
   
			/* Validate Material type lines */
			if @LineType in ('M', 'J', 'E') and @artranstype not in ('A','C','W')
				begin
   				/* No location val as of yet Validate location
   				exec @rcode = bspLocationVal @co, @Loc, @errmsg ouptut
   				if @rcode <> 0
					begin
   					select @errortext = @errorstart + '- Location:' + @Loc +': '+ @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end */

				/*Validate Material*/
				/*exec @rcode = bspHQMatlVal @MatlGroup, @Material, @msg = @errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + '- Material:' + @Material +': '+ @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end */
   
          		/* Validate UM*/
	   			exec @rcode = bspHQUMVal @UM, @errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + '- UM:' + isnull(@UM,'') +': '+ isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
       			end/* material val */
   
   			/* Validate Contract types */
   			if @LineType = 'C'
           		begin
				/* Validate Contract Item */
   				exec @rcode = bspJCCIVal @JCCo, @Contract, @ContractItem, @errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + '- Contract :' + isnull(@Contract,'') + ', ' + 'Item :' + isnull(@ContractItem,'') +': ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   					if @rcode <> 0 goto bspexit
   					end
   				end/* contract types*/
  			end /* trans type A or C */
   
		If @TransTypeLine = 'D' or @TransTypeLine = 'C'
			begin
			/* Get Closed Revenue Account to post changes to when Contract is Final Closed. 
				If Line TransType = A, not required because Line GL Account will be Closed Rev Account returned from Item Validation. */
			if @isContractFlag='Y' and @ContractStatus = 3
  				begin
				/* New Item on Change.  */  				
  				select @GLRevAcct = d.ClosedRevAcct
				from bJCDM d with (nolock)
				join bJCCI i with (nolock) on i.JCCo = d.JCCo and i.Department = d.Department
				where i.JCCo = @JCCo and i.Contract = @Contract and i.Item = @ContractItem
				if @TransTypeLine = 'C' and @GLRevAcct is null
					begin
					select @errortext = @errorstart + 'Contract Item: ' + isnull(@ContractItem,'') + ': is missing department Closed Revenue Account.'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
				
				/* Old Item on Change or Delete. */
				select @oldGLRevAcct = d.ClosedRevAcct
				from bJCDM d with (nolock)
				join bJCCI i with (nolock) on i.JCCo = d.JCCo and i.Department = d.Department
				where i.JCCo = @oldJCCo and i.Contract = @oldContract and i.Item = @oldItem
				if @oldGLRevAcct is null
					begin
					select @errortext = @errorstart + 'Contract Item: ' + isnull(@oldItem,'') + ': is missing department Closed Revenue Account.'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
  				end
  				
			/* get the old accounts for the receivable type */
			select @oldARGLCo = GLCo, @oldGLARAcct= GLARAcct, @oldGLRetainAcct = GLRetainAcct, @oldGLDiscountAcct = GLDiscountAcct,
				@oldGLARFCRecvAcct=GLARFCRecvAcct, @oldGLARFCWoffAcct=GLFCWriteOffAcct						
			from bARRT with (nolock)
      		where ARCo = @co and RecType = @oldRecType

       		if @@rowcount = 0
				begin
				select @errortext = @errorstart + 'Receivable Type:' + isnull(convert(varchar(3),@oldRecType),'') + ': is invalid'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   
			/* Get the account for the taxcode */
			if @oldTaxCode is not null
				begin
				exec @rcode = bspHQTaxRateGetAll @oldTaxGroup, @oldTaxCode, @oldtransdate, null, @taxrate output, @gstrate output, @pstrate output, 
					@oldHQTXcrdGLAcct output, @oldHQTXcrdRetgGLAcct output, null, null, @oldHQTXcrdGLAcctPST output, 
					@oldHQTXcrdRetgGLAcctPST output, NULL, NULL, @errmsg output

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
					select @oldTaxAmount = @oldLineTaxAmount
					select @oldRetgTax = @oldLineRetgTax
					end
				else
					begin
					/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
					if @taxrate <> 0
						begin
						select @oldTaxAmount = (@oldLineTaxAmount * @gstrate) / @taxrate		--GST TaxAmount
						select @oldTaxAmountPST = @oldLineTaxAmount - @oldTaxAmount				--PST TaxAmount
						select @oldRetgTax = (@oldLineRetgTax * @gstrate) / @taxrate			--GST RetgTax
						select @oldRetgTaxPST = @oldLineRetgTax - @oldRetgTax					--PST RetgTax
						end
					end
				end /* tax code validation*/

			if @artranstype in ('C', 'W')
           		begin
				select @oldAmount = -(@oldAmount)
				select @oldRetainage = -(@oldRetainage)
				select @oldTaxAmount = -(@oldTaxAmount)
				select @oldTaxAmountPST = -(@oldTaxAmountPST)
				select @oldRetgTax = -(@oldRetgTax)
				select @oldRetgTaxPST = -(@oldRetgTaxPST)
   				select @oldFinanceChg = -(@oldFinanceChg)
				select @oldContractUnits = -(@oldContractUnits)
				select @oldLineTaxAmount = -(@oldLineTaxAmount)
				select @oldLineRetgTax = -(@oldLineRetgTax)
				end
			end /* trans type D or C */
	   
		/*validation specific for changes*/
		if @TransTypeLine = 'C'
			begin
			print '<<Validation specific for change>>'
			end
   
		/*validation specific for deletes*/
		if @TransTypeLine = 'D'
			begin
			/*need to check to see if there are any transaction lines applied to the line we are trying to delete*/
			if exists (select top 1 1 from bARTH h with (nolock)
				join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
				where l.ARCo = @co and l.ApplyMth = @mth and l.ApplyTrans = @ARTrans and h.ARTransType <> 'I')
				begin
				select @errortext = @errorstart + ' - Transaction - ' + isnull(convert(varchar(40),@ARTrans),'') + 
					' - has other transactions applied to it that must first be removed. Cannot delete! '
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
			end
   
update_audit: /* Update audit lists - Need to update GL , JC distribution*/
	select @i=1, @InterCompany = 10	/*set first Intercompany account */
    while @i<=13
		BEGIN	/* Begin Audit Update */
		/*Validate GL Accounts*/
		/* spin through each type of GL account, check it and write GL Amount */
   
   		/****** new values *****/
   		select @PostAmount = 0, @oldPostAmount = 0, @PostGLCo = null, @oldPostGLCo = null,
   			@compareICamt = 0, @compareIColdamt = 0, @chksubtype = 'N'
   
		/* AR Receivables Account */
		if @i=1
       		begin
       		select @PostGLCo= @ARGLCo, @PostGLAcct=@GLARAcct, @PostAmount = (isnull(@Amount,0) - isnull(@Retainage,0) - isnull(@FinanceChg,0)),
				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldGLARAcct, @oldPostAmount= -(isnull(@oldAmount,0) - isnull(@oldRetainage,0) - isnull(@oldFinanceChg,0)),
				@errorAccount = 'AR Receivable Account'
   
   			/* Need to declare proper GLAcct SubType */
   			select @chksubtype = 'R'
			end
   
  		/* Retainage Receivables Account */
  		if @i=2
       		begin
       		select @PostGLCo=@ARGLCo, @PostGLAcct=@GLRetainAcct, @PostAmount=isnull(@Retainage,0),
   				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLRetainAcct, @oldPostAmount=-(isnull(@oldRetainage,0)),
				@errorAccount = 'AR Retainage Account'
	       	
			/* Need to declare proper GLAcct SubType */
			select @chksubtype = 'R'
			end
   
  		/* Tax account.  Standard US or GST */
  		if @i=3 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdGLAcct, @PostAmount=-(isnull(@TaxAmount,0)),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdGLAcct, @oldPostAmount=isnull(@oldTaxAmount,0),
			@errorAccount = 'AR Tax Account'
   
  		/* Retainage Tax account.  Standard US or GST */
  		if @i=4 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcct, @PostAmount=-(isnull(@RetgTax,0)),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdRetgGLAcct, @oldPostAmount=isnull(@oldRetgTax,0),
			@errorAccount = 'AR Retg Tax Account'

  		/* Tax account.  PST */
  		if @i=5 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdGLAcctPST, @PostAmount=-(isnull(@TaxAmountPST,0)),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdGLAcctPST, @oldPostAmount=isnull(@oldTaxAmountPST,0),
			@errorAccount = 'AR Tax Account PST'

  		/* Retainage Tax account.  PST */
  		if @i=6 select @PostGLCo=@ARGLCo, @PostGLAcct=@HQTXcrdRetgGLAcctPST, @PostAmount=-(isnull(@RetgTaxPST,0)),
			@oldPostGLCo=@oldARGLCo, @oldPostGLAcct = @oldHQTXcrdRetgGLAcctPST, @oldPostAmount=isnull(@oldRetgTaxPST,0),
			@errorAccount = 'AR Retg Tax Account PST'

		/* Revenue/Income Account - Can also be WriteOff Account */
  		if @i=7 
			begin
			select @PostGLCo=@Line_GLCo, @PostGLAcct=@GLRevAcct, @PostAmount=-(isnull(@Amount,0)-isnull(@LineTaxAmount,0)-isnull(@LineRetgTax,0)-isnull(@FinanceChg,0)),
				@oldPostGLCo=@oldLine_GLCo, @oldPostGLAcct=@oldGLRevAcct, @oldPostAmount=(isnull(@oldAmount,0)-isnull(@oldLineTaxAmount,0)-isnull(@oldLineRetgTax,0)-isnull(@oldFinanceChg,0)),
				@errorAccount = (case when @artranstype = 'W' then 'AR WriteOff Account' else 'AR Revenue Account' end)

			/* Need to declare proper GLAcct SubType */
			if isnull(@JCCo,0) <> 0 and isnull(@Contract,'') <> '' and @artranstype <> 'W'
				select @chksubtype = 'J'
			else if @source = 'SM Invoice'
				select @chksubtype = 'S'
			
			--Capture revenue reconciliation records for SM agreement invoices.
			INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, SMAgreementID, SMAgreementBillingScheduleID, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
			SELECT CASE @artranstype WHEN 'I' THEN 0 WHEN 'A' THEN 1 END, 0 Posted, @HQBatchDistributionID, vSMAgreement.SMAgreementID, vSMAgreementBillingSchedule.SMAgreementBillingScheduleID, 'R', @co, @mth, @batchid, @PostGLCo, @PostGLAcct, @PostAmount
			FROM dbo.bARBL
				INNER JOIN dbo.vSMAgreementBillingSchedule ON bARBL.SMAgreementBillingScheduleID = vSMAgreementBillingSchedule.SMAgreementBillingScheduleID
				INNER JOIN dbo.vSMAgreement ON vSMAgreementBillingSchedule.SMCo = vSMAgreement.SMCo AND vSMAgreementBillingSchedule.Agreement = vSMAgreement.Agreement AND vSMAgreementBillingSchedule.Revision = vSMAgreement.Revision
			WHERE bARBL.Co = @co AND bARBL.Mth = @mth AND bARBL.BatchId = @batchid AND bARBL.BatchSeq = @seq AND bARBL.ARLine = @ARLine
			
			SELECT @SMWorkCompletedID = SMWorkCompletedID, @IsReversing = IsReversing
			FROM dbo.vSMWorkCompletedARBL
			WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq AND ARLine = @ARLine
			IF @@rowcount > 0
			BEGIN
				INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
				SELECT @IsReversing, 0 Posted, @HQBatchDistributionID, SMWorkCompleted.SMWorkCompletedID, SMWorkOrderScope.SMWorkOrderScopeID, SMWorkOrder.SMWorkOrderID, SMWorkCompleted.[Type], 'R', @co, @mth, @batchid, @PostGLCo, @PostGLAcct, @PostAmount
				FROM dbo.SMWorkCompleted
					INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompleted.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = SMWorkOrderScope.Scope
					INNER JOIN dbo.SMWorkOrder ON SMWorkCompleted.SMCo = SMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = SMWorkOrder.WorkOrder
				WHERE SMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID
				
				IF @IsReversing = 0
				BEGIN
					--We don't update the Trans # because it isn't available until posting
					SELECT @SMTransDesc = dbo.vfToString(@GLDetlDesc),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Trans Type', dbo.vfToString(@artranstype)),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Cust #', dbo.vfToString(@customer)),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Sort Name', dbo.vfToString(@SortName)),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Invoice', dbo.vfToString(@invoice)),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Contract', dbo.vfToString(@Contract)),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Desc', dbo.vfToString(@transdesc)),
						@SMTransDesc = REPLACE(@SMTransDesc, 'Check #', dbo.vfToString(@checkno))

					EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Invoice', @TransactionsShouldBalance = 0, @msg = @errmsg OUTPUT
					
					IF @GLEntryID = -1
					BEGIN
						EXEC @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
						IF @rcode <> 0 GOTO bspexit
					END
					
					INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, BatchSeq, Line, InterfacingCo)
					VALUES (@GLEntryID, @co, @mth, @batchid, @seq, @ARLine, @co)
					
					INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
					VALUES (@GLEntryID, 1, @PostGLCo, @PostGLAcct, @PostAmount, @transdate, @SMTransDesc)
				END
			END
			end
   
   		/* AR FinanceChg Receivable Account */
   		if @i=8
			begin 
			select @PostGLCo=@ARGLCo, @PostGLAcct=@GLARFCRecvAcct, @PostAmount=IsNull(@FinanceChg,0),
				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLARFCRecvAcct, @oldPostAmount=-(IsNull(@oldFinanceChg,0)),
				@errorAccount='AR FC Receivable GLAcct'

			/* Need to declare proper GLAcct SubType */
			select @chksubtype = 'R'				
			end
   
		/* AR FinanceChg WriteOff Account */
		if @i=9
			begin
			select @PostGLCo=@ARGLCo, @PostGLAcct=@GLARFCWoffAcct, @PostAmount=-(IsNull(@FinanceChg,0)),
				@oldPostGLCo=@oldARGLCo, @oldPostGLAcct=@oldGLARFCWoffAcct, @oldPostAmount=IsNull(@oldFinanceChg,0),
				@errorAccount='AR FC WriteOff Account'
			end
   
		/* If in 'A'dd or 'D'elete mode and ARGL Company is the same as the GLRev Company
		   then skip all intercompany processing completely. */
		if @i >= @InterCompany and @TransTypeLine in ('A', 'D') and @ARGLCo = @Line_GLCo
			begin
			select @i = 13
			goto skip_GLUpdate
			end
   
   		/* Cross company requires 4 stages to accomodate 'C'hange mode as well as 'Add' and 'D'elete */
   			
		/* cross company part I  --  InterCompany Payables GLCo and GLAcct, retrieve OLD values */
	XCompany10:
	    if @i=10 
	  		begin
			if @TransTypeLine = 'A' and @ARGLCo <> @Line_GLCo goto XCompany11	-- There is no Old Inter-APGLCo
	  	  	if @TransTypeLine = 'C' and @ARGLCo = @oldLine_GLCo goto XCompany11	-- There is no Old Inter-APGLCo
			select @oldPostGLCo = APGLCo, @oldPostGLAcct = APGLAcct, 
				@oldPostAmount = (isnull(@oldAmount,0) - isnull(@oldLineTaxAmount,0) - isnull(@oldLineRetgTax,0)),
				@compareICamt = (isnull(@Amount,0) - isnull(@LineTaxAmount,0) - isnull(@LineRetgTax,0)),
				@errorAccount='XREF GL Acct'
	  	  	from bGLIA with (nolock)
	      	where ARGLCo = @Line_GLCo and APGLCo = @ARGLCo

	 	  	if @@rowcount = 0
	        	begin
	        	select @errortext = 'Invalid cross company entry in GLIA. Must have Old PayableGLCo = '
	         		+ convert(varchar(10),@oldARGLCo) + ' - ' + @errmsg
	  	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	  			if @rcode <> 0 goto get_next_bcARBH
	        	end
			end
   
		/* Skip, do not accumulate Intercompany values for lines whose amounts have
		   not changed unless the Intercompany itself has changed. This is evaluated 
		   separately from NON-Intercompany to avoid doubling amounts. */
		if @TransTypeLine = 'C' and @oldPostAmount = @compareICamt and @Line_GLCo = @oldLine_GLCo
		select @oldPostAmount = 0
   
   		/* cross company part II  --  InterCompany Payables GLCo and GLAcct, retrieve NEW values */
	XCompany11:
	    if @i=11 	
	  		begin
			if @TransTypeLine = 'C' and @ARGLCo = @Line_GLCo goto XCompany12		-- There is no NEW Inter-APGLCo
	  	  	select @PostGLCo = APGLCo, @PostGLAcct = APGLAcct, 
	  			@PostAmount = -(isnull(@Amount,0) - isnull(@LineTaxAmount,0) - isnull(@LineRetgTax,0)), 
				@compareIColdamt = -(isnull(@oldAmount,0) - isnull(@oldLineTaxAmount,0) - isnull(@oldLineRetgTax,0)),
				@errorAccount='XREF GL Acct'
	  	  	from bGLIA with (nolock)
	      	where ARGLCo = @Line_GLCo and APGLCo = @ARGLCo

	 	  	if @@rowcount = 0
	        	begin
	        	select @errortext = 'Invalid cross company entry in GLIA. Must have New PayableGLCo = '
	         		+ convert(varchar(10),@ARGLCo) + ' - ' + @errmsg
	  	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	  			if @rcode <> 0 goto get_next_bcARBH
	        	end
	      	end
   
		/* Skip, do not accumulate Intercompany values for lines whose amounts have
		   not changed unless the Intercompany itself has changed. This is evaluated 
		   separately from NON-Intercompany to avoid doubling amounts. */
		if @TransTypeLine = 'C' and @PostAmount = @compareIColdamt and @Line_GLCo = @oldLine_GLCo
		select @PostAmount = 0
   
   		/* cross company part III  --  InterCompany Receivables GLCo and GLAcct, retrieve OLD values */
	XCompany12:
	    if @i=12 
	  	  	begin
			if @TransTypeLine = 'A' and @ARGLCo <> @Line_GLCo goto XCompany13	-- There is no Old Inter-ARGLCo
	  	  	if @TransTypeLine = 'C' and @ARGLCo = @oldLine_GLCo goto XCompany13	-- There is no Old Inter-ARGLCo  	  	
			select @oldPostGLCo = ARGLCo, @oldPostGLAcct = ARGLAcct,
				@oldPostAmount = -(isnull(@oldAmount,0) - isnull(@oldLineTaxAmount,0) - isnull(@oldLineRetgTax,0)), 
				@compareICamt = -(isnull(@Amount,0) - isnull(@LineTaxAmount,0) - isnull(@LineRetgTax,0)),
				@errorAccount = 'XREF GL Acct'
	  	  	from bGLIA with (nolock)
	      	where ARGLCo = @Line_GLCo and APGLCo = @ARGLCo  
	
	      	if @@rowcount = 0
	        	begin
	        	select @errmsg = 'Invalid cross company entry in GLIA. Must have Old ReceivableGLCo = '
	         		+ convert(varchar(10),@oldLine_GLCo) + ' -  ' + @errmsg
	  			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto get_next_bcARBH
	        	end
	  	  	end
   
		/* Skip, do not accumulate Intercompany values for lines whose amounts have
		   not changed unless the Intercompany itself has changed. This is evaluated 
		   separately from NON-Intercompany to avoid doubling amounts. */
		if @TransTypeLine = 'C' and @oldPostAmount = @compareICamt and @Line_GLCo = @oldLine_GLCo
		select @oldPostAmount = 0
   
   		/* cross company part IV  --  InterCompany Receivables GLCo and GLAcct, retrieve NEW values */
	XCompany13:    
		if @i=13 
	  	  	begin
			if @TransTypeLine = 'C' and @ARGLCo = @Line_GLCo goto ARBAUpdate	-- There is no NEW Inter-ARGLCo
	  	  	select @PostGLCo = ARGLCo, @PostGLAcct = ARGLAcct, 
	  			@PostAmount = (isnull(@Amount,0) - isnull(@LineTaxAmount,0) - isnull(@LineRetgTax,0)), 
				@compareIColdamt = (isnull(@oldAmount,0) - isnull(@oldLineTaxAmount,0) - isnull(@oldLineRetgTax,0)),
				@errorAccount = 'XREF GL Acct'
	  	  	from bGLIA with (nolock)
	      	where ARGLCo = @Line_GLCo and APGLCo = @ARGLCo
	
	      	if @@rowcount = 0
	        	begin
	        	select @errmsg = 'Invalid cross company entry in GLIA. Must have New ReceivableGLCo = '
	         		+ convert(varchar(10),@Line_GLCo) + ' -  ' + @errmsg
	  	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto get_next_bcARBH
	        	end
	  	  	end 
   
		/* Skip, do not accumulate Intercompany values for lines whose amounts have
		   not changed unless the Intercompany itself has changed. This is evaluated 
		   separately from NON-Intercompany to avoid doubling amounts. */
		if @TransTypeLine = 'C' and @PostAmount = @compareIColdamt and @Line_GLCo = @oldLine_GLCo
		select @PostAmount = 0
   
		/* dont create GL if old and new are the same */
		if @glinvoicelvl = 2
			begin
			if @TransTypeLine='C' and @PostAmount=-IsNull(@oldPostAmount,0) and @PostGLCo=@oldPostGLCo and @PostGLAcct=@oldPostGLAcct
				and @invoice=@oldinvoice and @transdesc=@oldtransdesc
			goto skip_GLUpdate
			end
		else
			begin	
			if @TransTypeLine='C' and @PostAmount=-IsNull(@oldPostAmount,0) and @PostGLCo=@oldPostGLCo and @PostGLAcct=@oldPostGLAcct
			goto skip_GLUpdate
			end

	ARBAUpdate:
		/*********  This 1st Update/Insert relates to OLD values during Change and Delete Modes *********/
   
   		/* if intercompany then try to update the record so there is only one record per transfer */
   		if isnull(@oldPostAmount,0) <> 0 and @i>=@InterCompany and @TransTypeLine <> 'A'  
     		begin
     		update bARBA 
			set Amount = Amount + @oldPostAmount
     		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=0 and ARLine=@oldPostGLCo and OldNew = 0   /* yes we are using ARLine for the Xcompany */
				and GLAcct=@oldPostGLAcct
     		if @@rowcount=1 select @oldPostAmount=0  /* set Amount to zero so we dont re-add the record*/
     		end
   
		/* if not intercompany then update a record if GLAccts are the same.  ARGLAcct, GLRetainAcct
   		   and GLARFCRecvAcct may be the same account if user chooses.  Also GLWriteOffAcct and 
		   GLFCWriteOffAcct may be the same. */
	    if isnull(@oldPostAmount,0) <> 0 and @i < @InterCompany and @TransTypeLine <> 'A'
	        begin
	        update bARBA
	        set Amount = Amount + @oldPostAmount
	        where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and GLCo=@oldPostGLCo 
				and GLAcct=@oldPostGLAcct and ARLine=@ARLine and OldNew = 0
	        if @@rowcount=1 select @oldPostAmount=0 	/* set Amount to zero so we don't re-add the record*/
	        end
   
		/* For posting OLD values to all Accounts i=1 thru i=10 */
		if isnull(@oldPostAmount,0) <> 0 and @TransTypeLine <> 'A'
			Begin
			exec @rcode = bspGLACfPostable @oldPostGLCo, @oldPostGLAcct, @chksubtype, @errmsg output
			if @rcode <> 0
				begin
          	   	select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@oldPostGLCo),'') + '- GL Account - ( '+ isnull(@errorAccount,'') + '): ' + isnull(@oldPostGLAcct,'') + ': ' + isnull(@errmsg,'')
              	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              	if @rcode <> 0 goto bspexit
              	end
			else
	           	begin
		       	insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
					ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
					ContractItem, ActDate, Description, Amount)
		       	values(@co, @mth, @batchid, @oldPostGLCo, @oldPostGLAcct, 
					case when @i < @InterCompany then @seq else 0 end, 
					0, 
					case when @i < @InterCompany then @ARTransHD else 0 end, 
					case when @i < @InterCompany then @ARLine else @oldPostGLCo end,
          			case when @i < @InterCompany then @artranstype else 'X' end, 
					case when @i < @InterCompany then @customer else null end, 
					case when @i < @InterCompany then @SortName else null end, 
					case when @i < @InterCompany then @custgroup else null end,
					case when @i < @InterCompany then @oldinvoice else null end,
   		           	case when @i < @InterCompany then @oldContract else null end, 
					case when @i < @InterCompany then @oldItem else null end, 
					@transdate, 
					-- we will use old transaction description next, since AR does not post to Detail level in GLDT
					case when @i < @InterCompany then @oldtransdesc else 'Inter-Company Transfer' end, 
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
          	End
   
		/*********  This 2nd Update/Insert relates to NEW values during Add and Change Modes *********/
   
	    /* if intercompany then try to update the record so there is only one record per transfer */
	    if isnull(@PostAmount,0) <> 0 and @i >= @InterCompany and @TransTypeLine <> 'D'
			begin
	        update bARBA
	        set Amount=Amount + @PostAmount
	        where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=0 and ARLine=@PostGLCo and OldNew = 1	/* yes we are using ARLine for the Xcompany */
				and GLAcct=@PostGLAcct
	        if @@rowcount=1 select @PostAmount=0 	/* set Amount to zero so we don't re-add the record*/
	        end

		/* if not intercompany then update a record if GLAccts are the same.  ARGLAcct, GLRetainAcct
   		   and GLARFCRecvAcct may be the same account if user chooses.  Also GLWriteOffAcct and 
		   GLFCWriteOffAcct may be the same. */
	    if isnull(@PostAmount,0) <> 0 and @i < @InterCompany and @TransTypeLine <> 'D'
	        begin
	        update bARBA
	        set Amount=Amount + @PostAmount
	        where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and GLCo=@PostGLCo 
				and GLAcct=@PostGLAcct and ARLine=@ARLine and OldNew = 1
	        if @@rowcount=1 select @PostAmount=0 	/* set Amount to zero so we don't re-add the record*/
	        end
   
		/* For posting NEW values to all Accounts i=1 thru i=10 */
  		if isnull(@PostAmount,0) <> 0 and (@TransTypeLine <>'D') 
	       	Begin
     	   	exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, @chksubtype, @errmsg output
      	   	if @rcode <> 0
          		begin
         	   	select @errortext = @errorstart + 'GLCo -: ' + isnull(convert(varchar(10),@PostGLCo),'') + '- GL Account - ( ' + isnull(@errorAccount,'') + '): ' + isnull(@PostGLAcct, '') + ': ' + isnull(@errmsg,'')
              	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              	if @rcode <> 0 goto bspexit
              	end
			else
              	begin
	           	insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, ARTrans, ARLine,
					ARTransType, Customer, SortName, CustGroup, Invoice, Contract,
					ContractItem, ActDate, Description, Amount)
	           	values(@co, @mth, @batchid, @PostGLCo, @PostGLAcct, 
					case when @i < @InterCompany then @seq else 0 end, 
					1, 
					case when @i < @InterCompany then @ARTransHD else 0 end, 
					case when @i < @InterCompany then @ARLine else @PostGLCo end,
					case when @i < @InterCompany then @artranstype else 'X' end, 
					case when @i < @InterCompany then @customer else null end, 
					case when @i < @InterCompany then @SortName else null end, 
					case when @i < @InterCompany then @custgroup else null end, 
					case when @i < @InterCompany then @invoice else null end, 
					case when @i < @InterCompany then @Contract else null end,
					case when @i < @InterCompany then @ContractItem else null end, 
					@transdate,
					-- we will use transaction description next, since AR does not post to Detail level in GLDT 
					case when @i < @InterCompany then @transdesc else 'Inter-Company Transfer' end, 
					@PostAmount)
      	       	if @@rowcount = 0
               		begin
					select @errmsg = 'Unable to add AR Detail audit 1 - ' + @errortext , @rcode = 1
          	        GoTo bspexit
					end

				/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
				if not exists(select 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @PostGLCo)
   					begin
   					insert bHQCC (Co, Mth, BatchId, GLCo)
   					values (@co, @mth, @batchid, @PostGLCo)
   					end
             	end
	       	End
   
	skip_GLUpdate:
		/* get next GL record */
		select @i=@i+1, @errmsg=''
		END    /* End Audit Update */
 
	/* JC Update = insert into bARBI */
	if @isContractFlag = 'Y'
		BEGIN
		select @changed = 'N'
		if @TransTypeLine = 'C' and (@transdate <> @oldtransdate or isnull(@JCCo,0)<> isnull(@oldJCCo,0) or isnull(@Contract,'') <>isnull(@oldContract,'') or
			isnull(@ContractItem,0) <> isnull(@oldItem,0) or isnull(@LineDesc,'') <> isnull(@oldLineDesc,'') or
			isnull(@invoice,'') <> isnull(@oldinvoice,'') or isnull(@ContractUnits,0) <> isnull(@oldContractUnits,0) or
			isnull(@Amount,0) <> isnull(@oldAmount,0) or isnull(@Retainage,0) <> isnull(@oldRetainage,0) or
			isnull(@LineTaxAmount,0) <> isnull(@oldLineTaxAmount,0) or isnull(@LineRetgTax,0) <> isnull(@oldLineRetgTax,0) or 
			isnull(@Line_GLCo,0) <> isnull(@oldLine_GLCo,0) or isnull(@GLRevAcct,'') <> isnull(@oldGLRevAcct,'')) select @changed = 'Y'
 
		if (@TransTypeLine = 'A' or @changed = 'Y') and @artranstype <> 'W'
      		Begin
    		/* check JCCO */
   			if not exists(select 1 from bJCCO with (nolock) where JCCo=@JCCo)
       			begin
       			select @errortext = @errorstart + '- JC Company -: ' + isnull(convert(char(3),@JCCo),'') +': is invalid'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
       			end
	   
           	/* check if Contract or Item is null */
           	if @Contract is null
               	begin
               	select @errortext = @errorstart + '- Contract -: may not be null'
               	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
               	end
   
           	if @ContractItem is null
               	begin
               	select @errortext = @errorstart + '- Contract Item -: may not be null'
               	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
               	end
   
			if @Amount = 0 and @Retainage = 0 and @ContractUnits = 0 goto JCUpdate_Old
   
           	insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, Description,  ActualDate, ARTrans,
  				GLCo, GLAcct, Invoice, BilledUnits, BilledTax, BilledAmt, Retainage)
           	values (@co, @mth, @batchid, @JCCo, @Contract, @ContractItem, @seq, @ARLine, 1, @LineDesc, @transdate, @ARTransHD,
  				@Line_GLCo, @GLRevAcct, @invoice,  @ContractUnits,
  				case @UpdateTax when 'Y' then (@LineTaxAmount + @LineRetgTax) else 0 end,
  				case @UpdateTax when 'Y' then @Amount else (@Amount - isnull(@LineTaxAmount,0) - isnull(@LineRetgTax,0)) end, 
				case @UpdateTax when 'Y' then @Retainage else @Retainage - isnull(@LineRetgTax,0) end)
  			if @@rowcount = 0
               	begin
               	select @errmsg = 'Unable to add AR Contract audit - ' + isnull(@errmsg,''), @rcode = 1
               	GoTo bspexit
               	end
			End
   
	JCUpdate_Old:
		/* update old amounts to JC */
   		if (@TransTypeLine = 'D' or @changed = 'Y') and @artranstype <> 'W'
       		Begin
       		if not exists(select 1 from bJCCO with (nolock)where JCCo=@oldJCCo)
				begin
        		select @errortext = @errorstart + '- JC Company -: ' + isnull(convert(char(3),@oldJCCo),'') +': is invalid'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
        		end

			/* check if Contract or Item is null */
			if @oldContract is null
           		begin
        		select @errortext = @errorstart + '- old Contract -: may not be null'
        		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		if @rcode <> 0 goto bspexit
        		end

    		if @oldItem is null
        		begin
       			select @errortext = @errorstart + '- old Contract Item -: may not be null'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
        		end
   
    		if @oldAmount = 0 and @oldRetainage = 0 and @oldContractUnits = 0 goto JCUpdate_End
   
       		/* subtract by - 0 to prevent a negative zero being written to the record */
    		insert into bARBI(ARCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, ARTrans, Description, ActualDate,
    			GLCo, GLAcct,Invoice, BilledUnits,BilledTax, BilledAmt, Retainage)
    		values(@co, @mth, @batchid, @oldJCCo, @oldContract, @oldItem, @seq, @ARLine, 0, @ARTransHD, @oldLineDesc, @oldtransdate,
		   		@oldLine_GLCo, @oldGLRevAcct, @oldinvoice, -(@oldContractUnits),
		   		case @UpdateTax when 'Y' then -(isnull(@oldLineTaxAmount,0) + isnull(@oldLineRetgTax,0)) - 0 else 0 end,
				case @UpdateTax when 'Y' then -@oldAmount else -(@oldAmount - isnull(@oldLineTaxAmount,0) - isnull(@oldLineRetgTax,0)) - 0 end,
				case @UpdateTax when 'Y' then -@oldRetainage else -(@oldRetainage - isnull(@oldLineRetgTax,0)) - 0 end)
    		if @@rowcount = 0
       			begin
        		select @errmsg = 'Unable to add AR Contract audit - ' + @errmsg, @rcode = 1
        		goTo bspexit
        		end

       		End
   
	JCUpdate_End:
		END /* End - JC Update loop */
   
	goto get_next_bcARBL
	end /* ARBL Loop */
   
	close bcARBL
	deallocate bcARBL
	select @opencursorARBL = 0

	if not exists(select 1 from ARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq)
   		begin
		select @errortext = @errorstart + '- No batch transaction lines exist for this sequence.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end
  
	/* Create Misc Distributions automatically.
	   Create only on New Invoices (Not Adjustments, Credits, or Writeoffs to existing invoices) based on AR Customer Setup option. */
	if @transtype = 'A' and @artranstype = 'I' and @MiscDistOnInvYN = 'Y'
		begin
		if not exists(select top 1 1 from bARBM with (nolock)
				where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq)
			begin
			/* Calculate Misc Dist default amount.  Sum Batch Lines. */
			select @miscdistdfltvalue = sum(IsNull(l.Amount,0)) - (sum(IsNull(l.TaxAmount,0)) + sum(IsNull(l.RetgTax,0)))
			from bARBL l with (nolock)
			where l.Co = @co and l.Mth = @mth and l.BatchId = @batchid and l.BatchSeq = @seq	--and l.TransType <> 'D'

			/* Set the default Misc Dist Code.  Either from Contract or Customer */
			select @miscdistcodedflt = isnull(@contractmiscdistcode, @custmiscdistcode)
			
			/* Insert single bARBM record */
			if @miscdistcodedflt is not null
				begin
				select @mdcdescription = Description
				from bARMC with (nolock)
				where CustGroup = @custgroup and MiscDistCode = @miscdistcodedflt
				
				insert bARBM(Co, Mth, BatchId, CustGroup, MiscDistCode, BatchSeq, TransType, DistDate, Description, Amount)
				values(@co, @mth, @batchid, @custgroup, @miscdistcodedflt, @seq, 'A', @transdate, @mdcdescription, @miscdistdfltvalue)
				if @@rowcount = 0
					begin
					select @errortext = @errorstart + '- Miscellaneous Distributions could not be created automatically.  You must add manually.'
   					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end
				end
			end
		end
		
	goto get_next_bcARBH
   
   	end /* ARBH LOOP*/

close bcARBH
deallocate bcARBH
select @opencursorARBH=0
   
/* Check Misc Distributions - Updating bARBM with Transaction number and Dist Code
   validation are both accomplished for an entire batch and therefore should occur
   after looping through each header/Seq */
/* Need to update the misc dist. transaction number if the header was a 'change' type
   and the misc distribution is a add type.  Posting program will not update transaction
   number, so we will do it here. */
update bARBM
set ARTrans = h.ARTrans
from bARBH h with (nolock)
join bARBM m with (nolock) on m.Co = h.Co and m.Mth = h.Mth and m.BatchId = h.BatchId and m.BatchSeq = h.BatchSeq
where m.Co = @co and m.Mth = @mth and m.BatchId = @batchid
	and m.TransType = 'A' and h.TransType ='C'

exec @rcode = bspARBH1_ValMiscDist @co, @mth, @batchid, @errmsg output
if @rcode <> 0 goto bspexit
   
-- make sure debits and credits balance
select @AR_glco = GLCo
from bARBA with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
group by GLCo
having isnull(sum(Amount),0) <> 0
if @@rowcount <> 0
	begin
	select @errortext =  'GL Company ' + isnull(convert(varchar(3), @AR_glco),'') + ' entries dont balance!'
  	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end
   
bspexit:
   
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select top 1 1 from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @status = 2	/* validation errors */
  	end
   
update bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
  	goto terminate
  	end
   
terminate:
if @opencursorARBH = 1
   	begin
   	close bcARBH
	deallocate bcARBH
   	end
if @opencursorARBL = 1
   	begin
   	close bcARBL
   	deallocate bcARBL
	end
   
if @rcode <> 0 select @errmsg = @errmsg			--+ char(13) + char(10) + '[bspARBHVal]'
return @rcode









GO
GRANT EXECUTE ON  [dbo].[bspARBHVal] TO [public]
GO
