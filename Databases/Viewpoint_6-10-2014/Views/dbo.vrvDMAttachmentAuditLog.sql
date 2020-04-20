SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	Assign the original AttachmentName to each record of
	the table/view DMAttachementAuditLog
  Note:
	This view ensures the attachment is always referred to the
	original name because it is allowed to rename a document and
	the original name is only stored in "NewValue" of the "Add" event
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	5/16/08	127653	New
********************************************************************/
CREATE view [dbo].[vrvDMAttachmentAuditLog]
as
SELECT 
	 d.AttachmentID
	,e.AttachmentName
	,d.DateTime AS AttachmentDateTime
	,d.UserName
	,d.FieldName
	,d.OldValue
	,d.NewValue
	,d.Event
FROM DMAttachmentAuditLog d (Nolock)
INNER JOIN (SELECT AttachmentID, NewValue AS AttachmentName FROM DMAttachmentAuditLog (NoLock) WHERE Event = 'Add') e 
ON e.AttachmentID = d.AttachmentID

GO
GRANT SELECT ON  [dbo].[vrvDMAttachmentAuditLog] TO [public]
GRANT INSERT ON  [dbo].[vrvDMAttachmentAuditLog] TO [public]
GRANT DELETE ON  [dbo].[vrvDMAttachmentAuditLog] TO [public]
GRANT UPDATE ON  [dbo].[vrvDMAttachmentAuditLog] TO [public]
GRANT SELECT ON  [dbo].[vrvDMAttachmentAuditLog] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvDMAttachmentAuditLog] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvDMAttachmentAuditLog] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvDMAttachmentAuditLog] TO [Viewpoint]
GO
