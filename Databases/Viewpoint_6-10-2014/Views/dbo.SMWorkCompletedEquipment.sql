SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[SMWorkCompletedEquipment]
AS
SELECT *
FROM dbo.vSMWorkCompletedEquipment




GO
GRANT SELECT ON  [dbo].[SMWorkCompletedEquipment] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedEquipment] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedEquipment] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedEquipment] TO [public]
GRANT SELECT ON  [dbo].[SMWorkCompletedEquipment] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkCompletedEquipment] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkCompletedEquipment] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkCompletedEquipment] TO [Viewpoint]
GO
