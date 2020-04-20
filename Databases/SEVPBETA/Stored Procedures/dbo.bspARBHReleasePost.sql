SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspARBHReleasePost]
/***********************************************************
* CREATED BY  : CJW 10/23/97
* MODIFIED By : GG 04/22/99    (SQL 7.0)
*		bc 08/26/99  changed the 0 ARLine theory into the 10000 line theory
* 		bc 02/08/00  added the original invoice number to the applied transaction header
*		TJL - 06/19/01  Added to Insert, where clauses so as not to insert 0.00 value lines into bARTL
*		TJL - 07/20/01  When Retainage is released two header and associated transactions are generated.
*				   Field in ARTH/ARTL may differ depending.  Modified for this difference.
*		TJL - 09/06/01  Issue #14552, Modified to set bARTH.PurgeFlag to 'N' by default
* 		CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*  		TLV 07/11/02 - Move Attachment when posted Call-1138029
*		TJL 01/18/04 - Issue #23477, Insert correct GLCo and GLRevAccount on the Released Retainage Invoice.
*		TJL  02/03/04 - Issue #23642, Insert original TaxGroup and TaxCode on 'Release', TaxGroup on 'Released' transactions
*		TJL 02/17/04 - Issue #18616, Reindex attachments after posting A or C records.
*		TJL 02/19/04 - Issue #22667, Enable AR Release Retainage Notes.
*		TJL 03/09/05 - Issue #27263, Remove TaxCode from 'Release' transaction
*		TJL 03/31/05 - 6x Issue #27207, Change input variables to LowerCase, @errmsg from 60 to 255 char
*		TJL 02/26/07 - Issue #120561, Made adjustment pertaining to bHQCC Close Control entry handling
*		TJL 07/01/08 - Issue #128371, AR Release International Sales Tax
*		GP 10/30/08	- Issue 130576, changed text datatype to varchar(max)
*
* USAGE:
* Posts a validated batch of bARBH Release retainage
* and deletes successfully posted bARBH
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
   
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @source bSource, @errmsg varchar(255) output)
as
set nocount on
   
declare @rcode int, @tablename char(20), @JCInterface tinyint, @JCTrans bTrans

declare @ARTrans bTrans, @ARTransZero bTrans,
	@ARLine smallint, @OldNew tinyint, @BatchSeq int, @JCCo bCompany, @Job bJob,
	@PhaseGroup bGroup, @Phase bPhase, @CT bJCCType,
	@CheckNo varchar(10), @ActDate bDate, @Description bDesc, @GLCo bCompany,
	@GLAcct bGLAcct, @UM bUM, @JobUnits bUnits, @JobHours bHrs, @Amount bDollar, @ARCurrentFlag bYN,
	@Status tinyint, @newline smallint, @oldline smallint, @invoice char(10), @Notes varchar(256),
	@guid uniqueIdentifier, @transtype char(1)
   
select @rcode=0

if @source not in ('ARRelease')
	begin
	select @errmsg = 'Invalid Source', @rcode = 1
	goto bspexit
	end

select @JCInterface = JCInterface, @ARCurrentFlag = RelRetainOpt
from bARCO with (nolock)
where ARCo=@co

if @JCInterface not in (0,1)
	begin
	select @errmsg = 'Invalid JC Interface level', @rcode = 1
	goto bspexit
	end

/* check for date posted */
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'ARBH', @errmsg output, @Status output
if @rcode <> 0 goto bspexit

if @Status <> 3 and @Status <> 4	/* valid - OK to post, or posting in progress */
	begin
	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
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
   
/*****  update ******/
/*** loop through ARBH ****/
select @BatchSeq=min(BatchSeq)
from bARBH h with (nolock)
where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
while @BatchSeq is not null
	BEGIN
   	begin transaction
   	/* Get UniqueAttchID for re-indexing at end of procedure */
   	select @guid = UniqueAttchID, @transtype = TransType
   	from bARBH h with (nolock)
   	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @BatchSeq
   
   	/* get next available transaction # for ARTH */
   	select @tablename = 'bARTH'
	exec @ARTrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
	if @ARTrans = 0 goto AR_posting_error
   
	exec @ARTransZero = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
	if @ARTransZero = 0 goto AR_posting_error
   
	select @invoice = min(t.Invoice)
   	from bARBH b with (nolock)
   	join bARBL l with (nolock) on l.Co = b.Co and l.Mth = b.Mth and l.BatchId = b.BatchId and l.BatchSeq= b.BatchSeq
   	join bARTH t with (nolock) on t.ARCo = l.Co and t.Mth = l.ApplyMth and t.ARTrans = l.ApplyTrans
   	where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq=@BatchSeq
   
   	/* insert ARTH record - This record represents that which is to Release from an existing invoice.*/
   	insert into bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, Description, Source, TransDate, DueDate,
		CreditAmt, Invoiced, Paid, Retainage, DiscTaken, AmountDue, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId, UniqueAttchID)
	select Co, Mth, @ARTrans, ARTransType, CustGroup, Customer, NULL, JCCo, Contract, NULL, 'Release Retainage', @source, TransDate, NULL,
   		0, 0, 0, 0, 0, 0, NULL, NULL, 'N','N', BatchId, UniqueAttchID
   	from bARBH with (nolock)
   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@BatchSeq
   	if @@rowcount = 0 goto AR_posting_error
   
   	/* insert the ARTH record that has retainage applied to itself - This record represents the NEW invoice created as a result of the previous release. */
   	insert into bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, Description, Source, TransDate, DueDate,
		CreditAmt, Invoiced, Paid, Retainage, DiscTaken, AmountDue, AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId, Notes, UniqueAttchID)
   	select Co, @mth, @ARTransZero, ARTransType, CustGroup, Customer, RecType, JCCo, Contract, Invoice, 'Released Retainage', @source, TransDate, DueDate,
		0, 0, 0, 0, 0, 0, @mth, @ARTransZero, 'N','N', BatchId, Notes, UniqueAttchID
	from bARBH with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@BatchSeq
   	if @@rowcount = 0 goto AR_posting_error
   
   	/*we need to update transaction number to other batches that need it*/
   	/*GL*/
   	update bARBA 
   	set ARTrans = @ARTrans
   	from bARBA b, bARBH h
	where b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
		and h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @BatchSeq
   
   	/*Job*/
	update bARBI 
   	set ARTrans = @ARTrans
   	from bARBI i, bARBH h
   	where i.ARCo = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
		and h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @BatchSeq
   
   	/* Create 'R'elease lines applied against the original invoices from which we are releasing retainage. */
  	insert into ARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
   		Amount, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, DiscOffered, 
		DiscTaken, JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
  	select Co, Mth, @ARTrans, ARLine, RecType, LineType, Description, GLCo, NULL, TaxGroup, TaxCode,
		-isnull(Amount,0), 0, 0, isnull(RetgPct,0), -isnull(Retainage,0), -isnull(RetgTax,0), 0,
		0, JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine
  	from bARBL with (nolock)
  	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq and ARLine < 10000 and
		(isnull(Amount,0) <> 0 or isnull(TaxAmount,0) <> 0 or isnull(Retainage,0) <> 0 or isnull(RetgTax,0) <> 0 or
	 	 isnull(DiscOffered,0) <> 0 or isnull(DiscTaken,0) <> 0)
   
	/* now insert the line(s) for this header transaction (applied to itself) - represented by lines 10000 and greater */
	/* if the ARCurrentFlag is set to 'Y' then clear out the retainage in ARTL*/
   
   	/* overwrite the '10000' lines going into ARTL starting at 1 */
   	select @newline = 0, @oldline = null
   	select @oldline = min(ARLine)
   	from ARBL with (nolock)
	where Co = @co and Mth = @mth and BatchId=@batchid and BatchSeq=@BatchSeq and ARLine > 9999
	while @oldline is not null
		begin
		select @newline = @newline + 1
   
    	/* Create 'R'eleased lines relative to the New 'R' type invoice. - This represents lines of the NEW invoice. */
    	insert into ARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, 
			Amount, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, DiscOffered, DiscTaken, 
			JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
    	select Co, Mth, @ARTransZero, @newline, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, 
			isnull(Amount,0), case when isnull(TaxAmount,0) = 0 then 0 else isnull(Amount,0) - isnull(TaxAmount,0) end, isnull(TaxAmount,0), 
			case @ARCurrentFlag when 'Y' then 0 else (case when isnull(Amount,0) = 0 then 0 else isnull(Retainage,0)/isnull(Amount,0) end) end, 
			isnull(Retainage,0), isnull(RetgTax,0),	0, 0, 
			JCCo, Contract, Item, Mth, @ARTransZero, @newline
    	from bARBL with (nolock)
    	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@BatchSeq and ARLine = @oldline and
			(isnull(Amount,0) <> 0 or isnull(TaxAmount,0) <> 0 or isnull(Retainage,0) <> 0 or isnull(RetgTax,0) <> 0 or
	 		isnull(DiscOffered,0) <> 0 or isnull(DiscTaken,0) <> 0)
   
		select @oldline = min(ARLine)
		from ARBL with (nolock)
		where Co = @co and Mth = @mth and BatchId=@batchid and BatchSeq=@BatchSeq and ARLine > @oldline
		end
   
   	/* delete batch lines just posted */
	delete bARBL where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq
	/* delete header record */
	delete bARBH where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @BatchSeq

	/* commit trans */
	commit transaction
   
   	--issue 18616
   	if @transtype in ('A','C')
   		begin
   		if @guid is not null
   			begin
   			exec @rcode = bspHQRefreshIndexes null, null, @guid, null
   			end
   		end
   
   	goto AR_posting_loop	--Get next BatchSeq
   
AR_posting_error:
	/* Error occured within transaction - rollback any updates and continue with next BatchSeq */
	rollback transaction
   
AR_posting_loop:
	/* Get next BatchSeq */
	select @BatchSeq=min(BatchSeq) 
   	from bARBH h with (nolock)
	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and BatchSeq > @BatchSeq
	if @@rowcount = 0
		begin
		select @BatchSeq = null
       	end
   	END
   
/* make sure AR Audit is empty */
if exists(select 1 from bARBH where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all AR entries were updated  - unable to close batch!', @rcode = 1
	goto bspexit
	end
   
/**** Update GL using entries from bARBA ****/
exec @rcode=bspARBH1_PostGL @co,@mth, @batchid, @dateposted,'ARRelease', @source, @errmsg output
if @rcode<>0 goto bspexit
/**** Update JC using entries from bARBI *****/
exec @rcode = bspARBH1_PostJCContract @co, @mth, @batchid, @dateposted, @source, @errmsg output
if @rcode <> 0 goto bspexit
   
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
from bARCO a 
where ARCo=@co
   
/**** delete HQ Close Control entries *****/
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

/* set HQ Batch status to 5 (posted) */
update bHQBC
set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBHReleasePost] TO [public]
GO
