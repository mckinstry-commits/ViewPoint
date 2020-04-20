SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspSiteFooterLinksUpdate
(
	@SiteID int,
	@DisplayName varchar(50),
	@Destination varchar(255),
	@LinkOrder int,
	@LinkTypeID int,
	@Original_SiteFooterLinkID int,
	@Original_Destination varchar(255),
	@Original_DisplayName varchar(50),
	@Original_LinkOrder int,
	@Original_LinkTypeID int,
	@Original_SiteID int,
	@SiteFooterLinkID int
)
AS
	SET NOCOUNT OFF;
UPDATE pSiteFooterLinks SET SiteID = @SiteID, DisplayName = @DisplayName, Destination = @Destination, LinkOrder = @LinkOrder, LinkTypeID = @LinkTypeID WHERE (SiteFooterLinkID = @Original_SiteFooterLinkID) AND (Destination = @Original_Destination OR @Original_Destination IS NULL AND Destination IS NULL) AND (DisplayName = @Original_DisplayName OR @Original_DisplayName IS NULL AND DisplayName IS NULL) AND (LinkOrder = @Original_LinkOrder) AND (LinkTypeID = @Original_LinkTypeID) AND (SiteID = @Original_SiteID);
	SELECT SiteFooterLinkID, SiteID, DisplayName, Destination, LinkOrder, LinkTypeID FROM pSiteFooterLinks WHERE (SiteFooterLinkID = @SiteFooterLinkID)


GO
GRANT EXECUTE ON  [dbo].[vpspSiteFooterLinksUpdate] TO [VCSPortal]
GO
