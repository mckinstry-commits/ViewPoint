SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE [dbo].[vpspPageSiteTemplatesUpdate]
(
	@PageSiteTemplateID int,
	@SiteID int,
	@PageTemplateID int,
	@RoleID int,
	@AvailableToMenu bit, 
	@Name varchar(50),
	@Description varchar(255),
	@Notes varchar(3000),
	@Original_PageSiteTemplateID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_PageTemplateID int,
	@Original_RoleID int,
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;

IF @PageTemplateID = -1
	BEGIN
	SET @PageTemplateID = NULL
	END

IF @Original_PageTemplateID = -1
	BEGIN
	SET @Original_PageTemplateID = NULL
	END

UPDATE pPageSiteTemplates SET SiteID = @SiteID, 
	PageTemplateID = @PageTemplateID, RoleID = @RoleID, AvailableToMenu = @AvailableToMenu, 
	Name = @Name, Description = @Description, Notes = @Notes 
	WHERE (PageSiteTemplateID = @Original_PageSiteTemplateID) 
		AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL)
		AND (Name = @Original_Name) 
		AND (Notes = @Original_Notes OR (@Original_Notes IS NULL AND Notes IS NULL))
		AND (PageTemplateID = @Original_PageTemplateID OR (PageTemplateID IS NULL AND @Original_PageTemplateID IS NULL))
		AND (RoleID = @Original_RoleID) 
		AND (SiteID = @Original_SiteID);
SELECT PageSiteTemplateID, SiteID, PageTemplateID, RoleID, AvailableToMenu, Name, Description, Notes 
	FROM pPageSiteTemplates WHERE (PageSiteTemplateID = @PageSiteTemplateID)



GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteTemplatesUpdate] TO [VCSPortal]
GO
