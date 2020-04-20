SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredEquipmentExt] AS 
SELECT *, 
(
	SELECT WorkOrderQuote 
	FROM vSMEntity 
	WHERE SMRequiredEquipment.SMCo = vSMEntity.SMCo AND SMRequiredEquipment.EntitySeq = vSMEntity.EntitySeq
) WorkOrderQuote
FROM SMRequiredEquipment
GO
GRANT SELECT ON  [dbo].[SMRequiredEquipmentExt] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredEquipmentExt] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredEquipmentExt] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredEquipmentExt] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredEquipmentExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredEquipmentExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredEquipmentExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredEquipmentExt] TO [Viewpoint]
GO
