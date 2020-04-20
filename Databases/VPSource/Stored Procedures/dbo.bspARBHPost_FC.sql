SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspARBHPost_FC]
   /***********************************************************
   * CREATED BY  : CJW 9/5/97
   * MODIFIED By : GG 04/22/99    (SQL 7.0)
   *     	GR 11/12/99 - changed to insert ARLine into ApplyLine and @artrans into ApplyTrans
   *                  	field if the transaction type is 'A' - adding new
   *     	GR 11/16/99 - changed to insert Mth into ApplyMth field if the transaction
   *                  	type is 'A' - adding new
   *    	GR 11/24/99 - corrected delete queries ARTL and ARTH if transtype is D
   *    	bc 09/19/00 - added file attachment code
   *   	kb 03/6/01 - fixed some joins for changed and delete record when
   *              		updating ARTL. Problem was it was updating all trans
   *                	where the trans # matched instead of restricting on month
   *	 	TJL 5/10/01 - Corrected problem of FC posting to itself instead of applying to
   *                 	an invoice if FCType is set to 'I' - Invoice in ARCM
   *    	MV 06/22/01 - Issue 12769 BatchUserMemoUpdate
   *		TJL 06/29/01 - Added to Insert, where clauses so as not to insert 0.00 value lines into bARTL
   *   	TV/RM 02/22/02 Attachment Fix
   *		TJL 02/28/02 - Issue #14171, Add FinanceChg, rptApplyMth, rptApplyTrans columns
   *		TJL 03/20/02 - Rewrote and reorganized for improved performance.
   *    	CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
   *		GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
   *		TJL 09/18/03 - Issue #22394, Performance Enhancements, Add NoLocks
   *		TJL 02/04/04 - Issue #23642, Insert TaxGroup into ARTL
   *		TJL 02/17/04 - #18616, Reindex attachments after posting A or C records.
   *		TJL 03/31/05 - 6x Issue #27207, Change @errmsg from 60 to 255 characters
   *		TJL 10/15/07 - Issue #125729, Added MatlGroup, Material, INCo, Loc to Original Line Insert on Add/Change Trans
   *		GP 10/30/08	- Issue 130576, changed text datatype to varchar(max)
   *		TJL 05/14/09 - Issue #133432, Latest Attachment Delete process.
   *
   * USAGE:
   * Posts a validated batch of ARBH and ARBL entries
   * deletes successfully posted bARBH and ARBL rows
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
   declare @rcode int, @opencursor tinyint, @fctype char(1),
   	@status tinyint, @errorstart varchar(50), @Notes varchar(256)
   
   /* ARBH Cursor Declares */
   declare @seq int, @transtype char(1), @artrans bTrans, @custgroup bGroup,
   	@customer bCustomer, @appliedmth bMonth, @appliedtrans bTrans,
   	@guid uniqueidentifier
   
   select @rcode = 0, @opencursor = 0
   
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
   if @source not in ('ARFinanceC')
    	begin
    	select @errmsg = 'Invalid source!', @rcode = 1
    	goto bspexit
    	end
   
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'ARBH', @errmsg output,
   	@status output
   if @rcode <> 0 goto bspexit
   
   if @status <> 3 and @status <> 4	--valid - OK to post, or posting in progress
    	begin
      	select @errmsg = 'Invalid Batch status -  must be -valid OK to post- or -posting in progress-!', @rcode = 1
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
   
   /* declare cursor on AR Header Batch for validation */
   declare bcARBH cursor for
   select BatchSeq, TransType, ARTrans, CustGroup,	Customer, AppliedMth, AppliedTrans,
   	UniqueAttchID
   from bARBH with (nolock)
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* open cursor */
   open bcARBH
   select @opencursor = 1
   
   /* loop through all rows in ARBH and update their info */
   ar_posting_loop:
   
   /* get row from ARBH */
   fetch next from bcARBH into @seq, @transtype, @artrans, @custgroup, @customer,
   		@appliedmth, @appliedtrans, @guid
   
   if @@fetch_status <> 0 goto ar_posting_end
   
   	select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
   	/* Get Finance Charge Type for this Customer */
    	select @fctype = FCType
   	from bARCM with (nolock)
   	where CustGroup = @custgroup and Customer = @customer
   
      	begin transaction
      	if @transtype = 'A'	/* adding new AR FC*/
       	begin
        	exec @artrans = bspHQTCNextTrans bARTH, @co, @mth, @errmsg output
    	  	if isnull(@artrans, 0) = 0 goto ar_posting_error
   
         	/* insert AR Header */
    	   	insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, CustRef,
    		 	RecType, JCCo, Contract, Invoice, Source, TransDate, DueDate, Description,
    		 	AppliedMth, AppliedTrans, PurgeFlag, EditTrans, BatchId, PayTerms,
   			Notes, UniqueAttchID)
   		select Co, Mth, @artrans, ARTransType, CustGroup, Customer, CustRef,
   			RecType, JCCo, Contract, Invoice, Source, TransDate,
   			case when @fctype in ('A','R') then DueDate else null end,
   			Description,
   			case when @fctype in ('A','R') then Mth else AppliedMth end,
   			case when @fctype in ('A','R') then @artrans else AppliedTrans end,
   			'N', 'Y', BatchId, PayTerms, Notes, UniqueAttchID
   		from bARBH with (nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
        	if @@rowcount = 0 goto ar_posting_error
   
    	 	/* we need to update transaction number to other batches that need it */
    	  	--GL
          	update bARBA
   		set ARTrans = @artrans
      		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
          	/* update bARBH for BatchUserMemoUpdate */
        	update bARBH
   		set ARTrans = @artrans
       	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
	   	/* now insert all the items in bARTL from ARBL for this ARTrans/Seq */
    	insert into ARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
		 		Amount, FinanceChg, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, DiscTaken,
				JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine, rptApplyMth, rptApplyTrans,
				MatlGroup, Material, INCo, Loc)
      	select Co, Mth, @artrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
			 	Amount, FinanceChg, 0, 0, 0, 0, 0, 0, JCCo, Contract, Item,
 		 		case when @fctype in ('A', 'R') then @mth else @appliedmth end,
		 		case when @fctype in ('A', 'R') then @artrans else @appliedtrans end,
				ARLine, rptApplyMth, rptApplyTrans, MatlGroup, Material, INCo, Loc
     	from bARBL with (nolock)
   		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and
   				(isnull(Amount,0) <> 0 or isnull(TaxAmount,0) <> 0 or isnull(Retainage,0) <> 0
   				or isnull(DiscOffered,0) <> 0 or isnull(DiscTaken,0) <> 0 or isnull(FinanceChg,0) <> 0
   				or isnull(AddRetainage,0) <> 0)
   
         	/* update ARTrans in the batch record for BatchUserMemoUpdate */
         	update bARBL
        	set ARTrans = @artrans
         	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
        	/* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
        	exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AR FinanceChargeDetail', @errmsg output
        	if @rcode <> 0 goto ar_posting_error
   
      		/* need to delete items out of batch that were just added */
      		delete bARBL
      		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
    
    		end   --End Transtype A
   
   	if @transtype = 'C'	  --update existing AR Headers
   		/* Finance Charges are greatly dependent upon the conditions from which they were
   		   originally generated.  Therefore, only this limited set of header values
   		   will be allowed to be updated. - User should otherwise delete the transaction
   		   entirely. */
        	begin
         	update bARTH
          	set TransDate = b.TransDate, DueDate = b.DueDate, Description = b.Description,
    			Notes = b.Notes, UniqueAttchID = b.UniqueAttchID
   		from bARBH b with (nolock)
   		join bARTH h with (nolock) on h.ARCo = b.Co and h.Mth = b.Mth and h.ARTrans = b.ARTrans
          	where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq
   
         	if @@rowcount = 0 goto ar_posting_error
   
		/* first insert any new lines to this changed Header.
	   **** This will never occur for FCTypes 'A' or 'R'. Only FCType 'I' ***** */
  	   	insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
				Amount,	FinanceChg, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, DiscTaken,
			JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine, rptApplyMth, rptApplyTrans,
			MatlGroup, Material, INCo, Loc)
     	select Co, Mth, @artrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
				Amount,	FinanceChg, 0, 0, 0, 0, 0, 0, JCCo, Contract, Item,
			@appliedmth, @appliedtrans, ApplyLine, rptApplyMth, rptApplyTrans,
			MatlGroup, Material, INCo, Loc
	 	from bARBL with (nolock)
   		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and TransType='A' and
   				(isnull(Amount,0) <> 0 or isnull(TaxAmount,0) <> 0 or isnull(Retainage,0) <> 0
   				or isnull(DiscOffered,0) <> 0 or isnull(DiscTaken,0) <> 0 or isnull(FinanceChg,0) <> 0
   				or isnull(AddRetainage,0) <> 0)
   
         	/* update ARTrans in the batchtable for BatchUserMemoUpdate */
        	update bARBL
        	set ARTrans = @artrans
      	   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   			and TransType = 'A'
   
          	/* now update all the items that were changed */
         	update bARTL
        	set Description = b.Description, GLCo = b.GLCo, GLAcct = b.GLAcct,
    			Amount = b.Amount, FinanceChg = b.FinanceChg
    	  	from bARBL b with (nolock)
   		join bARTL l with (nolock) on l.ARCo=b.Co and l.Mth = b.Mth and l.ARTrans=b.ARTrans and l.ARLine=b.ARLine
    		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq
   			and b.TransType='C'
   
           /* call bspBatchUserMemoUpdate to update user memos in bARTL before deleting the batch record */
       	exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AR FinanceChargeDetail', @errmsg output
       	if @rcode <> 0 goto ar_posting_error
   
    	  	/* Finally delete individual lines that were marked as 'D' for this changed batch */
   		delete bARTL
   		from bARTL l with (nolock)
   		join bARBL b with (nolock) on b.Co = l.ARCo and b.Mth = l.Mth and b.ARTrans = l.ARTrans and b.ARLine = l.ARLine
   		where b.Co = @co and b.Mth = @mth and b.BatchId=@batchid and b.BatchSeq=@seq
   			and b.TransType = 'D'
   
      		/* need to delete items out of batch that were just added */
      		delete bARBL
      		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq 
   
       	end   --trans type C
   
    	if @transtype = 'D'	 --Delete header and lines if this header is marked as 'D'
           begin
    	    /* first delete all items */
    	   	delete bARTL where ARCo=@co and Mth = @mth and ARTrans=@artrans
   
    	    /* now delete the Header */
           delete bARTH where ARCo=@co and Mth = @mth and ARTrans=@artrans
   
      		/* need to delete items out of batch that were just added */
      		delete bARBL
      		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq 
   
       	end   --end transtype D
   
       /* call bspBatchUserMemoUpdate to update user memos in bARTH before deleting the batch record */
   	if @transtype in ('A', 'C')
   		begin
   		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AR FinanceCharge', @errmsg output
   		if @rcode <> 0 goto ar_posting_error
   		end
   
   	/* Everything has been processed. Now delete all from batch table for this
   	   Transaction/Seq Header */
   	delete bARBH where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and
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
   
    	goto ar_posting_loop	-- Get the next bARBH header transaction/Seq and process
   
   /* if error occurred within transaction - rollback any updates, deletes and inserts
      and exit the posting process. */
   ar_posting_error:
   	select @rcode = 1
    	rollback transaction
    	goto bspexit
   
   ar_posting_end:			--no more rows to process
   if @opencursor=1
    	begin
     	close bcARBH
     	deallocate bcARBH
      	select @opencursor=0
      	end
   
   /* make sure batch is empty */
   if exists(select 1 from bARBH with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
     	begin
      	select @errmsg = 'Not all AR header entries were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
   
   if exists(select 1 from bARBL with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
    	begin
     	select @errmsg = 'Not all AR item entries were posted - unable to close batch!', @rcode = 1
      	goto bspexit
    	end
   
   /**** update GL using entries from bARBA ****/
   exec @rcode=bspARBH1_PostGL @co,@mth,@batchid,@dateposted,@source,@source, @errmsg output
   if @rcode<>0 goto bspexit
   
   /**** update JC using entries from bARBI *****/
   -- exec @rcode = bspARBH1_PostJCContract @co, @mth, @batchid, @dateposted, @source, @errmsg output
   -- if @rcode <> 0 goto bspexit
   
   /**** delete HQ Close Control entries *****/
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
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
   
   /**** delete HQ Close Control entries *****/
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* set HQ Batch status to 5 (posted) */
   update bHQBC
   set Status = 5, DateClosed = getdate(),  Notes = convert(varchar(max),@Notes)
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   if @@rowcount = 0
     	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
   if @opencursor = 1
    	begin
    	close bcARBH
    	deallocate bcARBH
    	end
   
   if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBHPost_FC]'
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARBHPost_FC] TO [public]
GO
