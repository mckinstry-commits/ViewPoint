SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ellen Noel
-- Create date: 08/08/2012
-- Description:	Returns the Life To Date balance in PRED table for a given prco/employee/dedcode.
--				This is specifically for deductions that are subject to arrears.
-- =============================================
CREATE FUNCTION [dbo].[vfPREmplDLLifeToDateBalance]
	(@Key_PRCo bCompany, @Key_Employee bEmployee, @Key_DedCode bEDLCode)
RETURNS bDollar
AS
BEGIN
	DECLARE @LifeToDateBalance bDollar
	SELECT @LifeToDateBalance = LifeToDateArrears - LifeToDatePayback
	FROM dbo.PRED
	WHERE PRCo = @Key_PRCo AND
		  Employee = @Key_Employee AND
		  DLCode = @Key_DedCode
	
	RETURN ISNULL(@LifeToDateBalance, 0)
END
	  
GO
GRANT EXECUTE ON  [dbo].[vfPREmplDLLifeToDateBalance] TO [public]
GO
