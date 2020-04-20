SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--		Author:	Lane Gresham
-- Create Date: 09/20/11
-- Description:	Query to get list of items to populate SM Generate PM WorkOrders Search
-- =============================================
CREATE FUNCTION [dbo].[vfSMGeneratePMWorkOrdersSearch]
(
	@SMCo bCompany, 
	@CustGroup bGroup,
	@ServiceCenter varchar(10),
	@Customer bCustomer,
	@ServiceSite varchar(20),
	@AgreementType varchar(15),
	@DueWithinTheNextDay int
)
RETURNS TABLE
AS
RETURN
(	
	SELECT 'Y' [Create],
		   'N' [Skip],
		   SMAgreementService.Agreement,
		   ARCM.Name AS SMCustomer,
		   SMAgreementService.Revision Rev,
		   SMAgreementService.[Service],
		   SMAgreementService.ServiceSite [Site],
		   SMAgreementExtended.AgreementType AS SMAgreementType,
		   SMAgreementService.[Description] ServiceName,
		   CASE SMAgreementService.RecurringPatternType WHEN 'D' THEN 'Daily'
														WHEN 'W' THEN 'Weekly'
														WHEN 'M' THEN 'Monthly'
														WHEN 'Y' THEN 'Yearly' END Frequency,
		   SMAgreementServiceDatesGenerated.ServiceDate,
		   WorkOrderScope.[Date] LastPerformed,
		   WorkOrderScope.ScopeStatus LastScopeStatus,
		   SMContact.FullName ContactName,
		   SMContact.Phone ContactPhone,
		   SMAgreementService.ScheOptDueType,
		   SMAgreementService.ScheOptDays
	FROM dbo.SMAgreementService
		INNER JOIN SMAgreementServiceDatesGenerated ON SMAgreementService.SMCo = SMAgreementServiceDatesGenerated.SMCo AND
											 SMAgreementService.Agreement = SMAgreementServiceDatesGenerated.Agreement AND
											 SMAgreementService.Revision = SMAgreementServiceDatesGenerated.Revision AND 
											 SMAgreementService.[Service] = SMAgreementServiceDatesGenerated.[Service]
		LEFT JOIN SMAgreementServiceDate ON SMAgreementServiceDatesGenerated.SMCo = SMAgreementServiceDate.SMCo AND
											SMAgreementServiceDatesGenerated.Agreement = SMAgreementServiceDate.Agreement AND
											SMAgreementServiceDatesGenerated.Revision = SMAgreementServiceDate.Revision AND
											SMAgreementServiceDatesGenerated.[Service] = SMAgreementServiceDate.[Service] AND
											SMAgreementServiceDatesGenerated.ServiceDate = SMAgreementServiceDate.ServiceDate
		OUTER APPLY (SELECT TOP 1 SMAgreementServiceDate.ServiceDate LastServiceDate, SMAgreementServiceDate.SMCo, SMAgreementServiceDate.WorkOrder, SMAgreementServiceDate.Scope 
					FROM SMAgreementServiceDate
					WHERE SMAgreementServiceDate.SMCo=SMAgreementService.SMCo
						AND SMAgreementServiceDate.Agreement=SMAgreementService.Agreement
						AND SMAgreementServiceDate.Revision=SMAgreementService.Revision
						AND SMAgreementServiceDate.Service=SMAgreementService.Service
						AND SMAgreementServiceDate.WorkOrder IS NOT NULL
					ORDER BY SMAgreementServiceDate.ServiceDate DESC) LastAgreementServiceDate
		LEFT JOIN SMAgreementExtended ON SMAgreementService.SMCo = SMAgreementExtended.SMCo AND
						 SMAgreementService.Agreement = SMAgreementExtended.Agreement AND
						 SMAgreementService.Revision = SMAgreementExtended.Revision
		LEFT JOIN SMServiceSite ON SMAgreementService.SMCo = SMServiceSite.SMCo AND
									SMAgreementService.ServiceSite = SMServiceSite.ServiceSite
		LEFT JOIN ARCM ON SMAgreementExtended.CustGroup = ARCM.CustGroup AND 
						  SMAgreementExtended.Customer = ARCM.Customer
		LEFT JOIN SMContact ON SMServiceSite.ContactGroup = SMContact.ContactGroup AND
							   SMServiceSite.ContactSeq = SMContact.ContactSeq
		OUTER APPLY (SELECT TOP 1 CASE WHEN SMWorkOrderScope.IsComplete='Y' THEN 'Complete' ELSE 'Open' END ScopeStatus, Date
			FROM SMWorkOrderScope
			LEFT JOIN SMWorkCompleted ON SMWorkOrderScope.SMCo=SMWorkCompleted.SMCo
				AND SMWorkOrderScope.WorkOrder=SMWorkCompleted.WorkOrder
				AND SMWorkOrderScope.Scope=SMWorkCompleted.Scope
			WHERE SMWorkOrderScope.SMCo=LastAgreementServiceDate.SMCo
				AND SMWorkOrderScope.WorkOrder=LastAgreementServiceDate.WorkOrder
				AND SMWorkOrderScope.Scope=LastAgreementServiceDate.Scope
			ORDER BY SMWorkCompleted.Date DESC) WorkOrderScope
	WHERE SMAgreementService.SMCo = @SMCo AND
		  SMAgreementServiceDate.ServiceDate IS NULL AND --Filter out the service dates that had a workorder generated or was skipped
		  SMAgreementExtended.RevisionStatus BETWEEN 2 AND 4 AND -- Allow generating work orders for active, expired and terminated agreements
		  (@Customer IS NULL OR SMAgreementExtended.CustGroup = @CustGroup AND SMAgreementExtended.Customer = @Customer) AND
		  (@ServiceCenter IS NULL OR @ServiceCenter = ISNULL(SMAgreementService.ServiceCenter, SMServiceSite.DefaultServiceCenter)) AND
		  (@ServiceSite IS NULL OR SMAgreementService.ServiceSite = @ServiceSite) AND
		  (@AgreementType IS NULL OR SMAgreementExtended.AgreementType = @AgreementType) AND
		  SMAgreementServiceDatesGenerated.ServiceDate <= DATEADD(d,@DueWithinTheNextDay,dbo.vfDateOnly())
)
GO
GRANT SELECT ON  [dbo].[vfSMGeneratePMWorkOrdersSearch] TO [public]
GO
