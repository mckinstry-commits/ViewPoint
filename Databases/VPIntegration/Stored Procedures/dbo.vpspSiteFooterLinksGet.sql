SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT SiteFooterLinkID, SiteID, DisplayName, Destination, LinkOrder, LinkTypeID FROM pSiteFooterLinks


GO
GRANT EXECUTE ON  [dbo].[vpspSiteFooterLinksGet] TO [VCSPortal]
GO