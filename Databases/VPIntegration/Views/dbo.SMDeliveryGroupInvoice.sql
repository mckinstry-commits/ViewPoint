SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDeliveryGroupInvoice]
AS
SELECT     dbo.vSMDeliveryGroupInvoice.*
FROM         dbo.vSMDeliveryGroupInvoice

GO
GRANT SELECT ON  [dbo].[SMDeliveryGroupInvoice] TO [public]
GRANT INSERT ON  [dbo].[SMDeliveryGroupInvoice] TO [public]
GRANT DELETE ON  [dbo].[SMDeliveryGroupInvoice] TO [public]
GRANT UPDATE ON  [dbo].[SMDeliveryGroupInvoice] TO [public]
GO
