SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VCPageSiteTemplates]
AS
SELECT     PageSiteTemplateID, SiteID, PageTemplateID, RoleID, [dbo].[vfBitToBYN](AvailableToMenu) as 'AvailableToMenu', Name, [Description], Notes
FROM         dbo.pPageSiteTemplates


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 10/12/09
-- Description:	Insert instead of Trigger. Insert into pPageSiteTemplates - convert AvailableToMenu from bYN to Bit.
-- =============================================
CREATE TRIGGER [dbo].[vtVCPageSiteTemplatesi] ON  [dbo].[VCPageSiteTemplates] 
   INSTEAD OF INSERT
AS   
BEGIN
	SET NOCOUNT ON;
	INSERT INTO pPageSiteTemplates
	(
		SiteID,
		RoleID,
		AvailableToMenu,
		Name,
		[Description],
		Notes
	) 
	SELECT
		inserted.SiteID,
		0,
		[dbo].vfBYNToBit(inserted.AvailableToMenu),
		inserted.Name,
		inserted.[Description],
		inserted.Notes
	FROM inserted
END



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 10/12/09
-- Description:	Update instead of Trigger. Insert into pPageSiteTemplates - convert AvailableToMenu from bYN to Bit.
-- =============================================
CREATE TRIGGER [dbo].[vtVCPageSiteTemplatesu] ON [dbo].[VCPageSiteTemplates] INSTEAD OF UPDATE AS
BEGIN
	SET NOCOUNT ON;
	UPDATE pPageSiteTemplates set 
		Name = inserted.Name, 
		[Description] = inserted.[Description], 
		AvailableToMenu = [dbo].vfBYNToBit(inserted.AvailableToMenu),
		Notes = inserted.Notes
	FROM inserted 
		JOIN pPageSiteTemplates ON pPageSiteTemplates.PageSiteTemplateID = inserted.PageSiteTemplateID
END


GO
GRANT SELECT ON  [dbo].[VCPageSiteTemplates] TO [public]
GRANT INSERT ON  [dbo].[VCPageSiteTemplates] TO [public]
GRANT DELETE ON  [dbo].[VCPageSiteTemplates] TO [public]
GRANT UPDATE ON  [dbo].[VCPageSiteTemplates] TO [public]
GRANT SELECT ON  [dbo].[VCPageSiteTemplates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VCPageSiteTemplates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VCPageSiteTemplates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VCPageSiteTemplates] TO [Viewpoint]
GO
