SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 07/19/12
-- Description:	List all related work orders for a given SM Agreement
-- =============================================
CREATE VIEW [dbo].[SMAgreementWorkOrderList]
AS
	WITH AgreementWorkOrderScope
	AS 
	(
		SELECT ISNULL(SMAgreementServiceDatesGenerated.SMCo, SMAgreementServiceDate.SMCo) SMCo,
			   ISNULL(SMAgreementServiceDatesGenerated.Agreement, SMAgreementServiceDate.Agreement) Agreement,
			   ISNULL(SMAgreementServiceDatesGenerated.Revision, SMAgreementServiceDate.Revision) Revision,
			   ISNULL(SMAgreementServiceDatesGenerated.[Service], SMAgreementServiceDate.[Service]) [Service],
			   ISNULL(SMAgreementServiceDatesGenerated.ServiceDate, SMAgreementServiceDate.ServiceDate) ServiceDate,
			   CASE WHEN SMAgreementServiceDate.ServiceDate IS NOT NULL AND SMAgreementServiceDate.WorkOrder IS NULL THEN 'Skipped' ELSE dbo.vfToString(SMAgreementServiceDate.WorkOrder) END CreatedWorkOrder,
			   SMAgreementServiceDate.WorkOrder,
			   SMAgreementServiceDate.Scope
			FROM SMAgreementServiceDatesGenerated
			FULL JOIN SMAgreementServiceDate ON SMAgreementServiceDatesGenerated.SMCo = SMAgreementServiceDate.SMCo AND
				SMAgreementServiceDatesGenerated.Agreement = SMAgreementServiceDate.Agreement AND
				SMAgreementServiceDatesGenerated.Revision = SMAgreementServiceDate.Revision AND
				SMAgreementServiceDatesGenerated.[Service] = SMAgreementServiceDate.[Service] AND
				SMAgreementServiceDatesGenerated.ServiceDate = SMAgreementServiceDate.ServiceDate
	)

	SELECT SMAgreementService.SMCo,
		SMAgreementService.Agreement,
		SMAgreementExtended.EffectiveDate,
		SMAgreementExtended.EndDate,
		SMAgreementService.Revision,
		SMAgreementService.[Service],
		SMAgreementService.Description [ServiceDesc],
		AgreementWorkOrderScope.ServiceDate, --output so we can sort by for the due date
		AgreementWorkOrderScope.CreatedWorkOrder WorkOrder,
		AgreementWorkOrderScope.Scope,
		CASE WHEN ThisWorkOrderScope.IsComplete IS NULL THEN NULL
			WHEN ThisWorkOrderScope.IsComplete='Y' THEN 'Complete' 
			ELSE 'Open' END Status,
		SMAgreementService.ServiceSite [Site],
		SMAgreementService.[Description] ServiceName,
		CASE SMAgreementService.RecurringPatternType WHEN 'D' THEN 'Daily'
			WHEN 'W' THEN 'Weekly'
			WHEN 'M' THEN 'Monthly'
			WHEN 'Y' THEN 'Yearly' END Frequency,
		CASE SMAgreementService.ScheOptDueType WHEN 1 THEN 'On ' WHEN 2 THEN 'By ' ELSE '' END + CONVERT(VARCHAR, AgreementWorkOrderScope.ServiceDate, 101) + CASE WHEN SMAgreementService.ScheOptDueType = 3 THEN ' - ' + CONVERT(VARCHAR, DATEADD(d, SMAgreementService.ScheOptDays, AgreementWorkOrderScope.ServiceDate), 101) ELSE '' END  DueDate,
		SMWorkOrder.SMWorkOrderID,
		ThisWorkOrderScope.SMWorkOrderScopeID
	FROM dbo.SMAgreementService
		INNER JOIN AgreementWorkOrderScope ON SMAgreementService.SMCo = AgreementWorkOrderScope.SMCo AND
			SMAgreementService.Agreement = AgreementWorkOrderScope.Agreement AND
			SMAgreementService.Revision = AgreementWorkOrderScope.Revision AND 
			SMAgreementService.[Service] = AgreementWorkOrderScope.[Service]
		LEFT JOIN SMAgreementExtended ON SMAgreementService.SMCo = SMAgreementExtended.SMCo AND
			SMAgreementService.Agreement = SMAgreementExtended.Agreement AND
			SMAgreementService.Revision = SMAgreementExtended.Revision
		LEFT JOIN SMWorkOrder
			ON SMWorkOrder.SMCo=AgreementWorkOrderScope.SMCo 
			AND SMWorkOrder.WorkOrder = AgreementWorkOrderScope.WorkOrder
		LEFT JOIN SMWorkOrderScope ThisWorkOrderScope
			ON ThisWorkOrderScope.SMCo=AgreementWorkOrderScope.SMCo 
			AND ThisWorkOrderScope.WorkOrder = AgreementWorkOrderScope.WorkOrder
			AND ThisWorkOrderScope.Scope = AgreementWorkOrderScope.Scope
	
	WHERE SMAgreementExtended.RevisionStatus BETWEEN 2 AND 4 -- Allow generating work orders for active, expired and terminated agreements
GO
GRANT SELECT ON  [dbo].[SMAgreementWorkOrderList] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementWorkOrderList] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementWorkOrderList] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementWorkOrderList] TO [public]
GO
