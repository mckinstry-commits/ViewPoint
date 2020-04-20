SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].vspVSUpdateBatchAttachmentTypeId 
/************************************************************************
* Created: John Dabritz 12/11/09, issue 135609 persist attachment type id for scan batches
*
* Usage:
* Updates existing AttachmentTypeID in the bVSBH scan batch record with the input ID
* (new records always created with a null AttachmentTypeID)
*
* Inputs:
*	@batchid    	    ID of the batch record in bVSBH (bBatchID)
*	@attachmentTypeID	new AttachmentTypeID column value (integer, may be null)
*                       NOTE: If @attachmentTypeID = 0, it is converted to null
*                             prior to saving.
* 
**************************************************************************/
(@batchID int, @attachmentTypeID int)
as
   
   /* convert input @AttachmentTypeID of zero to null */
   update bVSBH
   set AttachmentTypeID = NULLIF(@attachmentTypeID,0)
   where BatchId = @batchID

GO
GRANT EXECUTE ON  [dbo].[vspVSUpdateBatchAttachmentTypeId] TO [public]
GO
