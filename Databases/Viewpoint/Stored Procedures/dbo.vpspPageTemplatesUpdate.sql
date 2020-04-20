SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE       PROCEDURE dbo.vpspPageTemplatesUpdate
(
	@PageTemplateID int,
	@RoleID int,
	@PatriarchID int,
	@AvailableToMenu bit,
	@Name varchar(50),
	@Description varchar(255),
	@Notes varchar(3000),
	@Original_PageTemplateID int,
	@Original_Description varchar(255),
	@Original_AvailableToMenu bit,
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_PatriarchID int,
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;

IF @PatriarchID = -1 SET @PatriarchID = NULL
IF @Original_PatriarchID = -1 SET @Original_PatriarchID = NULL

UPDATE pPageTemplates SET RoleID = @RoleID, 
	PatriarchID = @PatriarchID, Name = @Name, Description = @Description, 
	Notes = @Notes, AvailableToMenu = @AvailableToMenu 
	WHERE 
	(PageTemplateID = @Original_PageTemplateID) AND 
	(Description = @Original_Description) AND 
	(Name = @Original_Name) AND 
	(Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) AND 
	(PatriarchID = @Original_PatriarchID OR (@Original_PatriarchID IS NULL AND PatriarchID IS NULL)) AND 
    (RoleID = @Original_RoleID);
	SELECT PageTemplateID, RoleID, PatriarchID, Name, Description, Notes FROM pPageTemplates WHERE (PageTemplateID = @PageTemplateID)




GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplatesUpdate] TO [VCSPortal]
GO
