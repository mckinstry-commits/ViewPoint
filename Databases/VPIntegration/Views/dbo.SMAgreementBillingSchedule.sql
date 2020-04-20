SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementBillingSchedule]
AS
SELECT     dbo.vSMAgreementBillingSchedule.*
FROM         dbo.vSMAgreementBillingSchedule

GO
GRANT SELECT ON  [dbo].[SMAgreementBillingSchedule] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementBillingSchedule] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementBillingSchedule] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementBillingSchedule] TO [public]
GO
