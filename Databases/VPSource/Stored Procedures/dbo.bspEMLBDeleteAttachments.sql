SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMLBDeleteAttachments    Script Date: 8/28/99 9:34:28 AM ******/
CREATE procedure [dbo].[bspEMLBDeleteAttachments]
/***********************************************************
* CREATED BY: 	 bc 06/08/99
* MODIFIED By : TV 02/11/04 - 23061 added isnulls
*		TJL 01/23/07 - Issue #27822, 6x Rewrite.  Return attachments deleted count	
*
* USAGE:  deletes all the attachments for a given piece of deleted equipment
*	       designed for location transfers
*
*
*
* INPUT PARAMETERS
*   EMCo        EM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   Equipment
*   Revenue Code
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@emco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @attachdeletecount int output, @msg varchar(255) output
as
set nocount on
declare @rcode int
   
select @rcode = 0, @attachdeletecount = 0
   
/* delete all existing attachemnts in EMLB for this piece of equipment */
delete bEMLB where Co = @emco and Mth = @mth and BatchId = @batchid and AttachedToSeq = @seq
select @attachdeletecount = @@rowcount
   
bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMLBDeleteAttachments]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLBDeleteAttachments] TO [public]
GO
