SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspJCIBInsertExistingTrans]
    /***********************************************************
     * CREATED BY: DANF 01/17/2000
     *             DANF 03/22/2001
     *             MV   07/05/01 - Issue 12769 BatchUserMemoInsertExisting
     *             DANF 04/11/02 - Added Restriction to not allow inter company posting to be inserted into a batch.
     *             TV 05/29/02 - Insert @uniqueattchid into batch table
     *			   GF 06/09/2003 - issue #21405 - do not allow JCTransType='RU' to be pulled in.
     *			   TV - 23061 added isnulls
     *			   DANF 05/30/06 - Recode - Added validation to inhabit usere from pulling reversals back into a batch.
     *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
     * USAGE:
     * This procedure is used by the JC Revenue entries to pull existing
     * transactions from bJCID into bJCIB for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bJCID.
     * Adds entry to next available Seq# in bJCIB
     *
     * JCIB insert trigger will update InUseBatchId in bJCID
     *
     * INPUT PARAMETERS
     *   Co         JC Co to pull from
     *   Mth        Month of batch
     *   BatchId    Batch ID to insert transaction into
     *   ItemTrans  JCID Detail transaction to add to batch.
     * OUTPUT PARAMETERS
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    @co bCompany,
    @mth bMonth,
    @batchid bBatchID,
    @Itemtrans bTrans,
    @errmsg varchar(200) OUTPUT
AS
    SET NOCOUNT ON
    --#142350 - renaming @itemtrans
    DECLARE @rcode int,
			@inuseby bVPUserName,
			@status tinyint,
			@source bSource,
			@inusebatchid bBatchID,
			@seq int,
			@errtext varchar(60),
			@ItmTrans bTrans,
			@transsource varchar(10),
			@contract bContract,
			@item bContractItem,
			@jctranstype varchar(2),
			@description bTransDesc,
			@posteddate smalldatetime,
			@actualdate smalldatetime,
			@contractamt bDollar,
			@contractunits bUnits,
			@unitprice bUnitCost,
			@billedunits bUnits,
			@billedamt bDollar,
			@receivedamt bDollar,
			@currentretainamt bDollar,
			@acojob bJob,
			@ACO bACO,
			@acoitem bACOItem,
			@glco bCompany,
			@gltransacct bGLAcct,
			@gloffsetacct bGLAcct,
			@reversalstatus tinyint,
			@arco bCompany,
			@artrans int,
			@artransline tinyint,
			@arinvoice varchar(10),
			@archeck varchar(10),
			@billedtax bDollar,
			@OrigMth bMonth,
			@OrigItemTrans bTrans,
			@uniqueattchid uniqueidentifier

    select @rcode = 0
   
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC RevAdj', 'JCIB', @errtext output, @status output
    if @rcode <> 0
    	begin
        	select @errmsg = @errtext, @rcode = 1
        	goto bspexit
       	end
   
   
    if @status <> 0
    	begin
    	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
    	goto bspexit
    	end
   
    /* validate existing JCID Trans */
   
    select  @transsource=TransSource, @inusebatchid=InUseBatchId,
              @contract=Contract, @item=Item, @jctranstype=JCTransType,
              @description=Description, @posteddate=PostedDate, @actualdate=ActualDate, @contractamt=ContractAmt,
    	      @contractunits=ContractUnits, @unitprice=UnitPrice, @billedunits=BilledUnits,
    	      @billedamt=BilledAmt, @receivedamt=ReceivedAmt, @currentretainamt=CurrentRetainAmt,
    	      @acojob=ACOJob, @ACO=ACO, @acoitem=ACOItem, @glco=GLCo, @gltransacct=GLTransAcct,
    	      @gloffsetacct=GLOffsetAcct, @reversalstatus=ReversalStatus, @arco=ARCo,
    	      @artrans=ARTrans, @artransline=ARTransLine, @arinvoice=ARInvoice, @archeck=ARCheck, @billedtax=BilledTax,
                  @arco = ARCo, @arinvoice = ARInvoice, @archeck = ARCheck, @uniqueattchid = UniqueAttchID
   
    	from bJCID where JCCo=@co and Mth=@mth and ItemTrans = @Itemtrans
   
    if @@rowcount = 0
    	begin
    	select @errmsg = 'JC transaction #' + isnull(convert(varchar(6),@ItmTrans),'') + ' not found!', @rcode = 1
    	goto bspexit
    	end
    if @inusebatchid is not null
    	begin
    	select @source=Source
    	       from HQBC
    	       where Co=@co and BatchId=@inusebatchid and Mth=@mth
    	    if @@rowcount<>0
    	       begin
    		select @errmsg = 'Transaction already in use by ' +
    		      isnull(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
    		      isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
    			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@source,''), @rcode = 1
   
    		goto bspexit
    	       end
    	    else
    	       begin
    		select @errmsg='Transaction already in use by another batch!', @rcode=1
    		goto bspexit
    	       end
    	end
   
    if @transsource <> 'JC RevAdj'
    	begin
    	select @errmsg = 'This JC transaction was created with a ' + isnull(@transsource,'') + ' source!', @rcode = 1
    	goto bspexit
    	end
   
    if @jctranstype = 'IC'
    	begin
    	select @errmsg = 'This is a Inter Company transaction which cannot be edited!', @rcode = 1
    	goto bspexit
    	end
   
    if @jctranstype = 'RU'
   	begin
   	select @errmsg = 'This is a JC Roll up transaction which cannot be edited!', @rcode = 1
    	goto bspexit
    	end

    /*validate Reversal Status, cannot be 2, 3, 4 as we do not store the Orig month and transaction to be changed */
   /************************************* 
       '0=no action
       '1=Transaction is to be reversed.
       '2=Reversal Transaction.
       '3=original Transaction Reversed.
       '4=reversal canceld
   *************************************/ 
    if @reversalstatus in (2,3,4)
      begin
      select @rcode = 1
      If @reversalstatus = 2 select @errmsg = 'Reversal Transactions cannot be changed or deleted. -  reversal status:' + isnull(convert(varchar(1),@reversalstatus),'')
      If @reversalstatus = 3 select @errmsg = 'Transactions has been Reversed cannot be changed or deleted. -  reversal status:' + isnull(convert(varchar(1),@reversalstatus),'')
      If @reversalstatus = 4 select @errmsg = 'Canceled Reversal Transactions cannot be changed or deleted. -  reversal status:' + isnull(convert(varchar(1),@reversalstatus),'')
      goto bspexit
      end
   
    /* get next available sequence # for this batch */
    select @seq = isnull(max(BatchSeq),0)+1 from bJCIB where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* add JC item transaction to batch */
    insert into bJCIB (Co, Mth, BatchId, BatchSeq, TransType, ItemTrans, Contract,
                       Item, ActDate, JCTransType, Description, GLCo, GLTransAcct,
                       GLOffsetAcct, ReversalStatus, OrigMth, OrigItemTrans, BilledUnits,
                       BilledAmt,
                       OldContract, OldItem, OldActDate, OldJCTransType,
                       OldDescription, OldGLCo, OldGLTransAcct, OldGLOffsetAcct,
                       OldReversalStatus, OldBilledUnits, OldBilledAmt,
                       ARCo, OldARCo, ARInvoice, OldARInvoice, ARCheck, OldARCheck, ToJCCo,
                       UniqueAttchID)
    values (@co, @mth, @batchid, @seq, 'C', @Itemtrans, @contract,
            @item, @actualdate, @jctranstype, @description, @glco, @gltransacct,
            @gloffsetacct, @reversalstatus, @OrigMth, @OrigItemTrans, @billedunits,
            @billedamt,
            @contract,
            @item, @actualdate, @jctranstype, @description, @glco, @gltransacct,
            @gloffsetacct, @reversalstatus, @billedunits,
            @billedamt,
            @arco, @arco, @arinvoice, @arinvoice, @archeck, @archeck, @co, @uniqueattchid )
   
    if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to add entry to JC Reveune Adjustment Batch!', @rcode = 1
    	goto bspexit
    	end
   
       /* BatchUserMemoInsertExisting - update the user memo in the batch record */
       exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'JC AdjRev',
            0, @errmsg output
            if @rcode <> 0
            begin
              select @errmsg = 'Unable to update User Memos in JCIB', @rcode = 1
              goto bspexit
              end
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCIBInsertExistingTrans] TO [public]
GO
