SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspSiteFooterLinksDelete
(
	@Original_SiteFooterLinkID int,
	@Original_Destination varchar(255),
	@Original_DisplayName varchar(50),
	@Original_LinkOrder int,
	@Original_LinkTypeID int,
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pSiteFooterLinks WHERE (SiteFooterLinkID = @Original_SiteFooterLinkID) AND (Destination = @Original_Destination OR @Original_Destination IS NULL AND Destination IS NULL) AND (DisplayName = @Original_DisplayName OR @Original_DisplayName IS NULL AND DisplayName IS NULL) AND (LinkOrder = @Original_LinkOrder) AND (LinkTypeID = @Original_LinkTypeID) AND (SiteID = @Original_SiteID)


GO
GRANT EXECUTE ON  [dbo].[vpspSiteFooterLinksDelete] TO [VCSPortal]
GO
