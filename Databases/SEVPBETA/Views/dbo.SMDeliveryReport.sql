SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDeliveryReport]
AS
SELECT     dbo.vSMDeliveryReport.*
FROM         dbo.vSMDeliveryReport

GO
GRANT SELECT ON  [dbo].[SMDeliveryReport] TO [public]
GRANT INSERT ON  [dbo].[SMDeliveryReport] TO [public]
GRANT DELETE ON  [dbo].[SMDeliveryReport] TO [public]
GRANT UPDATE ON  [dbo].[SMDeliveryReport] TO [public]
GO
