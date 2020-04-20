SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      VIEW [dbo].[DDALog]
AS SELECT  * FROM  dbo.vDDAL




GO
GRANT SELECT ON  [dbo].[DDALog] TO [public]
GRANT INSERT ON  [dbo].[DDALog] TO [public]
GRANT DELETE ON  [dbo].[DDALog] TO [public]
GRANT UPDATE ON  [dbo].[DDALog] TO [public]
GRANT SELECT ON  [dbo].[DDALog] TO [VCSPortal]
GO
