SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalStoredProceduresInsert
(
	@Name varchar(50),
	@Description varchar(255)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalStoredProcedures(Name, Description) VALUES (@Name, @Description);
	SELECT StoredProcedureID, Name, Description FROM pPortalStoredProcedures WHERE (StoredProcedureID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalStoredProceduresInsert] TO [VCSPortal]
GO
