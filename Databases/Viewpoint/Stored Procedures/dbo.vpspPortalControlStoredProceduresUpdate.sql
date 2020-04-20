SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlStoredProceduresUpdate
(
	@PortalControlID int,
	@GetStoredProcedureID int,
	@AddStoredProcedureID int,
	@UpdateStoredProcedureID int,
	@DeleteStoredProcedureID int,
	@Original_PortalControlID int,
	@Original_AddStoredProcedureID int,
	@Original_DeleteStoredProcedureID int,
	@Original_GetStoredProcedureID int,
	@Original_UpdateStoredProcedureID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalControlStoredProcedures SET PortalControlID = @PortalControlID, GetStoredProcedureID = @GetStoredProcedureID, AddStoredProcedureID = @AddStoredProcedureID, UpdateStoredProcedureID = @UpdateStoredProcedureID, DeleteStoredProcedureID = @DeleteStoredProcedureID WHERE (PortalControlID = @Original_PortalControlID) AND (AddStoredProcedureID = @Original_AddStoredProcedureID OR @Original_AddStoredProcedureID IS NULL AND AddStoredProcedureID IS NULL) AND (DeleteStoredProcedureID = @Original_DeleteStoredProcedureID OR @Original_DeleteStoredProcedureID IS NULL AND DeleteStoredProcedureID IS NULL) AND (GetStoredProcedureID = @Original_GetStoredProcedureID OR @Original_GetStoredProcedureID IS NULL AND GetStoredProcedureID IS NULL) AND (UpdateStoredProcedureID = @Original_UpdateStoredProcedureID OR @Original_UpdateStoredProcedureID IS NULL AND UpdateStoredProcedureID IS NULL);
	SELECT PortalControlID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID FROM pPortalControlStoredProcedures WHERE (PortalControlID = @PortalControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlStoredProceduresUpdate] TO [VCSPortal]
GO
