SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredMiscExt] AS 
SELECT *, 
(
	SELECT WorkOrderQuote 
	FROM vSMEntity 
	WHERE SMRequiredMisc.SMCo = vSMEntity.SMCo AND SMRequiredMisc.EntitySeq = vSMEntity.EntitySeq
) WorkOrderQuote
FROM SMRequiredMisc
GO
GRANT SELECT ON  [dbo].[SMRequiredMiscExt] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredMiscExt] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredMiscExt] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredMiscExt] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredMiscExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredMiscExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredMiscExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredMiscExt] TO [Viewpoint]
GO
