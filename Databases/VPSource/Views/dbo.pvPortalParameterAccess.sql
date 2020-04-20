SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[pvPortalParameterAccess]
AS
	SELECT 0 AS KeyField, 'Always hide' AS 'AccessDescription'
	UNION
	SELECT 1 AS KeyField, 'Always show' AS 'AccessDescription'
	UNION
	SELECT 2 As KeyField, 'Show when empty' AS 'AccessDescription'

GO
GRANT SELECT ON  [dbo].[pvPortalParameterAccess] TO [public]
GRANT INSERT ON  [dbo].[pvPortalParameterAccess] TO [public]
GRANT DELETE ON  [dbo].[pvPortalParameterAccess] TO [public]
GRANT UPDATE ON  [dbo].[pvPortalParameterAccess] TO [public]
GRANT SELECT ON  [dbo].[pvPortalParameterAccess] TO [VCSPortal]
GO
