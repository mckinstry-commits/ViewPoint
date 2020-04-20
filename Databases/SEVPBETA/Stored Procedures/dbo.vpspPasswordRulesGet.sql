SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPasswordRulesGet
AS
	SET NOCOUNT ON;
exec vspPasswordRulesGet

GO
GRANT EXECUTE ON  [dbo].[vpspPasswordRulesGet] TO [VCSPortal]
GO
