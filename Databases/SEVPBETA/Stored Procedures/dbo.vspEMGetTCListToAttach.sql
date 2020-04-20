SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMGetTCListToAttach]
/*************************************
* Created:	GP 09/08/2008
* Modified:
* 
* Returns a list of KeyID's for timecards in a given batch that have no attachments
*
* Input:
*	@emco			EM Company
*	@mth			Batch Month
*	@batchid		Batch ID
*
* Output:
*	resultset containing keystrings
*
**************************************/
(@emco bCompany = null, @mth bMonth = null, @batchid bBatchID = null)

as 
set nocount on
 
select KeyID from bEMBF with (nolock)
where Co = @emco and Mth = @mth and BatchId = @batchid and UniqueAttchID is null


vspexit:
  	return

GO
GRANT EXECUTE ON  [dbo].[vspEMGetTCListToAttach] TO [public]
GO
