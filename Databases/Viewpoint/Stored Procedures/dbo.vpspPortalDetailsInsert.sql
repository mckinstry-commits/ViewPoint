SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalDetailsInsert
(
	@Name varchar(50),
	@GetStoredProcedureID int,
	@AddStoredProcedureID int,
	@UpdateStoredProcedureID int,
	@DeleteStoredProcedureID int,
	@ParameterMissingMessageID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalDetails(Name, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID, ParameterMissingMessageID) VALUES (@Name, @GetStoredProcedureID, @AddStoredProcedureID, @UpdateStoredProcedureID, @DeleteStoredProcedureID, @ParameterMissingMessageID);
	SELECT DetailsID, Name, GetStoredProcedureID, AddStoredProcedureID, UpdateStoredProcedureID, DeleteStoredProcedureID, ParameterMissingMessageID FROM pPortalDetails WHERE (DetailsID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsInsert] TO [VCSPortal]
GO
