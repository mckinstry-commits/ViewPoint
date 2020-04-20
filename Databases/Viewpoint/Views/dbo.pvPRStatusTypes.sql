SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPRStatusTypes]
AS

	SELECT CAST(0 AS BIT) AS 'Status', 'No' AS 'StatusDescription'
	UNION
	SELECT CAST(1 AS BIT) As 'Status', 'Yes' AS 'StatusDescription'

GO
GRANT SELECT ON  [dbo].[pvPRStatusTypes] TO [public]
GRANT INSERT ON  [dbo].[pvPRStatusTypes] TO [public]
GRANT DELETE ON  [dbo].[pvPRStatusTypes] TO [public]
GRANT UPDATE ON  [dbo].[pvPRStatusTypes] TO [public]
GRANT SELECT ON  [dbo].[pvPRStatusTypes] TO [VCSPortal]
GO
