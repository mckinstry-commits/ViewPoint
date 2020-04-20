SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalDataGridDelete
(
	@Original_DataGridID int,
	@Original_AddStoredProcedureID int,
	@Original_DefaultSortID int,
	@Original_DeleteStoredProcedureID int,
	@Original_GetStoredProcedureID int,
	@Original_IDColumn int,
	@Original_ParameterMissingMessageID int,
	@Original_UpdateStoredProcedureID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalDataGrid WHERE (DataGridID = @Original_DataGridID) AND (AddStoredProcedureID = @Original_AddStoredProcedureID OR @Original_AddStoredProcedureID IS NULL AND AddStoredProcedureID IS NULL) AND (DefaultSortID = @Original_DefaultSortID OR @Original_DefaultSortID IS NULL AND DefaultSortID IS NULL) AND (DeleteStoredProcedureID = @Original_DeleteStoredProcedureID OR @Original_DeleteStoredProcedureID IS NULL AND DeleteStoredProcedureID IS NULL) AND (GetStoredProcedureID = @Original_GetStoredProcedureID OR @Original_GetStoredProcedureID IS NULL AND GetStoredProcedureID IS NULL) AND (IDColumn = @Original_IDColumn OR @Original_IDColumn IS NULL AND IDColumn IS NULL) AND (ParameterMissingMessageID = @Original_ParameterMissingMessageID OR @Original_ParameterMissingMessageID IS NULL AND ParameterMissingMessageID IS NULL) AND (UpdateStoredProcedureID = @Original_UpdateStoredProcedureID OR @Original_UpdateStoredProcedureID IS NULL AND UpdateStoredProcedureID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataGridDelete] TO [VCSPortal]
GO
