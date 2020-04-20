SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalStoredProceduresDelete
(
	@Original_StoredProcedureID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalStoredProcedures WHERE (StoredProcedureID = @Original_StoredProcedureID) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) AND (Name = @Original_Name)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalStoredProceduresDelete] TO [VCSPortal]
GO
