SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE dbo.vpspMenuTemplatesInsert
(
	@RoleID int,
	@Name varchar(50),
	@Description varchar(255),
	@Notes varchar(3000)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pMenuTemplates(RoleID, Name, Description, Notes) VALUES (@RoleID, @Name, @Description, @Notes);
	SELECT MenuTemplateID, RoleID, Name, Description, Notes FROM pMenuTemplates WHERE (MenuTemplateID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplatesInsert] TO [VCSPortal]
GO
