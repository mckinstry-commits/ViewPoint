SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredMaterialExt] AS 
SELECT *, 
(
	SELECT WorkOrderQuote 
	FROM vSMEntity 
	WHERE SMRequiredMaterial.SMCo = vSMEntity.SMCo AND SMRequiredMaterial.EntitySeq = vSMEntity.EntitySeq
) WorkOrderQuote
FROM SMRequiredMaterial
GO
GRANT SELECT ON  [dbo].[SMRequiredMaterialExt] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredMaterialExt] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredMaterialExt] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredMaterialExt] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredMaterialExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredMaterialExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredMaterialExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredMaterialExt] TO [Viewpoint]
GO
