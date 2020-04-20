SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredLabor] AS 
SELECT l.*
FROM vSMRequiredLabor l
GO
GRANT SELECT ON  [dbo].[SMRequiredLabor] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredLabor] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredLabor] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredLabor] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredLabor] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredLabor] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredLabor] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredLabor] TO [Viewpoint]
GO
