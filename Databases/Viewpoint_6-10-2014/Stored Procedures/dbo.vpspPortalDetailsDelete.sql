SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalDetailsDelete
(
	@Original_DetailsID int,
	@Original_AddStoredProcedureID int,
	@Original_DeleteStoredProcedureID int,
	@Original_GetStoredProcedureID int,
	@Original_Name varchar(50),
	@Original_ParameterMissingMessageID int,
	@Original_UpdateStoredProcedureID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalDetails WHERE (DetailsID = @Original_DetailsID) AND (AddStoredProcedureID = @Original_AddStoredProcedureID OR @Original_AddStoredProcedureID IS NULL AND AddStoredProcedureID IS NULL) AND (DeleteStoredProcedureID = @Original_DeleteStoredProcedureID OR @Original_DeleteStoredProcedureID IS NULL AND DeleteStoredProcedureID IS NULL) AND (GetStoredProcedureID = @Original_GetStoredProcedureID OR @Original_GetStoredProcedureID IS NULL AND GetStoredProcedureID IS NULL) AND (Name = @Original_Name OR @Original_Name IS NULL AND Name IS NULL) AND (ParameterMissingMessageID = @Original_ParameterMissingMessageID OR @Original_ParameterMissingMessageID IS NULL AND ParameterMissingMessageID IS NULL) AND (UpdateStoredProcedureID = @Original_UpdateStoredProcedureID OR @Original_UpdateStoredProcedureID IS NULL AND UpdateStoredProcedureID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsDelete] TO [VCSPortal]
GO
