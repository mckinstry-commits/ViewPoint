SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/11/11
-- Description:	Get a list of Work Completed info for a selected workorder from the multi billing form
--              using the work order, scope and the provided filter.
-- Modification:MB TK-18934 Update so that price included in agreement work completed will not be billable.
--				LaneG TK-19722 11/29/12 - Added a check for the NonBillable
-- =============================================
CREATE PROCEDURE dbo.vspSMBillingWorkCompletedList
		@SMCo tinyint,
		@WorkOrder int,
		@Scope int,
		@SMSessionID int=NULL,
		@ServiceCenter varchar(10)=NULL,
		@Division varchar(10)=NULL,
		@Customer int=NULL,
		@BillTo int=NULL,
		@ServiceSite varchar(20)=NULL,
		@DateProvidedMin smalldatetime=NULL,
		@DateProvidedMax smalldatetime=NULL,
		@LineType tinyint=NULL,
		@msg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT CASE WHEN SMWorkCompleted.SMSessionID=@SMSessionID AND NOT @SMSessionID IS NULL THEN 'Y' ELSE 'N' END Bill,
		SMWorkOrderScope.WorkOrder, 
		SMWorkOrderScope.Scope,
		WorkCompleted, 
		Type, 
		SMInvoice.Invoice, Date, 
		SMWorkCompleted.ReferenceNo,
		SMWorkCompleted.Description, ProjCost, ActualCost, PriceTotal,
		SMInvoice.SMInvoiceID,
		SMWorkOrderScope.SMWorkOrderScopeID AS KeyID
		FROM SMWorkOrder
		LEFT JOIN SMWorkOrderScope ON SMWorkOrderScope.SMCo=SMWorkOrder.SMCo
			AND SMWorkOrderScope.WorkOrder=SMWorkOrder.WorkOrder
		LEFT JOIN SMWorkCompleted	
			ON SMWorkCompleted.SMCo=SMWorkOrderScope.SMCo
			AND SMWorkCompleted.WorkOrder=SMWorkOrderScope.WorkOrder
			AND SMWorkCompleted.Scope=SMWorkOrderScope.Scope
		LEFT JOIN SMInvoice
			ON SMInvoice.SMCo=SMWorkCompleted.SMCo
			AND SMInvoice.SMInvoiceID=SMWorkCompleted.SMInvoiceID
		LEFT JOIN (SELECT DISTINCT SMCo, WorkOrder, Scope FROM SMWorkCompleted
				WHERE SMSessionID=@SMSessionID) AS SessionWorkorderScopes
			ON SessionWorkorderScopes.SMCo=SMWorkCompleted.SMCo
			AND SessionWorkorderScopes.WorkOrder=SMWorkCompleted.WorkOrder
			AND SessionWorkorderScopes.Scope=SMWorkCompleted.Scope
		WHERE SMWorkOrder.SMCo=@SMCo
			AND SMWorkCompleted.Provisional=0 
			AND (SMWorkOrderScope.WorkOrder=@WorkOrder OR @WorkOrder IS NULL)
			AND (SMWorkOrderScope.Scope=@Scope OR @Scope IS NULL)
			AND ((
				(SMWorkCompleted.SMSessionID=@SMSessionID 
				OR (SMWorkCompleted.SMSessionID IS NULL AND SMWorkCompleted.SMInvoiceID IS NULL))
				AND (@DateProvidedMin IS NULL OR SMWorkCompleted.Date >= @DateProvidedMin)
				AND (@DateProvidedMax IS NULL OR SMWorkCompleted.Date <= @DateProvidedMax)
				AND (@LineType IS NULL OR SMWorkCompleted.Type=@LineType)
				AND (@ServiceCenter IS NULL OR SMWorkOrder.ServiceCenter=@ServiceCenter)
				AND (@Division IS NULL OR SMWorkOrderScope.Division = @Division)
				AND (@Customer IS NULL OR SMWorkOrder.Customer = @Customer)
				AND (@BillTo IS NULL OR SMWorkOrderScope.BillToARCustomer = @BillTo)
				AND (@ServiceSite IS NULL OR SMWorkOrder.ServiceSite = @ServiceSite)) 
			 OR (SessionWorkorderScopes.WorkOrder IS NOT NULL
				AND (SMWorkCompleted.SMInvoiceID IS NULL
				OR SMWorkCompleted.SMSessionID=@SMSessionID))
			 )
			 AND (SMWorkCompleted.Coverage IS NULL OR SMWorkCompleted.Coverage <> 'C')
			 AND NOT SMWorkCompleted.NonBillable = 'Y'
		ORDER BY SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope, Type, WorkCompleted  
		RETURN 0
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingWorkCompletedList] TO [public]
GO
