SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DMAttachmentSearchGrouping]
AS
SELECT     dbo.vDMAttachmentSearchGrouping.*
FROM         dbo.vDMAttachmentSearchGrouping


GO
GRANT SELECT ON  [dbo].[DMAttachmentSearchGrouping] TO [public]
GRANT INSERT ON  [dbo].[DMAttachmentSearchGrouping] TO [public]
GRANT DELETE ON  [dbo].[DMAttachmentSearchGrouping] TO [public]
GRANT UPDATE ON  [dbo].[DMAttachmentSearchGrouping] TO [public]
GO
