SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[DMAttachmentTypes] as select a.* From vDMAttachmentTypes a

GO
GRANT SELECT ON  [dbo].[DMAttachmentTypes] TO [public]
GRANT INSERT ON  [dbo].[DMAttachmentTypes] TO [public]
GRANT DELETE ON  [dbo].[DMAttachmentTypes] TO [public]
GRANT UPDATE ON  [dbo].[DMAttachmentTypes] TO [public]
GO
