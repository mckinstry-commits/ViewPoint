SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalStoredProcedureParametersDelete
(
	@Original_ParameterID int,
	@Original_DefaultValue varchar(50),
	@Original_ParameterName varchar(50),
	@Original_StoredProcedureID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalStoredProcedureParameters WHERE (ParameterID = @Original_ParameterID) AND (DefaultValue = @Original_DefaultValue OR @Original_DefaultValue IS NULL AND DefaultValue IS NULL) AND (ParameterName = @Original_ParameterName) AND (StoredProcedureID = @Original_StoredProcedureID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalStoredProcedureParametersDelete] TO [VCSPortal]
GO
