SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMTBInsertExistingTrans    Script Date: 8/28/99 9:34:17 AM ******/
   
    CREATE   procedure [dbo].[bspCMTBInsertExistingTrans]
    /***********************************************************
     * CREATED BY: SE   8/20/96
     * MODIFIED By : SE 11/1/97
     *               MV 7/4/01 Issue 12967 BatchUserMemoInsertExisting
     *                TV 05/28/02 Insert @uniqueattchid into batch table.
	 *				 mh 7/14/06 - Recode issue 27561.  Should not be able to add a Transaction whose
	 *				 source does not match the batch source.
	 *				 mh 02/25/09 - Issue 132249.  Correct validation of source.  
     * USAGE:
     * This procedure is used by the CM Transfer program to pull existing
     * transactions from bCMTT into bCMTB for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bCMTT.
     * Makes sure the Transactions exist and haven't been cleared in CMDT
     * Adds entry to next available Seq# in bCMTB
     *
     * CMTB insert trigger will update InUseBatchId in bCMTT
     *
     * INPUT PARAMETERS
     *   CMCo         CM Co
     *   Mth          Month of batch to insert transaction into
     *   BatchID      BatchId Transaction should be put into
     *   TransfTrans  Transfer Transaction to be inserted.
     * OUTPUT PARAMETERS
     *   @msg     Error message if invalid,
     * RETURN VALUE
     *   0 Success
     *   1 fail
     *****************************************************/
   
		@co bCompany, @mth bMonth, @batchid bBatchID, @cmtrans bTrans, @errmsg varchar(255) output
   
    as
   
    set nocount on
   
	declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
	@fromcmco bCompany, @tocmco bCompany, @fromcmacct bCMAcct, @tocmacct bCMAcct,
	@fromcmtrans bTrans, @tocmtrans bTrans, @inusebatchid bBatchID, @seq int,
	@stmtdate bDate, @actdate bDate, @description bDesc, @amount bDollar, @cmref bCMRef,
	@uniqueattchid uniqueidentifier, @dtsource bSource 
   
   
    /* validate HQ Batch */
    select @source = Source, @tablename = TableName, @inuseby = InUseBy, @status = [Status]
    from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid

    if @@rowcount = 0
	begin
		select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
		goto bspexit
	end

    if @source <> 'CM Trnsfr'
	begin
		select @errmsg = 'Invalid Batch source - must be (CM Entry)!', @rcode = 1
		goto bspexit
	end

    if @tablename <> 'CMTB'
    begin
    	select @errmsg = 'Invalid Batch table name - must be (CMTB)!', @rcode = 1
    	goto bspexit
    end

    if @inuseby <> SUSER_SNAME()
   	begin
    	select @errmsg = 'Batch already in use by ' + @inuseby, @rcode = 1
    	goto bspexit
   	end

    if @status <> 0
   	begin
    	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
    	goto bspexit
   	end
 
--02/25/09 - Issue 132249...comment out the following code

--mh 7/14/06 - If The Source in CMTR for the transaction being pulled in does not match the source
--of this batch reject the add.  In other words, do not allow entry to be pulled into a transfern entry 
--batch.

--	select @dtsource = Source from bCMDT where CMCo = @co and Mth = @mth and CMTrans = @cmtrans  
--
--	if @dtsource <> @source
--	begin
--		if @dtsource = 'CM Entry' and @source = 'CM Trnsfr'
--		begin		
--			select @errmsg = 'CM transaction source is CM Entry.  Transaction cannot be added to a CM Transfer batch.', @rcode = 1
--			goto bspexit
--		end
--	end
--end mh 7/14/06

--end 02/25/09 Issue 132249
   
	/* validate existing CM Transfer Trans */
	select  @inusebatchid = InUseBatchId, @fromcmco = FromCMCo, @tocmco = ToCMCo,
	@fromcmacct = FromCMAcct, @tocmacct = ToCMAcct,	@fromcmtrans = FromCMTrans, @tocmtrans = ToCMTrans,
	@amount = Amount, @cmref = CMRef, @actdate = ActDate, @description = [Description], @uniqueattchid = UniqueAttchID 
	from bCMTT where CMCo = @co and Mth = @mth and CMTransferTrans = @cmtrans

	if @@rowcount = 0
	begin
		select @errmsg = 'CM transfer #' + convert(varchar(6),@cmtrans) + ' not found!', @rcode = 1
		goto bspexit
	end

	--Begin 132249	  
	--Check From CM Trans
	if (select Source from bCMDT where CMCo = @co and Mth = @mth and CMTrans = @fromcmtrans) = 'CM Entry' and @source = 'CM Trnsfr'
	begin
		select @errmsg = 'CM transaction source is CM Entry.  Transaction cannot be added to a CM Transfer batch.', @rcode = 1
		goto bspexit
	end

	--Check To CM Trans
	if (select Source from bCMDT where CMCo = @co and Mth = @mth and CMTrans = @tocmtrans) = 'CM Entry' and @source = 'CM Trnsfr'
	begin
		select @errmsg = 'CM transaction source is CM Entry.  Transaction cannot be added to a CM Transfer batch.', @rcode = 1
		goto bspexit
	end
	--End 132249

    if @inusebatchid is not null
	begin
		select @source=Source
		from HQBC
		where Co=@co and BatchId=@inusebatchid and Mth=@mth

	    if @@rowcount<>0
	    begin
			select @errmsg = 'Transaction already in use by ' +
		    convert(varchar(2),DATEPART(month, @mth)) + '/' +
		    substring(convert(varchar(4),DATEPART(year, @mth)),3,4) +
			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1

			goto bspexit
	    end
	    else
	    begin
			select @errmsg='Transaction already in use by another batch!', @rcode=1
			goto bspexit
	    end
	end
   
    /* check transfer 'from' bCMDT entry */
	select @stmtdate=StmtDate from bCMDT where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans
    if @@rowcount <> 1
    begin
    	select @errmsg = 'Missing transfer (from) transaction ' + convert(varchar(6), @fromcmtrans), @rcode = 1
   	 	goto bspexit
   	end
   
   
    if @stmtdate is not null
    begin
    	select @errmsg = 'The transfer (from) transaction has been cleared on a Statement dated '
				+ convert(varchar(12),@stmtdate, 1), @rcode = 1
    	goto bspexit
    end
  
    /* check transfer 'to' bCMDT entry */
    select @stmtdate=StmtDate from bCMDT where CMCo = @tocmco and Mth = @mth and CMTrans = @tocmtrans
   
    if @@rowcount <> 1
    begin
    	select @errmsg = 'Missing transfer (to) transaction ' + convert(varchar(6), @tocmtrans), @rcode = 1
    	goto bspexit
    end

    if @stmtdate is not null
   	begin
    	select @errmsg = 'The transfer (to) transaction has been cleared on a Statement dated '
    		+ convert(varchar(12),@stmtdate, 1), @rcode = 1
    	goto bspexit
   	end
   
    /* checks out OK - get next available sequence # for this batch */
    select @seq = isnull(max(BatchSeq),0) + 1 from bCMTB
    	where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* add CM transaction to batch */
    insert into bCMTB (Co, Mth, BatchId, BatchSeq, BatchTransType, CMTransferTrans,
            FromCMCo, FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans,
            CMRef, Amount, ActDate, Description,
            OldFromCMAcct, OldToCMAcct, OldActDate, OldAmount, OldCMRef, OldDesc, UniqueAttchID )
    values (@co, @mth, @batchid, @seq, 'C', @cmtrans,
            @fromcmco, @fromcmacct, @fromcmtrans, @tocmco, @tocmacct, @tocmtrans,
            @cmref, @amount, @actdate, @description,
            @fromcmacct, @tocmacct, @actdate, @amount, @cmref, @description, @uniqueattchid )
    if @@rowcount <> 1
   	begin
    	select @errmsg = 'Unable to add entry to CM Transfer Batch!', @rcode = 1
    	goto bspexit
   	end
   
     /* BatchUserMemoInsertExisting - update the user memo in the batch record */
	exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'CM Trans', 0, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = 'Unable to update User Memos in CMTB', @rcode = 1
		goto bspexit
	end
   
    select @rcode = 0, @errmsg = 'Successful'
   
bspexit:

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMTBInsertExistingTrans] TO [public]
GO
