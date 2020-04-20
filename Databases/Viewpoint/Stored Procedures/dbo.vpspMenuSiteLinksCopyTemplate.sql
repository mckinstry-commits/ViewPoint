SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Tom Jochums
-- Create date: 2011-10-03
-- Modified By: Chris G 10/31/2011- D-03296 - Fix but stopping pMenuSiteLinkRoles from copying
--
-- Description:	This was a heavy refactor of the original stored proc that
--				was used to copy templates to sites. Wipes out the old 
--				controls on a site, and then replaces it with all new controls
--              and menus - with all security coming from the template.
-- =============================================
CREATE PROCEDURE [dbo].[vpspMenuSiteLinksCopyTemplate]
(
  	@SiteID int,
  	@MenuTemplateID int
)
AS
BEGIN
	exec vspMenuSiteLinksCopyTemplate @SiteID, @MenuTemplateID
END

GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksCopyTemplate] TO [VCSPortal]
GO
