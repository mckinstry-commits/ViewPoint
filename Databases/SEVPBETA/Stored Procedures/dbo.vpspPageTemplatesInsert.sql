SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE      PROCEDURE dbo.vpspPageTemplatesInsert
(
	@PageTemplateID int,
	@RoleID int,
	@PatriarchID int,
	@AvailableToMenu bit,
	@Name varchar(50),
	@Description varchar(255),
	@Notes varchar(3000)
)
AS
	SET NOCOUNT OFF;

IF @PatriarchID = -1 SET @PatriarchID = NULL

INSERT INTO pPageTemplates(RoleID, PatriarchID, AvailableToMenu, Name, Description, Notes) 
VALUES (@RoleID, @PatriarchID, @AvailableToMenu, @Name, @Description, @Notes);
SELECT PageTemplateID, RoleID, PatriarchID, AvailableToMenu, Name, Description, Notes 
FROM pPageTemplates WHERE (PageTemplateID = SCOPE_IDENTITY())




GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplatesInsert] TO [VCSPortal]
GO
