SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCIDReversalsInit    Script Date: 8/28/99 9:35:02 AM ******/
   CREATE     procedure [dbo].[bspJCIDReversalsInit]
   /***********************************************************
    * CREATED BY: JM  11/10/97
    * MODIFIED By : JRE 8/10/98
    * MODIFIED By :  DANF  04/06/01 Corrected Billed units
    * 				 DANF 02/03/02 - 20124 Added To Company.
    *				TV - 23061 added isnulls
    *    		  DANF 03/15/05 - #27294 - Remove scrollable cursor.
	*			  DANF 05/24/06 - #30710 - Correct Error when Initializing more than 256 reversals.
    *
    * USAGE:
    * This procedure is used by the JC Post Outstanding entries to initialize
    * reversal transactions from bJCID into bJCIB for editing. 
    *
    * Checks batch info in bHQBC, and transaction info in bJCID.
    * Adds entry to next available Seq# in bJCIB
    *
    * Pulls transaction in the OrigMth that are marked 1(reversal), and aren't
    * already in a batch.
    *
    * JCIB insert trigger will update InUseBatchId in bJCID
    * 
    * INPUT PARAMETERS
    *   Co         JC Co to pull from
    *   Mth        Month of batch
    *   BatchId    Batch ID to insert transaction into 
    *   OrigMth    Original month to pull reversal transactions from
    *   TransDate  Transaction date to add new entries with
    *
    * OUTPUT PARAMETERS
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/ 
   
   	@co bCompany, @batchmth bMonth, @batchid bBatchID, 
   	@origmth bMonth, @transdate bDate, @errmsg varchar(200) output
   
   as
   set nocount on
   declare @batchseq int, 	@billedunits bUnits,@billedamt bDollar,	@contract bContract,
   	@cursoropen tinyint, @description bTransDesc, @errtext varchar(60),
   	@glco bCompany, @gloffsetacct bGLAcct, @gltransacct bGLAcct, @item bContractItem,
   	@itemtrans bTrans, @jctranstype varchar(2), @mth bMonth, @postedmth bMonth,
   	@numrows int, @rcode int, @status tinyint	
   	
   select @rcode = 0, @cursoropen = 0, @numrows = 0
   
   /* make sure that the original month is less than the reversal month */
   if @origmth >= @batchmth  
   	begin
   	select @errmsg = 'Original month must come before batch month!', @rcode = 1
   	goto error
   	end
   
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @batchmth, @batchid, 'JC RevAdj', 'JCIB', @errtext output, @status output
   if @rcode <> 0
   	begin
       	select @errmsg = @errtext, @rcode = 1
       	goto error
      	end
   
   if @status <> 0 
   	begin
   	select @errmsg = 'Invalid Batch status - must be (open)!', @rcode = 1
   	goto error
   	end
   
   /* use a cursor to get each available transaction and insert it*/
   declare bJCID_reversals cursor local fast_forward for select 
   	Contract, Item,	JCTransType, Description, GLCo,	GLTransAcct,
   	GLOffsetAcct, ItemTrans, BilledUnits, BilledAmt, Mth
   	
      from JCID where JCCo=@co and Mth<=@origmth and InUseBatchId is null 
            and TransSource = 'JC RevAdj' and ReversalStatus = 1
   
   open bJCID_reversals
   select @cursoropen = 1
   begin transaction reversals
   insert_loop:
   fetch next from bJCID_reversals into 
   	@contract, @item, @jctranstype, @description, @glco, @gltransacct,
     	@gloffsetacct, @itemtrans,@billedunits,	@billedamt, @postedmth
   
   	if @@fetch_status <> 0
   	   begin
   	     goto bspexit
   	   end
   
   /* get next available sequence # for this batch */
   select @batchseq = isnull(max(BatchSeq),0)+1 from bJCIB where Co = @co and Mth = @batchmth and BatchId = @batchid
   
   /*
    * add a new JC transaction to batch with same GLAccts but negative amt and reversataus of 2(Reversing)
   
    * all old values should be set to 0 and transaction should be setup as an add
    */
   insert into bJCIB (Co, Mth, BatchId, BatchSeq, TransType, ItemTrans, Contract, Item,
   	ActDate, JCTransType, Description, GLCo, GLTransAcct, GLOffsetAcct, 
   	ReversalStatus, OrigMth, OrigItemTrans, BilledUnits, BilledAmt, ToJCCo)
   values (@co, @batchmth, @batchid, @batchseq, 'A', null, @contract, @item, @transdate, 
           @jctranstype, @description, @glco, @gltransacct, @gloffsetacct, 2, 
           @postedmth, @itemtrans, (-1*@billedunits), (-1*@billedamt), @co)
   
   select @numrows = @numrows + @@rowcount
    goto insert_loop
   
   bspexit:
   if @cursoropen =1
   	begin
   	close bJCID_reversals
   	deallocate bJCID_reversals
   	commit transaction reversals
   	end
   
   select @rcode = 0, @errmsg = isnull(convert(varchar(10), @numrows),'') + ' entries reversed!'
   return @rcode
   
   error:
   if @cursoropen =1
   	begin
   	close bJCID_reversals
   	deallocate bJCID_reversals
   	rollback transaction reversals
   	end
       
   select @errmsg = @errmsg + ' - reversals not initialized.'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCIDReversalsInit] TO [public]
GO
