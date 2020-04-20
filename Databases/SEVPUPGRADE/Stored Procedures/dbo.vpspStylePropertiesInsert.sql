SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspStylePropertiesInsert
(
	@Name varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pStyleProperties(Name) VALUES (@Name);
	SELECT StyleID, Name FROM pStyleProperties WHERE (StyleID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspStylePropertiesInsert] TO [VCSPortal]
GO
