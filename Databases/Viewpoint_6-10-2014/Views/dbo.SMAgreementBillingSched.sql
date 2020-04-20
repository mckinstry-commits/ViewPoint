SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementBillingSched]
AS
SELECT     dbo.SMAgreementBillingSchedule.*
FROM         dbo.SMAgreementBillingSchedule
WHERE SMAgreementBillingSchedule.[Service] IS NULL

GO
GRANT SELECT ON  [dbo].[SMAgreementBillingSched] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementBillingSched] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementBillingSched] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementBillingSched] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementBillingSched] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementBillingSched] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementBillingSched] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementBillingSched] TO [Viewpoint]
GO
