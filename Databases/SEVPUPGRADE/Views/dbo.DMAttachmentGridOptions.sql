SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DMAttachmentGridOptions
AS
SELECT     dbo.vDMAttachmentGridOptions.*
FROM         dbo.vDMAttachmentGridOptions

GO
GRANT SELECT ON  [dbo].[DMAttachmentGridOptions] TO [public]
GRANT INSERT ON  [dbo].[DMAttachmentGridOptions] TO [public]
GRANT DELETE ON  [dbo].[DMAttachmentGridOptions] TO [public]
GRANT UPDATE ON  [dbo].[DMAttachmentGridOptions] TO [public]
GO
