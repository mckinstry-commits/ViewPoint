SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspVSGetBatchInfo]
/*****************************
*    Modified 12/11/2009 John Dabritz:  135609, added h.AttachmentTypeID to selection
*****************************/
(@batchid int)
as

select h.BatchId, h.Description, h.CreatedDate, h.CreatedBy, h.InUseBy, 
       d.ImageID, d.PageCount, d.Attached, h.AttachmentTypeID 
from bVSBH h left outer join bVSBD d on h.BatchId = d.BatchId where h.BatchId=@batchid





GO
GRANT EXECUTE ON  [dbo].[vspVSGetBatchInfo] TO [public]
GO
