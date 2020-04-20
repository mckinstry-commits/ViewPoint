SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlGet
AS
	SET NOCOUNT ON;
SELECT PageSiteControlID, StoredProcedureID FROM pQueryControl


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlGet] TO [VCSPortal]
GO
