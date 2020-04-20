SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredEquipment] AS SELECT a.* FROM vSMRequiredEquipment a
GO
GRANT SELECT ON  [dbo].[SMRequiredEquipment] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredEquipment] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredEquipment] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredEquipment] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredEquipment] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredEquipment] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredEquipment] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredEquipment] TO [Viewpoint]
GO
