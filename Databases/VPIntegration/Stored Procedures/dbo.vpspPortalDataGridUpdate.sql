SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE [dbo].[vpspPortalDataGridUpdate]
(
	@IDColumn int,
	@DefaultSortID int,
	@GetStoredProcedureID int,
	@AddStoredProcedureID int,
	@UpdateStoredProcedureID int,
	@DeleteStoredProcedureID int,
	@ParameterMissingMessageID int,
    @SortAscending int,
	@Original_DataGridID int,
	@Original_AddStoredProcedureID int,
	@Original_DefaultSortID int,
	@Original_DeleteStoredProcedureID int,
	@Original_GetStoredProcedureID int,
	@Original_IDColumn int,
	@Original_ParameterMissingMessageID int,
	@Original_UpdateStoredProcedureID int,
	@DataGridID int,
	@Name varchar(50),
	@Editable BIT
)
AS
	SET NOCOUNT OFF;

IF @IDColumn = -1 SET @IDColumn = NULL
IF @DefaultSortID = -1 SET @DefaultSortID = NULL
IF @GetStoredProcedureID = -1 SET @GetStoredProcedureID = NULL
IF @AddStoredProcedureID = -1 SET @AddStoredProcedureID = NULL

IF @UpdateStoredProcedureID = -1 SET @UpdateStoredProcedureID = NULL
IF @DeleteStoredProcedureID = -1 SET @DeleteStoredProcedureID = NULL
IF @ParameterMissingMessageID = -1 SET @ParameterMissingMessageID = NULL


UPDATE pPortalDataGrid SET Name = @Name, IDColumn = @IDColumn, DefaultSortID = @DefaultSortID, 
GetStoredProcedureID = @GetStoredProcedureID, AddStoredProcedureID = @AddStoredProcedureID, 
UpdateStoredProcedureID = @UpdateStoredProcedureID, 
DeleteStoredProcedureID = @DeleteStoredProcedureID, 
ParameterMissingMessageID = @ParameterMissingMessageID,
SortAscending = @SortAscending,
Editable = @Editable 
WHERE (DataGridID = @Original_DataGridID) ;

	SELECT Name, DataGridID, IDColumn, DefaultSortID, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID, ParameterMissingMessageID FROM pPortalDataGrid WHERE (DataGridID = @DataGridID)




GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataGridUpdate] TO [VCSPortal]
GO
