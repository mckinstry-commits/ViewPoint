SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspARBHPost_Cash]
/***********************************************************
* CREATED BY  : JRE 8/28/97
* MODIFIED By : bc 8/27/98
*		JM 9/24/98 - Issue #2943, Added update of ARCM.SortName to GL update statement on bARBA so
*					it will be available to bspARBH1_PostGL for insertion into GLDT.
*		JM 9/29/98 - Changed update statements at	approxlines 177-201 to
*					'isnull(ARTrans,0)<>@ARTrans'.
*		JM 11/20/98 - Added mult by @NoNegZero set to 1 for all values selected from a table
*			 		as minus the col value, including isnulls. For example, '-Retainage'
*			 		becomes '-Retainage*@NoNegZero' and 'isnull(-Retainage,0)' becomes
*					'isnull(-Retainage,0)*@NoNegZero'. This is to prevent negative zeros in database,
* 			 		per various Issues (in this case #2963) and per MS KB Article Q189390.
*			 		This effects insert and update statements against bARTL.
*		JM 2/4/99 - Added condition to where clause for insert into bARTL to eliminate lines
*					with zero in all of the following from bARBL: Amount, TaxAmount, Retainage,
*					DiscOffered, DiscTaken.
*		JM 4/1/99 - Changed 'and' to 'or' in inclusion statement in where clause at
*					approx line 305.
*		JM 6/21/99 - Issue #4374, Added update of CMDeposit to bARTH, approx line 376.
*		bc 6/30/99 - @NoNegZero really doesn't work when multiplying by one but it does
*					work if you subtract by zero
*    	GR 2/29/00 - Issue 5284 - this issue has been modified after discussion with carol,
*                	decided to delete misc dist on deletion of a cash receipt. ARTH trigger
*              		checks to see whether misc dist are marked for deletions, if not marked then
*               	rejects deletion
*    	GG 4/26/00 - removed references to MSCo and MSTrans
*   	GR 6/15/00 - added update of checkdate on update of ARTH
*   	bc 09/19/00 - added file attachment code
*    	bc 12/05/00 issue #11508
*  		MV 06/22/01 - Issue 12769 BatchUserMemoUpdate
*		TJL 08/07/01 - Issue 11672 MiscCashReceipts EM Enhancement
*     	bc 10/11/01 - update ARTH.CMCo, ARTH.CMAcct on a 'C'hange transaction
*    	TV/RM 02/22/02 Attachment Fix
*		TJL 04/01/02 - Issue #16734,  Post FinanceChg value in new FinanceChg column.
*						Restructured code for better performance.
*       CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*		GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*		TJL 04/26/02 - Issue #16669, Correct Misc Dist Post on 'C'hange code.
*		TJL 07/31/02 - Issue #11219, Add 'Apply TaxDisc' column for user input.
*		TJL 08/08/03 - Issue #22087, Performance mods, Add noLocks
*		TJL 12/30/03 - Issue #23386, Update ARTH.CheckNo when added back and Changed
*		TJL 01/14/04 - Issue #22979, On Change, correct ARBI (JCID) distribution. Insert correct ARTrans
*		TJL 02/17/04 - #18616, Reindex attachments after posting A or C records.
*		TJL 03/31/05 - 6x Issue #27207, Change Input variables to LowerCase, @errmsg from 60 to 255 char
*						and change 7 occurances of @source (before LowerCase change) to @msource
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*		GP 10/30/08	- Issue 130576, changed text datatype to varchar(max)
*		TJL 05/14/09 - Issue #133432, Latest Attachment Delete process.
*		TJL 08/24/09 - Issue #135045, ARTrans value not being updated to distribution tables when transaction added back for change.
*
* USAGE:
* 	Posts a validated batch of Cash Receipts ARBH and ARBL entries
* 	and deletes successfully posted bARBH and ARBL rows
*
* 	clears  bHQCC when complete
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
   
(@co bCompany = null, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
	@source bSource, @errmsg varchar(255) output)

as

set nocount on

/* 04/01/02: If you are accustomed to seeing alot of variables here, the list has been
  greatly reduced by using a 'select' statement from bARBH for the header insert rather
  than from variables */

/* Declare working variables */
declare  @BatchSeq int, @errorstart varchar(50), @errortext varchar(100),
	@inusebatchid bBatchID, @keyfield varchar(128), @lastseq int, @NoNegZero bDollar,
 	@rcode int, @SortName bSortName, @msource varchar(255), @status tinyint,
	@updatekeyfield varchar(128), @Notes varchar(256)

/* Declare necessary Header variables */
declare @TransType char(1), @CustGroup bGroup,  @Customer bCustomer, @ARTrans bTrans,
	@ARTransType char(1), @guid uniqueidentifier
   
select @rcode = 0, @lastseq=0, @NoNegZero = 0
   
if not exists (select 1 from ARCO with (nolock) where ARCo=@co)
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
   
/* validate source */
if @source<>'AR Receipt'
	begin
	select @errmsg = @source + ' is invalid', @rcode = 1
	goto bspexit
	end

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'ARBH', @errmsg output, @status output
if @rcode <> 0 goto bspexit
   
if @status <> 3 and @status <> 4 -- valid - OK to post, or posting in progress
   	begin
   	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
   	goto bspexit
   	end
   
/* check for a payment batch */
if exists (select top 1 1 from bARBH with (nolock) 
  	where Co=@co and Mth = @mth and BatchId = @batchid and ARTransType not in ('P','M'))
  	begin
  	select @errmsg = 'Unable to continue, non-payment transactions exist in batch', @rcode = 1
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
   
/***************************************/
/* AR Header Batch loop for validation */
/***************************************/
select @BatchSeq=Min(BatchSeq)
from bARBH with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid
   
while @BatchSeq is not null
   	BEGIN	/* Begin batch seq loop */
   	/* read batch header */
   	select  @TransType = TransType, @ARTrans = ARTrans, @source = Source,
		@ARTransType = ARTransType, @CustGroup = CustGroup, @Customer = Customer,
		@guid = UniqueAttchID
   	from bARBH with (nolock)
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq
   
   	--read sortname from bARCM
   	select @SortName = SortName
   	from bARCM with (nolock)
   	where CustGroup=@CustGroup and Customer=@Customer
   
   	select @errorstart = 'Seq#' + convert(varchar(6),@BatchSeq)
   
   	if (@BatchSeq=@lastseq)
		begin
		select @errmsg = 'Duplicate Seq, error with cursor!', @rcode=1
		goto bspexit
		end

   	select @lastseq=@BatchSeq
   
   	begin transaction
   
   	if @TransType = 'A'	/* adding new AR */
		Begin	/* Begin Add Loop */
		-- get next ARTrans Number
      	if isnull(@ARTrans,0)=0
     		begin
         	exec @ARTrans = bspHQTCNextTrans bARTH, @co, @mth, @errmsg output
  	 		if @ARTrans = 0
  	       		begin
  	       		select @errortext = 'Unable to retreive AR Transaction number!'
  	       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	       		if @rcode <> 0 goto bspexit
  	       		end
   
			update bARBH
   			set ARTrans = @ARTrans
       		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq
   
  	     	if @@rowcount = 0
  	       		begin
  	       		select @errortext = 'Unable to update AR Transaction number in ARBH'
  	       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	       		if @rcode <> 0 goto bspexit
  	       		end
         	end
   
		/* need to update transaction number to other batches that need it*/
		--GL
		update bARBA
		set ARTrans = @ARTrans, SortName = @SortName
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		--Misc Dist
		update bARBM
		set ARTrans = @ARTrans
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Contract
		update bARBI
		set ARTrans = @ARTrans
		where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Jobs
		update bARBJ
		set ARTrans = @ARTrans
		where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Equipment
		update bARBE
		set ARTrans = @ARTrans
		where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Lines
		update bARBL
		set ARTrans = @ARTrans
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- insert AR Header
		insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer,
     		CustRef, RecType, JCCo, Contract, CheckNo, Source, CheckDate, AppliedMth,
      		AppliedTrans, CMCo, CMAcct, CMDeposit, CreditAmt, TransDate, DueDate, DiscDate,
      		Description, PayTerms, PurgeFlag, EditTrans, BatchId, InUseBatchID, UniqueAttchID,
			Notes)
		select Co, Mth, @ARTrans, ARTransType, CustGroup, Customer, CustRef, RecType,
			JCCo, Contract, CheckNo, Source, CheckDate, AppliedMth, AppliedTrans,
			CMCo, CMAcct, CMDeposit, CreditAmt, TransDate, DueDate, DiscDate,
			Description, PayTerms, 'N', 'Y', @batchid, @inusebatchid, UniqueAttchID,
			Notes
		from bARBH with (nolock)
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq
   
   		if @@rowcount = 0 goto ar_posting_error
   
		-- now insert all the items from ARBL for this ARTrans
		insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
			TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered, 
			TaxDisc, DiscTaken, FinanceChg, JCCo, Contract, Item, ContractUnits, Job, PhaseGroup, 
			Phase, CostType, ApplyMth, ApplyTrans, ApplyLine, INCo, Loc, UM, JobUnits, JobHours, ActDate, MatlGroup,
 			Material, UnitPrice, ECM, MatlUnits, CustJob, EMCo, Equipment, EMGroup, CostCode, EMCType, CompType, Component)
		select Co, Mth, @ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
      		TaxGroup, TaxCode, isnull(-Amount,0) - @NoNegZero, -TaxBasis - @NoNegZero, isnull(-TaxAmount,0) - @NoNegZero, 
			isnull(-RetgTax,0) - @NoNegZero, isnull(RetgPct,0), isnull(-Retainage,0) - @NoNegZero,
      		isnull(DiscOffered,0), isnull(-TaxDisc,0) - @NoNegZero, isnull(-DiscTaken,0) - @NoNegZero,
			isnull(-FinanceChg,0) - @NoNegZero, JCCo, Contract, Item, ContractUnits, Job,
       		PhaseGroup, Phase, CostType,
      		/*If On Account or Misc the @Applied Mth is null*/
  			isnull(ApplyMth, @mth),
  			/*If On Account or Misc the @AppliedTrans is null*/
  			isnull(ApplyTrans,@ARTrans),
  			/*If On Account or Misc the @ApplyLine is null*/
			isnull(ApplyLine,ARLine),
  			INCo, Loc, UM, -JobUnits - @NoNegZero, -JobHours - @NoNegZero, ActDate, MatlGroup, Material, UnitPrice, ECM,
  			MatlUnits, CustJob, EMCo, Equipment, EMGroup, CostCode, EMCType, CompType, Component
		from bARBL with (nolock)
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq and
			(isnull(Amount,0) - @NoNegZero <> 0 or isnull(TaxAmount,0) - @NoNegZero <> 0 or isnull(Retainage,0) - @NoNegZero <> 0 or
			isnull(DiscOffered,0) <> 0 or isnull(DiscTaken,0) - @NoNegZero <> 0 or isnull(FinanceChg,0) - @NoNegZero <> 0 or
			isnull(TaxDisc,0) - @NoNegZero <> 0)

		if @@rowcount = 0 goto ar_posting_error
   
		/* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
		if exists (select top 1 1 from bARBL with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq)
			begin
			if @ARTransType='M'
   				begin
				select @msource = 'AR MiscRecDetail'
				exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @BatchSeq, @msource, @errmsg output
				if @rcode <> 0 goto ar_posting_error
				end
			end
   
		/* now delete all the lines we just added */
		delete bARBL
   		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq
   
		/*need to update Misc Distributions batch*/
		insert into bARMD(ARCo, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount)
		select Co, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount
		from bARBM with (nolock)
		where Co = @co and Mth=@mth and BatchId = @batchid and BatchSeq = @BatchSeq
   
   		/*now delete items just added*/
   		delete bARBM 
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq
   
		End /* End Transtype A */
   
	if @TransType = 'C'	/* update existing AR Headers */
		Begin	/* Begin TranType C Loop */
		update bARTH
   		set CustGroup = b.CustGroup, Customer = b.Customer, CustRef = b.CustRef, RecType = b.RecType,
			JCCo = b.JCCo, Contract = b.Contract, CheckNo = b.CheckNo, CreditAmt = b.CreditAmt, Source = b.Source,
			TransDate = b.TransDate, CheckDate = b.CheckDate, DueDate = b.DueDate, DiscDate = b.DiscDate,
			Description = b.Description, PayTerms = b.PayTerms, AppliedMth = b.AppliedMth,
			AppliedTrans = b.AppliedTrans, CMCo = b.CMCo, CMAcct = b.CMAcct, CMDeposit = b.CMDeposit,
			UniqueAttchID = b.UniqueAttchID, Notes = b.Notes, BatchId = b.BatchId
   		from bARBH b with (nolock)
   		join bARTH h with (nolock) on h.ARCo = b.Co and h.Mth = b.Mth and h.ARTrans = b.ARTrans
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@BatchSeq
   
		if @@rowcount = 0 goto ar_posting_error
   
		/* First insert any new lines to this changed Header.  This can occur when the payment
		distribution is modified to include other invoices that are different than those 
		originally distributed against. */
		insert into ARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
    		TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered, TaxDisc,
	 		DiscTaken, FinanceChg, JCCo, Contract, Item, ContractUnits,
			ApplyMth, ApplyTrans, ApplyLine, Job, PhaseGroup, Phase, CostType, UM, JobUnits, JobHours,
			ActDate, INCo, Loc, MatlGroup, Material, UnitPrice, MatlUnits, CustJob,
			EMCo, Equipment, EMGroup, CostCode, EMCType, CompType, Component)
		select Co, @mth, @ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
  			TaxGroup, TaxCode, isnull(-Amount,0) - @NoNegZero, -TaxBasis - @NoNegZero, isnull(-TaxAmount,0) - @NoNegZero,
			isnull(-RetgTax,0) - @NoNegZero, isnull(RetgPct,0), isnull(-Retainage,0) - @NoNegZero,
  			isnull(DiscOffered,0), isnull(-TaxDisc,0) - @NoNegZero,
  			isnull(-DiscTaken,0) - @NoNegZero, isnull(-FinanceChg,0) - @NoNegZero, JCCo, Contract, Item, ContractUnits,
  			/*If On Account or Misc the @Applied Mth is null*/
			isnull(ApplyMth, @mth),
  			/*If On Account or Misc the @AppliedTrans is null*/
  			isnull(ApplyTrans,@ARTrans),
  			/*If On Account or Misc the @ApplyLine is null*/
 			isnull(ApplyLine,ARLine),
			Job, PhaseGroup, Phase, CostType, UM, -JobUnits - @NoNegZero, -JobHours - @NoNegZero,
			ActDate, INCo, Loc, MatlGroup, Material, UnitPrice, MatlUnits, CustJob,
			EMCo, Equipment, EMGroup, CostCode, EMCType, CompType, Component
		from bARBL with (nolock)
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq and TransType='A' and
			(isnull(Amount,0) - @NoNegZero <> 0 or isnull(TaxAmount,0) - @NoNegZero <> 0 or isnull(Retainage,0) - @NoNegZero <> 0 or
			isnull(DiscOffered,0) <> 0 or isnull(DiscTaken,0) - @NoNegZero <> 0 or isnull(FinanceChg,0) - @NoNegZero <> 0 or
			isnull(TaxDisc,0) - @NoNegZero <> 0)
   
		/* When a Cash Receipt Transaction or Misc Receipt Transaction gets added back into a batch for change, it is possible
		   that new ARBL Lines get created and won't contain the ARTrans value from the transaction being added back.  This occurs
				In ARCashReceipts:  when user redistributes the cash payment to a different invoice than the one originally posted to.
				In ARMiscReceipts:  when user adds new Misc Receipt lines that did not exist on original posted transaction.
		   In each case, it is necessary to set the ARTrans value into the appropriate distribution tables prior to posting
		   these distributions.  It is the same principle as when creating these transactions originally in 'Add' mode. */
 		--GL
		update bARBA
		set ARTrans = @ARTrans, SortName = @SortName
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		--Misc Dist
		update bARBM
		set ARTrans = @ARTrans
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Contract
		update bARBI
		set ARTrans = @ARTrans
		where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Jobs
		update bARBJ
		set ARTrans = @ARTrans
		where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Equipment
		update bARBE
		set ARTrans = @ARTrans
		where ARCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
   
		-- Lines
		update bARBL
		set ARTrans = @ARTrans
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq and isnull(ARTrans,0) <> @ARTrans
  
		/* Now update all the items that were changed on the original Lines. */
		update bARTL
		set RecType=b.RecType, LineType = b.LineType, Description = b.Description, GLCo = b.GLCo,
			GLAcct = b.GLAcct, TaxGroup = b.TaxGroup, TaxCode = b.TaxCode, Amount = -b.Amount - @NoNegZero,
   			TaxBasis = -b.TaxBasis - @NoNegZero, TaxAmount = -b.TaxAmount - @NoNegZero, 
			RetgTax = -b.RetgTax - @NoNegZero, RetgPct = b.RetgPct,  
   			Retainage = -b.Retainage - @NoNegZero, DiscOffered = b.DiscOffered, TaxDisc = -b.TaxDisc - @NoNegZero,
			DiscTaken = -b.DiscTaken - @NoNegZero, FinanceChg = -b.FinanceChg - @NoNegZero,
   			JCCo = b.JCCo, Contract = b.Contract, Item = b.Item, ContractUnits = b.ContractUnits,
   			Job = b.Job, PhaseGroup = b.PhaseGroup, Phase = b.Phase, CostType = b.CostType, UM = b.UM, 
			JobUnits = -b.JobUnits - @NoNegZero, JobHours = -b.JobHours - @NoNegZero, ActDate = b.ActDate,
			INCo = b.INCo, Loc = b.Loc,	MatlGroup = b.MatlGroup, Material = b.Material, 
			UnitPrice = b.UnitPrice, ECM = b.ECM, MatlUnits = b.MatlUnits, CustJob = b.CustJob,
  			EMCo = b.EMCo, Equipment = b.Equipment, EMGroup = b.EMGroup, CostCode = b.CostCode,
			EMCType = b.EMCType, CompType = b.CompType, Component = b.Component
		from bARBL b with (nolock)
		join bARTL l with (nolock) on l.ARCo=b.Co and l.Mth = b.Mth and l.ARTrans=b.ARTrans and l.ARLine=b.ARLine
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@BatchSeq
		and b.TransType='C'
   
		/* if an existing transaction is pulled into a batch and has its editible dollar values
		   changed from 'not-equal-to-zero' to 'equal-to-zero'
		   (meaning it is being unapplied in full) then delete the existing line in ARTL instead of updating 
		   the record with zero amounts.  This is required because some of the supporting detail
		   forms do not have a 'Delete' action available.  Issue #11508 bc */
		delete bARTL
		from bARTL d
		join bARBL b with (nolock) on d.ARCo=b.Co and d.Mth = b.Mth and d.ARTrans=@ARTrans and d.ARLine=b.ARLine
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@BatchSeq and b.TransType= 'C' and
     		(abs(b.Amount) = 0 and abs(b.TaxAmount) = 0 and abs(b.Retainage) = 0
			and abs(b.DiscTaken) = 0 and abs(b.FinanceChg) = 0 and abs(b.TaxDisc) = 0)
   
  		/* Finally delete any items that were marked for deletion of the changed batch - This
	       follows the above delete for a reason.  Some of the Cash Receipts related forms
	       do not allow 'Action D', on lines, and therefore lines are deleted by placing 
	       0.00 in place of a value.  The above code then will delete this line.  However,
	       At this point, I am still checking if other related forms do allow the 'D' action.
	       The code below will perform a delete if this action is allowed elsewhere.  It does
	       no harm otherwise. */
		delete bARTL 
   		from bARBL b with (nolock)
   		join bARTL l on l.ARCo=b.Co and l.Mth = b.Mth and l.ARTrans=b.ARTrans and l.ARLine=b.ARLine
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@BatchSeq and b.TransType='D'
   
      	/* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
      	if exists (select top 1 1 from bARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
			and BatchSeq = @BatchSeq)
     		begin
       		if @ARTransType='M'
				begin
				select @msource = 'AR MiscRecDetail'
           		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @BatchSeq, @msource, @errmsg output
				if @rcode <> 0 goto ar_posting_error
				end
         	end
   
     	/* need to delete lines out of batch that were just updated or added in change mode */
    	delete bARBL
    	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq

  		/*Now we need to take care of changes to the miscellaneous distribution file*/
  		/*First insert all new misc distribution*/
  		insert into bARMD(ARCo, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount)
  		select Co, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount
  		from bARBM with (nolock)
  		where Co = @co and Mth=@mth and BatchId = @batchid and BatchSeq = @BatchSeq and TransType = 'A'
   
  		/*Now update all items that were changed*/
  		update bARMD
  		set DistDate = m.DistDate, Description= m.Description, Amount = m.Amount
  		from bARBM m with (nolock)
  		join bARMD d with (nolock) on d.ARCo = m.Co and d.Mth = m.Mth and d.CustGroup = m.CustGroup and
   			d.ARTrans = m.ARTrans and d.MiscDistCode = m.MiscDistCode 
  		where m.Co = @co and m.Mth = @mth and m.BatchId = @batchid and m.BatchSeq = @BatchSeq and m.TransType = 'C'
   
  		/*Now delete all rows marked for delete of the changed misc dist batch*/
  		delete bARMD
  		from bARBM m with (nolock)
  		join bARMD d on d.ARCo = m.Co and d.Mth = m.Mth and d.CustGroup = m.CustGroup and
   			d.ARTrans = m.ARTrans and d.MiscDistCode = m.MiscDistCode
  		where m.Co = @co and m.Mth = @mth and m.BatchId = @batchid and m.BatchSeq = @BatchSeq and m.TransType = 'D'
   
  		/*now delete items from the misc dist batch for this Change transaction */
  		delete bARBM
  		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq

    	End /*trans type C*/
   
	if @TransType = 'D'	/*Delete existing AR Lines */
       	begin
  		/*first delete all items*/
  		delete bARTL
     	where ARCo=@co and ARTrans=@ARTrans and Mth = @mth

    	/* now delete the Header */
     	delete bARTH
     	where ARCo=@co and ARTrans=@ARTrans and Mth = @mth

     	/* delete misc dist, added this as per issue 5284 and on discussion with Carol */
     	delete bARMD
     	where ARCo=@co and ARTrans=@ARTrans and Mth = @mth
   
		/* delete all from bARBL for lines marked for delete. */
       	delete bARBL
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq
   
       	/* delete current row from ARBM */
       	delete bARBM
       	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq
   
   		end /* end transtype D*/
   
	/* call bspBatchUserMemoUpdate to update user memos in bARTH before deleting the batch record */
	if exists (select top 1 1 from bARBH with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq)
       	begin
       	if @TransType in ('A','C')
			begin
           	select @msource = case @ARTransType when 'M' then 'AR MiscRec' else 'AR CashReceipts' end
           	exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @BatchSeq, @msource, @errmsg output
           	if @rcode <> 0 goto ar_posting_error
			end
       	end
   
	/* All lines were deleted as processed. Now delete current row from ARBH if no lines exist. */
	delete bARBH
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq and
		not exists(select 1 from bARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq)
   
	/* commit transaction */
	commit transaction
   
   	--issue 18616
   	if @TransType in ('A','C')
   		begin
   		if @guid is not null
   			begin
   			exec @rcode = bspHQRefreshIndexes null, null, @guid, null
   			end
   		end
   
	goto ar_posting_end		-- Get the next bARBH header transaction/Seq and process
   
ar_posting_error:		/* error occured within transaction - rollback any updates and continue */
	select @rcode = 1
	rollback transaction
	goto bspexit
   
ar_posting_end:			/* no more rows to process */
	/*** next header ***/
	select @BatchSeq=Min(BatchSeq)
	from bARBH with (nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq>@BatchSeq
   
	END	/* End batch seq loop */
   
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
   
/**** update GL using entries from bARBA for ARTransType='P' *****/
if (select count(*) from bARBA with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and ARTransType='P')>0
  	begin
  	exec @rcode = bspARBH1_PostGL @co, @mth, @batchid, @dateposted, 'Receipt', @source, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end

/**** update GL using entries from bARBA for ARTransType='M' *****/
if (select count(*) from bARBA with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and ARTransType='M')>0
  	begin
  	exec @rcode = bspARBH1_PostGL @co, @mth, @batchid, @dateposted, 'MiscCash', @source, @errmsg output
  	if @rcode <> 0 goto bspexit
  	end
   
/**** update CM using entries from bARBC *****/
exec @rcode = bspARBH1_PostCM @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit

/**** update JC Contracts using entries from bARBI *****/
exec @rcode = bspARBH1_PostJCContract @co, @mth, @batchid, @dateposted, @source, @errmsg output
if @rcode <> 0 goto bspexit

/**** update JC Jobs using entries from bARBJ *****/
exec @rcode = bspARBH1_PostJCJob @co, @mth, @batchid, @dateposted, @source, @errmsg output
if @rcode <> 0 goto bspexit

/**** update EM Equipment using entries from bARBE *****/
exec @rcode = bspARBH1_PostEM @co, @mth, @batchid, @dateposted,  @source,  @errmsg output
if @rcode <> 0 goto bspexit
   
/* set interface levels note string */
select @Notes=Notes from bHQBC with (nolock)
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
   
/***** delete HQ Close Control entries *****/
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

/***** set HQ Batch status to 5 (posted) *****/
update bHQBC
set Status = 5, DateClosed = getdate(),  Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end

bspexit:

if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBHPost_Cash]'
return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspARBHPost_Cash] TO [public]
GO
