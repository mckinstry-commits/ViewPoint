SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VCPageSiteTemplateControls
AS
SELECT     dbo.pPageSiteControls.*
FROM         dbo.pPageSiteControls

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley, Matt Pement	
-- Create date: 10-19-09
-- Description:	On insert, remove the id column because V6 cant insert into a primary key identity column
-- =============================================
CREATE TRIGGER [dbo].[vtVCPageSiteTemplateControlsi]
   ON  [dbo].[VCPageSiteTemplateControls] 
   INSTEAD OF INSERT
AS   
BEGIN
	SET NOCOUNT ON;
	INSERT INTO pPageSiteControls
	(
		PageSiteTemplateID,
		SiteID,
		PortalControlID,
		ControlPosition,
		ControlIndex,
		RoleID,
		HeaderText
	) 
	SELECT
		inserted.PageSiteTemplateID,
		inserted.SiteID,
		inserted.PortalControlID,
		inserted.ControlPosition,
		inserted.ControlIndex,
		inserted.RoleID,
		inserted.HeaderText
	FROM inserted
END
GO
GRANT SELECT ON  [dbo].[VCPageSiteTemplateControls] TO [public]
GRANT INSERT ON  [dbo].[VCPageSiteTemplateControls] TO [public]
GRANT DELETE ON  [dbo].[VCPageSiteTemplateControls] TO [public]
GRANT UPDATE ON  [dbo].[VCPageSiteTemplateControls] TO [public]
GRANT SELECT ON  [dbo].[VCPageSiteTemplateControls] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VCPageSiteTemplateControls] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VCPageSiteTemplateControls] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VCPageSiteTemplateControls] TO [Viewpoint]
GO
