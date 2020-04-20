SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredLaborExt] AS 
SELECT *, 
(
	SELECT WorkOrderQuote 
	FROM vSMEntity 
	WHERE SMRequiredLabor.SMCo = vSMEntity.SMCo AND SMRequiredLabor.EntitySeq = vSMEntity.EntitySeq
) WorkOrderQuote
FROM SMRequiredLabor
GO
GRANT SELECT ON  [dbo].[SMRequiredLaborExt] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredLaborExt] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredLaborExt] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredLaborExt] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredLaborExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredLaborExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredLaborExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredLaborExt] TO [Viewpoint]
GO
