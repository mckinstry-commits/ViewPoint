SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/11/12
-- Description:	Retrieves SMInvoiceID that are related to a work order
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetWorkOrderInvoices]
(	
	@SMCo bCompany, @WorkOrder int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT DISTINCT SMInvoiceID
	FROM dbo.SMWorkCompleted 
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND SMInvoiceID IS NOT NULL
)
GO
GRANT SELECT ON  [dbo].[vfSMGetWorkOrderInvoices] TO [public]
GO
