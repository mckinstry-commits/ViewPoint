SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlStoredProceduresInsert
(
	@PortalControlID int,
	@GetStoredProcedureID int,
	@AddStoredProcedureID int,
	@UpdateStoredProcedureID int,
	@DeleteStoredProcedureID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalControlStoredProcedures(PortalControlID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID) VALUES (@PortalControlID, @GetStoredProcedureID, @AddStoredProcedureID, @UpdateStoredProcedureID, @DeleteStoredProcedureID);
	SELECT PortalControlID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID FROM pPortalControlStoredProcedures WHERE (PortalControlID = @PortalControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlStoredProceduresInsert] TO [VCSPortal]
GO
