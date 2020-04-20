SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDeliveryGroup]
AS
SELECT     dbo.vSMDeliveryGroup.*
FROM         dbo.vSMDeliveryGroup

GO
GRANT SELECT ON  [dbo].[SMDeliveryGroup] TO [public]
GRANT INSERT ON  [dbo].[SMDeliveryGroup] TO [public]
GRANT DELETE ON  [dbo].[SMDeliveryGroup] TO [public]
GRANT UPDATE ON  [dbo].[SMDeliveryGroup] TO [public]
GRANT SELECT ON  [dbo].[SMDeliveryGroup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDeliveryGroup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDeliveryGroup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDeliveryGroup] TO [Viewpoint]
GO
