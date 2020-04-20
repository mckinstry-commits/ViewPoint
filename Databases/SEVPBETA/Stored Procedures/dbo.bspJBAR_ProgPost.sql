SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBAR_ProgPost]
/***********************************************************
* CREATED BY  : bc 10/27/99
* MODIFIED By : bc 06/20/00
* 		bc 10/10/00 - added discount from JBAL to update DiscOffered in ARTL
*		tjl  4/16/01 - Minor mod setting ARTL linetype to 'O' for Non-Contracts interfaced from JB
*     	MV 06/04/01 - Issue 13538 - update Notes when trantype = 'C' change.
*     	kb 4/2/2 - issue #16872
*		TJL 10/18/02 - Issue #18982, ARTL trigger error on T&MBill Non-Contract 'Delete' or 'Change'
*		TJL 10/23/02 - Issue #19100, Changed, Deleted Bills interfaced to AR should create ARTH.DiscDate
*						and ARTH.DueDate as NULL to be consistent with AR.
*		TJL 11/20/02 - Issue #17278, Allow changes to bills in a closed month.
*		TJL 04/30/03 - Issue #20936, Reverse Release Retainage
*		TJL 08/11/03 - Issue #22102, If TaxCode has Changed on item, update original ARTL line
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 01/15/04 - Issue #23338, If Bill DueDate changes, update AR Released Inv DueDate also.
*		TJL 02/04/04 - Issue #23642, When TaxCode is changed, also update TaxGroup on all applied lines.
*		TJL 08/02/04 - Issue #25283, If JBAL Old values are still NULL (No Old ARTL line), generate on the fly
*		TJL 09/02/04 - Issue #22565, Interface Notes from JBIT to ARTL
*		TJL 09/09/04 - Issue #25472, If transactions apply to Released/Credit Inv, warn user (Conditional Skip Release Process)
*		TJL 02/14/05 - Issue #27104, Modify TransDate, DueDate on Release and Released transactions when Invoice Date changes
*		TJL 04/15/05 - Issue #28437, RelRetg fails to JC, GL, AR when interfacing mult bills. (Contains ClosedMth bill)
*		TJL 10/03/05 - Issue #29832, Skip Release Posting for Closed Mth Headers @batchmth <> @batchmth
*		TJL 01/12/06 - Issue #28182, 6x Recode.  Increase output @errmsg to 255 from 60
*		TJL 01/07/08 - Issue #120443, Post JBIN Notes and JBIT Notes to Released (2nd R or Credit Invoice) in ARTH, ARTL
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 11/14/08 - Issue #120080, Header Only Changes.  Correct code to update "Release" and "Released" transactions
*		TJL 04/04/11 - Issue #142949, If TaxCode changes from NULL to some value, Trigger Error that TaxCode not same as original
*         
* USAGE:
* Posts a validated batch of JBAR and JBAL entries
* deletes successfully posted JBAR and JBAL rows
*
* clears  bHQCC when complete
*
* INPUT PARAMETERS
*   JBCo        JB Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   PostingDate Posting date to write out if successful
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@jbco bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @source char(10), @errmsg varchar(255) output)
   
as
set nocount on
declare @rcode int, @opencursor tinyint, @opencursorJBAR tinyint,  @status tinyint,
   	@errorstart varchar(50), @inusebatchid bBatchID, @lastseq int, @numrows int, 
   	@closedmthYN bYN, @errortext varchar(100), @tablename char(20)
   
/*Header declares*/
declare @arco bCompany, @seq int, @batchtranstype char(1), @billnum int, @artrans bTrans,
   	@change_trans1 bTrans, @change_trans2 bTrans, @delete_trans bTrans,
   	@custgroup bGroup, @customer bCustomer, @jbcontract bContract, @rectype tinyint,
   	@invoice char(10), @description bDesc, @transdate bDate, @duedate bDate,
   	@discdate bDate, @payterms bPayTerms, @changed bYN, @billmonth bMonth, @revrelretgYN bYN,
   	@relretgtrans bTrans, @originvtrans bTrans, @notes varchar(8000)
   
/* old header values */
declare @olddesc bDesc, @oldtransdate bDate, @oldduedate bDate, @olddiscdate bDate, @oldpayterms bPayTerms, 
   	@oldinvdate bDate, @oldnotes varchar(8000)
   
/* Line declares */
declare @linetype char(1), @altlinetype char(1)

select @rcode = 0, @lastseq=0, @tablename = 'bARTH', @closedmthYN = 'N'

/* set open cursor flags to false */
select @opencursor = 0

/* get GL interface info from ARCO */
if not exists(select 1 from bJBCO with (nolock) where JBCo = @jbco)
   	begin
   	select @errmsg = 'Missing JB Company!', @rcode = 1
   	goto bspexit
   	end
   
/* check for date posted */
if @dateposted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
/* check source */
if @source not in ('JB')
   	begin
   	select @errmsg = 'Invalid source!', @rcode = 1
   	goto bspexit
   	end

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @jbco, @mth, @batchid, @source, 'JBAR', @errmsg output, @status output
if @rcode <> 0 goto bspexit
   
/* valid - OK to post, or posting in progress */
if @status <> 3 and @status <> 4
   	begin
   	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
   	goto bspexit
   	end
   
/* set HQ Batch status to 4 (posting in progress) */
update bHQBC
set Status = 4, DatePosted = @dateposted
where Co = @jbco and Mth = @mth and BatchId = @batchid
   
if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
/* get the AR company based on the JB company in JCCO */
select @arco = ARCo
from bJCCO with (nolock)
where JCCo = @jbco
   
/* declare cursor on AR Header Batch for validation */
declare bcJBAR cursor local fast_forward for
select BatchSeq, BatchTransType, BillMonth, BillNumber, ARTrans, CustGroup, Customer, Contract, RecType,
   	Invoice, Description, TransDate, DueDate, DiscDate, PayTerms, oldDescription, oldTransDate, oldDueDate, 
   	oldDiscDate, oldPayTerms, RevRelRetgYN, Notes, oldNotes 
from bJBAR with (nolock)
where Co = @jbco and Mth = @mth and BatchId = @batchid

/* open cursor */
open bcJBAR

/* set open cursor flag to true */
select @opencursor = 1

/* loop through all rows in JBAR and update their info.*/
ar_posting_loop:

select @change_trans1 = null, @change_trans2 = null, @delete_trans = null, @changed = 'N'

/* get row from JBAR */
fetch next from bcJBAR into  @seq, @batchtranstype, @billmonth, @billnum, @artrans, @custgroup, @customer, 
   	@jbcontract, @rectype, @invoice, @description, @transdate, @duedate, @discdate, @payterms,	@olddesc, 
   	@oldtransdate, @oldduedate, @olddiscdate, @oldpayterms, @revrelretgYN, @notes, @oldnotes
   
if @@fetch_status <> 0 goto ar_posting_end
select @errorstart = 'Seq#' + convert(varchar(6),@seq)
if (@seq=@lastseq)
   	begin
  	select @errmsg = 'Duplicate Seq, error with cursor!', @rcode=1
  	goto bspexit
  	end
   
select @lastseq=@seq
select @numrows = count(*)
from bJBAL with (nolock)
where Co=@jbco and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and ARLine < 10000
   
begin transaction
if @batchtranstype = 'A'	/* adding new AR */
  	Begin
  	exec @artrans = bspHQTCNextTrans @tablename, @arco, @mth, @errmsg output
  	if @artrans = 0
    	begin
    	select @errortext = 'Unable to retrieve AR Transaction number!'
    	exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    	if @rcode <> 0 goto ar_posting_error
    	end
   
  	/* insert AR Header */
  	insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType,
       	JCCo, Contract,
       	Invoice, Source,
       	TransDate, DueDate, DiscDate, Description, PayTerms, AppliedMth, AppliedTrans,
       	PurgeFlag, EditTrans, BatchId, InUseBatchID, Notes)
	select @arco, @mth, @artrans, 'I', @custgroup, @customer, @rectype,
		case when @jbcontract is null then null else @jbco end, @jbcontract,
		@invoice, @source,
		@transdate, @duedate, @discdate, @description, @payterms, @mth, @artrans,
		'N', 'Y', @batchid, @inusebatchid, r.Notes
	from bJBAR r with (nolock)
   	where r.Co = @jbco and r.Mth = @mth and r.BatchId = @batchid and r.BatchSeq = @seq
   
	if @@rowcount = 0 goto ar_posting_error
   
  	/* put new ARTH trans # into JBIN */
  	update bJBIN
  	set ARTrans = @artrans
  	where JBCo = @jbco and BillMonth = @billmonth and BillNumber = @billnum 
   	
  	/*now insert all the items from JBAL for this ARTrans */
  	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
		TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax,
    	DiscOffered,
     	JCCo,
     	Contract, Item, ContractUnits, ApplyMth, ApplyTrans, ApplyLine,
		UM, MatlUnits, Notes)
  	select @arco, Mth, @artrans, ARLine, @rectype,
		case when @jbcontract is null then 'O' else 'C' end,
		Description, GLCo, GLAcct, TaxGroup, TaxCode, isnull(Amount,0) + isnull(TaxAmount,0) + isnull(RetgTax,0),
		isnull(TaxBasis,0), isnull(TaxAmount,0), isnull(RetgPct,0), isnull(Retainage,0), isnull(RetgTax,0),
     	isnull(Discount,0),
    	case when @jbcontract is null then null else @jbco end,
   		@jbcontract, Item, isnull(Units,0), @mth, @artrans, ARLine,
    	UM, 0, Notes
  	from bJBAL with (nolock)
  	where Co=@jbco and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and ARLine < 10000

  	if @@rowcount <> @numrows goto ar_posting_error
   
	/* update JBIT.ARLine */
   	if @jbcontract is not null
   		begin
  		update bJBIT
  		set ARLine = l.ARLine
  		from bJBIT t with (nolock)
  		join bARTL l with (nolock) on l.ARCo = @arco and l.Mth = @mth and l.ARTrans = @artrans and l.Item = t.Item
  		where t.JBCo = @jbco and t.BillNumber = @billnum and t.BillMonth = @billmonth /*@mth*/
   		end
   
  	/*we need to update transaction number to other batches that need it*/
  	/*GL*/
  	update bJBGL
  	set ARTrans = @artrans
  	from bJBGL b with (nolock) 
	join bJBAR h with (nolock) on b.JBCo = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and b.JBTransType = 'J'
   
  	/*Job*/
  	update bJBJC
	set ARTrans = @artrans
  	from bJBJC i with (nolock)
	join bJBAR h with (nolock) on i.JBCo = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and i.JBTransType = 'J'

  	End /* End Transtype A */

------------------------
/* ORIGINAL HEADER CHANGE: This unlike AR in that users cannot bring original transaction back into a 
   batch for change. Therefore the following logic is applied:
1) When a user makes a Change to a JB Bill Header they expect TransDate, DueDate, DiscDate, PayTerms
   to update the Original Invoice header.  This will occur.  

2) When a user makes a Change to a JB Bill Header Description or Notes its not so obvious.  (Is the
   Description or Note change intended for the Original Bill or the Adjustment Transaction??)
   Therefore it was decided to send Description and Notes changes to the Original Invoice header.
   Likewise, as part of this same process, an Old and New Adjustment gets created.  These will
   contain the Old Description/Notes and New Description/Notes so if user wants to see how these
   changes have progressed thru time, the adjustments will keep a running history. */
if @batchtranstype = 'C' and (isnull(@transdate,'') <> isnull(@oldtransdate,'') or isnull(@duedate,'') <> isnull(@oldduedate,'') or
		isnull(@discdate,'') <> isnull(@olddiscdate,'') or isnull(@payterms,'') <> isnull(@oldpayterms,'') or
		isnull(@description,'') <> isnull(@olddesc,'') or isnull(@notes,'') <> isnull(@oldnotes,'')) 
	begin
  	update bARTH
  	set TransDate = @transdate /*InvoiceDate*/, DueDate = @duedate, DiscDate = @discdate, 
		PayTerms = @payterms, Description = @description, Notes = @notes
  	where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans=@artrans		--Original Invoice Header Trans
	if @@rowcount = 0
		begin
    	select @errortext = 'Unable to update AR Invoice header info! '
		select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : Mth = '
		select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : ARTrans = ' 
		select @errortext = @errortext + isnull(convert(varchar(10), @artrans),'')
    	exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    	if @rcode <> 0 goto ar_posting_error
    	end
	else
		begin
		/* Look for an associated 'R'elease transaction and if exists, update TransDate. */
		if (isnull(@transdate,'') <> isnull(@oldtransdate,'')) and exists(select 1
			from bARTH with (nolock)
			where ARCo = @arco and Mth = @billmonth and ARTrans = (@artrans + 1) and ARTransType = 'R'
				and CustGroup = @custgroup and Customer = @customer 
				and JCCo = @jbco and Contract = @jbcontract and Invoice is null
				and Source = 'JB' and AppliedMth is null and AppliedTrans is null)
			begin
			update bARTH
			set TransDate = @transdate
			where ARCo = @arco and Mth = @billmonth and ARTrans = (@artrans + 1) and ARTransType = 'R'
				and CustGroup = @custgroup and Customer = @customer 
				and JCCo = @jbco and Contract = @jbcontract and Invoice is null
				and Source = 'JB' and AppliedMth is null and AppliedTrans is null
			if @@rowcount = 0
				begin
	     		select @errortext = 'Unable to update Release AR Transaction TransDate! '
				select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : Mth = '
				select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : ARTrans = ' 
				select @errortext = @errortext + isnull(convert(varchar(10), (@artrans + 1)),'')
	     		exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
	     		if @rcode <> 0 goto ar_posting_error
	     		end
			end

		/* Look for an associated 'R'eleased invoice and if exists, update TransDate, DueDate. */
		if (isnull(@transdate,'') <> isnull(@oldtransdate,'') or isnull(@duedate,'') <> isnull(@oldduedate,'')
			or isnull(@notes,'') <> isnull(@oldnotes,'')) and exists(select 1
			from bARTH with (nolock)
			where ARCo = @arco and Mth = @billmonth and ARTrans = (@artrans + 2) and ARTransType = 'R'
				and CustGroup = @custgroup and Customer = @customer 
				and JCCo = @jbco and Contract = @jbcontract and Invoice is not null
				and Source = 'JB' and Mth = AppliedMth and ARTrans = AppliedTrans)
			begin
			update bARTH
			set TransDate = @transdate, DueDate = @duedate, Notes = @notes
			where ARCo = @arco and Mth = @billmonth and ARTrans = (@artrans + 2) and ARTransType = 'R'
				and CustGroup = @custgroup and Customer = @customer 
				and JCCo = @jbco and Contract = @jbcontract and Invoice is not null
				and Source = 'JB' and Mth = AppliedMth and ARTrans = AppliedTrans
			if @@rowcount = 0
				begin
	     		select @errortext = 'Unable to update Released AR Invoice TransDate, DueDate or Notes! '
				select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : Mth = '
				select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : ARTrans = ' 
				select @errortext = @errortext + isnull(convert(varchar(10), (@artrans + 2)),'')
	     		exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
	     		if @rcode <> 0 goto ar_posting_error
	     		end
			end
		end							
 	end
  
/* ORIGINAL HEADER CHANGE: This unlike AR in that users cannot bring original transaction back into a 
   batch for change. Therefore the following logic is applied:

1) When a user makes a Change to a JB Bill Header they expect TransDate, DueDate, DiscDate, PayTerms,
   Description, and Notes to update the appropriate related transactions.  These related transactions
   include 'Adjustment' transactions as well as any 'Release' or 'Released' retainage transactions. */
if @batchtranstype = 'C' 
	begin
	/* Update ONLY Original Header Transaction when DueDate or DiscDate or Notes changes. */
	if isnull(@transdate,'') <> isnull(@oldtransdate,'') or isnull(@duedate,'') <> isnull(@oldduedate,'') or
		isnull(@discdate,'') <> isnull(@olddiscdate,'') or isnull(@payterms,'') <> isnull(@oldpayterms,'') or
		isnull(@description,'') <> isnull(@olddesc,'') or isnull(@notes,'') <> isnull(@oldnotes,'')
		begin
  		update bARTH
  		set TransDate = @transdate /*InvoiceDate*/, PayTerms = @payterms,  DueDate = @duedate, DiscDate = @discdate, 
			Description = @description, Notes = @notes
  		where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans = @artrans		--Original Invoice Header Trans
		if @@rowcount = 0
			begin
    		select @errortext = 'Unable to update original AR Invoice header information! '
			select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : Mth = '
			select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : ARTrans = ' 
			select @errortext = @errortext + isnull(convert(varchar(10), @artrans),'')
    		exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    		if @rcode <> 0 goto ar_posting_error
    		end
		end

	/* Update Original and all Applied Transactions when TransDate, PayTerms, or Description changes. */
	/*if isnull(@transdate,'') <> isnull(@oldtransdate,'')
		begin
  		update bARTH
  		set TransDate = @transdate /*InvoiceDate*/
  		where ARCo = @arco and AppliedMth = @billmonth /*@mth*/ and AppliedTrans = @artrans		--Original & Applied Header Trans
		if @@rowcount = 0
			begin
    		select @errortext = 'Unable to update original or applied transaction header information! '
			select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : AppliedMth = '
			select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : AppliedTrans = ' 
			select @errortext = @errortext + isnull(convert(varchar(10), @artrans),'')
    		exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    		if @rcode <> 0 goto ar_posting_error
    		end
		end */

	/* Look to see if there has already been a release retainage transaction for this bill
	   indicating that this bill has already been interfaced. */
	select @relretgtrans = ARRelRetgTran, @originvtrans = ARRelRetgCrTran
	from bJBIN with (nolock)
	where JBCo = @jbco and BillMonth = @billmonth and BillNumber = @billnum

	/* Update any associated 'R'elease transaction when TransDate changes. */
	if (isnull(@transdate,'') <> isnull(@oldtransdate,'')) and exists(select 1
		from bARTH with (nolock)
		where ARCo = @arco and Mth = @billmonth and ARTrans = @relretgtrans and ARTransType = 'R'
			and CustGroup = @custgroup and Customer = @customer 
			and JCCo = @jbco and Contract = @jbcontract and Invoice is null
			and Source = 'JB' and AppliedMth is null and AppliedTrans is null)
		begin
		update bARTH
		set TransDate = @transdate
		where ARCo = @arco and Mth = @billmonth and ARTrans = @relretgtrans and ARTransType = 'R'
			and CustGroup = @custgroup and Customer = @customer 
			and JCCo = @jbco and Contract = @jbcontract and Invoice is null
			and Source = 'JB' and AppliedMth is null and AppliedTrans is null
		if @@rowcount = 0
			begin
     		select @errortext = 'Unable to update Release AR Transaction TransDate! '
			select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : Mth = '
			select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : ARTrans = ' 
			select @errortext = @errortext + isnull(convert(varchar(10), @relretgtrans),'')
     		exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto ar_posting_error
     		end
		end

	/* Update any associated 'R'eleased invoice transaction when TransDate or DueDate changes. */
	if (isnull(@transdate,'') <> isnull(@oldtransdate,'') or isnull(@duedate,'') <> isnull(@oldduedate,'')
		or isnull(@notes,'') <> isnull(@oldnotes,'')) and exists(select 1
		from bARTH with (nolock)
		where ARCo = @arco and Mth = @billmonth and ARTrans = @originvtrans and ARTransType = 'R'
			and CustGroup = @custgroup and Customer = @customer 
			and JCCo = @jbco and Contract = @jbcontract and Invoice is not null
			and Source = 'JB' and Mth = AppliedMth and ARTrans = AppliedTrans)
		begin
		update bARTH
		set TransDate = @transdate, DueDate = @duedate, Notes = @notes
		where ARCo = @arco and Mth = @billmonth and ARTrans = @originvtrans and ARTransType = 'R'
			and CustGroup = @custgroup and Customer = @customer 
			and JCCo = @jbco and Contract = @jbcontract and Invoice is not null
			and Source = 'JB' and Mth = AppliedMth and ARTrans = AppliedTrans
		if @@rowcount = 0
			begin
     		select @errortext = 'Unable to update Released AR Invoice TransDate, DueDate or Notes! '
			select @errortext = @errortext + 'ARCo = ' + isnull(convert(varchar(3), @arco),'') + ' : Mth = '
			select @errortext = @errortext + isnull(convert(varchar(13), @billmonth),'') + ' : ARTrans = ' 
			select @errortext = @errortext + isnull(convert(varchar(10), @originvtrans),'')
     		exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto ar_posting_error
     		end
		end
 	end

/******** END ORIGINAL HEADER CHANGE ******************************/
   
/******** BEGIN ADJUSTMENT PROCESS ****************************/
   
if exists(select 1
         from bJBAL with (nolock)
         where Co = @jbco and Mth=@mth and BatchId = @batchid and BatchSeq = @seq and ARLine < 10000 and
			(isnull(Amount,0) <> isnull(oldAmount,0) or isnull(Units,0) <> isnull(oldUnits,0) or
			isnull(TaxCode,'') <> isnull(oldTaxCode,'') or isnull(TaxBasis,0) <> isnull(oldTaxBasis,0) or
			isnull(TaxAmount,0) <> isnull(oldTaxAmount,0) or isnull(Retainage,0) <> isnull(oldRetainage,0) or
			isnull(RetgTax,0) <> isnull(oldRetgTax,0) or
			isnull(convert(varchar(8000),Notes),'') <> isnull(convert(varchar(8000),oldNotes),''))) 
select @changed = 'Y'
   
if @batchtranstype = 'C' and @changed = 'Y'
	Begin
	/***************************************
	* Back out old information - First 'A' *
	***************************************/
  	exec @change_trans1 = bspHQTCNextTrans @tablename, @arco, @mth, @errmsg output
  	if @change_trans1 = 0
    	begin
    	select @errortext = 'Unable to retreive AR Transaction number!'
    	exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    	if @rcode <> 0 goto ar_posting_error
    	end
    
	/* create an AR record based on the changed info */
	insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, 
		JCCo, Contract, 
		Invoice, Source, TransDate, DueDate, DiscDate, Description, PayTerms, AppliedMth, AppliedTrans,
 		PurgeFlag, EditTrans, BatchId, InUseBatchID, Notes)
	values (@arco, @mth, @change_trans1, 'A', @custgroup, @customer, @rectype, 
		case when @jbcontract is null then null else @jbco end, @jbcontract, 
		@invoice, @source, @oldtransdate, NULL, NULL, @olddesc, @oldpayterms, @billmonth /*@mth*/, @artrans,
  		'N', 'Y', @batchid, @inusebatchid, @oldnotes)

	if @@rowcount = 0 goto ar_posting_error
   
   	/* Conversion problem:  A ContractItem in JBAL may exist that does not in AR.  We
   	   will be missing Old information, in this case, and must provide adequate values
   	   on the fly.  LineType requires the extra step below */
   	select @altlinetype = case when @jbcontract is null then 'O' else 'C' end
   
  	/* Insert all the items from JBAL for this OLD/Reversing Adjustment ARTrans */
  	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
		TaxGroup, TaxCode, Amount,
     	TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax,
     	DiscOffered, 
		JCCo, Contract, 
		Item, ContractUnits, ApplyMth, ApplyTrans, ApplyLine, UM, MatlUnits, Notes)
  	select @arco, Mth, @change_trans1, ARLine, @rectype, isnull(oldLineType,@altlinetype), oldDescription, GLCo, GLAcct,
		TaxGroup, oldTaxCode, -(isnull(oldAmount,0) + isnull(oldTaxAmount,0) + isnull(oldRetgTax,0)) - 0,
    	isnull(-oldTaxBasis,0), isnull(-oldTaxAmount,0), isnull(-RetgPct,0), isnull(-oldRetainage,0), isnull(-oldRetgTax,0),
     	isnull(-oldDiscount,0), 
		case when @jbcontract is null then null else @jbco end, @jbcontract, 
		Item, isnull(-oldUnits,0), @billmonth /*@mth*/, @artrans, ARLine, UM, 0, oldNotes
  	from bJBAL with (nolock)
  	where Co=@jbco and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and ARLine < 10000

  	if @@rowcount <> @numrows goto ar_posting_error
  
  	/* update transaction number to batches for the old values */
  	/*GL*/
  	update bJBGL
  	set ARTrans = @change_trans1
  	from bJBGL b with (nolock) 
	join bJBAR h with (nolock) on b.JBCo = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and b.OldNew = 0 and b.JBTransType = 'J'
   
  	/*Job*/
  	update bJBJC
  	set ARTrans = @change_trans1
  	from bJBJC i with (nolock)
	join bJBAR h with (nolock) on i.JBCo = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and i.OldNew = 0 and i.JBTransType = 'J'
   
   	/****************************************
   	* Some changes may require updating		*
   	* all previous lines with new values	*
   	****************************************/
   	if exists(select 1
   	          from bJBAL with (nolock)
   	          where Co = @jbco and Mth=@mth and BatchId = @batchid and BatchSeq = @seq and ARLine < 10000 and
   	                  isnull(TaxCode,'') <> isnull(oldTaxCode,''))
   		begin
   		/* TaxCode has changed but we will update TaxGroup just in case some old transactions have 
   		   applied transactions that are missing the TaxGroup.  This will prevent an ARTL update trigger
   		   error.  Missing TaxGroup on Applied transactions should have been fixed in Issue #23642 */
   		update l
   		set l.TaxCode = bl.TaxCode, l.TaxGroup = bl.TaxGroup
   		from bJBAL bl with (nolock)
   		join bJBAR br with (nolock) on br.Co = bl.Co and br.Mth = bl.Mth and br.BatchId = bl.BatchId and br.BatchSeq = bl.BatchSeq
   		--join bARTL l on l.ARCo = @arco and l.Mth = br.BillMonth and l.ARTrans = br.ARTrans		--Change Orig Lines only
   		join bARTL l with (nolock) on l.ARCo = @arco and l.ApplyMth = br.BillMonth and l.ApplyTrans = br.ARTrans
   		where br.Co=@jbco and br.Mth=@mth and br.BatchId=@batchid and br.BatchSeq=@seq and bl.ARLine < 10000
   			--and l.ARCo = @arco and l.Mth = br.BillMonth and l.ARTrans = br.ARTrans and l.ARLine = bl.ARLine	--Change Orig Lines only
   			and l.ARCo = @arco and l.ApplyMth = br.BillMonth and l.ApplyTrans = br.ARTrans and l.ApplyLine = bl.ARLine
   		end
   
   	/******************************************
   	* Some changes may require updating only  *
   	* the original lines with new values	  *
   	******************************************/
   	if exists(select 1
   	          from bJBAL with (nolock)
   	          where Co = @jbco and Mth=@mth and BatchId = @batchid and BatchSeq = @seq and ARLine < 10000 and
   	                  isnull(convert(varchar(8000),Notes),'') <> isnull(convert(varchar(8000),oldNotes),''))
   		begin
   		/* Item/Line Notes has changed.  Update the Original Lines with New Item/Line Notes */
   		update l
   		set l.Notes = bl.Notes, l.Description = bl.Description
   		from bJBAL bl with (nolock)
   		join bJBAR br with (nolock) on br.Co = bl.Co and br.Mth = bl.Mth and br.BatchId = bl.BatchId and br.BatchSeq = bl.BatchSeq
   		join bARTL l on l.ARCo = @arco and l.Mth = br.BillMonth and l.ARTrans = br.ARTrans					--Change Orig Lines only
   		where br.Co=@jbco and br.Mth=@mth and br.BatchId=@batchid and br.BatchSeq=@seq and bl.ARLine < 10000
   			and l.ARCo = @arco and l.Mth = br.BillMonth and l.ARTrans = br.ARTrans and l.ARLine = bl.ARLine	--Change Orig Lines only

		/* Item/Line Notes has changed.  Update the 'R'eleased (2nd R) Credit Invoice Lines with New Item/Line Notes. 
		   This update needs to occur at this time because Release Amounts themselves may not have changed and
		   therefore the RelRetg Posting code may not fire. */
		if exists(select 1
			from bARTH with (nolock)
			where ARCo = @arco and Mth = @billmonth and ARTrans = (@artrans + 2) and ARTransType = 'R'
				and CustGroup = @custgroup and Customer = @customer 
				and JCCo = @jbco and Contract = @jbcontract and Invoice is not null
				and Source = 'JB' and Mth = AppliedMth and ARTrans = AppliedTrans)
			begin
   			update l
   			set l.Notes = bl.Notes
   			from bJBAL bl with (nolock)
   			join bJBAR br with (nolock) on br.Co = bl.Co and br.Mth = bl.Mth and br.BatchId = bl.BatchId and br.BatchSeq = bl.BatchSeq
   			join bARTL l on l.ARCo = @arco and l.Mth = br.BillMonth and l.ARTrans = br.ARTrans + 2					--Change 'R'eleased Lines only
   			where br.Co=@jbco and br.Mth=@mth and br.BatchId=@batchid and br.BatchSeq=@seq and bl.ARLine < 10000
   				and l.ARCo = @arco and l.Mth = br.BillMonth and l.ARTrans = br.ARTrans + 2 and l.ARLine = bl.ARLine	--Change 'R'eleased Lines only
			end
   		end
   
	/***********************************
	* Add new information - Second 'A' *
	***********************************/
  	exec @change_trans2 = bspHQTCNextTrans @tablename, @arco, @mth, @errmsg output
  	if @change_trans2 = 0
    	begin
    	select @errortext = 'Unable to retreive AR Transaction number!'
    	exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    	if @rcode <> 0 goto ar_posting_error
    	end
   
  	insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, 
		JCCo, Contract, 
		Invoice, Source, TransDate, DueDate, DiscDate, Description, PayTerms, AppliedMth, AppliedTrans,
   		PurgeFlag, EditTrans, BatchId, InUseBatchID, Notes)
  	values (@arco, @mth, @change_trans2, 'A', @custgroup, @customer, @rectype, 
		case when @jbcontract is null then null else @jbco end, @jbcontract, 
		@invoice, @source, @transdate, NULL, NULL, @description, @payterms, @billmonth /*@mth*/, @artrans,
     	'N', 'Y', @batchid, @inusebatchid, @notes)

  	if @@rowcount = 0 goto ar_posting_error
   
  	/* Insert all the items from JBAL for this NEW Adjustment ARTrans */
  	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
		TaxGroup, TaxCode, Amount,
    	TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax,
    	DiscOffered, 
		JCCo, Contract, 
		Item, ContractUnits, ApplyMth, ApplyTrans, ApplyLine, UM, MatlUnits, Notes)
  	select @arco, Mth, @change_trans2, ARLine, @rectype, isnull(oldLineType,@altlinetype), Description, GLCo, GLAcct,
		TaxGroup, TaxCode, (isnull(Amount,0) + isnull(TaxAmount,0) + isnull(RetgTax,0)),
   		isnull(TaxBasis,0), isnull(TaxAmount,0), isnull(RetgPct,0), isnull(Retainage,0), isnull(RetgTax,0),
   		isnull(Discount,0), 
		case when @jbcontract is null then null else @jbco end, @jbcontract, 
		Item, isnull(Units,0), @billmonth /*@mth*/, @artrans, ARLine, UM, 0, Notes
  	from bJBAL with (nolock)
  	where Co=@jbco and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and ARLine < 10000
   
   	/* update transaction number to batches for the new values */
  	/*GL*/
  	update bJBGL
  	set ARTrans = @change_trans2
  	from bJBGL b with (nolock)
	join bJBAR h with (nolock) on b.JBCo = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and b.OldNew = 1 and b.JBTransType = 'J'

  	/*Job*/
  	update bJBJC
  	set ARTrans = @change_trans2
  	from bJBJC i with (nolock)
	Join bJBAR h with (nolock) on i.JBCo = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and i.OldNew = 1 and i.JBTransType = 'J'
   
	End /*trans type C*/
   
if @batchtranstype = 'D'	/* back out original invoice */
   	begin
  	exec @delete_trans = bspHQTCNextTrans @tablename, @arco, @mth, @errmsg output
  	if @delete_trans = 0
    	begin
    	select @errortext = 'Unable to retreive AR Transaction number!'
    	exec @rcode = bspHQBEInsert @arco, @mth, @batchid, @errortext, @errmsg output
    	if @rcode <> 0 goto bspexit
    	end
   
  	/* create an AR record based on the OLD changed info */
  	insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, RecType, 
		JCCo, Contract, 
		Invoice, Source,
   		TransDate, DueDate, DiscDate, Description, PayTerms, AppliedMth, AppliedTrans,
   		PurgeFlag, EditTrans, BatchId, InUseBatchID, Notes)
  	values (@arco, @mth, @delete_trans, 'A', @custgroup, @customer, @rectype, 
		case when @jbcontract is null then null else @jbco end, @jbcontract, 
		@invoice, @source,
		@oldtransdate, NULL, NULL, @olddesc, @oldpayterms, @billmonth /*@mth*/, @artrans,
   		'N', 'Y', @batchid, @inusebatchid, @oldnotes)

  	if @@rowcount = 0 goto ar_posting_error
   
   	/* Conversion problem:  A ContractItem in JBAL may exist that does not in AR.  We
   	   will be missing Old information, in this case, and must provide adequate values
   	   on the fly.  LineType requires the extra step below */
   	select @altlinetype = case when @jbcontract is null then 'O' else 'C' end
   
  	/*now insert all the items from JBAL for this ARTrans */
  	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct,
		TaxGroup, TaxCode, Amount, 
		TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax,
   		DiscOffered, 
		JCCo, Contract, 
		Item, ContractUnits, ApplyMth, ApplyTrans, ApplyLine, UM, MatlUnits, Notes)
  	select @arco, Mth, @delete_trans, ARLine, @rectype, isnull(oldLineType,@altlinetype), isnull(oldDescription,Description), GLCo, GLAcct,
		TaxGroup, isnull(oldTaxCode,TaxCode), -(isnull(oldAmount,0) + isnull(oldTaxAmount,0) + isnull(oldRetgTax,0)) - 0, 
		isnull(-oldTaxBasis,0), isnull(-oldTaxAmount,0), isnull(-oldRetgPct,0), isnull(-oldRetainage,0), isnull(-oldRetgTax,0),
    	isnull(-oldDiscount,0), 
		case when @jbcontract is null then null else @jbco end, @jbcontract, 
		Item, isnull(-oldUnits,0), @billmonth /*@mth*/, @artrans, ARLine, UM, 0, oldNotes
  	from bJBAL with (nolock)
  	where Co=@jbco and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and ARLine < 10000

  	if @@rowcount <> @numrows goto ar_posting_error
   
  	/* update transaction number to batches for the old values */
  	/*GL*/
  	update bJBGL
  	set ARTrans = @delete_trans
  	from bJBGL b with (nolock)
	join bJBAR h with (nolock) on b.JBCo = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and b.JBTransType = 'J'
   
  	/*Job*/
  	update bJBJC
  	set ARTrans = @delete_trans
  	from bJBJC i with (nolock)
	join bJBAR h with (nolock) on i.JBCo = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
  	where h.Co = @jbco and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @seq and i.JBTransType = 'J'

  	end /* end transtype D*/
   
/***********************************************************************************************
* Post release retainage records	- When Bill is in Open Mth (Skip for Closed Mth Bills)		*
*									- When Retainage or RetgRel has been modified.				*
*								  	- When Bills are being Deleted.								*
*																								*
* Posting Release Retg gets skipped for a Closed Mth bill because form prevents user  			*
* from changing RelRetg values.  																*
* 																								*
**********************************************************************************************/
if @billmonth = @mth
   	begin
	if (exists(select 1
		from bJBAL with (nolock)
		where Co = @jbco and Mth=@mth and BatchId = @batchid and BatchSeq = @seq and ARLine < 10000
   				and	(isnull(Retainage,0) <> isnull(oldRetainage,0) or isnull(RetgTax,0) <> isnull(oldRetgTax,0) or
					isnull(RetgRel,0) <> isnull(oldRetgRel,0) or isnull(RetgTaxRel,0) <> isnull(oldRetgTaxRel,0))))
   			or (@batchtranstype = 'D')
		begin
		if @revrelretgYN = 'N'
			begin
			exec @rcode = bspJBAR_PostRelRetg @jbco, @mth, @batchid, @seq, @errmsg output
			if @rcode <> 0 goto ar_posting_error
			end
		else
			begin
			exec @rcode = bspJBAR_PostRelRetgRev @jbco, @mth, @batchid, @seq, @errmsg output
			if @rcode <> 0 goto ar_posting_error
			end
		end
  	end
   
/**********************
* Misc Distributions *
**********************/
exec @rcode = bspJBAR_PostMiscDist @jbco, @mth, @batchid, @seq, @errmsg output
if @rcode <> 0 goto ar_posting_error

/* delete items just added*/
delete from bJBAL where Co = @jbco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
delete from bJBBM where JBCo = @jbco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

/* delete current row from JBAR*/
delete from bJBAR where Co = @jbco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

/* update JBIN = interfaced and clear the batch fields */
if @batchtranstype <> 'D'
   	begin
  	update bJBIN
  	set InvStatus = 'I', InUseMth = null, InUseBatchId = null
  	where JBCo = @jbco and BillMonth = @billmonth /*@mth*/ and BillNumber = @billnum
  	end
else
  	begin
  	/* delete the bill in JBIN */
  	delete from bJBIN where JBCo = @jbco and BillMonth = @billmonth /*@mth*/ and BillNumber = @billnum
  	end
 
/* commit transaction */
commit transaction
goto ar_posting_loop

ar_posting_error:		/* error occured within transaction - rollback any updates and continue */
	rollback transaction
   	goto ar_posting_loop
   
ar_posting_end:			/* no more rows to process */
	if @opencursor=1
  		begin
		close bcJBAR
  		deallocate bcJBAR
  		select @opencursor=0
  		end
   
/* make sure batch is empty */
if exists(select 1 from bJBAR with (nolock) where Co = @jbco and Mth = @mth and BatchId = @batchid)
  	begin
  	select @errmsg = 'Not all AR header entries were posted - unable to close batch!', @rcode = 1
  	goto bspexit
  	end
   
if exists(select 1 from bJBAL with (nolock) where Co = @jbco and Mth = @mth and BatchId = @batchid)
  	begin
  	select @errmsg = 'Not all AR item entries were posted - unable to close batch!', @rcode = 1
  	goto bspexit
  	end
   
/**** update GL using entries from bJBGL  *****/
if (select count(*) from bJBGL with (nolock) where JBCo = @jbco and Mth = @mth and BatchId = @batchid) > 0
	begin
	exec @rcode = bspJBAR_ProgPostGL @jbco, @mth, @batchid, @dateposted, 'Invoice', @source, @errmsg output
	if @rcode <> 0 goto bspexit
	end
   
/**** update JC using entries from bJBJC *****/
exec @rcode = bspJBAR_ProgPostJC @jbco, @mth, @batchid, @dateposted, @source, @errmsg output
if @rcode <> 0 goto bspexit
   
/**** delete HQ Close Control entries *****/
delete bHQCC where Co = @jbco and Mth = @mth and BatchId = @batchid
   
/* set HQ Batch status to 5 (posted) */
update bHQBC
set Status = 5, DateClosed = getdate()
where Co = @jbco and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end
   
bspexit:
if @opencursor = 1
	begin
	close bcJBAR
	deallocate bcJBAR
	end
   
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspJBAR_ProgPost]'
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBAR_ProgPost] TO [public]
GO
