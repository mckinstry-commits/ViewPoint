SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspLinkTypesInsert
(
	@Name varchar(50),
	@Description varchar(255)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pLinkTypes(Name, Description) VALUES (@Name, @Description);
	

execute vpspLinkTypesGet @LinkTypeID = SCOPE_IDENTITY




GO
GRANT EXECUTE ON  [dbo].[vpspLinkTypesInsert] TO [VCSPortal]
GO
