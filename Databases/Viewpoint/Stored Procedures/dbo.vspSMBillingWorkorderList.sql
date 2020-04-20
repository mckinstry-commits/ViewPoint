SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/11/11
-- Description:	Get a list of Work Order Scope info for multi workorder billing using
--              the provided filter.
-- Modification: MB TK-18934 Multiple Work Order Billing should not have Work Completed with
--				 Cost covered by agreement show up as invoicable item.
--				 LaneG TK-19722 11/29/12 - Added a check for the NonBillable
-- =============================================
CREATE PROCEDURE dbo.vspSMBillingWorkorderList
		@SMCo tinyint, 
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
		SELECT CASE WHEN ISNULL(Amounts.SessionCount,0)=Amounts.RecordCount THEN 'Y' 
			WHEN ISNULL(Amounts.SessionCount,0)>0 THEN null 
			ELSE 'N' END Bill,
			SMWorkOrder.WorkOrder,
			LEFT(SMWorkOrder.Description,60) WorkOrderDescription,
			SMWorkOrderScope.Scope,
			LEFT(SMWorkOrderScope.Description, 60) ScopeDescription,
			SMWorkOrder.Customer,
			CASE WHEN SMWorkOrder.Customer=SMWorkOrderScope.BillToARCustomer THEN NULL ELSE SMWorkOrderScope.BillToARCustomer END BillTo ,
			CASE WHEN SMWorkOrder.Customer=SMWorkOrderScope.BillToARCustomer THEN NULL ELSE ARCM.Name END BillToName,
			SMWorkOrder.ServiceSite,
			vSMServiceSite.Description ServiceSiteDescription,
			SMWorkOrder.ServiceCenter,
			vSMServiceCenter.Description ServiceCenterDescription,
			SMWorkOrderScope.Division,
			SMDivision.Description DivisionDescription,
			Amounts.BillableAmt,
			Amounts.CostAmt,
			ISNULL(Amounts.BillableAmt,0)-ISNULL(Amounts.CostAmt,0) Profit,
			CASE WHEN ISNULL(Amounts.CostAmt,0)=0 THEN 0 ELSE
			 (ISNULL(Amounts.BillableAmt,0)-ISNULL(Amounts.CostAmt,0))/Amounts.CostAmt END Margin,
			SMWorkOrder.SMWorkOrderID WorkOrderKeyID,
			SMWorkOrderScope.SMWorkOrderScopeID ScopeKeyID
		FROM SMWorkOrder 
		INNER JOIN SMWorkOrderScope
			ON SMWorkOrder.SMCo = SMWorkOrderScope.SMCo
			AND SMWorkOrder.WorkOrder = SMWorkOrderScope.WorkOrder
		INNER JOIN ARCM
			ON SMWorkOrder.CustGroup=ARCM.CustGroup
			AND SMWorkOrderScope.BillToARCustomer=ARCM.Customer
		LEFT JOIN vSMServiceSite
			ON vSMServiceSite.SMCo=SMWorkOrder.SMCo
			AND vSMServiceSite.ServiceSite=SMWorkOrder.ServiceSite
		LEFT JOIN vSMServiceCenter 
			ON vSMServiceCenter.SMCo=SMWorkOrder.SMCo
			AND vSMServiceCenter.ServiceCenter=SMWorkOrder.ServiceCenter
		LEFT JOIN SMDivision 
			ON SMDivision.SMCo=SMWorkOrderScope.SMCo
			AND SMDivision.ServiceCenter=SMWorkOrder.ServiceCenter
			AND SMDivision.Division=SMWorkOrderScope.Division
		INNER JOIN (SELECT SMCo, WorkOrder, Scope,
					SUM(1) RecordCount,
					SUM(CASE WHEN SMWorkCompleted.SMSessionID=@SMSessionID THEN 1 ELSE 0 END) SessionCount,
					SUM(CASE WHEN NoCharge='Y' THEN 0 ELSE PriceTotal END) BillableAmt,
					SUM(CASE WHEN ActualCost IS NULL THEN ProjCost ELSE ActualCost END) CostAmt
					FROM SMWorkCompleted 
					WHERE SMWorkCompleted.Provisional=0 
					AND (@DateProvidedMin IS NULL OR SMWorkCompleted.Date >= @DateProvidedMin)
					AND (@DateProvidedMax IS NULL OR SMWorkCompleted.Date <= @DateProvidedMax)
					AND (@LineType IS NULL OR SMWorkCompleted.Type=@LineType)
					AND (SMWorkCompleted.SMSessionID=@SMSessionID 
						OR (SMWorkCompleted.SMSessionID IS NULL 
							AND SMWorkCompleted.SMInvoiceID IS NULL)
						)
					AND (Coverage IS NULL OR Coverage <> 'C')
					AND NOT NonBillable = 'Y'
					GROUP BY SMCo, WorkOrder, Scope) AS Amounts 
			ON Amounts.SMCo=SMWorkOrderScope.SMCo
			AND Amounts.WorkOrder=SMWorkOrderScope.WorkOrder
			AND Amounts.Scope=SMWorkOrderScope.Scope
		LEFT JOIN (SELECT DISTINCT SMCo, WorkOrder, Scope FROM SMWorkCompleted WHERE SMSessionID=@SMSessionID) SessionWorkCompleted 
			ON SessionWorkCompleted.SMCo=SMWorkOrderScope.SMCo
			AND SessionWorkCompleted.WorkOrder=SMWorkOrderScope.WorkOrder
			AND SessionWorkCompleted.Scope=SMWorkOrderScope.Scope
		WHERE SMWorkOrder.SMCo=@SMCo
		  AND ((
			(@ServiceCenter IS NULL OR SMWorkOrder.ServiceCenter=@ServiceCenter)
			AND (@Division IS NULL OR SMWorkOrderScope.Division = @Division)
			AND (@Customer IS NULL OR SMWorkOrder.Customer = @Customer)
			AND (@BillTo IS NULL OR SMWorkOrderScope.BillToARCustomer = @BillTo)
			AND (@ServiceSite IS NULL OR SMWorkOrder.ServiceSite = @ServiceSite)
			)
		  OR NOT SessionWorkCompleted.SMCo IS NULL)
		  
		ORDER BY SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope

	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingWorkorderList] TO [public]
GO
