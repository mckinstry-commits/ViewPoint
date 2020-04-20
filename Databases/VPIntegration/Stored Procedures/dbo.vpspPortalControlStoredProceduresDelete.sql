SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlStoredProceduresDelete
(
	@Original_PortalControlID int,
	@Original_AddStoredProcedureID int,
	@Original_DeleteStoredProcedureID int,
	@Original_GetStoredProcedureID int,
	@Original_UpdateStoredProcedureID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalControlStoredProcedures WHERE (PortalControlID = @Original_PortalControlID) AND (AddStoredProcedureID = @Original_AddStoredProcedureID OR @Original_AddStoredProcedureID IS NULL AND AddStoredProcedureID IS NULL) AND (DeleteStoredProcedureID = @Original_DeleteStoredProcedureID OR @Original_DeleteStoredProcedureID IS NULL AND DeleteStoredProcedureID IS NULL) AND (GetStoredProcedureID = @Original_GetStoredProcedureID OR @Original_GetStoredProcedureID IS NULL AND GetStoredProcedureID IS NULL) AND (UpdateStoredProcedureID = @Original_UpdateStoredProcedureID OR @Original_UpdateStoredProcedureID IS NULL AND UpdateStoredProcedureID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlStoredProceduresDelete] TO [VCSPortal]
GO
