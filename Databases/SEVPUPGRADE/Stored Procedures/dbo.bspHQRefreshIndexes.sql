SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     Procedure [dbo].[bspHQRefreshIndexes]
 /*************************************************
 * Created: 10/04/01 - RM
 * Modified: 10/03/02 - RM  Added Distinct into cursor to speed up processing.
 *			GG 10/03/02 - cleanup, removed join with bHQAI
 *			RM 03/26/04 - Issue# 23061 - Added IsNulls
 *			RM 09/21/05 - #29828 - added (nolock)
 *			DANF 07/31/07 - changed reference from bspHQCreateIndex to vspHQCreateIndex
 *
 *
 * Usage:
 *	Refresh ALL indexes and OVERWRITE ALL DATA IN INDEX TABLE.
 *
 * Pass-in:
 *
 * Returns: @rcode  - 1 = Fail
 *				   0 = Success
 *
 *
 *************************************************/
   (@attid int = null, @mod char(2) = null,@uniqueattchid uniqueidentifier = null,@msg varchar(255) = '' output)
   
  as 
   
  declare @rcode int
  
  set nocount on
   
  select @rcode = 0
   
   
  declare AllAttachments cursor for
  Select AttachmentID
  from bHQAT with (nolock)
  where AttachmentID = isnull(@attid,AttachmentID) 
  	and  upper(left(FormName,2)) = upper(isnull(@mod,left(FormName,2)))
  	and UniqueAttchID = isnull(@uniqueattchid,UniqueAttchID)
  order by AttachmentID
  
   
  open AllAttachments
   
  fetch next from AllAttachments into @attid
  while @@fetch_status = 0 
   	begin
    	exec @rcode = vspHQCreateIndex @attid,'Y',@msg output
   	if @rcode <> 0 goto bspexit
   
   	fetch next from AllAttachments into @attid
   	end
   
   
  bspexit:
   	close AllAttachments
   	deallocate AllAttachments
  
  	if @rcode <> 0 select @msg = isnull(@msg,'') + char(13) + char(10) + '[bspHQRefreshIndexes]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQRefreshIndexes] TO [public]
GO
