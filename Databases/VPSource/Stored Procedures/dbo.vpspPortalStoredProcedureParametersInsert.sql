SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalStoredProcedureParametersInsert
(
	@StoredProcedureID int,
	@ParameterName varchar(50),
	@DefaultValue varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalStoredProcedureParameters(StoredProcedureID, ParameterName, DefaultValue) VALUES (@StoredProcedureID, @ParameterName, @DefaultValue);
	SELECT ParameterID, StoredProcedureID, ParameterName, DefaultValue FROM pPortalStoredProcedureParameters WHERE (ParameterID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalStoredProcedureParametersInsert] TO [VCSPortal]
GO
