SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VAAttachmentTypeSecurity] as select a.* From vVAAttachmentTypeSecurity a
GO
GRANT SELECT ON  [dbo].[VAAttachmentTypeSecurity] TO [public]
GRANT INSERT ON  [dbo].[VAAttachmentTypeSecurity] TO [public]
GRANT DELETE ON  [dbo].[VAAttachmentTypeSecurity] TO [public]
GRANT UPDATE ON  [dbo].[VAAttachmentTypeSecurity] TO [public]
GO
