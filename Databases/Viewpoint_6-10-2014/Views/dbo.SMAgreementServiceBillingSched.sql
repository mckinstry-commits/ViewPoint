SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementServiceBillingSched]
AS
SELECT     dbo.SMAgreementBillingSchedule.*
FROM         dbo.SMAgreementBillingSchedule
WHERE SMAgreementBillingSchedule.[Service] IS NOT NULL

GO
GRANT SELECT ON  [dbo].[SMAgreementServiceBillingSched] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementServiceBillingSched] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementServiceBillingSched] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementServiceBillingSched] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementServiceBillingSched] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementServiceBillingSched] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementServiceBillingSched] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementServiceBillingSched] TO [Viewpoint]
GO
