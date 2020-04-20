SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT PortalControlID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID FROM pPortalControlStoredProcedures


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlStoredProceduresGet] TO [VCSPortal]
GO