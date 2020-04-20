SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspMenuTemplatesDelete
(
	@Original_MenuTemplateID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pMenuTemplates WHERE (MenuTemplateID = @Original_MenuTemplateID) AND (Description = @Original_Description) AND (Name = @Original_Name) AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) AND (RoleID = @Original_RoleID) 


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplatesDelete] TO [VCSPortal]
GO
