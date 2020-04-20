SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGEmplMiscAmountsGet    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGEmplMiscAmountsGet]
/***********************************************************/
-- CREATED BY: EN 6/21/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Gets the PAYG Misc Amounts for a specific employee.  
--
-- INPUT PARAMETERS
--   @PRCo		PR Company
--   @TaxYear	Tax Year
--	 @Employee	Employee
--	 @EndDate	Ending Date of pay date range to update
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @PRCo bCompany = NULL,
 @TaxYear char(4) = NULL,
 @Employee bEmployee = NULL,
 @FirstMonthIsPartialYN bYN = 'N',
 @FromDate bDate = NULL,
 @PartialMonthThruDate bDate = NULL,
 @PRAUBeginMonth bDate = NULL,
 @PRAUEndMonth bDate = NULL,
 @ThruDate bDate = NULL,
 @LastDateOfEndMonth bDate = NULL,
 @Message varchar(4000) OUTPUT
)
AS
SET NOCOUNT ON

	-- Using Detail (PRDT) when first month of summary is a partial month
	-- This would never be the first summary for the employee/tax year 
	SELECT Items.ItemCode,  
		   Items.EDLType, 
		   Items.EDLCode, 
		   SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END)
	FROM dbo.bPRDT PRDT (nolock)
	JOIN dbo.vPRAUEmployerMiscItems Items ON Items.PRCo = PRDT.PRCo AND Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
	JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
									AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
									AND PRSQ.Employee = PRDT.Employee
	WHERE	PRDT.PRCo = @PRCo AND Items.TaxYear = @TaxYear 
			AND PRDT.Employee = @Employee 
			AND @FirstMonthIsPartialYN = 'Y' 
			AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
			AND PRSQ.CMRef IS NOT NULL
			AND PRDT.OldMth IS NOT NULL
	GROUP BY Items.ItemCode, Items.EDLType, Items.EDLCode

	UNION

	-- Adding ACCUMS (PRAU)
	SELECT Items.ItemCode, 
		   Items.EDLType, 
		   Items.EDLCode, 
		   SUM(PREA.Amount) 
	FROM dbo.vPRAUEmployerMiscItems Items
	JOIN dbo.bPREA PREA (nolock) ON PREA.PRCo = Items.PRCo AND PREA.EDLType = Items.EDLType 
									AND PREA.EDLCode = Items.EDLCode
	WHERE	Items.PRCo = @PRCo AND Items.TaxYear = @TaxYear 
			AND PREA.Employee = @Employee
			AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
	GROUP BY Items.ItemCode, Items.EDLType, Items.EDLCode

	UNION

	-- Subtracting Detail (PRDT) from last month accums when getting amounts for partial last month
	SELECT Items.ItemCode,  
		   Items.EDLType, 
		   Items.EDLCode, 
		   SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1
	FROM dbo.bPRDT PRDT (nolock)
	JOIN dbo.vPRAUEmployerMiscItems Items ON Items.PRCo = PRDT.PRCo AND Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
	JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
									AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
									AND PRSQ.Employee = PRDT.Employee
	WHERE	PRDT.PRCo = @PRCo AND Items.TaxYear = @TaxYear 
			AND PRDT.Employee = @Employee 
			AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
			AND PRSQ.CMRef IS NOT NULL
			AND PRDT.OldMth IS NOT NULL
	GROUP BY Items.ItemCode, Items.EDLType, Items.EDLCode
	--)
	



GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGEmplMiscAmountsGet] TO [public]
GO
