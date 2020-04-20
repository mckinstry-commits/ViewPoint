SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VCSiteAttachments]
AS
SELECT * --SiteAttachmentID, SiteID, Name, FileName, AttachmentTypeID, Date, Size, Description
FROM dbo.pSiteAttachments

GO
GRANT SELECT ON  [dbo].[VCSiteAttachments] TO [public]
GRANT INSERT ON  [dbo].[VCSiteAttachments] TO [public]
GRANT DELETE ON  [dbo].[VCSiteAttachments] TO [public]
GRANT UPDATE ON  [dbo].[VCSiteAttachments] TO [public]
GO
