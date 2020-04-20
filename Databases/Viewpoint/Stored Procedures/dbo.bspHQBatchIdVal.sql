SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQBatchIdVal]
/******************************************
* Created: ??
* Modified: RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*
* Validates HQ Batch Id number
* pass in Company#, Month, and Batch Id
* returns error message if error
****************************************/
   (@hqco bCompany = 0, @mth bMonth = null, @batch bBatchID = 0, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   	
   if @hqco = 0
   	begin
   	select @msg = 'Missing HQ Company#!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Batch month!', @rcode = 1
   	goto bspexit
   	end
   
   if @batch = 0
   	begin
   	select @msg='Missing Batch Id number!', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select 1 from bHQBC with (nolock)
   	where Co = @hqco and @mth = Mth and @batch = BatchId)
   	goto bspexit
   else
   	begin
   	select @msg = 'Month ' + isnull(convert (char(8),@mth),'') + 'BatchId ' + isnull(convert(char(4),@batch),'') + ' Not a valid HQ Batch!', @rcode = 1
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBatchIdVal] TO [public]
GO
