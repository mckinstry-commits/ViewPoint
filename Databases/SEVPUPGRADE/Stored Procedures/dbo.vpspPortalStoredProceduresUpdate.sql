SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalStoredProceduresUpdate
(
	@Name varchar(50),
	@Description varchar(255),
	@Original_StoredProcedureID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@StoredProcedureID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalStoredProcedures SET Name = @Name, Description = @Description WHERE (StoredProcedureID = @Original_StoredProcedureID) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) AND (Name = @Original_Name);
	SELECT StoredProcedureID, Name, Description FROM pPortalStoredProcedures WHERE (StoredProcedureID = @StoredProcedureID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalStoredProceduresUpdate] TO [VCSPortal]
GO
