SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE      PROCEDURE dbo.vpspPageTemplatesDelete
(
	@Original_PageTemplateID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_PatriarchID int,
	@Original_RoleID int,
	@AvailableToMenu int
)
AS
	SET NOCOUNT OFF;

IF @Original_PatriarchID = -1 SET @Original_PatriarchID = NULL

DELETE FROM pPageTemplates WHERE (PageTemplateID = @Original_PageTemplateID) 
	AND (Description = @Original_Description) AND (Name = @Original_Name) 
	AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) 
	AND (PatriarchID = @Original_PatriarchID OR @Original_PatriarchID IS NULL AND PatriarchID IS NULL) AND (RoleID = @Original_RoleID) 
	AND (AvailableToMenu = @AvailableToMenu)





GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplatesDelete] TO [VCSPortal]
GO
