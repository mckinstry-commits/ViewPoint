SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[vpspPortalDataGridInsert]
(
	@IDColumn int,
	@DefaultSortID int,
	@GetStoredProcedureID int,
	@AddStoredProcedureID int,
	@UpdateStoredProcedureID int,
	@DeleteStoredProcedureID int,
	@ParameterMissingMessageID int,
	@Name varchar(50),
	@Editable BIT
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalDataGrid(Name, IDColumn, DefaultSortID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID, ParameterMissingMessageID, Editable, StartInEditMode) VALUES (@Name, @IDColumn, @DefaultSortID, @GetStoredProcedureID, @AddStoredProcedureID, @UpdateStoredProcedureID, @DeleteStoredProcedureID, @ParameterMissingMessageID, @Editable, 0);
	SELECT Name, DataGridID, IDColumn, DefaultSortID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID, ParameterMissingMessageID, Editable FROM pPortalDataGrid WHERE (DataGridID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataGridInsert] TO [VCSPortal]
GO
