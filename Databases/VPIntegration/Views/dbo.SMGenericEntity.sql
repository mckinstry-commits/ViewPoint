SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMGenericEntity]
AS
SELECT *, SMRateOverrideID AS SMGenericEntityID
FROM dbo.vSMRateOverride
GO
GRANT SELECT ON  [dbo].[SMGenericEntity] TO [public]
GRANT INSERT ON  [dbo].[SMGenericEntity] TO [public]
GRANT DELETE ON  [dbo].[SMGenericEntity] TO [public]
GRANT UPDATE ON  [dbo].[SMGenericEntity] TO [public]
GO
