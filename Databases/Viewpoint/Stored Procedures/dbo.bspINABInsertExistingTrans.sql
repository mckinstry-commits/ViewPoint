SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINABInsertExistingTrans]
    /***********************************************************
     * CREATED BY: GR 12/10/99
     * Modified: GG 3/14/00
     *           MV 7/3/01 - Issue 12769 BatchUserMemoInsertExisting
     *           RM 09/07/01 - Added Source 'IN Count'
     *           RM 09/13/01 - Removed Source 'IN Count'
     *           TV 05/29/02 - insert UniqueAttchID into Batch table
     *
     * USAGE:
     * This procedure is used by the IN Adjustments program to pull existing
     * transactions from bINDT for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bINAB
     *
     *
     * INPUT PARAMETERS
   
     *   Co         IN Company
     *   Mth        Month of batch
     *   BatchId    Batch ID to insert transaction into
     *   INTrans    IN Transaction to pull
     *
     * OUTPUT PARAMETERS
   
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    (@co bCompany, @mth bMonth, @batchid bBatchID,
    @intrans bTrans, @errmsg varchar(200) output)
    as
    set nocount on
    declare @rcode int, @inuseby bVPUserName, @status tinyint,
    @dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @batchseq int,
    @errtext varchar(60), @source bSource
    select @rcode = 0
    --validate HQ Batch
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'IN Adj', 'INAB', @errtext output, @status output
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
    --all adjustments can be pulled into a batch as long as it's InUseFlag is set to null*/
    select @inusebatchid = InUseBatchId
    from bINDT where INCo=@co and Mth=@mth and INTrans=@intrans
    if @@rowcount = 0
    	begin
    	select @errmsg = 'The IN Tranasction :' + convert(varchar(6),@intrans) + ' cannot be found.' , @rcode = 1
    	goto bspexit
    	end
    if @inusebatchid is not null
    	begin
        select @source=Source from HQBC
        where Co=@co and BatchId=@inusebatchid  and Mth=@mth
   
       select @errmsg = 'Transaction already in use by ' +
    	    substring(convert(varchar(3), @mth), 1, 3) +
    		substring(convert(varchar(8), @mth), 7 ,2) +
    		' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
    	    goto bspexit
        end
   
    --get next available sequence # for this batch
    select @batchseq = isnull(max(BatchSeq),0)+1 from bINAB
    where Co = @co and Mth = @mth and BatchId = @batchid
   
    --add Transaction to batch
    insert into bINAB (Co, Mth, BatchId, BatchSeq, BatchTransType, INTrans, Loc, MatlGroup,
        Material, ActDate, Description, GLCo, GLAcct, UM, Units, UnitCost, ECM, TotalCost,
        OldLoc, OldMaterial, OldActDate, OldDescription, OldGLAcct, OldUnits, OldUnitCost,
        OldECM, OldTotalCost, UniqueAttchID)
    select INCo, @mth, @batchid, @batchseq, 'C', INTrans, Loc, MatlGroup, Material,
        ActDate, Description, GLCo, GLAcct, StkUM, StkUnits, StkUnitCost, StkECM,
        StkTotalCost , Loc, Material, ActDate, Description, GLAcct, StkUnits, StkUnitCost,
        StkECM, StkTotalCost, UniqueAttchID
    from bINDT
    where INCo = @co and Mth = @mth and INTrans = @intrans
   
    /* BatchUserMemoInsertExisting - update the user memo in the batch record */
       exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @batchseq, 'IN Adjustments',
            0, @errmsg output
            if @rcode <> 0
            begin
              select @errmsg = 'Unable to update User Memos in INAB', @rcode = 1
              goto bspexit
              end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINABInsertExistingTrans] TO [public]
GO
