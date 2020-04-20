SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DMAttachmentGridColumnOrder]
AS
SELECT     dbo.vDMAttachmentGridColumnOrder.*
FROM         dbo.vDMAttachmentGridColumnOrder


GO
GRANT SELECT ON  [dbo].[DMAttachmentGridColumnOrder] TO [public]
GRANT INSERT ON  [dbo].[DMAttachmentGridColumnOrder] TO [public]
GRANT DELETE ON  [dbo].[DMAttachmentGridColumnOrder] TO [public]
GRANT UPDATE ON  [dbo].[DMAttachmentGridColumnOrder] TO [public]
GO
