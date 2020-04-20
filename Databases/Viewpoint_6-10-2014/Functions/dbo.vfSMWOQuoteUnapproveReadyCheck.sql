SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		David Solheim
-- Create date: 6/11/13
-- Description:	Determines if a Work Order Quote has billings, WC, or new scopes
-- =============================================
CREATE FUNCTION [dbo].[vfSMWOQuoteUnapproveReadyCheck]
(	
	@SMCo bCompany, @WorkOrderQuote varchar(15)
)
RETURNS bYN
AS
BEGIN
	DECLARE @Ready bYN

	SET @Ready = (SELECT
	(
	CASE WHEN 
		EXISTS (
			SELECT 1 FROM SMInvoiceDetail 
			where SMInvoiceDetail.SMCo = @SMCo
			AND SMInvoiceDetail.WorkOrder = WOScope.WorkOrder) 
		OR EXISTS (
			SELECT 1 FROM SMWorkCompleted 
			where SMWorkCompleted.SMCo = @SMCo
			AND SMWorkCompleted.WorkOrder = WOScope.WorkOrder
			AND SMWorkCompleted.AutoAdded = 0) 
		OR EXISTS (SELECT 1 FROM SMWorkOrderScope 
			where SMWorkOrderScope.SMCo = @SMCo
			AND SMWorkOrderScope.WorkOrder = WOScope.WorkOrder 
			AND ISNULL(SMWorkOrderScope.WorkOrderQuote, '') <> @WorkOrderQuote) 
	THEN 'Y' 
	ELSE 'N' 
	END)
	FROM SMWorkOrderQuoteExt
	OUTER APPLY (
		SELECT TOP 1 *
		FROM dbo.SMWorkOrderScope
		WHERE SMWorkOrderQuoteExt.SMCo = SMWorkOrderScope.SMCo AND
			SMWorkOrderQuoteExt.WorkOrderQuote = SMWorkOrderScope.WorkOrderQuote
		) WOScope
	WHERE SMWorkOrderQuoteExt.SMCo = @SMCo
	AND SMWorkOrderQuoteExt.WorkOrderQuote = @WorkOrderQuote
	)

	RETURN @Ready
END
GO
GRANT EXECUTE ON  [dbo].[vfSMWOQuoteUnapproveReadyCheck] TO [public]
GO
