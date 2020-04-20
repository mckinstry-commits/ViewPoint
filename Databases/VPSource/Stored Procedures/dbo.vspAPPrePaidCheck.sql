SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPPrePaidCheck]
   	
   /***********************************************************
    * CREATED BY: MV   09/07/05
    * MODIFIED By : 
    *
    * USAGE:
    * checks for prepaids in the APEntry batch before posting.  Called
	* from APBatchProcressing form.
    *
    * INPUT PARAMETERS
    *   Co		batch company
	*	Mth		batch month
	*	BatchId	batch id
    *	
    * OUTPUT PARAMETERS
    *   @PrePaidYN		                     
	*
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@co int, @mth bMonth, @batchid int, @prepaidyn bYN output, @errmsg varchar(100) output) 
   as
   set nocount on
   
   	declare @rcode int
   	select @rcode = 0, @prepaidyn='N'
   
   if @co is null
   	begin
   	select @errmsg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   
   if @batchid is null
   	begin
   	select @errmsg = 'Missing Batch ID!', @rcode = 1
   	goto bspexit
   	end
   
   
  if exists (Select top 1 1 from APHB where Co = @co and Mth = @mth and BatchId = @batchid
		 and PrePaidYN = 'Y' and BatchTransType <> 'D')
	begin
	select @prepaidyn = 'Y'
	end
  
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPrePaidCheck] TO [public]
GO
