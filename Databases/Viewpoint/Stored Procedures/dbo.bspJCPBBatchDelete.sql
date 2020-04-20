SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPBBatchDelete    Script Date: 8/28/99 9:33:00 AM ******/
   CREATE proc [dbo].[bspJCPBBatchDelete]
   /***********************************************************
    * CREATED BY: 	LM   04/14/97
    * MODIFIED By : TV - 23061 added isnulls
	*				GF 04/02/2009 - issue #129898
	*
    *
    * USAGE:
    * 	Deletes records in JC Projections Batch and sets batch status to 6.
    *
    *
    * INPUT PARAMETERS
    *   JCCo, Month, BatchId, error msg
    *    
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Phase
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@jcco bCompany, @mth bMonth, @batchid bBatchID, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   set @rcode = 0
   
   
---- clear bJCPB and bJCPD
delete bJCPD where Co=@jcco and Mth=@mth and BatchId=@batchid

delete bJCPB where Co=@jcco and Mth=@mth and BatchId=@batchid


-- -- -- verify all records deleted for batch
if exists(select 1 from bJCPB with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid)
	begin
	select @msg = 'Error occurred clearing records from batch.', @rcode = 1
	goto bspexit
	end

-- -- -- update batch status
update bHQBC set Status=6 
where Co=@jcco and Mth=@mth and BatchId=@batchid
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPBBatchDelete] TO [public]
GO
