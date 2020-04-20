SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspGetPageSitesBySiteAndControl]
-- =============================================
-- Author:		2011/09/19 TEJ
--
-- Description:	Returns the PageSiteTemplate on which the passed in portal control
-- resides for the given siteID
-- =============================================
	@PortalControlID int,
	@SiteID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT TOP 1 PageSiteTemplateID FROM  pPageSiteTemplates WHERE PageTemplateID IN (
		SELECT DISTINCT NavigationPageID 
		           FROM pPortalControlButtons 
		          WHERE PortalControlID = @PortalControlID
		            AND NavigationPageID IS NOT NULL
	) AND SiteID = @SiteID
END

GO
GRANT EXECUTE ON  [dbo].[vpspGetPageSitesBySiteAndControl] TO [VCSPortal]
GO
