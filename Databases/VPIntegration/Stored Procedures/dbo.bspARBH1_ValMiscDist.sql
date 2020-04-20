SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_ValMiscDist    Script Date: 8/28/99 9:34:07 AM ******/
   CREATE proc [dbo].[bspARBH1_ValMiscDist]
   /***********************************************************
    * CREATED BY: 	 JRE
    * MODIFIED By : CJW
    *
    * USAGE:
    * Validates each entry in bARBM for a selected batch - must be called 
    * prior to posting the batch. Called by Invoice Val and Posting Val
    *
    * INPUT PARAMETERS
    *   co        AR Co 
    *   mth       Month of batch
    *   batchid    Batch ID to validate                
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/ 
   @co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output 
   as
   
   set nocount on
   
   declare @MiscDistCode char(10), @CustGroup bGroup, @BatchSeq int, @rcode int,
           @errorstart varchar(50),@errortext varchar(255)
   
   select @rcode=0
   
   /* get first Cust Group */
   select @CustGroup=min(CustGroup) from bARBM
            where Co=@co and Mth=@mth and BatchId=@batchid
   WHILE @CustGroup is not null
   /* get first MiscDist Code */
   
   	BEGIN
   	select @MiscDistCode=min(MiscDistCode) from bARBM
            where Co=@co and Mth=@mth and BatchId=@batchid and CustGroup=@CustGroup
           WHILE @MiscDistCode is not null
   
              BEGIN
   	   select @BatchSeq=min(BatchSeq) from bARBM
              where Co=@co and Mth=@mth and BatchId=@batchid and CustGroup=@CustGroup
                           and MiscDistCode=@MiscDistCode
              WHILE @BatchSeq is not null
   
                 BEGIN
                 select @errorstart = 'Seq# ' + convert(varchar(6),@BatchSeq)
   	     /* Validate Dist Code*/
                exec @rcode = bspARMiscDistCodeVal @CustGroup, @MiscDistCode, @errmsg output
   		     if @rcode <> 0
   		        begin
   			  select @errortext = @errorstart + ' - Misc Dist Code :' + isnull(@MiscDistCode,'') +', ' +  isnull(@errmsg,'')
   	   	          exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		          if @rcode <> 0 goto bspexit  /* couldnt write error */
   		        end
   
               /* get next BatchSeq*/
               select @BatchSeq =min(BatchSeq) from bARBM
                where Co =@co and Mth = @mth and BatchId = @batchid and CustGroup=@CustGroup
                  and MiscDistCode=@MiscDistCode and BatchSeq>@BatchSeq
             END
   
   	  /* get next Misc Dist Code */
   	  select @MiscDistCode =min(MiscDistCode) from bARBM
                where Co =@co and Mth = @mth and BatchId = @batchid and CustGroup=@CustGroup
                and MiscDistCode>@MiscDistCode
         END
   
   
         /* get next Cust Group */
         select @CustGroup=min(CustGroup) from bARBM
            where Co=@co and Mth=@mth and BatchId=@batchid and CustGroup>@CustGroup
   
   end /* ARBM LOOP*/
   
   bspexit:
   	if @rcode <> 0 select @errmsg = @errmsg			--+ char(13) + char(10) + '[bspARBH1_ValMiscDist]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_ValMiscDist] TO [public]
GO
