SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMDBInsertExistingTrans    Script Date: 8/28/99 9:34:16 AM ******/
/*
* DROP PROC dbo.bspGLDBInsertExistingTrans
*/

CREATE   procedure [dbo].[bspCMDBInsertExistingTrans]
/***********************************************************
* CREATED BY:	SE  08/20/1996
* MODIFIED By:	GG	12/02/1997
*				MV	07/04/2001 - Issue 12769 BatchUserMemoInsertExisting
*				TV	05/28/2002 - Pass back @uniqueattchid to batch table
*				mh	07/14/2006 - Recode issue 27561.  Should not be able to add a Transaction whose
*				 source does not match the batch source.
*				CHS	04/22/2011	- B-03437 add TaxCode
* 
* USAGE:
* This procedure is used by the CM Post Outstanding entries to pull existing
* transactions from bCMDT into bCMDB for editing.
*
* Checks batch info in bHQBC, and transaction info in bCMDT.
* Adds entry to next available Seq# in bCMDB
*
* CMDB insert trigger will update InUseBatchId in bCMDT
*
* INPUT PARAMETERS
*   CMCo       CM Co to Validate
*   Mth        Month of batch
*   BatchId    Batch ID to insert transaction into
*   CMDTTrans  CM Detail transaction to add to batch.
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/

@co bCompany, @mth bMonth, @batchid bBatchID,
    	@cmtrans bTrans, @errmsg varchar(255) output
   
    as
   
    set nocount on
   
    declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
    	@dtsource bSource, @cmacct bCMAcct, @inusebatchid bBatchID, @seq int,
    	@cmtranstype bCMTransType, @actdate bDate, @stmtdate bDate,
        @description bDesc, @amount bDollar, @cmref bCMRef, @cmrefseq tinyint, @payee varchar(20),
    	@glco bCompany, @cmglacct bGLAcct, @glacct bGLAcct, @void bYN, @uniqueattchid Uniqueidentifier,
    	@TaxGroup bGroup, @TaxCode bTaxCode, @OldTaxGroup bGroup, @OldTaxCode bTaxCode
   
    select @rcode = 0
   
    /* validate HQ Batch */
    select @source = Source, @tablename = TableName, @inuseby = InUseBy,
    	@status = Status
    	from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
    	goto bspexit
    	end
    if @source <> 'CM Entry'
    	begin
    	select @errmsg = 'Invalid Batch source - must be (CM Entry)!', @rcode = 1
    	goto bspexit
    	end
    if @tablename <> 'CMDB'
    	begin
    	select @errmsg = 'Invalid Batch table name - must be (CMDB)!', @rcode = 1
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
   
    /* validate existing CM Trans */
   
    select  @dtsource = Source, @inusebatchid = InUseBatchId,
            @cmacct = CMAcct, @cmtranstype = CMTransType, @actdate = ActDate, @stmtdate = StmtDate,
            @description = Description, @amount = Amount, @cmref = CMRef, @cmrefseq = CMRefSeq,
            @payee = Payee, @glco = GLCo, @cmglacct = CMGLAcct, @glacct = GLAcct, @void = Void, 
            @uniqueattchid = UniqueAttchID, @TaxGroup = TaxGroup, @TaxCode = TaxCode
    	from bCMDT where CMCo = @co and Mth = @mth and CMTrans = @cmtrans
    if @@rowcount = 0
    	begin
    	select @errmsg = 'CM transaction #' + convert(varchar(6),@cmtrans) + ' not found!', @rcode = 1
    	goto bspexit
    	end

--mh 7/14/06 - If The Source in CMDT for the transaction being pulled in does not match the source
--of this batch reject the add.  In other words, do not allow transfers to be pulled into an entry 
--batch.
	if @dtsource <> @source
	begin
		if @dtsource = 'CM Trnsfr' and @source = 'CM Entry'
		begin
			select @errmsg = 'CM Transaction source is CM Transfer.  Transaction cannot be added to a CM Entry batch.', @rcode = 1
			goto bspexit
		end
	end
--end mh 7/14/06

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
    if substring(@dtsource,1,2) <> 'CM'
    	begin
    	select @errmsg = 'This CM transaction was created with a ' + @dtsource + ' source!', @rcode = 1
    	goto bspexit
    	end
    if @stmtdate is not null
    	begin
    	select @errmsg = 'This transaction has been cleared.  You must unclear it before you can edit it.', @rcode = 1
    	goto bspexit
    	end
   
    /* get next available sequence # for this batch */
    select @seq = isnull(max(BatchSeq),0)+1 from bCMDB where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* add CM transaction to batch */
    insert into bCMDB (Co, Mth, BatchId, BatchSeq, BatchTransType, CMTrans, CMAcct, CMTransType,
    	ActDate, Description, Amount, CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, GLAcct, Void,
            OldCMAcct, OldActDate, OldDesc, OldAmount, OldCMRef, OldCMRefSeq, OldPayee,
            OldGLCo, OldCMGLAcct, OldGLAcct, OldVoid, UniqueAttchID,
            TaxGroup, TaxCode, OldTaxGroup, OldTaxCode)
    values (@co, @mth, @batchid, @seq, 'C', @cmtrans, @cmacct, @cmtranstype, @actdate,
            @description, @amount, @cmref, @cmrefseq, @payee, @glco, @cmglacct, @glacct, @void,
            @cmacct, @actdate, @description, @amount, @cmref, @cmrefseq, @payee, @glco, @cmglacct,
            @glacct, @void, @uniqueattchid, @TaxGroup, @TaxCode, @TaxGroup, @TaxCode)
    if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to add entry to CM Detail Batch!', @rcode = 1
    	goto bspexit
    	end
   
    /* BatchUserMemoInsertExisting - update the user memo in the batch record */
       exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'CM Post',
            0, @errmsg output
            if @rcode <> 0
            begin
              select @errmsg = 'Unable to update User Memos in CMDB', @rcode = 1
              goto bspexit
              end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMDBInsertExistingTrans] TO [public]
GO
