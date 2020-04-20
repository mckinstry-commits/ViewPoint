SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspARBHPost]
/***********************************************************
* CREATED BY  : CJW 5/28/97
* MODIFIED By : bc 02/28/00 added notes to ARTL
* MODIFIED BY:  JC 02/02/00 --Added Mth to the Where clause in the join statement.
*   	GR 03/07/00 -- Added MIsc Distribution table(ARBM) deletion
*  		JRE 7/25/00 -- added @@error after inserts and deletes
*     	bc 09/19/00 - added file attachment code
*     	bc 09/20/00 - fixed the Update to ARMD where TransType = 'C' and 'D'
*		GG 11/28/00 - fixed error if unable to get next AR Trans#
*	  	TJL  03/12/01 -  added ReasonCode
*     	MV 06/25/01 - Issue 12769 BatchUserMemoUpdate
*     	TV/RM 02/22/02 - Attachment fix
*		TJL 3/25/02 - Issue #16747, Insert value in FinanceChg column
*     	CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*		GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*		TJL 04/09/02 - Rewrote and reorganized for improved performance.
*		TJL 04/26/02 - Issue #16669, Correct Misc Dist Post on 'C'hange code.
*		TJL 08/08/03 - Issue #22087, Performance mods, add NoLocks
*		TJL 02/17/04 - #18616, Reindex attachments after posting A or C records.
*		TJL 03/29/04 - Issue #24140, Update ARBH ud fields to ARTH
*		TJL 06/02/08 - Issue #128286, ARInvoiceEntry International Sales Tax
*		GP 10/30/08	- Issue 130576, changed text datatype to varchar(max)
*		TJL 05/14/09 - Issue #133432, Latest Attachment Delete process.
*		TJL 06/30/09 - Issue #121350, Create original ARTL lines for an Adjustment during post rather than during validation
*       ECV 12/13/10 - Issue 131640, Add update of SM system
*       ECV 12/13/10 - Modified for move of SMInvoiceID from vSMWorkCompleted to vSMWorkCompletedDetail
*
* USAGE:
* Posts a validated batch of ARBH and ARBL entries
* deletes successfully posted bARBH and ARBL rows
*
* clears  bHQCC when complete
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   PostingDate Posting date to write out if successful
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
   
(@co bCompany, @mth bMonth, @batchid bBatchID,
	@dateposted bDate = null,  @source char(10), @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor tinyint, @status tinyint, @errorstart varchar(50), 
	@inusebatchid bBatchID, @Notes varchar(256),@opencursorARBL tinyint,
	@SMCo bCompany, @SMBatchID int

/*Header declares*/
declare @seq int, @transtype char(1), @artrans bTrans, @artranstype char(1),
	@appliedmth bMonth, @appliedtrans bTrans, @guid uniqueIdentifier

--Variables used for SM
DECLARE @SMWorkCompletedID bigint, @SMAgreementBillingScheduleID bigint, @GLEntryID bigint,
	@SMGLEntryID bigint, @SMGLDetailTransactionID bigint, @Journal bJrnl, @ARLine smallint

DECLARE @GLEntriesToDelete TABLE (RevenueGLEntryID bigint NULL, RevenueGLDetailTransactionEntryID bigint NULL)

--Table used by SM to capture the ARBL records that will be processed and update SM lines
DECLARE @WorkCompletedARBL TABLE (SMWorkCompletedID bigint, SMInvoiceID bigint, IsReversing bit, ARCo bCompany NULL, Mth bMonth NULL, ARTrans bTrans NULL, ARLine smallint NULL, ApplyMth bMonth NULL, ApplyTrans bTrans NULL, ApplyLine smallint NULL, IsReversingEntry bit)

select @rcode = 0

/* set open cursor flags to false */
select @opencursor = 0, @opencursorARBL = 0

/* get GL interface info from ARCO */
if not exists(select 1 from bARCO with (nolock) where ARCo = @co)
	begin
	select @errmsg = 'Missing AR Company!', @rcode = 1
	goto bspexit
	end
   
/* check for date posted */
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

/* check source */
if @source not in ('AR Invoice','AR FinChg','SM Invoice')
	begin
	select @errmsg = 'Invalid source!', @rcode = 1
	goto bspexit
	end
   
/* validate HQ Batch */

exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'ARBH', @errmsg output, @status output
if @rcode <> 0 goto bspexit

if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
	begin
	select @errmsg = 'Invalid Batch status:  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
	goto bspexit
	end
   
/* set HQ Batch status to 4 (posting in progress) */
update bHQBC
set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end

SELECT @Journal = InvoiceJrnl
FROM dbo.ARCO
WHERE ARCo = @co
   
/* declare cursor on AR Header Batch for validation */
declare bcARBH cursor local fast_forward for 
select BatchSeq, TransType, ARTrans, Source, ARTransType,
	AppliedMth, AppliedTrans, UniqueAttchID
from bARBH with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
   
/* open cursor */
open bcARBH

/* set open cursor flag to true */
select @opencursor = 1

/* loop through all rows in ARBH and update their info.*/
ar_posting_loop:

/* get row from ARBH */
fetch next
from bcARBH into @seq, @transtype, @artrans, @source, @artranstype, 
	@appliedmth, @appliedtrans, @guid

if @@fetch_status <> 0 goto ar_posting_end
   
select @errorstart = 'Seq#' + convert(varchar(6),@seq)

begin transaction
/* Create 0.00 value original lines for those Adjustment transactions lines being added for the first time.
   The original line needs to be added to the original invoice so the Adjustment line can be applied against it. */
if @artranstype = 'A'
	begin
	if exists(select 1 from bARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
				and ApplyLine is null)
		begin
		/* We have Adjustment Lines that do not yet exist on the original invoice.  Insert a 0.00 original line. */
		insert into bARTL(ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
			Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered, TaxDisc, DiscTaken, FinanceChg, ApplyMth, ApplyTrans,
			ApplyLine, JCCo, Contract, Item, ContractUnits, Job, PhaseGroup, Phase, CostType, UM, JobUnits,
			JobHours, ActDate, INCo, Loc, MatlGroup, Material, UnitPrice, ECM, MatlUnits, SMWorkCompletedID, SMAgreementBillingScheduleID)
		select Co, ApplyMth, ApplyTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
			0,0,0,0,0,0,0,0,0,0, ApplyMth, ApplyTrans, ARLine, JCCo, Contract, Item, 0, Job, PhaseGroup, Phase, CostType, UM, 0,
			0, ActDate, INCo, Loc, MatlGroup, Material, 0, ECM, 0, SMWorkCompletedID, SMAgreementBillingScheduleID
		from bARBL with (nolock)
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ApplyLine is null

		if @@rowcount = 0 or @@error<>0 goto ar_posting_error
		
		/* Now need to update batch lines with ApplyLine information.  From this point forward everything is in 
		   place and the rest of the Post will function normally. */
		update bARBL
		set ApplyLine = ARLine
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ApplyLine is null

		if @@rowcount = 0 or @@error<>0 goto ar_posting_error
  		end
	end
	
if @transtype = 'A'	/* adding new AR */
  	begin
  	exec @artrans = bspHQTCNextTrans bARTH, @co, @mth, @errmsg output
  	if @artrans = 0 goto ar_posting_error

  	/* insert AR Header */
  	insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, CustRef, RecType, 
		JCCo, Contract, Invoice, Source, TransDate, DueDate, DiscDate,
			Description, PayTerms, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId,
			InUseBatchID, ReasonCode, Notes, UniqueAttchID)
  	select Co, Mth, @artrans, ARTransType, CustGroup, Customer, CustRef, RecType, 
		JCCo, Contract, Invoice, Source, TransDate, DueDate, DiscDate,
		Description, PayTerms,
		case @artranstype when 'I' then @mth else AppliedMth end,
		case @artranstype when 'I' then @artrans else AppliedTrans end,
		'N', 'Y', @batchid, @inusebatchid, ReasonCode, Notes, UniqueAttchID
   	from bARBH with (nolock)
   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
	if @@rowcount = 0 goto ar_posting_error
   
   
	/*we need to update transaction number to other batches that need it*/
	/*GL*/
	update bARBA 
   	set ARTrans = @artrans
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
	/*Misc Dist*/
	update bARBM 
   	set ARTrans = @artrans
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
	/*Job*/
	update bARBI 
   	set ARTrans = @artrans
	where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
	/*BatchUserMemoUpdate*/
	update bARBH 
   	set ARTrans = @artrans
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
  	/*now insert all the items from ARBL for this ARTrans */
  	insert into ARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
   		TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered, TaxDisc,
		FinanceChg, JCCo, Contract, Item, ContractUnits, ApplyMth, ApplyTrans, ApplyLine,
		INCo, Loc, UM, MatlGroup, Material, UnitPrice, ECM, MatlUnits, Notes, SMWorkCompletedID, SMAgreementBillingScheduleID)
  	select Co, Mth, @artrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
     	TaxGroup, TaxCode,
	 	case when @artranstype in ('W','C') and Amount <> 0 then isnull(-1 * Amount,0) else isnull(Amount,0) end,
     	case when @artranstype in ('W','C') and TaxBasis <> 0 then isnull(-1 * TaxBasis,0)	else isnull(TaxBasis,0) end,
     	case when @artranstype in ('W','C') and TaxAmount <> 0 then isnull(-1 * TaxAmount,0) else isnull(TaxAmount,0) end,
		case when @artranstype in ('W','C') and RetgTax <> 0 then isnull(-1 * RetgTax,0) else isnull(RetgTax,0) end,
     	isnull(RetgPct,0),
     	case when @artranstype in ('W','C') and Retainage <> 0 then isnull(-1 * Retainage,0) else isnull(Retainage,0) end,
     	case when @artranstype in ('W','C') and DiscOffered <> 0 then isnull(-1 * DiscOffered,0) else isnull(DiscOffered,0) end,
     	case when @artranstype in ('W','C') and TaxDisc <> 0 then isnull(-1 * TaxDisc,0) else isnull(TaxDisc,0) end,
  		case when @artranstype in ('W','C') and isnull(FinanceChg, 0) <> 0 then isnull(-1 * FinanceChg,0) else isnull(FinanceChg, 0) end,
     	JCCo, Contract, Item,
     	case when @artranstype in ('W','C') and ContractUnits <> 0 then isnull(-1 * ContractUnits,0) else isnull(ContractUnits,0) end,
	 	/*If applied to transaction, then set to applied to month; else set to invoice month*/
     	case @artranstype when 'I' then @mth else @appliedmth end,
     	/*If applied to transaction, then set transaction to applied to transaction; else set to invoice transaction*/
     	case @artranstype when 'I' then @artrans else @appliedtrans end,
     	/*If applied to transaction, then set line to applied to line; else set to invoiced line*/
	 	case @artranstype when 'I' then ARLine else ApplyLine end,
     	INCo, Loc, UM, MatlGroup, Material, UnitPrice, ECM,
     	case when @artranstype in ('W','C') and MatlUnits <> 0 then isnull(-1 * MatlUnits,0) else isnull(MatlUnits,0) end,
		Notes, SMWorkCompletedID, SMAgreementBillingScheduleID
  	from bARBL with (nolock)
  	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
	if @@rowcount = 0 or @@error<>0 goto ar_posting_error

	/*BatchUserMemoUpdate*/
	update bARBL
	set ARTrans = @artrans
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and isnull(ARTrans,0) <> @artrans

	/* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
	if exists (select top 1 1 from bARBL with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
		begin
		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AR InvoiceEntryDetail', @errmsg output
		if @rcode <> 0 goto ar_posting_error
		end

	BEGIN TRY
		IF @artranstype = 'I'
		BEGIN
			--If the invoice batch record was created from SM then we need the SM Invoice to point
			--to the newly created invoice. We only update if the SM invoice wasn't already pointing to an AR invoice
			--because all changes to the invoice after that should be applied changes, NOT change records.
			UPDATE vSMInvoice
			SET Invoiced = 1, ARPostedMth = @mth, ARTrans = @artrans
			FROM dbo.vSMInvoiceARBH
				INNER JOIN dbo.vSMInvoice ON vSMInvoiceARBH.SMInvoiceID = vSMInvoice.SMInvoiceID
			WHERE vSMInvoiceARBH.Co = @co AND vSMInvoiceARBH.Mth = @mth AND vSMInvoiceARBH.BatchId = @batchid AND vSMInvoiceARBH.BatchSeq = @seq
		END
	
		DELETE @WorkCompletedARBL
		
		INSERT @WorkCompletedARBL
		SELECT vSMWorkCompletedARBL.SMWorkCompletedID, vSMWorkCompletedARBL.SMInvoiceID, vSMWorkCompletedARBL.IsReversing, bARTL.ARCo, bARTL.Mth, bARTL.ARTrans, bARTL.ARLine, bARTL.ApplyMth, bARTL.ApplyTrans, bARTL.ApplyLine, vSMWorkCompletedARBL.IsReversing
		FROM dbo.vSMWorkCompletedARBL
			LEFT JOIN dbo.bARBL ON vSMWorkCompletedARBL.Co = bARBL.Co AND vSMWorkCompletedARBL.Mth = bARBL.Mth AND vSMWorkCompletedARBL.BatchId = bARBL.BatchId AND vSMWorkCompletedARBL.BatchSeq = bARBL.BatchSeq AND vSMWorkCompletedARBL.ARLine = bARBL.ARLine
			LEFT JOIN dbo.bARTL ON bARBL.Co = bARTL.ARCo AND bARBL.Mth = bARTL.Mth AND bARBL.Mth = bARTL.Mth AND bARBL.ARTrans = bARTL.ARTrans AND bARBL.ARLine = bARTL.ARLine
		WHERE vSMWorkCompletedARBL.Co = @co AND vSMWorkCompletedARBL.Mth = @mth AND vSMWorkCompletedARBL.BatchId = @batchid AND vSMWorkCompletedARBL.BatchSeq = @seq 

		IF @@rowcount > 0
		BEGIN
			--Insert the records from the batch and the original if an adjustment was made to a line that doesn't exist.
			INSERT dbo.vSMWorkCompletedARTL (SMWorkCompletedID, SMInvoiceID, ARCo, Mth, ARTrans, ARLine, ApplyMth, ApplyTrans, ApplyLine)
			SELECT WorkCompletedARTL.SMWorkCompletedID, WorkCompletedARTL.SMInvoiceID, WorkCompletedARTL.ARCo, WorkCompletedARTL.Mth, WorkCompletedARTL.ARTrans, WorkCompletedARTL.ARLine, WorkCompletedARTL.ApplyMth, WorkCompletedARTL.ApplyTrans, WorkCompletedARTL.ApplyLine
			FROM @WorkCompletedARBL WorkCompletedARBL
				CROSS APPLY (
					SELECT SMWorkCompletedID, SMInvoiceID, ARCo, Mth, ARTrans, ARLine, ApplyMth, ApplyTrans, ApplyLine
					UNION
					SELECT SMWorkCompletedID, SMInvoiceID, ARCo, ApplyMth, ApplyTrans, ApplyLine, ApplyMth, ApplyTrans, ApplyLine) WorkCompletedARTL
			WHERE WorkCompletedARBL.ARLine IS NOT NULL AND NOT EXISTS(SELECT 1 FROM vSMWorkCompletedARTL WHERE WorkCompletedARTL.ARCo = ARCo AND WorkCompletedARTL.Mth = Mth AND WorkCompletedARTL.ARTrans = ARTrans AND WorkCompletedARTL.ARLine = ARLine)

			UPDATE vSMWorkCompleted
			SET SMWorkCompletedARTLID = vSMWorkCompletedARTL.SMWorkCompletedARTLID
			FROM @WorkCompletedARBL WorkCompletedARBL
				INNER JOIN dbo.vSMWorkCompleted ON WorkCompletedARBL.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				LEFT JOIN dbo.vSMWorkCompletedARTL ON WorkCompletedARBL.ARCo = vSMWorkCompletedARTL.ARCo AND WorkCompletedARBL.Mth = vSMWorkCompletedARTL.Mth AND WorkCompletedARBL.ARTrans = vSMWorkCompletedARTL.ARTrans AND WorkCompletedARBL.ARLine = vSMWorkCompletedARTL.ARLine
			WHERE IsReversingEntry = 0

			--Clear the gl entries to delete to clear entries from the previous loop
			DELETE @GLEntriesToDelete

			--Update the work completed gl to no longer point to a set of gl entries and capture the old gl entries to get rid of them
			UPDATE dbo.vSMWorkCompletedGL
			SET RevenueGLEntryID = NULL, RevenueGLDetailTransactionEntryID = NULL, RevenueGLDetailTransactionID = NULL
				OUTPUT DELETED.RevenueGLEntryID, DELETED.RevenueGLDetailTransactionEntryID
					INTO @GLEntriesToDelete
			FROM @WorkCompletedARBL WorkCompletedARBL
				INNER JOIN dbo.vSMWorkCompletedGL ON WorkCompletedARBL.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
			WHERE WorkCompletedARBL.IsReversing = 0

			DELETE vSMGLEntry
			FROM @GLEntriesToDelete GLEntriesToDelete
				INNER JOIN dbo.vSMGLEntry ON GLEntriesToDelete.RevenueGLEntryID = vSMGLEntry.SMGLEntryID OR GLEntriesToDelete.RevenueGLDetailTransactionEntryID = vSMGLEntry.SMGLEntryID

			--We didn't have the trans during validation so we update the description with the trans if needed
			UPDATE vGLEntryTransaction
			SET [Description] = REPLACE([Description], 'Trans #', dbo.vfToString(@artrans))
			FROM dbo.vGLEntryBatch
				INNER JOIN dbo.vGLEntryTransaction ON vGLEntryBatch.GLEntryID = vGLEntryTransaction.GLEntryID	
			WHERE vGLEntryBatch.Co = @co AND vGLEntryBatch.Mth = @mth AND vGLEntryBatch.BatchId = @batchid AND vGLEntryBatch.BatchSeq = @seq 

			WHILE EXISTS(SELECT 1 FROM dbo.vGLEntryBatch WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq)
			BEGIN
				SELECT TOP 1 @ARLine = Line, @GLEntryID = GLEntryID
				FROM dbo.vGLEntryBatch 
				WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq
				
				SELECT @SMWorkCompletedID = SMWorkCompletedID
				FROM dbo.vSMWorkCompletedARBL
				WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq AND ARLine = @ARLine
				
				IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID)
				BEGIN
					INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
					SELECT SMWorkCompletedID, SMCo, CASE [Type] WHEN 3 /* 3 Is the miscellaneous type*/ THEN 1 ELSE 0 END
					FROM vSMWorkCompleted
					WHERE SMWorkCompletedID = @SMWorkCompletedID
				END
				
				--Copy over the gl entry to a sm gl entry
				INSERT vSMGLEntry (SMWorkCompletedID, Journal, TransactionsShouldBalance)
				SELECT @SMWorkCompletedID, @Journal, 0
				FROM dbo.vGLEntry
				WHERE GLEntryID = @GLEntryID
				
				SET @SMGLEntryID = SCOPE_IDENTITY()
				
				--Copy the transactions
				INSERT dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT @SMGLEntryID, 1, GLCo, GLAccount, Amount, ActDate, [Description]
				FROM dbo.vGLEntryTransaction
				WHERE GLEntryID = @GLEntryID
				
				SET @SMGLDetailTransactionID = SCOPE_IDENTITY()
				
				--Update the work completed gl so it can handle transferring wip
				UPDATE dbo.vSMWorkCompletedGL
				SET RevenueGLEntryID = @SMGLEntryID, RevenueGLDetailTransactionEntryID = @SMGLEntryID, RevenueGLDetailTransactionID = @SMGLDetailTransactionID
				WHERE SMWorkCompletedID = @SMWorkCompletedID
				
				--get rid of the gl entries since it was only needed during validation
				DELETE vGLEntry
				FROM dbo.vGLEntryBatch
					INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
				WHERE vGLEntryBatch.Co = @co AND vGLEntryBatch.Mth = @mth AND vGLEntryBatch.BatchId = @batchid AND vGLEntryBatch.BatchSeq = @seq AND vGLEntryBatch.Line = @ARLine
			END

			DELETE dbo.vSMWorkCompletedARBL
			WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq
			
			DELETE dbo.vSMInvoiceARBH
			WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq
		END
		
		UPDATE dbo.vSMDetailTransaction
		SET Posted = 1, HQBatchDistributionID = NULL
		FROM dbo.vHQBatchDistribution
			INNER JOIN vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
		WHERE vHQBatchDistribution.Co = @co AND vHQBatchDistribution.Mth = @mth AND vHQBatchDistribution.BatchId = @batchid
	END TRY
	BEGIN CATCH
		SET @errmsg = ERROR_MESSAGE()
		GOTO ar_posting_error
	END CATCH

	/* now delete all the Items we just added */
	delete bARBL 
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   	
	/*need to update Misc Distributions batch*/
	insert into bARMD(ARCo, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount)
	select Co, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount
	from bARBM with (nolock)
   	where Co = @co and Mth=@mth and BatchId = @batchid and BatchSeq = @seq
   
	/*now delete items just added*/
	delete bARBM 
   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

	end /* End Transtype A */
   
if @transtype = 'C'	/* update existing AR Headers */
	begin
	update bARTH
	set BatchId = b.BatchId, CustGroup = b.CustGroup, Customer = b.Customer, CustRef = b.CustRef, 
		RecType = b.RecType, JCCo = b.JCCo, Contract = b.Contract, Invoice = b.Invoice,
  		Source = b.Source, TransDate = b.TransDate, DueDate = b.DueDate, DiscDate = b.DiscDate,
  		Description = b.Description, PayTerms = b.PayTerms, AppliedMth = b.AppliedMth,
  		AppliedTrans = b.AppliedTrans, ReasonCode = b.ReasonCode, Notes = b.Notes,
 		UniqueAttchID = b.UniqueAttchID
	from bARBH b with (nolock)
	join bARTH h on h.ARCo = b.Co and h.Mth = b.Mth and h.ARTrans = b.ARTrans
	where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq
   
	if @@rowcount = 0 goto ar_posting_error
   
  	/* first insert any new lines to this changed Header.*/
  	/*now insert all the items from ARBL for this AR Trans */
  	insert into ARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, 
		GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct,
		Retainage, DiscOffered, TaxDisc, FinanceChg, JCCo, Contract, Item, 
		ContractUnits, ApplyMth, ApplyTrans, ApplyLine, Job, PhaseGroup, Phase,
		CostType, UM, JobUnits, JobHours, INCo, Loc, MatlGroup, Material, UnitPrice,
		Notes)
  	select Co, Mth, @artrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
     	case when @artranstype in ('W','C') and Amount <> 0 then  isnull(-1 * Amount,0) else isnull(Amount,0) end,
     	case when @artranstype in ('W','C') and TaxBasis <> 0 then  isnull(-1 * TaxBasis,0) else isnull(TaxBasis,0) end,
     	case when @artranstype in ('W','C') and TaxAmount <> 0 then isnull(-1 * TaxAmount,0) else isnull(TaxAmount,0) end,
		case when @artranstype in ('W','C') and RetgTax <> 0 then isnull(-1 * RetgTax,0) else isnull(RetgTax,0) end,
     	isnull(RetgPct,0),
     	case when @artranstype in ('W','C') and Retainage <> 0 then isnull(-1 * Retainage,0) else isnull(Retainage,0) end,
     	case when @artranstype in ('W','C') and DiscOffered <> 0 then isnull(-1 * DiscOffered,0) else isnull(DiscOffered,0) end,
     	case when @artranstype in ('W','C') and TaxDisc <> 0 then isnull(-1 * TaxDisc,0) else isnull(TaxDisc,0) end,
     	case when @artranstype in ('W','C') and isnull(FinanceChg,0) <> 0 then isnull(-1 * FinanceChg,0) else isnull(FinanceChg,0) end,
     	JCCo, Contract, Item,
     	case when @artranstype in ('W','C') and ContractUnits <> 0 then isnull(-1 * ContractUnits,0) else isnull(ContractUnits,0) end,
     	/*If applied to transaction, then set to applied to month; else set to invoice month*/
	 	case @artranstype when 'I' then @mth else @appliedmth end,
     	/*If applied to transaction, then set transaction to applied to transaction; else set to invoice transaction*/
	 	case @artranstype when 'I' then @artrans else @appliedtrans end,
     	/*If applied to transaction, then set line to applied to line; else set to invoiced line*/
	 	case @artranstype when 'I' then ARLine else ApplyLine end,
	 	Job, PhaseGroup, Phase, CostType, UM, JobUnits, JobHours, INCo, Loc, MatlGroup,
	 	Material, UnitPrice, Notes
  	from bARBL with (nolock)
  	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and TransType='A'
   
	/*BatchUserMemoUpdate*/
	update bARBL
	set ARTrans = @artrans
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and isnull(ARTrans,0) <> @artrans

  	/* now update all the items that were changed */
  	update bARTL
  	set RecType=b.RecType, LineType = b.LineType, Description = b.Description, GLCo = b.GLCo,
      	GLAcct = b.GLAcct, TaxGroup = b.TaxGroup, TaxCode = b.TaxCode,
      	Amount = case when @artranstype in ('W','C') and b.Amount <> 0 then isnull(- 1 * b.Amount,0) else isnull(b.Amount,0) end,
      	TaxBasis = case when @artranstype in ('W','C') and b.TaxBasis <> 0 then isnull(-1 * b.TaxBasis,0) else isnull(b.TaxBasis,0) end,
      	TaxAmount = case when @artranstype in ('W','C') and b.TaxAmount <> 0 then isnull(-1 * b.TaxAmount,0) else isnull(b.TaxAmount,0) end,
		RetgTax = case when @artranstype in ('W','C') and b.RetgTax <> 0 then isnull(-1 * b.RetgTax,0) else isnull(b.RetgTax,0) end,
      	RetgPct =isnull(b.RetgPct,0),
      	Retainage = case when @artranstype in ('W','C') and b.Retainage <> 0 then isnull(-1 * b.Retainage,0) else isnull(b.Retainage,0) end,
      	DiscOffered = case when @artranstype in ('W','C') and b.DiscOffered <> 0 then isnull(-1 * b.DiscOffered,0) else isnull(b.DiscOffered,0) end,
      	TaxDisc = case when @artranstype in ('W','C') and b.TaxDisc <> 0 then isnull(-1 * b.TaxDisc,0) else isnull(b.TaxDisc,0) end,
   		FinanceChg = case when @artranstype in ('W','C') and isnull(b.FinanceChg, 0) <> 0 then isnull(-1 * b.FinanceChg,0) else isnull(b.FinanceChg,0) end,
      	JCCo = b.JCCo, Contract = b.Contract, Item = b.Item,
      	ContractUnits = case when @artranstype in ('W','C') and b.ContractUnits <> 0 then isnull(-1 * b.ContractUnits,0) else isnull(b.ContractUnits,0) end,
      	Job = b.Job, Phase = b.Phase, CostType = b.CostType, UM = b.UM, JobUnits = b.JobUnits, JobHours = b.JobHours,
      	INCo = b.INCo, Loc = b.Loc, MatlGroup = b.MatlGroup, Material = b.Material, UnitPrice = b.UnitPrice,
	  	ECM = b.ECM, MatlUnits = b.MatlUnits, Notes = b.Notes
  	from bARBL b with (nolock)
	join bARTL l on l.ARCo=b.Co and l.Mth = b.Mth and l.ARTrans=b.ARTrans and l.ARLine=b.ARLine
  	where b.Co=@co and l.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq  
	and b.TransType='C'
   
	/*Finally delete any items that were marked for deletion of the changed batch*/
	delete bARTL 
   	from bARBL b with (nolock)
   	join bARTL l on l.ARCo=b.Co and l.Mth = b.Mth and l.ARTrans=b.ARTrans and l.ARLine=b.ARLine
	where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq and b.TransType='D'
   
	/* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
	if exists (select top 1 1 from bARBL b with (nolock) where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and
		b.BatchSeq=@seq)
		begin
		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AR InvoiceEntryDetail', @errmsg output
		if @rcode <> 0 goto ar_posting_error
   	    end
   
  	/* need to delete items out of batch that were just added */
  	delete bARBL
  	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq 

  	/*Now we need to take care of changes to the miscellaneous distribution file*/
  	/*First insert all new misc distribution*/
  	insert into bARMD(ARCo, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount)
  	select Co, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount
  	from bARBM with (nolock)
  	where Co = @co and Mth=@mth and BatchId = @batchid and BatchSeq = @seq and TransType = 'A'
   
  	/*Now update all items that were changed*/
  	update bARMD
  	set DistDate = m.DistDate, Description= m.Description, Amount = m.Amount
  	from bARBM m with (nolock)
  	join bARMD d on d.ARCo = m.Co and d.Mth = m.Mth and d.CustGroup = m.CustGroup and
   	d.ARTrans = m.ARTrans and d.MiscDistCode = m.MiscDistCode
  	where m.Co = @co and m.Mth = @mth and m.BatchId = @batchid and m.BatchSeq = @seq and m.TransType = 'C'

  	/*Now delete all rows marked for delete of the changed misc dist batch*/
  	delete bARMD
  	from bARBM m with (nolock)
  	join bARMD d on d.ARCo = m.Co and d.Mth = m.Mth and d.CustGroup = m.CustGroup and
   	d.ARTrans = m.ARTrans and d.MiscDistCode = m.MiscDistCode
  	where m.Co = @co and m.Mth = @mth and m.BatchId = @batchid and m.BatchSeq = @seq and m.TransType = 'D'

  	/*now delete items from the misc dist batch for this Change transaction */
  	delete bARBM
  	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
      	
   	end /*trans type C*/
   
if @transtype = 'D'	/*Delete existing AR Lines */
	begin

	/*first delete all items*/
	delete bARTL where ARCo=@co and Mth = @mth and ARTrans=@artrans

	/* now delete the Header */
	delete bARTH where ARCo=@co and Mth = @mth and ARTrans=@artrans

	/* now delete the Misc Distributions */
	delete bARMD where ARCo=@co and Mth = @mth and ARTrans=@artrans
   
   	/* need to delete items out of batch that were just deleted */
   	delete bARBL
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
   	/*delete items from mist dist batch that were just deleted */
   	delete bARBM where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

	end /* end transtype D*/
   
/* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
if exists (select top 1 1 from bARBH with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq)
	begin
   	If @transtype in ('A','C')
       	begin
		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AR InvoiceEntry', @errmsg output
		if @rcode <> 0 goto ar_posting_error
		end
   	end
   
/* delete current row from ARBH*/
delete from bARBH where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and
	not exists(select 1 from bARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq)

/* commit transaction */
commit transaction

--issue 18616
if @transtype in ('A','C')
	begin
	if @guid is not null
		begin
		exec @rcode = bspHQRefreshIndexes null, null, @guid, null
		end
	end
   
goto ar_posting_loop		-- Get the next bARBH header transaction/Seq and process

/* error occured within transaction - rollback any updates and continue */
ar_posting_error:
	select @rcode = 1
	rollback transaction
	goto bspexit
   
/* no more rows to process */
ar_posting_end:
	if @opencursor=1
  			begin
  			close bcARBH
  			deallocate bcARBH
  			select @opencursor=0
  			end
   
/* make sure batch is empty */
if exists(select top 1 1 from bARBH with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
  	select @errmsg = 'Not all AR header entries were posted - unable to close batch!', @rcode = 1
  	goto bspexit
  	end

if exists(select top 1 1 from bARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
  	begin
  	select @errmsg = 'Not all AR item entries were posted - unable to close batch!', @rcode = 1
  	goto bspexit
  	end

/**** update GL using entries from bARBA for ARTransType='I' *****/
if (select count(*) from bARBA with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and ARTransType='I')>0
  	begin
  	exec @rcode = bspARBH1_PostGL @co, @mth, @batchid, @dateposted, 'Invoice', @source, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end

/**** update GL using entries from bARBA for ARTransType='C' *****/
if (select count(*) from bARBA with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and ARTransType='C')>0
  	begin
  	exec @rcode = bspARBH1_PostGL @co, @mth, @batchid, @dateposted, 'Cr Memo', @source, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end

/**** update GL using entries from bARBA for ARTransType='W' *****/
if (select count(*) from bARBA with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and ARTransType='W')>0
  	begin
  	exec @rcode = bspARBH1_PostGL @co, @mth, @batchid, @dateposted, 'Write Off', @source, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end
   
/**** update GL using entries from bARBA for ARTransType='A' *****/
if (select count(*) from bARBA with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and ARTransType='A')>0
  	begin
  	exec @rcode = bspARBH1_PostGL @co, @mth, @batchid, @dateposted, 'Adjustment', @source, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end
   
/**** update JC using entries from bARBI *****/
if @source in ('AR Receipt','AR Invoice', 'ARFinanceC', 'ARRelease')
BEGIN
	exec @rcode = bspARBH1_PostJCContract @co, @mth, @batchid, @dateposted, @source, @errmsg output
	if @rcode <> 0 goto bspexit
END

/* set interface levels note string */
select @Notes=Notes 
from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
	select @Notes=@Notes +
       'AR Finance Charge Level set at: ' + convert(char(1), a.FCLevel) + char(13) + char(10) +
       'CM Interface Level set at: ' + convert(char(1), a.CMInterface) + char(13) + char(10) +
       'EM Interface Level set at: ' + convert(char(1), a.EMInterface) + char(13) + char(10) +
       'GL Invoice Interface Level set at: ' + convert(char(1), a.GLInvLev) + char(13) + char(10) +
       'GL Misc Rcpt Interface Level set at: ' + convert(char(1), a.GLMiscCashLev) + char(13) + char(10) +
       'GL Receipt Interface Level set at: ' + convert(char(1), a.GLPayLev) + char(13) + char(10) +
       'JC Interface Level set at: ' + convert(char(1), a.JCInterface) + char(13) + char(10)
	from bARCO a with (nolock)
	where ARCo=@co
	
EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Notes = @Notes, @msg = @errmsg OUTPUT

bspexit:
	if @opencursor = 1
   		begin
   		close bcARBH
   		deallocate bcARBH
   		end
   
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBHPost]'
return @rcode










GO
GRANT EXECUTE ON  [dbo].[bspARBHPost] TO [public]
GO
