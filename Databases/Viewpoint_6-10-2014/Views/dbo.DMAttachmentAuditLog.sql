SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DMAttachmentAuditLog] as select a.* From vDMAttachmentAuditLog a
GO
GRANT SELECT ON  [dbo].[DMAttachmentAuditLog] TO [public]
GRANT INSERT ON  [dbo].[DMAttachmentAuditLog] TO [public]
GRANT DELETE ON  [dbo].[DMAttachmentAuditLog] TO [public]
GRANT UPDATE ON  [dbo].[DMAttachmentAuditLog] TO [public]
GRANT SELECT ON  [dbo].[DMAttachmentAuditLog] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DMAttachmentAuditLog] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DMAttachmentAuditLog] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DMAttachmentAuditLog] TO [Viewpoint]
GO
