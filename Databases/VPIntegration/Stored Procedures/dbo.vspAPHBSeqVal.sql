SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE    proc [dbo].[vspAPHBSeqVal]
   /***************************************************
   * CREATED BY    : MV 11/01/06
   *
   * Usage:
   *   Returns Header description for display in header Seq label
   *
   * Input:
   *	@co         
   *    @mth
   *	@batchid      
   *	@seq
   * Output:
   *   @msg          header description
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @seq int = null,
       @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @co is null
   	begin
      	goto bspexit
   	end
 
   if @mth is null
   	begin
   		goto bspexit
   	end

	if @batchid is null
   	begin
   		goto bspexit
   	end

	if @seq is null
   	begin
   		goto bspexit
   	end

	begin
		select @msg = Description from APHB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	end   

   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPHBSeqVal] TO [public]
GO
