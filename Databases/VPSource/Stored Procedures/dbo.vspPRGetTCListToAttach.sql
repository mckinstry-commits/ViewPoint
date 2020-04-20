SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRGetTCListToAttach]
/*************************************
* Created: EN 09/21/07
* Modified:
* 
* Returns a list of KeyID's for timecards in a given batch that have no attachments
*
* Input:
*	@prco			PR Company
*	@mth			Batch Month
*	@batchid		Batch ID
*
* Output:
*	resultset containing keystrings
*
**************************************/
(@prco bCompany, @mth bMonth, @batchid bBatchID)

as 
set nocount on
 
select KeyID from dbo.bPRTB (nolock)
where Co = @prco and Mth = @mth and BatchId = @batchid and UniqueAttchID is null


vspexit:
  	return

GO
GRANT EXECUTE ON  [dbo].[vspPRGetTCListToAttach] TO [public]
GO
