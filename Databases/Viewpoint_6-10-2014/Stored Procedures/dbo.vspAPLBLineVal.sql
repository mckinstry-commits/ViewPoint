SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE    proc [dbo].[vspAPLBLineVal]
   /***************************************************
   * CREATED BY    : MV 11/01/06
   *
   * Usage:
   *   Returns Detail description for display in Line label
   *
   * Input:
   *	@co         
   *    @mth
   *	@batchid      
   *	@seq
   *    @line
   * Output:
   *   @msg          header description
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @seq int = null,
       @line int = null, @msg varchar(60) output)
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

	if @line is null
   	begin
   		goto bspexit
   	end

	begin
		select @msg = Description from APLB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and APLine=@line
	end   

   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPLBLineVal] TO [public]
GO
