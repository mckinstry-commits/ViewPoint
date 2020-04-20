SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPChkPrntPaymtCheck]
   /***********************************************************
    * CREATED BY: MV 02/15/06
    * MODIFIED By : 
    *
    * USAGE:
	* 1. sees if there are any payments in the batch and
    * 2. counts 'C'- check type payments for enabling reprint
	* 
    * returns two flags: for payments in the batch and the count of
    *	check type payments
    *
    * INPUT PARAMETERS
	*	@co	 AP company
	*	@mth batch month
	*	@batchid  batch id number
    *
    * OUTPUT PARAMETERS
    *	@paymentsyn	payments exist in this batch
	*	@count	count of check type payments
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
(@co bCompany ,@batchmth bMonth,@batchid int, @paymentsyn varchar(1) output,
	@count int output, @msg varchar(255)=null output)
  
  as
  set nocount on
  declare @rcode int, @paycount int
  select @rcode = 0, @paymentsyn = 'N',@paycount = 0,@count=0

  /* check required input params */
  if @co is null
  	begin
  	select @co = 'Missing Company.', @rcode = 1
  	goto bspexit
  	end
  
  if @batchmth is null
  	begin
  	select @msg = 'Missing Batch Month.', @rcode = 1
  	goto bspexit
  	end

 if @batchid is null
  	begin
  	select @msg = 'Missing Batch Id.', @rcode = 1
  	goto bspexit
  	end
  
 
-- check if payments exist in this batch
  select  @paycount = count(*) from APPB with (nolock) where Co=@co and Mth= @batchmth and BatchId= @batchid
	if isnull(@paycount,0) > 0 select @paymentsyn = 'Y'
-- if there are payments get count of check type payments
  if @paymentsyn = 'Y'
	begin
		select  @count = count(*) from APPB with (nolock) where Co=@co and Mth= @batchmth and BatchId= @batchid and PayMethod='C'
	end
		
	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPChkPrntPaymtCheck] TO [public]
GO
