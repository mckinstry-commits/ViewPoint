SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINIBInsertExistingTrans    Script Date: 12/17/2003 7:50:24 AM ******/
   
   
   
   CREATE     procedure [dbo].[bspINIBInsertExistingTrans]
    /***********************************************************
     * CREATED BY: RM 06/04/02
     * MODIFIED By : 
     *
     * USAGE:
     * This procedure is used by the IN MO Entry program to pull existing
     * transactions from bINMI into bINIB for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bINMI.
     * Adds entry to the Item that it is in bINMI for the seq passed in
     *
     * bINIB insert trigger will update InUseBatchId in bINMI
     *
     * INPUT PARAMETERS
     *   Co         JC Co to pull from
     *   Mth        Month of batch
     *   BatchId    Batch ID to insert transaction into
     *   MO         MO to pull
     *   Item       Item to pull
     *   Seq        Seq to put item under
     * OUTPUT PARAMETERS
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *   3   not found  if no errors but just not available
     *****************************************************/
    
    	@co bCompany, @mth bMonth, @batchid bBatchID,
    	@mo bMO, @item bItem, @seq int, @errmsg varchar(200) output
    
    as
    set nocount on
    declare @rcode int, @inuseby bVPUserName, @status tinyint,
    	@dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @errtext varchar(60),
    	@source bSource
    
    
    select @rcode = 0
    
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MO Entry', 'INMB', @errtext output, @status output
    if @rcode <> 0
       begin
        select @errmsg = @errtext, @rcode = 1
        goto bspexit
       end
    
    if @status <> 0
       begin
        select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
        goto bspexit
       end
    
    /* all Subcontract's can be pulled into a batch as long as it's InUseFlag is set to null*/
    select @inusemth=InUseMth, @inusebatchid = InUseBatchId from dbo.INMO where INCo=@co and MO=@mo
    if @@rowcount = 0
    	begin
    	select @errmsg = 'The Material Order :' + isnull(@mo,'MISSING: @mo') + ' cannot be found.' , @rcode = 1
    	goto bspexit
    	end
    
    if @inusebatchid <> @batchid or @inusemth<>@mth
    	begin
    	select @source=Source
    	       from HQBC
    	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
    	    --if @@rowcount<>0
    	    if @source <> ''
    	       begin
    		select @errmsg = 'MO Transaction already in use by ' +
    		      convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
    		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
    			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
    
    		goto bspexit
    	       end
    	    else
    	       begin
    		select @errmsg='MO Transaction already in use by another batch!', @rcode=1
    		goto bspexit
    	       end
    	end
    
    /*Now make sure the Item is not flaged */
    select @inusemth=InUseMth, @inusebatchid = InUseBatchId from dbo.INMI where INCo=@co and MO=@mo and MOItem = @item
    if @@rowcount = 0
    	begin
    	select @errmsg = 'The Material Order item :' + convert(varchar(5),@item) + ' cannot be found.' , @rcode = 3

    	goto bspexit
    	end
    
    if not @inusemth is null
    	begin
    	select @errmsg = 'This Material Order item is already in use by Batch #' + convert(varchar(8),@inusebatchid), @rcode = 1
    	goto bspexit
    	end
    
    if not @inusebatchid is null
    	begin
    	select @errmsg = 'This Material Order item is already in use by Batch #' + convert(varchar(8),@inusebatchid), @rcode = 1
    	goto bspexit
    	end
    
    
   	Insert into bINIB(Co,Mth,BatchId,BatchSeq,MOItem,
   				BatchTransType,Loc,MatlGroup,Material,Description,
   				JCCo,Job,PhaseGroup,Phase,JCCType,
   				GLCo,GLAcct,ReqDate,UM,OrderedUnits,
   				UnitPrice,ECM,TotalPrice,TaxGroup,TaxCode,
   				TaxAmt,RemainUnits,OldLoc,OldMatlGroup,OldMaterial,
   				OldDesc,OldJCCo,OldJob,OldPhaseGroup,OldPhase,
   				OldJCCType,OldGLCo,OldGLAcct,OldReqDate,OldUM,
   				OldOrderedUnits,OldUnitPrice,OldECM,OldTotalPrice,OldTaxGroup,
   				OldTaxCode,OldTaxAmt,OldRemainUnits)
   	Select i.INCo,@mth,@batchid,@seq,i.MOItem,'C',i.Loc,i.MatlGroup,
   				i.Material,i.Description,i.JCCo,i.Job,i.PhaseGroup,
   				i.Phase,i.JCCType,i.GLCo,i.GLAcct,i.ReqDate,
   				i.UM,i.OrderedUnits,i.UnitPrice,i.ECM,i.TotalPrice,
   				i.TaxGroup,i.TaxCode,i.TaxAmt,i.RemainUnits,
   				i.Loc,i.MatlGroup,i.Material,i.Description,i.JCCo,
   				i.Job,i.PhaseGroup,i.Phase,i.JCCType,i.GLCo,i.GLAcct,
   				i.ReqDate,i.UM,i.OrderedUnits,i.UnitPrice,i.ECM,i.TotalPrice,
   				i.TaxGroup,i.TaxCode,i.TaxAmt,i.RemainUnits
   	from dbo.INMI i where INCo=@co and MO=@mo and MOItem=@item 
    
    if @@rowcount > 0
    begin	
    /* update user memo to INIB batch table- BatchUserMemoInsertExisting */
         exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'MO Entry Items',
             @item, @errmsg output
             if @rcode <> 0
             begin
        	 select @errmsg = 'Unable to update user memo to MO Entry Item Batch!', @rcode = 1
        	 goto bspexit
        	 end
        
    end
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINIBInsertExistingTrans] TO [public]
GO
