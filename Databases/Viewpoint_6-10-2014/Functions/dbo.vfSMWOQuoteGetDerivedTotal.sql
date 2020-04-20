SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		David Solheim
-- Create date: 5/29/13
-- Description:	Fetched the derived cost total for a work order quote
-- =============================================
CREATE FUNCTION [dbo].[vfSMWOQuoteGetDerivedTotal]
(	
	@SMCo bCompany, @WorkOrderQuote varchar(15), @WorkOrderQuoteScope int
)
RETURNS int
AS
BEGIN
	DECLARE @Total int

	SET @Total = (
		ISNULL((select SUM(CostTotal) from SMRequiredMaterial 
		join SMEntityExt on SMRequiredMaterial.EntitySeq = SMEntityExt.EntitySeq
		WHERE SMRequiredMaterial.SMCo = @SMCo AND WorkOrderQuote = @WorkOrderQuote AND WorkOrderQuoteScope = @WorkOrderQuoteScope), 0)
		+
		ISNULL((select SUM(CostTotal) from SMRequiredMisc 
		join SMEntityExt on SMRequiredMisc.EntitySeq = SMEntityExt.EntitySeq
		WHERE SMRequiredMisc.SMCo = @SMCo AND WorkOrderQuote = @WorkOrderQuote AND WorkOrderQuoteScope = @WorkOrderQuoteScope), 0)
		+
		ISNULL((select SUM(CostRate * Qty) from SMRequiredLabor
		join SMEntityExt on SMRequiredLabor.EntitySeq = SMEntityExt.EntitySeq
		WHERE SMRequiredLabor.SMCo = @SMCo AND WorkOrderQuote = @WorkOrderQuote AND WorkOrderQuoteScope = @WorkOrderQuoteScope), 0)
		+
		ISNULL((select SUM(CostRate * RevQty * EquipQty) from SMRequiredEquipment
		join SMEntityExt on SMRequiredEquipment.EntitySeq = SMEntityExt.EntitySeq
		WHERE SMRequiredEquipment.SMCo = @SMCo AND WorkOrderQuote = @WorkOrderQuote AND WorkOrderQuoteScope = @WorkOrderQuoteScope), 0)
		)

	RETURN @Total
END
GO
GRANT EXECUTE ON  [dbo].[vfSMWOQuoteGetDerivedTotal] TO [public]
GO
