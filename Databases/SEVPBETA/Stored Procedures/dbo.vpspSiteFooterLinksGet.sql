SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspSiteFooterLinksGet
AS
	SET NOCOUNT ON;
SELECT SiteFooterLinkID, SiteID, DisplayName, Destination, LinkOrder, LinkTypeID FROM pSiteFooterLinks


GO
GRANT EXECUTE ON  [dbo].[vpspSiteFooterLinksGet] TO [VCSPortal]
GO
