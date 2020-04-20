SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspJBARProgVal]
/************************************************************************************
* CREATED BY: 	 bc 10/26/99
* MODIFIED By :  bc 04/19/00 - @Updatetax flag was not being read for type 'D' transactions
*  		bc 09/12/00 - changed source to 'JB'
*   	bc 12/13/00 - if only the amount has changed on an item, JC should still get updated
*    	bc 01/07/00 - corrected inter company gl processing
*		TJL 04/16/01 - Modify for Non-Contracts, if NULL skip Contract related validation procedures
*   	kb 06/11/01 - issue #12332
*    	kb 09/17/01 - issue #13716
*		TJL 05/06/02 - Issue #17172, Keep Tax credit with ARCo.
*		TJL 05/06/02 - Issue #17174, Check GL SubType codes.  
*		TJL 05/06/02 - Issue #17250, Fix intercompany processing for 'C'hange and 'D'eletes.
*		TJL 09/27/02 - Issue #18533, BilledAmt in bJBJC really should be Amount + TaxAmount
*						if contract option 'Interface Tax to JC' = 'Y'.  Consistent with AR
*		TJL 10/18/02 - Issue #18982, Separate intercompany amounts out by GLAcct
*		TJL 11/20/02 - Issue #17278, Allow changes to bills in a closed month.
*		TJL 03/24/03 - Issue #20086, Validate TaxCode
*		TJL 05/12/03 - Issue #21077, Do Not allow reducing more retainage than is currently open.
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 10/02/03 - Issue #22352, Catch and error on Inactive Customers
*		TJL 12/15/03 - Issue #23327, Related to #21077.  Fixes an incorrect evaluation of current open retg.
*		TJL 03/09/04 - Issue #23089, Use ClosedRevAcct both Old and New when Contract is Hard Closed
*		TJL 09/02/04 - Issue #22565, Interface Notes from JBIT to ARTL
*		TJL 09/09/04 - Issue #25472, If transactions apply to Released/Credit Inv, warn user (Conditional Skip Release Process)
*		TJL 12/30/04 - Issue #26673, Correct prob from Issue #25472.  RelRetg fails to JC, GL, AR when interfacing multiple Bills.
*		    01/05/05 - Pull from WebSite upon the next issue.
*		TJL 01/21/05 - Issue #26048, Post to JCID when Units exist without Amount or Retainage value.
*		TJL 03/11/05 - Issue #27370, Improve on Negative Open Retainage, Release Retainage processing, Remove Restrictions
*		TJL 04/15/05 - Issue #28437, Correct 2nd prob from Issue #25472.  RelRetg fails to JC, GL, AR when interfacing mult bills. (Contains ClosedMth bill)
*		TJL 09/07/05 - Issue #29763, Correct post to JC when the bill is a Tax only bill
*		TJL 02/26/07 - Issue #120561, Made adjustment pertaining to bHQCC Close Control entry handling
*		TJL 12/19/07 - Issue #126519, RecType cannot be changed once invoices are interfaced.  @rectype <> @oldrectype validation
*		TJL 01/03/08 - Issue #28968, Reviewed procedure for possibly the need for additional Isnull() usage
*		GG 02/25/08 - Issue #120107, separate sub ledger close - use AR close month
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 10/21/08 - Issue #128802, bcJBAL Cursor already open error
*		TJL 03/23/09 - Issue #128250, Allow Deleting Bills In Closed Mth
*		MV	02/04/10 - Issue #136500, bspHQTaxRateGetAll added NULL output param
*		TJL 06/21/10 - Issue #140212, Correct Cursor doesn't exist ERROR caused by some Validation failures
*		TJL 06/21/10 - Issue #140215, Correct Receivable Type 0 validation error.  RecType 0 is now excepted as valid
*		AMR 01/12/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
*		MV	06/23/11 - #143622 Correct 'cursor doesn't exist' error caused by validation failure for X company
*		MV	10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*
* USAGE:  Used to validate invoices in bJBAR.  Spins through headers and lines.
* Creates distributions for Job Cost, Misc Distributions, General Ledger.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Job distributions added to bARBI
* GL Account distributions added to bARBA
* Cross company GL in bGLIA
* GL debit and credit totals must balance.
******************************************************************************************/
    @jbco bCompany,
    @batchmth bMonth,
    @batchid bBatchID,
    @source char(10),
    @errmsg varchar(255) OUTPUT
AS 
SET nocount ON
DECLARE @rcode int,
    @errortext varchar(255),
    @seq int,
    @changed bYN,
    @inuseby bVPUserName,
    @status tinyint,
    @opencursorJBAL tinyint,
    @opencursorJBAR tinyint,
    @lastglmth bMonth,
    @lastsubmth bMonth,
    @maxopen tinyint,
    @accttype char(1),
    @itemcount int,
    @deletecount int,
    @errorstart varchar(50),
    @SortName varchar(15),
    @actdate bDate,
    @GLARAcct bGLAcct,
    @invjrnl bJrnl,
    @glinvoicelvl int,
    @AR_glco int,
    @fy bMonth,
    @RecTypeGLCo int,
    @PostGLCo bCompany,
    @PostAmount bDollar,
    @PostGLAcct bGLAcct,
    @oldPostGLCo bCompany,
    @oldPostAmount bDollar,
    @oldPostGLAcct bGLAcct,
    @i int,
    @HQTXGLAcct bGLAcct,
    @oldHQTXGLAcct bGLAcct,
    @GLRevAcct bGLAcct,
    @oldGLRevAcct bGLAcct,
    @errorAccount varchar(20),
    @UpdateTax bYN,
    @AmtChange bYN,
    @chksubtype char(1),
    @InterCompany int,
    @MiscDistCode char(10),
    @OldNew tinyint,
    @TmpCustomer varchar(15),
    @ReturnCustomer bCustomer,
    @retg bPct,
    @compareICamt bDollar,
    @compareIColdamt bDollar,
    @adjust_mth bMonth,
    @JClastmthsubclsd bMonth,
    @ARlastmthsubclsd bMonth,
    @closedmthYN bYN,
    @jbcontractstat tinyint

-- @ar_retg bDollar, @tempartrans bTrans, @openretg bDollar, @jbcontractitemamt bDollar,

/*Declare JB Header variables*/
--	#142350 - removing unused vars  @CustGroup bGroup,
DECLARE @batchtranstype char(1),
    @artrans bTrans,
    @artranstype char(1),
    @custgroup bGroup,
    @ARGLCo bCompany,
    @oldARGLCo bCompany,
    @GLRetainAcct bGLAcct,
    @GLDiscountAcct bGLAcct,
    @oldGLARAcct bGLAcct,
    @oldGLRetainAcct bGLAcct,
    @oldGLDiscountAcct bGLAcct,
    @customer bCustomer,
    @jbcontract bContract,
    @invoice char(10),
    @description bDesc,
    @transdate bDate,
    @duedate bDate,
    @discdate bDate,
    @payterms bPayTerms,
    @rectype tinyint,
    @oldinvoice char(10),
    @olddescription bDesc,
    @oldtransdate bDate,
    @oldduedate bDate,
    @olddiscdate bDate,
    @oldpayterms bPayTerms,
    @oldrectype tinyint,
    @arco bCompany,
    @billnumber varchar(10),
    @oldjbcontract bContract,
    @oldcustomer bCustomer,
    @oldSortName varchar(15),
    @billmonth bMonth

/*Declare JB Line variables */
--	#142350 - removing unused vars     @ARTrans bTrans,
DECLARE @ARLine smallint,
    @batchtranstypeLine char,
    @linedescription bDesc,
    @JCGLCo bCompany,
    @oldJCGLCo bCompany,
    @GLAcct bGLAcct,
    @TaxGroup bGroup,
    @TaxCode bTaxCode,
    @Amount bDollar,
    @Units bUnits,
    @TaxBasis bDollar,
    @LineTaxAmount bDollar,
    @RetgPct bPct,
    @Retainage bDollar,
    @LineRetgTax bDollar,
    @RetgRel bDollar,
    @LineRetgTaxRel bDollar,
    @jbcontractItem bContractItem,
    @UM bUM,
    @oldUnits bUnits,
    @oldlinedescription bDesc,
    @oldGLAcct bGLAcct,
    @oldTaxGroup bGroup,
    @oldTaxCode bTaxCode,
    @oldAmount bDollar,
    @oldTaxBasis bDollar,
    @oldLineTaxAmount bDollar,
    @oldRetgPct bPct,
    @oldRetainage bDollar,
    @oldLineRetgTax bDollar,
    @oldRetgRel bDollar,
    @oldLineRetgTaxRel bDollar,
    @oldUM bUM,
    @errorTrans bTrans,
    @errorLine smallint,
	--International Sales Tax
    @taxrate bRate,
    @gstrate bRate,
    @pstrate bRate,
    @HQTXcrdGLAcct bGLAcct,
    @HQTXcrdRetgGLAcct bGLAcct,
    @oldHQTXcrdGLAcct bGLAcct,
    @oldHQTXcrdRetgGLAcct bGLAcct,
    @HQTXcrdGLAcctPST bGLAcct,
    @HQTXcrdRetgGLAcctPST bGLAcct,
    @oldHQTXcrdGLAcctPST bGLAcct,
    @oldHQTXcrdRetgGLAcctPST bGLAcct,
    @TaxAmount bDollar,
    @RetgTax bDollar,
    @TaxAmountPST bDollar,
    @RetgTaxPST bDollar,
    @oldTaxAmount bDollar,
    @oldRetgTax bDollar,
    @oldTaxAmountPST bDollar,
    @oldRetgTaxPST bDollar

/* set open cursor flags to false */
SELECT  @opencursorJBAR = 0, @opencursorJBAL = 0, @closedmthYN = 'N'
   
/* validate source */
IF @source NOT IN ('JB') 
    BEGIN
        SELECT  @errmsg = ISNULL(@source, '') + ' is invalid', @rcode = 1
        GOTO bspexit
    END
   
/* validate HQ Batch */
EXEC @rcode = bspHQBatchProcessVal @jbco, @batchmth, @batchid, 'JB', 'JBAR', @errmsg OUTPUT, @status OUTPUT
IF @rcode <> 0 
    BEGIN
        SELECT  @errmsg = @errmsg, @rcode = 1
        GOTO bspexit
    END
   
IF @status < 0 OR @status > 3 
    BEGIN
        SELECT  @errmsg = 'Invalid Batch status!', @rcode = 1
        GOTO bspexit
    END
   
/* set HQ Batch status to 1 (validation in progress) */
UPDATE  bHQBC
SET     Status = 1
WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid
   
IF @@rowcount = 0 
    BEGIN
        SELECT  @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
        GOTO bspexit
    END
   
/* get the arco based on the jc company */
SELECT  @arco = ARCo, @JCGLCo = GLCo
FROM    bJCCO WITH (NOLOCK)
WHERE   JCCo = @jbco
   
/* clear HQ Batch Errors */
DELETE  bHQBE
WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid

/* clear JC Distributions Audit */
DELETE  bJBJC
WHERE   JBCo = @jbco AND Mth = @batchmth AND BatchId = @batchid

/* clear GL Distribution list */
DELETE  bJBGL
WHERE   JBCo = @jbco AND Mth = @batchmth AND BatchId = @batchid

/* clear the bJBAL list for all retainage lines that are applied to themselves */
DELETE  bJBAL
WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid AND ARLine > 9999

/* clear and refresh HQCC entries */
/* Clearing bHQCC here is OK since bJBAL insert trigger is not setting an initial record. */
DELETE  bHQCC
WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid

/* Removed per Issue #120561:  Because of the possibility of JC Cross Company GL Revenue values,
   this is better handled later in the procedure while inserting into GL distribution table itself. */   
--   insert into bHQCC(Co, Mth, BatchId, GLCo)
--   select distinct Co, Mth, BatchId, GLCo
--   from bJBAL with (nolock)
--   where Co=@jbco and Mth=@batchmth and BatchId=@batchid
   
/* get some company specific variables and do some validation*/
/*need to validate GLFY and GLJR if gl is going to be updated*/
SELECT  @invjrnl = InvoiceJrnl, @glinvoicelvl = GLInvLev, @AR_glco = GLCo
FROM    ARCO WITH (NOLOCK)
WHERE   ARCo = @arco		--JBCO/JCCo.ARCo
IF @glinvoicelvl > 0 
    BEGIN
        EXEC @rcode = bspGLJrnlVal @AR_glco, @invjrnl, @errmsg OUTPUT
        IF @rcode <> 0 OR @invjrnl IS NULL 
            BEGIN
                SELECT  @errortext = 'Invalid Journal - A valid journal must be setup in AR Company.'
                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                IF @rcode <> 0 
                    GOTO bspexit
            END
   /* validate Fiscal Year */
        SELECT  @fy = FYEMO
        FROM    bGLFY WITH (NOLOCK)
        WHERE   GLCo = @AR_glco AND @batchmth >= BeginMth AND @batchmth <= FYEMO
        IF @@rowcount = 0 
            BEGIN
                SELECT  @errortext = 'Must first add Fiscal Year'
                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                IF @rcode <> 0 
                    GOTO bspexit
            END
    END
   
/* declare cursor on JB Header Batch for validation */
DECLARE bcJBAR CURSOR FOR
SELECT BatchSeq, BillMonth, BillNumber, BatchTransType, Invoice, Contract, CustGroup, Customer,
RecType, Description, ARTrans, TransDate, PayTerms, DueDate, DiscDate,
oldInvoice, oldContract, oldCustomer, oldRecType, oldDescription, oldTransDate, oldDueDate,
oldDiscDate, oldPayTerms
FROM bJBAR WITH (NOLOCK)
WHERE Co = @jbco AND Mth = @batchmth AND BatchId = @batchid

/* open cursor */
OPEN bcJBAR
/* set open cursor flag to true */
SELECT  @opencursorJBAR = 1
/* get rows out of JBAR */
get_next_bcJBAR:
FETCH NEXT FROM bcJBAR INTO @seq, @billmonth, @billnumber, @batchtranstype, @invoice, @jbcontract, @custgroup, @customer,
	@rectype, @description, @artrans, @transdate, @payterms, @duedate, @discdate,
	@oldinvoice, @oldjbcontract, @oldcustomer, @oldrectype, @olddescription,
	@oldtransdate, @oldduedate, @olddiscdate, @oldpayterms
   
/*Loop through all rows */
WHILE (@@fetch_status = 0) 
    BEGIN
        SELECT  @errorstart = 'BillMonth ' + SUBSTRING(CONVERT(varchar(10), @billmonth, 1), 0, 3) + RIGHT(CONVERT(varchar(10), @billmonth, 1), 3) + ', BillNumber ' + CONVERT(varchar(10), @billnumber) + ': '
        SELECT  @errmsg = NULL
   
        IF @jbcontract IS NOT NULL 
            BEGIN
                SELECT  @UpdateTax = TaxInterface, @jbcontractstat = ContractStatus
                FROM    bJCCM m WITH (NOLOCK)
                WHERE   m.JCCo = @jbco AND m.Contract = @jbcontract
            END
   
        IF @batchtranstype <> 'A' AND @batchtranstype <> 'C' AND @batchtranstype <> 'D' 
            BEGIN
                SELECT  @errortext = @errorstart + ' - invalid transaction type, must be A, C, or D.'
                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                IF @rcode <> 0 
                    GOTO bspexit
            END
   
	/* validation specific to Add type JB header*/
        IF @batchtranstype = 'A' 
            BEGIN
                IF @batchmth <> @billmonth 
                    BEGIN
                        SELECT  @errmsg = '- Invalid operation: The billmonth of the bill being added '
                        SELECT  @errmsg = @errmsg + 'falls in a closed AR month.  This bill may not be added!  ' 
                        SELECT  @errmsg = @errmsg + 'User must clear the batch!'
                        SELECT  @errortext = @errorstart + ISNULL(@errmsg, '')	
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                        IF @rcode <> 0 
                            GOTO bspexit
                        GOTO get_next_bcJBAR
                    END
   
       	/* all old values must be null if a new transaction */
                IF @oldinvoice IS NOT NULL OR @oldjbcontract IS NOT NULL OR @oldcustomer IS NOT NULL OR @olddescription IS NOT NULL OR @oldtransdate IS NOT NULL OR @oldduedate IS NOT NULL OR @olddiscdate IS NOT NULL OR @oldpayterms IS NOT NULL 
                    BEGIN
                        SELECT  @errortext = @errorstart + ' - Old entries in batch must be null for Add type entries.'
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                        IF @rcode <> 0 
                            GOTO bspexit
                    END
            END
   
	/* validation specific to Add or Change type JB header */
        IF @batchtranstype = 'C' OR @batchtranstype = 'A' 
            BEGIN
       	/*validate customer*/
                SELECT  @TmpCustomer = CONVERT(varchar(15), @customer)
                EXEC @rcode = bspARCustomerVal @custgroup, @TmpCustomer, 'A', @ReturnCustomer OUTPUT, @errmsg OUTPUT
                IF @rcode = 0 
                    BEGIN
       	    /* Customer is Valid, get SortName */
                        SELECT  @SortName = m.SortName
                        FROM    bARCM m WITH (NOLOCK)
                        WHERE   m.CustGroup = @custgroup AND m.Customer = @customer
                    END
                IF @rcode <> 0 
                    BEGIN
       	    --select @errortext = @errorstart + '- Customer ' + convert(varchar(10),@customer) + ' is not a valid customer!'
                        SELECT  @errortext = @errorstart + '- Customer ' + ISNULL(CONVERT(varchar(10), @customer), '') + ': ' + ISNULL(@errmsg, '')
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                        IF @rcode <> 0 
                            GOTO bspexit
                    END
   
		/*validate JCCo only if this is a Contract related bill */
                IF @jbcontract IS NOT NULL 
                    BEGIN
                        EXEC @rcode = bspJCCompanyVal @jbco, @errmsg OUTPUT
                        IF @rcode <> 0 
                            BEGIN
                                SELECT  @errortext = @errorstart + '- JCCo:' + ISNULL(CONVERT (varchar(3), @jbco), '') + ': ' + ISNULL(@errmsg, '')
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                            END
   
                        SELECT  @errmsg = NULL
   
      		/*validate Contract only if Contract is not null */
                        EXEC @rcode = bspJCContractVal @jbco, @jbcontract, @retg OUTPUT, @msg = @errmsg OUTPUT
                        IF @rcode <> 0 
                            BEGIN
                                SELECT  @errortext = @errorstart + '- Contract:' + ISNULL(@jbcontract, '') + ': ' + ISNULL(@errmsg, '')
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                            END
                    END
            END /* End Header Add or Change Val */
   
   	/* validation specific to Change type JB header */
        IF @batchtranstype = 'C' 
            BEGIN
                IF @batchmth <> @billmonth 
                    BEGIN	/* Begin Closed month checks for bills being changed */
   			/* If a batch contains any Changed bills from a closed month, we need to make sure
   			   user is using an open month batch and we must check AR to see if any changes
   			   to the same bill already exist in a month later than this batch.  If so, 
   			   record the errors and move on to the next sequence header. */
                        SELECT  @JClastmthsubclsd = LastMthSubClsd
                        FROM    bGLCO WITH (NOLOCK)
                        WHERE   GLCo = @JCGLCo
                        IF @@rowcount = 0 
                            BEGIN
                                SELECT  @errortext = @errorstart + '- Invalid JC GL Company: ' + ISNULL(CONVERT(varchar(3), @JCGLCo), '')
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                                GOTO get_next_bcJBAR
                            END
   	
                        SELECT  @ARlastmthsubclsd = LastMthARClsd	-- #120107 - use AR close month
                        FROM    bGLCO WITH (NOLOCK)
                        WHERE   GLCo = @AR_glco
                        IF @@rowcount = 0 
                            BEGIN
                                SELECT  @errortext = @errorstart + '- Invalid AR GL Company: ' + ISNULL(CONVERT(varchar(3), @arco), '')
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                                GOTO get_next_bcJBAR
                            END		
   	
                        IF @billmonth <= @JClastmthsubclsd OR @billmonth <= @ARlastmthsubclsd 
                            BEGIN
   				/* This is a closed month change.  Must make sure that batch in use is for
   				   an open month in both JC and AR */
                                IF @batchmth <= @JClastmthsubclsd OR @batchmth <= @ARlastmthsubclsd 
                                    BEGIN
                                        SELECT  @errmsg = '- This Seq contains a closed month bill.  Use a batch '
                                        SELECT  @errmsg = @errmsg + 'month that is open in both AR and JC for this '
                                        SELECT  @errmsg = @errmsg + 'JCCo ARGLCo and JCGLCo. '
                                        SELECT  @errortext = @errorstart + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                        GOTO get_next_bcJBAR
                                    END
                                ELSE 
                                    BEGIN
   					/* This is a closed month change and the batch month in use is open month.
   					   We now need to check AR to see if there are previous changes to this same
   					   bill in a month later than this batch month. */
                                        SELECT  @adjust_mth = Mth
                                        FROM    bARTH WITH (NOLOCK)
                                        WHERE   ARCo = @arco /*JCCo.ARCo*/ AND AppliedMth = @billmonth AND AppliedTrans = @artrans AND ARTransType = 'A' AND Mth > @batchmth
                                        IF @@rowcount <> 0	-- an adjustment already exists in a later month.
                                            BEGIN
                                                SELECT  @errmsg = '- Changes to this bill already exist in a later month.  '
                                                SELECT  @errmsg = @errmsg + 'Use the batch month ' + ISNULL(CONVERT(varchar(8), @adjust_mth, 1), '')
                                                SELECT  @errmsg = @errmsg + ' or later. '	
                                                SELECT  @errortext = @errorstart + ISNULL(@errmsg, '')		
                                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                                IF @rcode <> 0 
                                                    GOTO bspexit
                                                GOTO get_next_bcJBAR
                                            END		
                                    END	
   				/* Having reached this point, This is a change to a closed month bill and the
   				   batch in use is OK.  We can proceed with normal validation. */	
                            END
                    END		/* End Closed month checks for bills being changed */
   
  		/*get old SortName*/
                SELECT  @oldSortName = m.SortName
                FROM    bARCM m WITH (NOLOCK)
                WHERE   m.CustGroup = @custgroup AND m.Customer = @oldcustomer
   
		/* RecType check 
		   JBIN RecType is Non-Nullable.  By default then, any Invoice marked for 'C'hange has previously
		   been interfaced and therefore the Old RecType value will never be null as well. */
                IF @rectype <> @oldrectype 
                    BEGIN
                        SELECT  @errortext = @errorstart + '- RecType should not be modified once Invoice has been interfaced to AR.  '
                        SELECT  @errortext = @errortext + 'Reset RecType value back to ' + ISNULL(CONVERT(varchar(3), @oldrectype), '') + ' and post.'
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                        IF @rcode <> 0 
                            GOTO bspexit
                        GOTO get_next_bcJBAR
                    END	
            END		/* End Header Change Val */
   
     	/* validation specific to Delete type JB header*/
        IF @batchtranstype = 'D' 
            BEGIN	/* Begin Header Delete Val */
                IF @batchmth <> @billmonth 
                    BEGIN
                        EXEC @rcode = vspJBITCheckForRetgRel @jbco, @billmonth, @billnumber, @errmsg OUTPUT
                        IF @rcode <> 0 
                            BEGIN
                                SELECT  @errmsg = '- Invalid operation: The billmonth of the bill being deleted falls in a closed AR month'
                                SELECT  @errmsg = @errmsg + ' and this Bill is being used to Release Retainage.  This bill may not be deleted!  ' 
                                SELECT  @errmsg = @errmsg + 'User must clear the batch!'
                                SELECT  @errortext = @errorstart + ISNULL(@errmsg, '')	
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit

                                UPDATE  bJBIN
                                SET     InvStatus = 'I'
                                WHERE   JBCo = @jbco AND BillMonth = @billmonth AND BillNumber = @billnumber
                                GOTO get_next_bcJBAR
                            END
                    END
   
      		/*get old SortName*/
                SELECT  @oldSortName = m.SortName
                FROM    bARCM m WITH (NOLOCK)
                WHERE   m.CustGroup = @custgroup AND m.Customer = @oldcustomer
   
            END /* End Header Delete validation */

     	/* Validation for all lines associated to this JB Transaction */
        DECLARE bcJBAL CURSOR FOR
        SELECT Item, ARLine, BatchTransType, GLCo, GLAcct, Description,
        TaxGroup, TaxCode, UM, Amount, Units, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, RetgRel, RetgTaxRel,
        oldDescription, oldAmount, oldUnits, oldTaxCode, oldTaxBasis, oldTaxAmount, oldRetgPct, oldRetainage, 
        oldRetgTax, oldRetgRel, oldRetgTaxRel
        FROM bJBAL WITH (NOLOCK)
        WHERE Co = @jbco AND Mth = @batchmth AND BatchId=@batchid AND BatchSeq=@seq
   
     	/* open cursor for line */
        OPEN bcJBAL
     	/* set appropiate cursor flag */
        SELECT  @opencursorJBAL = 1
       /*get first row (line)*/
        get_next_bcJBAL:
        FETCH NEXT FROM bcJBAL INTO
          		@jbcontractItem, @ARLine, @batchtranstypeLine, @JCGLCo, @GLRevAcct, @linedescription,
            	@TaxGroup, @TaxCode, @UM, @Amount, @Units, @TaxBasis, @LineTaxAmount, @RetgPct, @Retainage, @LineRetgTax, @RetgRel, @LineRetgTaxRel,
             	@oldlinedescription, @oldAmount, @oldUnits, @oldTaxCode, @oldTaxBasis, @oldLineTaxAmount, @oldRetgPct, @oldRetainage, 
				@oldLineRetgTax, @oldRetgRel, @oldLineRetgTaxRel
   
        WHILE (@@fetch_status = 0) 
            BEGIN /* Spin through the Lines */
                SELECT  @errorstart = 'Seq' + ISNULL(CONVERT(varchar(6), @seq), '') + ' Item ' + ISNULL(CONVERT(varchar(6), @ARLine), '') + ' '
	   
	   
			/* Reset Line variables as needed here.  
 			   Retrieved as each Lines TaxCode gets validated.  Reset to avoid leftover value when TaxCode is invalid */
                SELECT  @HQTXcrdGLAcct = NULL, @HQTXcrdRetgGLAcct = NULL, @HQTXcrdGLAcctPST = NULL, @HQTXcrdRetgGLAcctPST = NULL, @oldHQTXcrdGLAcct = NULL, @oldHQTXcrdRetgGLAcct = NULL, @oldHQTXcrdGLAcctPST = NULL, @oldHQTXcrdRetgGLAcctPST = NULL, @TaxAmount = 0, @TaxAmountPST = 0, @RetgTax = 0, @RetgTaxPST = 0, @oldTaxAmount = 0, @oldTaxAmountPST = 0, @oldRetgTax = 0, @oldRetgTaxPST = 0

       		/*validate transactions action*/
                IF @batchtranstypeLine <> 'A' AND @batchtranstypeLine <> 'C' AND @batchtranstypeLine <> 'D' 
                    BEGIN
                        SELECT  @errortext = @errorstart + ' - Invalid transaction type, must be A, C, or D.'
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                        IF @rcode <> 0 
                            GOTO bspexit
                    END
       
   			/*Validate Receivable Type*/
                EXEC @rcode = bspRecTypeVal @arco, @rectype, @errmsg OUTPUT
                IF @rectype IS NULL			--Issue #140215:  ISNULL(@rectype, 0) = 0
                    SELECT  @rcode = 1
                IF @rcode <> 0 
                    BEGIN
                        SELECT  @errortext = @errorstart + '- Receivable Type:' + ISNULL(CONVERT(varchar(3), @rectype), '') + ' - ' + ISNULL(@errmsg, '')
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT

                        IF @opencursorJBAL = 1 
                            BEGIN
                                CLOSE bcJBAL
                                DEALLOCATE bcJBAL
                                SELECT @opencursorJBAL = 0
                            END

                        GOTO get_next_bcJBAR
                    END
   
         	/* get the accounts for the receivable type*/
                SELECT  @ARGLCo = GLCo, @GLARAcct = GLARAcct, @GLRetainAcct = GLRetainAcct, @GLDiscountAcct = GLDiscountAcct
                FROM    bARRT WITH (NOLOCK)
                WHERE   ARCo = @arco AND RecType = @rectype
                IF @@rowcount = 0 
                    BEGIN
                        SELECT  @errortext = @errorstart + ' Receivable Type:' + ISNULL(CONVERT(varchar(3), @rectype), '') + ': is invalid'
                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                        IF @rcode <> 0 
                            GOTO bspexit
                    END
   
           /*validation specific to Add type transactions, or Change type transactions */
                IF @batchtranstypeLine = 'A' OR @batchtranstypeLine = 'C' 
                    BEGIN
				/* Validate Contract Item only if Contract is not null */
                        IF @jbcontract IS NOT NULL 
                            BEGIN
                                EXEC @rcode = bspJCCIVal @jbco, @jbcontract, @jbcontractItem, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + '- Contract :' + ISNULL(@jbcontract, '') + ', ' + 'Item :' + ISNULL(@jbcontractItem, '') + ': ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END
                            END
 
                        IF @TaxCode IS NULL AND (@LineTaxAmount <> 0 OR @LineRetgTax <> 0 OR @LineRetgTaxRel <> 0
                                                ) 
                            BEGIN
                                SELECT  @errortext = @errorstart + 'Tax Amount not allowed without a Tax Code'
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                            END

             	/*Validate Tax Group if there is a tax code */
                        IF @TaxCode IS NOT NULL 
                            BEGIN
                                IF NOT EXISTS ( SELECT  1
                                                FROM    bHQCO WITH (NOLOCK)
                                                WHERE   HQCo = @jbco AND TaxGroup = @TaxGroup ) 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + 'Company -: ' + ISNULL(CONVERT(varchar(10), @jbco), '') + '- missing Tax Group : ' + ISNULL(CONVERT(varchar(3), @TaxGroup), '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END
                            END
  
				/* Validate TaxCode by getting the accounts for the tax code */
                        IF @TaxCode IS NOT NULL 
                            BEGIN
                                EXEC @rcode = bspHQTaxRateGetAll @TaxGroup, @TaxCode, @transdate, NULL, @taxrate OUTPUT, @gstrate OUTPUT,
									@pstrate OUTPUT, @HQTXcrdGLAcct OUTPUT, @HQTXcrdRetgGLAcct OUTPUT, NULL, NULL, @HQTXcrdGLAcctPST OUTPUT,
									@HQTXcrdRetgGLAcctPST OUTPUT, NULL, NULL, @errmsg OUTPUT

                                IF @rcode <> 0 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + 'Company : ' + ISNULL(CONVERT(varchar(10), @arco), '') + ' - Tax Group : ' + ISNULL(CONVERT(varchar(3), @TaxGroup), '')
                                        SELECT  @errortext = @errortext + ' - TaxCode : ' + ISNULL(@TaxCode, '') + ' - is not valid! - ' + @errmsg
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END

                                IF @pstrate = 0 
                                    BEGIN
						/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
						   In any case:
						   a)  @taxrate is the correct value.  
						   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
						   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
                                        SELECT  @TaxAmount = @LineTaxAmount
                                        SELECT  @RetgTax = @LineRetgTax
                                    END
                                ELSE 
                                    BEGIN
						/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
                                        IF @taxrate <> 0 
                                            BEGIN
                                                SELECT  @TaxAmount = (@LineTaxAmount * @gstrate) / @taxrate		--GST TaxAmount
                                                SELECT  @TaxAmountPST = @LineTaxAmount - @TaxAmount				--PST TaxAmount
                                                SELECT  @RetgTax = (@LineRetgTax * @gstrate) / @taxrate			--GST RetgTax
                                                SELECT  @RetgTaxPST = @LineRetgTax - @RetgTax					--PST RetgTax
                                            END
                                    END
                            END

--   				/* Validate: If Possible, do not allow reducing retainage below the amount of open retainage. */
--   				if @Retainage is not null
--   					begin	/* Begin Lower Retg Loop */
--   					/* Get Total contract item amount. Necessary to determine if user is attempting
--   					   to reverse retainage already posted. */
--   					select @jbcontractitemamt = isnull(min(t.CurrContract),0) + isnull(sum(x.ChgOrderAmt),0)
--   					from JBIN n
--   					join JBIT t on t.JBCo = n.JBCo and t.BillMonth = n.BillMonth
--   						and t.BillNumber = n.BillNumber and t.Item = @jbcontractItem
--   					left join JBCC c on c.JBCo = n.JBCo and c.BillMonth = n.BillMonth
--   						and c.BillNumber = n.BillNumber
--   					left join JCOI i on i.JCCo = n.JBCo and i.Contract = n.Contract
--   						and i.Job = c.Job and i.ACO = c.ACO and i.Item = t.Item
--   					left join JBCX x on x.JBCo = n.JBCo and x.BillMonth = n.BillMonth
--   						and x.BillNumber = n.BillNumber and x.Job = i.Job and x.ACO = i.ACO and x.ACOItem = i.ACOItem
--   					where n.JBCo = @jbco and n.BillMonth = @billmonth
--   						and n.BillNumber = @billnumber and n.Contract = @jbcontract
--   
--   					/* Open retainage is calculated up to but not including this bill!  On a bill being Changed or 
--   					   Deleted, an ARTrans will be available.  However, on a bill being Added, ARTrans does 
--   					   not get set until posting, therefore for the sake of calculations, using (Max(ARTrans) + 1)
--   					   for this BillMonth is acceptable. */
--   					if @artrans is null		-- We are adding a new bill in an open month, (BatchMth & BillMth are same)
--   						begin
--   						select @tempartrans = isnull(max(ARTrans),0)
--   						from bARTH with (nolock)
--   						where ARCo = @arco and Mth = @billmonth
--   						select @tempartrans = @tempartrans + 1
--   						end
--   					else
--   						begin
--   						select @tempartrans = @artrans
--   						end
--   	
--   					/* Get total open retainage, in AR, up to but not including this bill */
--   					select @ar_retg = 0			
--   		      		select @ar_retg = isnull(sum(l.Retainage),0)
--   		      		from bARTH h with (nolock)
--   		      		join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans and
--   		        		l.JCCo = @jbco and l.Contract = @jbcontract and l.Item = @jbcontractItem
--   		      		where h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
--   						and (h.Mth < @billmonth or (h.Mth = @billmonth and h.ARTrans < @tempartrans))	--Less than this bill in 'C' mode
--	   	
--   					/* The validation test that follows is looking for an attempt by the users to send Retainage negative directly
--   					   as a result of inputting negative retainage on a positive item on this bill.  Therefore when determining
--   					   @openretg, (for the sake of this check) we assume negative retainage on the bill and therefore are not
--   					   concerned with the actual retainage value (as part of @openretg).  We only want to know if the input amount
--   					   will be greater than all of the current open retg combined for this item.  We do however, have to consider
--   					   any Release Retainage occuring at the same time on this bill.  The final result is that the Retainage value
--   					   on this bill (Negative value) cannot exceed the total positive retainage that already exists otherwise
--   					   the total retainage value for this item will go negative. (The below code is correct for this check!) */
--   			 		select @openretg = 0
--   					select @openretg = @ar_retg + isnull(@RetgRel,0)	-- AR Open Retg, remove this Bills Release Retg
--   	
--   					/* This preventative measure can only be invoked if the original contract item amount
--   					   is opposite in polarity to the user inputed retainage amount (indicating a reversal)
--   					   AND the current open retainage must be the same polarity as the original contract 
--    					   item amount (indicating that over reversing has not already occurred in the past).  
--   					   If over reversing has already occurred, then there is nothing we can do to protect
--   					   the users against themselves for this bill.  Let them continue! */
--	   -- -- 				if (@jbcontractitemamt > 0 and @Retainage < 0 and @openretg >= 0) or 
--	   -- -- 					(@jbcontractitemamt < 0 and @Retainage > 0 and @openretg <= 0)
--	   -- -- 					begin
--	   -- -- 					if abs(@openretg) < abs(@Retainage)
--	   -- -- 		      			begin
--	   -- -- 						select @errortext = @errorstart + 'Not enough Retainage Open in AR to allow lowering this Retainage amount!'
--	   -- -- 						exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--	   -- -- 						if @rcode <> 0 goto bspexit
--	   -- -- 		      			end
--	   -- -- 					end
--   					end 	/* End Lower Retg Loop */
                    END /* trans type A or C */
   
                IF @batchtranstypeLine = 'C' OR @batchtranstypeLine = 'D' 
                    BEGIN
				/* get old info from original ARTL lines for gl distributions */
                        SELECT  @oldTaxGroup = TaxGroup, @oldJCGLCo = GLCo, @oldGLRevAcct = GLAcct
                        FROM    ARTL WITH (NOLOCK)
                        WHERE   ARCo = @arco AND Mth = @billmonth /*@batchmth*/ AND ARTrans = @artrans AND ARLine = @ARLine
   
				/* If Contract has been Hard Closed since last interfacing this bill, then user has already moved GL from
				   the Contract's OpenRevAcct to its ClosedRevAcct.  This is not our responsibility.  Therefore (OLD)
				   @oldGLRevAcct and (NEW) @GLRevAcct are automatically the same ClosedRevAcct.  (Unless the user is
				   using an OverrideAcct).  Either way, this ClosedRevAcct (or OverrideAcct) has already been set 
				   by bspJBAR_Insert and can be used directly here as our (OLD) @oldGLRevAcct.*/
                        IF @jbcontractstat = 3 
                            SELECT  @oldGLRevAcct = @GLRevAcct	--Either ClosedRevAcct or OverrideAcct
   
       			/* get the old accounts for the receivable type */
                        SELECT  @oldARGLCo = GLCo, @oldGLARAcct = GLARAcct, @oldGLRetainAcct = GLRetainAcct, @oldGLDiscountAcct = GLDiscountAcct
                        FROM    bARRT WITH (NOLOCK)
                        WHERE   ARCo = @arco AND RecType = @oldrectype
                        IF @@rowcount = 0 
                            BEGIN
                                SELECT  @errortext = @errorstart + 'Old Receivable Type:' + ISNULL(CONVERT(varchar(3), @oldrectype), '') + ': is invalid'
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                            END
				   
				/* Getting the accounts for the old tax code */
                        IF @oldTaxCode IS NOT NULL 
                            BEGIN
                                EXEC @rcode = bspHQTaxRateGetAll @oldTaxGroup, @oldTaxCode, @oldtransdate, NULL, @taxrate OUTPUT, @gstrate OUTPUT,
									@pstrate OUTPUT, @oldHQTXcrdGLAcct OUTPUT, @oldHQTXcrdRetgGLAcct OUTPUT, NULL, NULL, @oldHQTXcrdGLAcctPST OUTPUT,
									@oldHQTXcrdRetgGLAcctPST OUTPUT, NULL, NULL, @errmsg OUTPUT

                                IF @rcode <> 0 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + 'Company : ' + ISNULL(CONVERT(varchar(10), @arco), '') + ' - Tax Group : ' + ISNULL(CONVERT(varchar(3), @oldTaxGroup), '')
                                        SELECT  @errortext = @errortext + ' - TaxCode : ' + ISNULL(@oldTaxCode, '') + ' - is not valid! - ' + @errmsg
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END

                                IF @pstrate = 0 
                                    BEGIN
						/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
						   In any case:
						   a)  @taxrate is the correct value.  
						   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
						   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
                                        SELECT  @oldTaxAmount = @oldLineTaxAmount
                                        SELECT  @oldRetgTax = @oldLineRetgTax
                                    END
                                ELSE 
                                    BEGIN
						/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
                                        IF @taxrate <> 0 
                                            BEGIN
                                                SELECT  @oldTaxAmount = (@oldLineTaxAmount * @gstrate) / @taxrate		--GST TaxAmount
                                                SELECT  @oldTaxAmountPST = @oldLineTaxAmount - @oldTaxAmount				--PST TaxAmount
                                                SELECT  @oldRetgTax = (@oldLineRetgTax * @gstrate) / @taxrate			--GST RetgTax
                                                SELECT  @oldRetgTaxPST = @oldLineRetgTax - @oldRetgTax					--PST RetgTax
                                            END
                                    END
                            END
                    END
   
         	/*validation specific for deletes*/
                IF @batchtranstypeLine = 'D' 
                    BEGIN
                        SELECT  @errorLine = NULL
                    END
   
                update_audit: /* Update audit lists - Need to update GL , JC distribution*/
                SELECT  @i = 1, @InterCompany = 8	/*set first Intercompany account */
                WHILE @i <= 11 
                    BEGIN
            	/*Validate GL Accounts*/
            	/* spin through each type of GL account, check it and write GL Amount */
                        SELECT  @PostGLAcct = NULL, @PostAmount = 0, @oldPostGLAcct = NULL, @oldPostAmount = 0, @chksubtype = 'N'
   
            	/****** new values *****/
           		/* AR Receivables Account */
                        IF @i = 1 
                            BEGIN
                                SELECT  @PostGLCo = @ARGLCo, @PostGLAcct = @GLARAcct, @PostAmount = (ISNULL(@Amount, 0) + ISNULL(@LineTaxAmount, 0) + ISNULL(@LineRetgTax, 0)) - ISNULL(@Retainage, 0), @oldPostGLCo = @oldARGLCo, @oldPostGLAcct = @oldGLARAcct, @oldPostAmount = -((ISNULL(@oldAmount, 0) + ISNULL(@oldLineTaxAmount, 0) + ISNULL(@oldLineRetgTax, 0)) - ISNULL(@oldRetainage, 0)), @errorAccount = 'AR Receivable Account'
   
                	/* if Retainage Acct is same as AR Acct then combine values */
              		--if isnull(@GLARAcct,'' ) = isnull(@GLRetainAcct,'') select @PostAmount = isnull(@Amount,0) + isnull(@LineTaxAmount,0) + isnull(@LineRetgTax,0)
                 	--if isnull(@oldGLARAcct,'') = isnull(@oldGLRetainAcct,'') select @oldPostAmount = -(isnull(@oldAmount,0) + isnull(@oldLineTaxAmount,0) + isnull(@oldLineRetgTax,0))
   
   					/* Need to declare proper GLAcct SubType */
                                SELECT  @chksubtype = 'R'				
                            END
   
             	/* Retainage Receivables Account */
                        IF @i = 2 
                            BEGIN
                                SELECT  @PostGLCo = @ARGLCo, @PostGLAcct = @GLRetainAcct, @PostAmount = ISNULL(@Retainage, 0), @oldPostGLCo = @oldARGLCo, @oldPostGLAcct = @oldGLRetainAcct, @oldPostAmount = -(ISNULL(@oldRetainage, 0)), @errorAccount = 'AR Retainage Account'
   
               		/* if Retainage Acct is same as AR Acct then retainage is posted with @i=1 */
              	    --if isnull(@GLARAcct,'') = isnull(@GLRetainAcct,'') select @PostAmount = 0
              	    --if isnull(@oldGLARAcct,'') = isnull(@oldGLRetainAcct,'') select @oldPostAmount = 0
   
   					/* Need to declare proper GLAcct SubType */
                                SELECT  @chksubtype = 'R'
                            END
      
  				/* Tax account.  Standard US or GST */
                        IF @i = 3 
                            SELECT  @PostGLCo = @ARGLCo, @PostGLAcct = @HQTXcrdGLAcct, @PostAmount = -(ISNULL(@TaxAmount, 0)), @oldPostGLCo = @oldARGLCo, @oldPostGLAcct = @oldHQTXcrdGLAcct, @oldPostAmount = ISNULL(@oldTaxAmount, 0), @errorAccount = 'AR Tax Account'
		   
  				/* Retainage Tax account.  Standard US or GST */
                        IF @i = 4 
                            SELECT  @PostGLCo = @ARGLCo, @PostGLAcct = @HQTXcrdRetgGLAcct, @PostAmount = -(ISNULL(@RetgTax, 0)), @oldPostGLCo = @oldARGLCo, @oldPostGLAcct = @oldHQTXcrdRetgGLAcct, @oldPostAmount = ISNULL(@oldRetgTax, 0), @errorAccount = 'AR Retg Tax Account'

  				/* Tax account.  PST */
                        IF @i = 5 
                            SELECT  @PostGLCo = @ARGLCo, @PostGLAcct = @HQTXcrdGLAcctPST, @PostAmount = -(ISNULL(@TaxAmountPST, 0)), @oldPostGLCo = @oldARGLCo, @oldPostGLAcct = @oldHQTXcrdGLAcctPST, @oldPostAmount = ISNULL(@oldTaxAmountPST, 0), @errorAccount = 'AR Tax Account PST'

  				/* Retainage Tax account.  PST */
                        IF @i = 6 
                            SELECT  @PostGLCo = @ARGLCo, @PostGLAcct = @HQTXcrdRetgGLAcctPST, @PostAmount = -(ISNULL(@RetgTaxPST, 0)), @oldPostGLCo = @oldARGLCo, @oldPostGLAcct = @oldHQTXcrdRetgGLAcctPST, @oldPostAmount = ISNULL(@oldRetgTaxPST, 0), @errorAccount = 'AR Retg Tax Account PST'
   
           		/* Revenue Account */
                        IF @i = 7 
                            BEGIN
                                SELECT  @PostGLCo = @JCGLCo, @PostGLAcct = @GLRevAcct, @PostAmount = -(ISNULL(@Amount, 0)), @oldPostGLCo = @oldJCGLCo, @oldPostGLAcct = @oldGLRevAcct, @oldPostAmount = ISNULL(@oldAmount, 0), @errorAccount = 'Revenue Account'
   				
   					/* Need to declare proper GLAcct SubType */
                                IF ISNULL(@JCGLCo, 0) <> 0 AND ISNULL(@jbcontract, '') <> '' 
                                    SELECT  @chksubtype = 'J'
                            END	
   
   				/* If in 'A'dd or 'D'elete mode and ARGL Company is the same as the GLRev Company
   				   then skip all intercompany processing completely. */
                        IF @i >= @InterCompany AND @batchtranstypeLine IN ('A', 'D') AND @ARGLCo = @JCGLCo 
                            BEGIN
                                SELECT  @i = 11
                                GOTO skip_GLUpdate
                            END			
   
   				/* Cross company requires 4 stages to accomodate 'C'hange mode as well as 'Add' and 'D'elete */
   			
           		/* cross company part I  --  InterCompany Payables GLCo and GLAcct, retrieve OLD values */
                        XCompany8:
                        IF @i = 8 
                            BEGIN
                                IF @batchtranstypeLine = 'A' AND @ARGLCo <> @JCGLCo 
                                    GOTO XCompany9		-- There is no Old Inter-APGLCo
                                IF @batchtranstypeLine = 'C' AND @ARGLCo = @oldJCGLCo 
                                    GOTO XCompany9	-- There is no Old Inter-APGLCo
                                SELECT  @oldPostGLCo = APGLCo, @oldPostGLAcct = APGLAcct, @oldPostAmount = (ISNULL(@oldAmount, 0)), @compareICamt = (ISNULL(@Amount, 0)), @errorAccount = 'XREF GL Acct'
                                FROM    bGLIA WITH (NOLOCK)
                                WHERE   ARGLCo = @JCGLCo AND APGLCo = @ARGLCo
   		
                                IF @@rowcount = 0 
                                    BEGIN
                                        SELECT  @errortext = 'Invalid cross company entry in GLIA. Must have Old PayableGLCo = ' + ISNULL(CONVERT(varchar(10), @oldARGLCo), '') + ' - ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT

                                        IF @opencursorJBAL = 1 
                                            BEGIN
                                                CLOSE bcJBAL
                                                DEALLOCATE bcJBAL
                                                SELECT @opencursorJBAL = 0
                                            END

                                        --IF @rcode <> 0 #143622 
                                            GOTO get_next_bcJBAR
                                    END
                            END
   
   				/* Skip, do not accumulate Intercompany values for lines whose amounts have
   				   not changed unless the Intercompany itself has changed. This is evaluated 
   				   separately from NON-Intercompany to avoid doubling amounts. */
                        IF @batchtranstypeLine = 'C' AND @oldPostAmount = @compareICamt AND @JCGLCo = @oldJCGLCo 
                            SELECT  @oldPostAmount = 0
   
   				/* cross company part II  --  InterCompany Payables GLCo and GLAcct, retrieve NEW values */
                        XCompany9:
                        IF @i = 9 
                            BEGIN
                                IF @batchtranstypeLine = 'C' AND @ARGLCo = @JCGLCo 
                                    GOTO XCompany10		-- There is no NEW Inter-APGLCo
                                SELECT  @PostGLCo = APGLCo, @PostGLAcct = APGLAcct, @PostAmount = -(ISNULL(@Amount, 0)), @compareIColdamt = -(ISNULL(@oldAmount, 0)), @errorAccount = 'XREF GL Acct'
                                FROM    bGLIA WITH (NOLOCK)
                                WHERE   ARGLCo = @JCGLCo AND APGLCo = @ARGLCo
   
                                IF @@rowcount = 0 
                                    BEGIN
                                        SELECT  @errortext = 'Invalid cross company entry in GLIA. Must have New PayableGLCo = ' + ISNULL(CONVERT(varchar(10), @ARGLCo), '') + ' - ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT

                                        IF @opencursorJBAL = 1 
                                            BEGIN
                                                CLOSE bcJBAL
                                                DEALLOCATE bcJBAL
                                                SELECT @opencursorJBAL = 0
                                            END

                                        --IF @rcode <> 0 #143622 
                                            GOTO get_next_bcJBAR
                                    END
                            END
   
   				/* Skip, do not accumulate Intercompany values for lines whose amounts have
   				   not changed unless the Intercompany itself has changed. This is evaluated 
   				   separately from NON-Intercompany to avoid doubling amounts. */
                        IF @batchtranstypeLine = 'C' AND @PostAmount = @compareIColdamt AND @JCGLCo = @oldJCGLCo 
                            SELECT  @PostAmount = 0
   
   				/* cross company part III  --  InterCompany Receivables GLCo and GLAcct, retrieve OLD values */
                        XCompany10:
                        IF @i = 10 
                            BEGIN
                                IF @batchtranstypeLine = 'A' AND @ARGLCo <> @JCGLCo 
                                    GOTO XCompany11		-- There is no Old Inter-ARGLCo
                                IF @batchtranstypeLine = 'C' AND @ARGLCo = @oldJCGLCo 
                                    GOTO XCompany11	-- There is no Old Inter-ARGLCo  	  	
                                SELECT  @oldPostGLCo = ARGLCo, @oldPostGLAcct = ARGLAcct, @oldPostAmount = -(ISNULL(@oldAmount, 0)), @compareICamt = -(ISNULL(@Amount, 0)), @errorAccount = 'XREF GL Acct'
                                FROM    bGLIA WITH (NOLOCK)
                                WHERE   ARGLCo = @JCGLCo AND APGLCo = @ARGLCo  
   		
                                IF @@rowcount = 0 
                                    BEGIN
                                        SELECT  @errmsg = 'Invalid cross company entry in GLIA. Must have Old ReceivableGLCo = ' + ISNULL(CONVERT(varchar(10), @oldJCGLCo), '') + ' -  ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT

                                        IF @opencursorJBAL = 1 
                                            BEGIN
                                                CLOSE bcJBAL
                                                DEALLOCATE bcJBAL
                                                SELECT @opencursorJBAL = 0
                                            END

                                        --IF @rcode <> 0 #143622 
                                            GOTO get_next_bcJBAR
                                    END
                            END
   
   				/* Skip, do not accumulate Intercompany values for lines whose amounts have
   				   not changed unless the Intercompany itself has changed. This is evaluated 
   				   separately from NON-Intercompany to avoid doubling amounts. */
                        IF @batchtranstypeLine = 'C' AND @oldPostAmount = @compareICamt AND @JCGLCo = @oldJCGLCo 
                            SELECT  @oldPostAmount = 0
   
   				/* cross company part IV  --  InterCompany Receivables GLCo and GLAcct, retrieve NEW values */
                        XCompany11:    
                        IF @i = 11 
                            BEGIN
                                IF @batchtranstypeLine = 'C' AND @ARGLCo = @JCGLCo 
                                    GOTO JBGLUpdate	-- There is no NEW Inter-ARGLCo
                                SELECT  @PostGLCo = ARGLCo, @PostGLAcct = ARGLAcct, @PostAmount = (ISNULL(@Amount, 0)), @compareIColdamt = (ISNULL(@oldAmount, 0)), @errorAccount = 'XREF GL Acct'
                                FROM    bGLIA WITH (NOLOCK)
                                WHERE   ARGLCo = @JCGLCo AND APGLCo = @ARGLCo
   		
                                IF @@rowcount = 0 
                                    BEGIN
                                        SELECT  @errmsg = 'Invalid cross company entry in GLIA. Must have New ReceivableGLCo = ' + ISNULL(CONVERT(varchar(10), @JCGLCo), '') + ' -  ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT

                                        IF @opencursorJBAL = 1 
                                            BEGIN
                                                CLOSE bcJBAL
                                                DEALLOCATE bcJBAL
                                                SELECT @opencursorJBAL = 0
                                            END

                                        --IF @rcode <> 0 #143622 
                                            GOTO get_next_bcJBAR
                                    END
                            END 
   
   				/* Skip, do not accumulate Intercompany values for lines whose amounts have
   				   not changed unless the Intercompany itself has changed. This is evaluated 
   				   separately from NON-Intercompany to avoid doubling amounts. */
                        IF @batchtranstypeLine = 'C' AND @PostAmount = @compareIColdamt AND @JCGLCo = @oldJCGLCo 
                            SELECT  @PostAmount = 0
   
           		/* dont create GL if old and new are the same */
                        IF @batchtranstypeLine = 'C' AND @PostAmount = -ISNULL(@oldPostAmount, 0) AND @PostGLCo = @oldPostGLCo AND @PostGLAcct = @oldPostGLAcct 
                            GOTO skip_GLUpdate
   
                        JBGLUpdate:
       			/*********  This 1st Update/Insert relates to OLD values during Change and Delete Modes *********/
	   
   				/* Lets first try to update to see if this GLAcct is already in batch 
   				   Note that 'Item' has been left out of the 'where' clause.  This results
   				   in a single GL record regardless of the number of Items/Lines that we
   				   cycle thru.  This is appropriate since GL is updated at Transaction level only. */
                        IF ISNULL(@oldPostAmount, 0) <> 0 AND @i < @InterCompany AND @batchtranstypeLine <> 'A' 
                            BEGIN
                                UPDATE  bJBGL
                                SET     Item = @jbcontractItem, ARLine = @ARLine, Amount = (@oldPostAmount + Amount)
                                WHERE   JBCo = @jbco AND Mth = @batchmth AND BatchId = @batchid AND GLCo = @oldPostGLCo AND GLAcct = @oldPostGLAcct AND BatchSeq = @seq AND OldNew = 0 AND JBTransType = 'J'
                                IF @@rowcount = 1 
                                    SELECT  @oldPostAmount = 0 	/* set Amount to zero so we don't re-add the record*/
                            END
   
       			/* if intercompany then try to update the record so there is only one record per transfer */
                        IF ISNULL(@oldPostAmount, 0) <> 0 AND @i >= @InterCompany AND @batchtranstypeLine <> 'A' 
                            BEGIN
                                UPDATE  bJBGL
                                SET     Amount = Amount + @oldPostAmount
                                WHERE   JBCo = @jbco AND Mth = @batchmth AND BatchId = @batchid AND BatchSeq = 0 AND Item = STR(@oldPostGLCo, 16, 0)	/* yes we are using Item for the Xcompany */ AND GLAcct = @oldPostGLAcct AND OldNew = 0 AND JBTransType = 'X' 
                                IF @@rowcount = 1 
                                    SELECT  @oldPostAmount = 0  /* set Amount to zero so we dont re-add the record*/
                            END
   
   				/* For posting OLD values to all Accounts i=1 thru i=8 */
                        IF ISNULL(@oldPostAmount, 0) <> 0 AND @batchtranstypeLine <> 'A' 
                            BEGIN
                                EXEC @rcode = bspGLACfPostable @oldPostGLCo, @oldPostGLAcct, @chksubtype, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + 'old GLCo -: ' + ISNULL(CONVERT(varchar(10), @oldPostGLCo), '') + '- old GL Account - ( ' + ISNULL(@errorAccount, '') + '): ' + ISNULL(@oldPostGLAcct, '') + ': ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END
                                ELSE 
                                    BEGIN
                                        INSERT  INTO bJBGL (JBCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, JBTransType, ARTrans, ARLine, Customer, SortName, CustGroup, Invoice, Contract, Item, ActDate, Description, Amount)
                                        VALUES  (@jbco, @batchmth, @batchid, @oldPostGLCo, @oldPostGLAcct, CASE WHEN @i < @InterCompany THEN @seq
                                                                                                                ELSE 0
                                                                                                           END, 0, CASE WHEN @i < @InterCompany THEN 'J'
                                                                                                                        ELSE 'X'
                                                                                                                   END, CASE WHEN @i < @InterCompany THEN @artrans
                                                                                                                             ELSE NULL
                                                                                                                        END, CASE WHEN @i < @InterCompany THEN @ARLine
                                                                                                                                  ELSE NULL
                                                                                                                             END, CASE WHEN @i < @InterCompany THEN @customer
                                                                                                                                       ELSE NULL
                                                                                                                                  END, CASE WHEN @i < @InterCompany THEN @SortName
                                                                                                                                            ELSE NULL
                                                                                                                                       END, CASE WHEN @i < @InterCompany THEN @custgroup
                                                                                                                                                 ELSE NULL
                                                                                                                                            END, CASE WHEN @i < @InterCompany THEN @oldinvoice
                                                                                                                                                      ELSE NULL
                                                                                                                                                 END, CASE WHEN @i < @InterCompany THEN @oldjbcontract
                                                                                                                                                           ELSE NULL
                                                                                                                                                      END, CASE WHEN @i < @InterCompany THEN @jbcontractItem
                                                                                                                                                                ELSE STR(@oldPostGLCo, 16, 0)
                                                                                                                                                           END, @transdate, 
   							-- we will use transaction description next, since JB does not post to Detail level in GLDT 
                                                 CASE WHEN @i < @InterCompany THEN @olddescription
                                                      ELSE 'Inter-Company Transfer'
                                                 END, @oldPostAmount)
                                        IF @@rowcount = 0 
                                            BEGIN
                                                SELECT  @errmsg = 'Unable to add GL Distribution audit - ' + ISNULL(@errmsg, ''), @rcode = 1
                                                GOTO bspexit
                                            END

						/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
                                        IF NOT EXISTS ( SELECT  1
                                                        FROM    bHQCC
                                                        WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid AND GLCo = @oldPostGLCo ) 
                                            BEGIN
                                                INSERT  bHQCC (Co, Mth, BatchId, GLCo)
                                                VALUES  (@jbco, @batchmth, @batchid, @oldPostGLCo)
                                            END
                                    END
                            END				
   
   				/*********  This 2nd Update/Insert relates to NEW values during Add and Change Modes *********/
   
   				/* Lets first try to update to see if this GLAcct is already in batch 
 
   			   Note that 'Item' has been left out of the 'where' clause.  This results
   			   in a single GL record regardless of the number of Items/Lines that we
   			   cycle thru.  This is appropriate since GL is updated at Transaction level only. */
                        IF ISNULL(@PostAmount, 0) <> 0 AND @i < @InterCompany AND @batchtranstypeLine <> 'D' 
                            BEGIN
                                UPDATE  bJBGL
                                SET     Item = @jbcontractItem, ARLine = @ARLine, Amount = (@PostAmount + Amount)
                                WHERE   JBCo = @jbco AND Mth = @batchmth AND BatchId = @batchid AND GLCo = @PostGLCo AND GLAcct = @PostGLAcct AND BatchSeq = @seq AND OldNew = 1 AND JBTransType = 'J'
                                IF @@rowcount = 1 
                                    SELECT  @PostAmount = 0 	/* set Amount to zero so we don't re-add the record*/
                            END
   
       			/* if intercompany then try to update the record so there is only one record per transfer */
                        IF ISNULL(@PostAmount, 0) <> 0 AND @i >= @InterCompany AND @batchtranstypeLine <> 'D' 
                            BEGIN
                                UPDATE  bJBGL
                                SET     Amount = Amount + @PostAmount
                                WHERE   JBCo = @jbco AND Mth = @batchmth AND BatchId = @batchid AND BatchSeq = 0 AND Item = STR(@PostGLCo, 16, 0) 	/* yes we are using Item for the Xcompany */ AND GLAcct = @PostGLAcct AND OldNew = 1 AND JBTransType = 'X' 
                                IF @@rowcount = 1 
                                    SELECT  @PostAmount = 0  /* set Amount to zero so we dont re-add the record*/
                            END
   
   				/* For posting NEW values to all Accounts i=1 thru i=8 */
                        IF ISNULL(@PostAmount, 0) <> 0 AND @batchtranstypeLine <> 'D' 
                            BEGIN
                                EXEC @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, @chksubtype, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + 'GLCo -: ' + ISNULL(CONVERT(varchar(10), @PostGLCo), '') + '- GL Account - ( ' + ISNULL(@errorAccount, '') + '): ' + ISNULL(@PostGLAcct, '') + ': ' + ISNULL(@errmsg, '')
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END
                                ELSE 
                                    BEGIN
                                        INSERT  INTO bJBGL (JBCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, JBTransType, ARTrans, ARLine, Customer, SortName, CustGroup, Invoice, Contract, Item, ActDate, Description, Amount)
                                        VALUES  (@jbco, @batchmth, @batchid, @PostGLCo, @PostGLAcct, CASE WHEN @i < @InterCompany THEN @seq
                                                                                                          ELSE 0
                                                                                                     END, 1, CASE WHEN @i < @InterCompany THEN 'J'
                                                                                                                  ELSE 'X'
                                                                                                             END, CASE WHEN @i < @InterCompany THEN @artrans
                                                                                                                       ELSE 0
                                                                                                                  END, CASE WHEN @i < @InterCompany THEN @ARLine
                                                                                                                            ELSE NULL
                                                                                                                       END, CASE WHEN @i < @InterCompany THEN @customer
                                                                                                                                 ELSE NULL
                                                                                                                            END, CASE WHEN @i < @InterCompany THEN @SortName
                                                                                                                                      ELSE NULL
                                                                                                                                 END, CASE WHEN @i < @InterCompany THEN @custgroup
                                                                                                                                           ELSE NULL
                                                                                                                                      END, CASE WHEN @i < @InterCompany THEN @invoice
                                                                                                                                                ELSE NULL
                                                                                                                                           END, CASE WHEN @i < @InterCompany THEN @jbcontract
                                                                                                                                                     ELSE NULL
                                                                                                                                                END, CASE WHEN @i < @InterCompany THEN @jbcontractItem
                                                                                                                                                          ELSE STR(@PostGLCo, 16, 0)
                                                                                                                                                     END, @transdate, 
   							-- we will use transaction description next, since JB does not post to Detail level in GLDT 
                                                 CASE WHEN @i < @InterCompany THEN @description
                                                      ELSE 'Inter-Company Transfer'
                                                 END, @PostAmount)
                                        IF @@rowcount = 0 
                                            BEGIN
                                                SELECT  @errmsg = 'Unable to add GL Distribution audit - ' + @errortext, @rcode = 1
                                                GOTO bspexit
                                            END

						/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
                                        IF NOT EXISTS ( SELECT  1
                                                        FROM    bHQCC
                                                        WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid AND GLCo = @PostGLCo ) 
                                            BEGIN
                                                INSERT  bHQCC (Co, Mth, BatchId, GLCo)
                                                VALUES  (@jbco, @batchmth, @batchid, @PostGLCo)
                                            END
                                    END
                            END
   
                        skip_GLUpdate:
           		/* get next GL record */
                        SELECT  @i = @i + 1, @errmsg = ''
                    END	/* End Audit Update */
   
         	/* Job Cost Update only if Contract is not null - No need to update JC for Non-Contract bills */
                IF @jbcontract IS NOT NULL 
                    BEGIN
                        SELECT  @changed = 'N'
                        IF @batchtranstypeLine = 'C' AND (ISNULL(@jbcontract, '') <> ISNULL(@oldjbcontract, '') OR ISNULL(@description, '') <> ISNULL(@olddescription, '') OR ISNULL(@transdate, '') <> ISNULL(@oldtransdate, '') OR ISNULL(@invoice, '') <> ISNULL(@oldinvoice, '') OR ISNULL(@Units, 0) <> ISNULL(@oldUnits, 0) OR ISNULL(@TaxAmount, 0) <> ISNULL(@oldTaxAmount, 0) OR ISNULL(@Amount, 0) <> ISNULL(@oldAmount, 0) OR ISNULL(@Retainage, 0) <> ISNULL(@oldRetainage, 0) OR ISNULL(@RetgTax, 0) <> ISNULL(@oldRetgTax, 0)
                                                         ) 
                            SELECT  @changed = 'Y'

           		/* JC Update = insert into bARBI */
                        IF ISNULL(@Amount, 0) = 0 AND ISNULL(@TaxAmount, 0) = 0 AND ISNULL(@Retainage, 0) = 0 AND ISNULL(@Units, 0) = 0 
                            GOTO JCUpdate_Old

           		/*If the line type is delete then do not update the new line - go update the old line */
                        IF @batchtranstypeLine = 'A' OR @changed = 'Y' 
                            BEGIN
       	    		/* check JCCO */
                                IF NOT EXISTS ( SELECT  1
                                                FROM    bJCCO WITH (NOLOCK)
                                                WHERE   JCCo = @jbco ) 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + '- JC Company -: ' + ISNULL(CONVERT(char(3), @jbco), '') + ': is invalid'
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END
   
             	    /* check if Contract or Item is null */
                                IF @jbcontract IS NULL AND EXISTS ( SELECT  1
                                                                    FROM    bJBIN WITH (NOLOCK)
                                                                    WHERE   JBCo = @jbco AND BillMonth = @billmonth /*@batchmth*/ AND BillNumber = @billnumber AND BillType IN ('P', 'B') ) 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + '- Contract -: may not be null'
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END
   
                                IF @jbcontractItem IS NULL AND EXISTS ( SELECT  1
                                                                        FROM    bJBIN WITH (NOLOCK)
                                                                        WHERE   JBCo = @jbco AND BillMonth = @billmonth /*@batchmth*/ AND BillNumber = @billnumber AND BillType IN ('P', 'B') ) 
                                    BEGIN
                                        SELECT  @errortext = @errorstart + '- Contract Item -: may not be null'
                                        EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                        IF @rcode <> 0 
                                            GOTO bspexit
                                    END

                                IF @jbcontract IS NOT NULL 
                                    BEGIN
                                        INSERT  INTO bJBJC (JBCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, JBTransType, Description, ActDate, ARTrans, Invoice, BilledUnits, BilledTax, BilledAmt, Retainage)
                                        VALUES  (@jbco, @batchmth, @batchid, @jbco, @jbcontract, @jbcontractItem, @seq, @ARLine, 1, 'J', @description, @transdate, @artrans, @invoice, @Units, CASE @UpdateTax
                                                                                                                                                                                                 WHEN 'Y' THEN ISNULL(@LineTaxAmount, 0) + ISNULL(@LineRetgTax, 0)
                                                                                                                                                                                                 ELSE 0
                                                                                                                                                                                               END, CASE @UpdateTax
                                                                                                                                                                                                      WHEN 'Y' THEN @Amount + ISNULL(@LineTaxAmount, 0) + ISNULL(@LineRetgTax, 0)
                                                                                                                                                                                                      ELSE @Amount
                                                                                                                                                                                                    END, CASE @UpdateTax
                                                                                                                                                                                                           WHEN 'Y' THEN @Retainage
                                                                                                                                                                                                           ELSE @Retainage - ISNULL(@LineRetgTax, 0)
                                                                                                                                                                                                         END)
                                        IF @@rowcount = 0 
                                            BEGIN
                                                SELECT  @errmsg = 'Unable to add JC Distribution record - ' + ISNULL(@errmsg, ''), @rcode = 1
                                                GOTO bspexit
                                            END
                                    END
                            END
                    END
   
                JCUpdate_Old:

   			/* update old amounts to JC */
                IF @batchtranstypeLine = 'D' OR @changed = 'Y' 
                    BEGIN
                        IF ISNULL(@oldAmount, 0) = 0 AND ISNULL(@oldTaxAmount, 0) = 0 AND ISNULL(@oldRetainage, 0) = 0 AND ISNULL(@oldUnits, 0) = 0 
                            GOTO JCUpdate_End
                        IF @oldjbcontract IS NULL 
                            GOTO JCUpdate_End

 	      		/* check if Contract is null */
                        IF @oldjbcontract IS NULL 
                            BEGIN
                                SELECT  @errortext = @errorstart + '- old Contract -: may not be null'
                                EXEC @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg OUTPUT
                                IF @rcode <> 0 
                                    GOTO bspexit
                            END

				/* subtract by - 0 to prevent a negative zero being written to the record */
                        IF @oldjbcontract IS NOT NULL 
                            BEGIN
                                INSERT  INTO bJBJC (JBCo, Mth, BatchId, JCCo, Contract, Item, BatchSeq, ARLine, OldNew, ARTrans, JBTransType, Description, ActDate, Invoice, BilledUnits, BilledTax, BilledAmt, Retainage)
                                VALUES  (@jbco, @batchmth, @batchid, @jbco, @oldjbcontract, @jbcontractItem, @seq, @ARLine, 0, @artrans, 'J', @olddescription, @oldtransdate, @oldinvoice, -(@oldUnits), CASE @UpdateTax
                                                                                                                                                                                                           WHEN 'Y' THEN -(ISNULL(@oldLineTaxAmount, 0) + ISNULL(@oldLineRetgTax, 0)) - 0
                                                                                                                                                                                                           ELSE 0
                                                                                                                                                                                                         END, CASE @UpdateTax
                                                                                                                                                                                                                WHEN 'Y' THEN -(@oldAmount + ISNULL(@oldLineTaxAmount, 0) + ISNULL(@oldLineRetgTax, 0)) - 0
                                                                                                                                                                                                                ELSE -(@oldAmount) - 0
                                                                                                                                                                                                              END, CASE @UpdateTax
                                                                                                                                                                                                                     WHEN 'Y' THEN -(@oldRetainage) - 0
                                                                                                                                                                                                                     ELSE -(@oldRetainage - ISNULL(@oldLineRetgTax, 0)) - 0
                                                                                                                                                                                                                   END)
                                IF @@rowcount = 0 
                                    BEGIN
                                        SELECT  @errmsg = 'Unable to add JC Distribution record - ' + ISNULL(@errmsg, ''), @rcode = 1
                                        GOTO bspexit
                                    END
                            END
                    END
   
                JCUpdate_End:
                GOTO get_next_bcJBAL
            END /* ARBL Loop */
   
        CLOSE bcJBAL
        DEALLOCATE bcJBAL
        SELECT  @opencursorJBAL = 0
   
   		/*Check Misc Distributions*/
        EXEC @rcode = bspJBAR_ValMiscDist @jbco, @batchmth, @batchid, @seq, @errmsg OUTPUT
        IF @rcode <> 0 
            BEGIN
                SELECT  @errmsg = @errmsg, @rcode = 1
                GOTO get_next_bcJBAR
            END
   
        GOTO get_next_bcJBAR
    END /* JBAR LOOP*/
   
CLOSE bcJBAR
DEALLOCATE bcJBAR
SELECT  @opencursorJBAR = 0
   
/************************************************************************************
* Post release retainage records 	- When Retainage or RetgRel is modified.		*
*								  	- When Bills are being Deleted.					*
*																					*
* Release Retg will run for a Closed Mth bill but form prevents user from changing	*
* RelRetg values and therefore though the 'R', 'R' records get dropped and readded	*
* the net change relative to GL is 0.00.  No harm done.								*
************************************************************************************/
IF (EXISTS ( SELECT 1
             FROM   bJBAL WITH (NOLOCK)
             WHERE  Co = @jbco AND Mth = @batchmth AND BatchId = @batchid AND ARLine < 10000 AND (ISNULL(Retainage, 0) <> ISNULL(oldRetainage, 0) OR ISNULL(RetgTax, 0) <> ISNULL(oldRetgTax, 0) OR ISNULL(RetgRel, 0) <> ISNULL(oldRetgRel, 0) OR ISNULL(RetgTaxRel, 0) <> ISNULL(oldRetgTaxRel, 0)
                                                                                                 ) )) OR (@batchtranstype = 'D') 
    BEGIN
        EXEC @rcode = bspJBARReleaseVal @jbco, @batchmth, @batchid, @errmsg OUTPUT
    END
   
/**************************************************************************/

-- Has never been implemented in this procedure for some reason? 09/10/08 TJL
-- Make sure debits and credits balance
--select @AR_glco = GLCo
--from bJBGL with (nolock)
--where JBCo = @jbco and Mth = @batchmth and BatchId = @batchid
--group by GLCo
--having isnull(sum(Amount),0) <> 0
--if @@rowcount <> 0
--	begin
--	select @errortext =  'GL Company ' + isnull(convert(varchar(3), @AR_glco),'') + ' entries dont balance!'
--  	exec @rcode = bspHQBEInsert @jbco, @batchmth, @batchid, @errortext, @errmsg output
--  	end

bspexit:
/* check HQ Batch Errors and update HQ Batch Control status */
SELECT  @status = 3	/* valid - ok to post */
IF EXISTS ( SELECT  1
            FROM    bHQBE WITH (NOLOCK)
            WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid ) 
    BEGIN
        SELECT  @status = 2	/* validation errors */
    END
   
UPDATE  bHQBC
SET     Status = @status
WHERE   Co = @jbco AND Mth = @batchmth AND BatchId = @batchid
IF @@rowcount <> 1 
    BEGIN
        SELECT  @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
        GOTO terminate
    END
   
terminate:
IF @opencursorJBAR = 1 
    BEGIN
        CLOSE bcJBAR
        DEALLOCATE bcJBAR
        SELECT @opencursorJBAR = 0
    END
IF @opencursorJBAL = 1 
    BEGIN
        CLOSE bcJBAL
        DEALLOCATE bcJBAL
        SELECT @opencursorJBAL = 0
    END
   
IF @rcode <> 0 
    SELECT  @errmsg = @errmsg		--+ char(13) + char(10) + '[bspJBARProgVal]'
RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[bspJBARProgVal] TO [public]
GO
