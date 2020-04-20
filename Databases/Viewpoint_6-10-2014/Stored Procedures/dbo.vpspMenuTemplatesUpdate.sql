SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspMenuTemplatesUpdate
(
	@RoleID int,
	@Name varchar(50),
	@Description varchar(255),
	@Notes varchar(3000),
	@Original_MenuTemplateID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_RoleID int,
	@MenuTemplateID int
)
AS
	SET NOCOUNT OFF;
UPDATE pMenuTemplates SET RoleID = @RoleID, Name = @Name, Description = @Description, Notes = @Notes WHERE (MenuTemplateID = @Original_MenuTemplateID) AND (Description = @Original_Description) AND (Name = @Original_Name) AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) AND (RoleID = @Original_RoleID);
	SELECT MenuTemplateID, RoleID, Name, Description, Notes FROM pMenuTemplates WHERE (MenuTemplateID = @MenuTemplateID)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplatesUpdate] TO [VCSPortal]
GO
