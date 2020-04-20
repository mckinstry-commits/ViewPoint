SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE     PROCEDURE dbo.vpspPageSiteTemplatesInsert
(
	@PageSiteTemplateID int,
	@SiteID int,
	@PageTemplateID int,
	@RoleID int,
	@AvailableToMenu bit,
	@Name varchar(50),
	@Description varchar(255),
	@Notes varchar(3000)
)
AS
	SET NOCOUNT OFF;

IF @PageTemplateID = -1
	BEGIN
	SET @PageTemplateID = NULL
	END

INSERT INTO pPageSiteTemplates(SiteID, PageTemplateID, RoleID, 
	AvailableToMenu, Name, Description, Notes) 
	VALUES (@SiteID, @PageTemplateID, @RoleID, @AvailableToMenu, 
	@Name, @Description, @Notes);
	
SELECT PageSiteTemplateID, SiteID, PageTemplateID, RoleID, AvailableToMenu, Name, Description, Notes 
	FROM pPageSiteTemplates WHERE (PageSiteTemplateID = SCOPE_IDENTITY())




GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteTemplatesInsert] TO [VCSPortal]
GO
