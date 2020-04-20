SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/24/11
-- Description:	Get a list of invoices contents with a description.
-- =============================================
CREATE PROCEDURE dbo.vspSMBillingInvoiceContentList
		@SMCo tinyint, 
		@SMInvoiceID int=NULL,
		@msg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@SMInvoiceID IS NULL)
	BEGIN
		SET @msg = 'Missing SM Invoice ID!'
		RETURN 1
	END	

	BEGIN TRY
		
		SELECT Distinct SMWorkCompleted.SMInvoiceID, SMWorkOrderScope.SMWorkOrderScopeID AS KeyID, 'WO: '+dbo.vfToString(SMWorkOrderScope.WorkOrder)+' Scope Seq: '+dbo.vfToString(SMWorkOrderScope.Scope) + ' ' + dbo.vfToString(SMWorkOrderScope.Description) Description
		FROM SMWorkCompleted 
		INNER JOIN SMWorkOrderScope 
			ON SMWorkOrderScope.SMCo = SMWorkCompleted.SMCo
			AND SMWorkOrderScope.WorkOrder = SMWorkCompleted.WorkOrder
			AND SMWorkOrderScope.Scope = SMWorkCompleted.Scope
		WHERE SMInvoiceID = @SMInvoiceID

		RETURN 0
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingInvoiceContentList] TO [public]
GO
