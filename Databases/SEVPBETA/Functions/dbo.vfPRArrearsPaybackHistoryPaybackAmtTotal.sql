SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ellen Noel
-- Create date: 08/08/2012
-- Description:	Returns the total amount of payback in PRArrears table for a given prco/employee/dedcode
-- =============================================
CREATE FUNCTION [dbo].[vfPRArrearsPaybackHistoryPaybackAmtTotal]
	(@Key_PRCo bCompany, @Key_Employee bEmployee, @Key_DedCode bEDLCode)
RETURNS bDollar
AS
BEGIN
	DECLARE @PaybackAmtTotal bDollar
	SELECT @PaybackAmtTotal = SUM(PaybackAmt)
	FROM dbo.PRArrears
	WHERE PRCo = @Key_PRCo AND
		  Employee = @Key_Employee AND
		  DLCode = @Key_DedCode
	
	RETURN ISNULL(@PaybackAmtTotal, 0)
END
	  

GO
GRANT EXECUTE ON  [dbo].[vfPRArrearsPaybackHistoryPaybackAmtTotal] TO [public]
GO
