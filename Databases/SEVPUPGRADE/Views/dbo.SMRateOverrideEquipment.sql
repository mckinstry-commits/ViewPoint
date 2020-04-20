SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRateOverrideEquipment]
AS
SELECT *
FROM dbo.vSMRateOverrideEquipment
GO
GRANT SELECT ON  [dbo].[SMRateOverrideEquipment] TO [public]
GRANT INSERT ON  [dbo].[SMRateOverrideEquipment] TO [public]
GRANT DELETE ON  [dbo].[SMRateOverrideEquipment] TO [public]
GRANT UPDATE ON  [dbo].[SMRateOverrideEquipment] TO [public]
GO
