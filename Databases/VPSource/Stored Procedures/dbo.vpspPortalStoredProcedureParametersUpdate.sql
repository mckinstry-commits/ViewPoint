SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalStoredProcedureParametersUpdate
(
	@StoredProcedureID int,
	@ParameterName varchar(50),
	@DefaultValue varchar(50),
	@Original_ParameterID int,
	@Original_DefaultValue varchar(50),
	@Original_ParameterName varchar(50),
	@Original_StoredProcedureID int,
	@ParameterID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalStoredProcedureParameters SET StoredProcedureID = @StoredProcedureID, ParameterName = @ParameterName, DefaultValue = @DefaultValue WHERE (ParameterID = @Original_ParameterID) AND (DefaultValue = @Original_DefaultValue OR @Original_DefaultValue IS NULL AND DefaultValue IS NULL) AND (ParameterName = @Original_ParameterName) AND (StoredProcedureID = @Original_StoredProcedureID);
	SELECT ParameterID, StoredProcedureID, ParameterName, DefaultValue FROM pPortalStoredProcedureParameters WHERE (ParameterID = @ParameterID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalStoredProcedureParametersUpdate] TO [VCSPortal]
GO
