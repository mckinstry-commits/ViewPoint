SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspSiteFooterLinksInsert
(
	@SiteID int,
	@DisplayName varchar(50),
	@Destination varchar(255),
	@LinkOrder int,
	@LinkTypeID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pSiteFooterLinks(SiteID, DisplayName, Destination, LinkOrder, LinkTypeID) VALUES (@SiteID, @DisplayName, @Destination, @LinkOrder, @LinkTypeID);
	SELECT SiteFooterLinkID, SiteID, DisplayName, Destination, LinkOrder, LinkTypeID FROM pSiteFooterLinks WHERE (SiteFooterLinkID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspSiteFooterLinksInsert] TO [VCSPortal]
GO
