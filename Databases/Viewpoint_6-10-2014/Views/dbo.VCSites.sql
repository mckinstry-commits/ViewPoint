SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VCSites]
AS
SELECT * --SiteID, Name, JCCo, Job, DateCreated, UserID, HeaderText, IdleTimeout, PageSiteTemplateID, Description, Notes, Active, SiteAttachmentID, 
                      --MaxAttachmentSize, ThemeID, ThemeColorID
FROM dbo.pSites AS s

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 10/26/09
-- Description:	Insert instead of Trigger. Insert into pSites - ignores incoming SiteID due to insert identity error.
-- =============================================
CREATE TRIGGER [dbo].[vtVCSitesi] ON  [dbo].[VCSites] 
   INSTEAD OF INSERT
AS   
BEGIN
	SET NOCOUNT ON;
	INSERT INTO pSites
	(
		Name,
		JCCo,
		Job,
		DateCreated,
		UserID,
		HeaderText,
		IdleTimeout,
		PageSiteTemplateID,
		[Description],
		Active,
		SiteAttachmentID,
		MaxAttachmentSize,
		Notes
	)
	SELECT
		Name,
		JCCo,
		Job,
		DateCreated,
		UserID,
		HeaderText,
		IdleTimeout,
		PageSiteTemplateID,
		[Description],
		Active,
		SiteAttachmentID,
		MaxAttachmentSize,
		Notes
	FROM inserted
END
GO
GRANT SELECT ON  [dbo].[VCSites] TO [public]
GRANT INSERT ON  [dbo].[VCSites] TO [public]
GRANT DELETE ON  [dbo].[VCSites] TO [public]
GRANT UPDATE ON  [dbo].[VCSites] TO [public]
GRANT SELECT ON  [dbo].[VCSites] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VCSites] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VCSites] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VCSites] TO [Viewpoint]
GO
