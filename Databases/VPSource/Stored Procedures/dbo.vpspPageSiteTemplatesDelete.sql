SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE     PROCEDURE dbo.vpspPageSiteTemplatesDelete
(
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

IF @Original_PageTemplateID = -1
	BEGIN
	SET @Original_PageTemplateID = NULL
	END

UPDATE pMenuSiteLinks SET PageSiteTemplateID = NULL WHERE PageSiteTemplateID = @Original_PageSiteTemplateID

DELETE FROM pPageSiteTemplates WHERE 
(PageSiteTemplateID = @Original_PageSiteTemplateID) AND 
(Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) AND 
(Name = @Original_Name) AND 
(Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) AND 
(PageTemplateID = @Original_PageTemplateID OR (@Original_PageTemplateID IS NULL AND PageTemplateID IS NULL)) AND
(RoleID = @Original_RoleID) AND
(SiteID = @Original_SiteID)





GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteTemplatesDelete] TO [VCSPortal]
GO
