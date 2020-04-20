SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementBillingScheduleExt]
AS
	SELECT *,
		--Get the billing sequence and count for scheduled billings. Include the billing type so that adjustment billings are excluded.
		CASE WHEN BillingType = 'S' THEN ROW_NUMBER() OVER (PARTITION BY SMCo, Agreement, Revision, [Service], BillingType ORDER BY [Date]) END BillingSequence,
		CASE WHEN BillingType = 'S' THEN COUNT(1) OVER (PARTITION BY SMCo, Agreement, Revision, [Service], BillingType) END BillingCount
	FROM dbo.SMAgreementBillingSchedule 
GO
GRANT SELECT ON  [dbo].[SMAgreementBillingScheduleExt] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementBillingScheduleExt] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementBillingScheduleExt] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementBillingScheduleExt] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementBillingScheduleExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementBillingScheduleExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementBillingScheduleExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementBillingScheduleExt] TO [Viewpoint]
GO
