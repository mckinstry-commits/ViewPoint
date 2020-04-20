SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPPBatchDelete    Script Date: 8/28/99 9:35:04 AM ******/
CREATE  proc [dbo].[bspJCPPBatchDelete]
/***********************************************************
* CREATED BY: 	LM   04/14/97
* MODIFIED By : TV - 23061 added isnulls
*				GF - ISSUE #138718 added delete for JCPPPhases and JCPPCostTypes
*
*
* USAGE:
* 	Deletes records in JC Progress Entry Batch and sets batch status to 6.
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
(@jcco bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- delete batch table
delete bJCPP where Co=@jcco and Mth=@mth and BatchId=@batchid

----#138718
---- delete progress batch phases
delete dbo.bJCPPPhases where Co=@jcco and Month = @mth and BatchId=@batchid

---- delte linked batch cost types
delete dbo.bJCPPCostTypes where Co=@jcco and Mth = @mth and BatchId=@batchid
----#138718

---- update batch status
update bHQBC set Status=6
where Co=@jcco and Mth=@mth and BatchId=@batchid




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPPBatchDelete] TO [public]
GO
