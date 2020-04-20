SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE      PROCEDURE dbo.vpspMenuSiteLinksInsert
(
	@MenuSiteLinkID int,
	@SiteID int,
	@MenuTemplateID int,
	@RoleID int,
	@Caption varchar(50),
	@PageSiteTemplateID int,
	@ParentID int,
	@MenuLevel int,
	@MenuOrder int
)
AS
DECLARE @newmenusitelinkid int
SET NOCOUNT OFF;
if @MenuSiteLinkID < 0 
	begin
	select @newmenusitelinkid = isnull(max(MenuSiteLinkID), 0) + 1 
	from pMenuSiteLinks where SiteID = @SiteID
	end
if @MenuSiteLinkID > 0
	begin
	select @newmenusitelinkid = @MenuSiteLinkID
	end

IF @PageSiteTemplateID = -1 SET @PageSiteTemplateID = NULL
IF @MenuTemplateID = -1 SET @MenuTemplateID = NULL

INSERT INTO pMenuSiteLinks(MenuSiteLinkID, SiteID, MenuTemplateID, RoleID, Caption, 
	PageSiteTemplateID, ParentID, MenuLevel, MenuOrder) 
VALUES (@newmenusitelinkid, @SiteID, @MenuTemplateID, @RoleID, @Caption, 
	@PageSiteTemplateID, @ParentID, @MenuLevel, @MenuOrder);
SELECT MenuSiteLinkID, SiteID, MenuTemplateID, RoleID, Caption, PageSiteTemplateID, 
	ParentID, MenuLevel, MenuOrder 
	FROM pMenuSiteLinks WHERE (MenuSiteLinkID = @newmenusitelinkid) AND (SiteID = @SiteID)




GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksInsert] TO [VCSPortal]
GO
