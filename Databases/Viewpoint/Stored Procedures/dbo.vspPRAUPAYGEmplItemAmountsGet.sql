SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGEmplItemAmountsGet    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGEmplItemAmountsGet]
/***********************************************************/
-- CREATED BY: EN 6/21/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Gets the PAYG ATO/Super Amounts for a specific employee.  
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
 @FBTBeginMonth bDate = NULL, 
 @FBTEndMonth bDate = NULL,
 @ThruDate bDate = NULL,
 @LastDateOfEndMonth bDate = NULL,
 @FBTLastDateOfEndMonth bDate = NULL,
 @Message varchar(4000) OUTPUT
)
AS
SET NOCOUNT ON

-- Search for amounts
;
WITH
	-- Determine the list of Item Codes and EDLTypes/EDLCodes specified by user needed to populate amounts
	EmployerItems (ItemCode, EDLType, EDLCode)
	AS	(
		SELECT	ItemCode, EDLType, EDLCode 
		FROM dbo.vPRAUEmployerATOItems 
		WHERE	PRCo = @PRCo AND TaxYear = @TaxYear
		UNION
		SELECT	ItemCode, DLType AS [EDLType], DLCode AS [EDLCode] 
		FROM dbo.vPRAUEmployerSuperItems 
		WHERE	PRCo = @PRCo AND TaxYear = @TaxYear
		)
, 
	AmountData (ItemCode, EDLType, Amount, LSAType)
	AS	(
		-- Using Detail (PRDT) when first month of summary is a partial month
		-- This would never be the first summary for the employee/tax year 
		-- Items besides GR, FBT, and LSA
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
				AND @FirstMonthIsPartialYN = 'Y' 
				AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode NOT IN ('GR  ', 'FBT ', 'LSA ')
		GROUP BY Items.ItemCode, Items.EDLType
		
		UNION
	
		-- GR Deductions subject amount (+)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PRDT.SubjectAmt), 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
				AND @FirstMonthIsPartialYN = 'Y' 
				AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'D'
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
			
		-- GR Earnings amount (-)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
				AND @FirstMonthIsPartialYN = 'Y' 
				AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
			
		-- FBT Earnings and Liabilities (+)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
				AND @FirstMonthIsPartialYN = 'Y' 
				AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND (Items.ItemCode = 'FBT ' AND Items.EDLType IN ('E', 'L'))
		GROUP BY Items.ItemCode, Items.EDLType
		
		UNION
		
		-- FBT Deductions (-)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
				AND @FirstMonthIsPartialYN = 'Y' 
				AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND (Items.ItemCode = 'FBT ' AND Items.EDLType = 'D')
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
		
		-- LSA items
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
				(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		JOIN dbo.bPREC PREC (nolock) ON PREC.PRCo = PRDT.PRCo AND PRDT.EDLType = 'E' AND PREC.EarnCode = PRDT.EDLCode
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
				AND @FirstMonthIsPartialYN = 'Y' 
				AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode = 'LSA '
		GROUP BY Items.ItemCode, Items.EDLType, PREC.ATOCategory

		UNION
		
		-- Adding ACCUMS (PRAU)
		-- Items besides GR, FBT, and LSA
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PREA.Amount), 
				NULL 
		FROM EmployerItems Items
		JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
				AND Items.ItemCode NOT IN ('GR  ', 'FBT ', 'LSA ')
		GROUP BY Items.ItemCode, Items.EDLType
		
		UNION
	
		-- GR Deductions subject amount (+)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PREA.SubjectAmt), 
				NULL 
		FROM EmployerItems Items
		JOIN dbo.bPREA PREA (nolock)ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
				AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'D'
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
			
		-- GR Earnings amount (-)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PREA.Amount) * -1, 
				NULL 
		FROM EmployerItems Items
		JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
				AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
			
		-- FBT Earnings and Liabilities (+)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PREA.Amount), 
				NULL 
		FROM EmployerItems Items
		JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @FBTBeginMonth AND @FBTEndMonth 
				AND (Items.ItemCode = 'FBT ' AND Items.EDLType IN ('E', 'L'))
		GROUP BY Items.ItemCode, Items.EDLType
		
		UNION
		
		-- FBT Deductions (-)
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PREA.Amount) * -1, 
				NULL 
		FROM EmployerItems Items
		JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @FBTBeginMonth AND @FBTEndMonth 
				AND (Items.ItemCode = 'FBT ' AND Items.EDLType = 'D')
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
		
		-- LSA items
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PREA.Amount), 
				(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) 
		FROM EmployerItems Items
		JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		JOIN dbo.bPREC PREC (nolock) ON PREC.PRCo = PREA.PRCo AND PREA.EDLType = 'E' AND PREC.EarnCode = PREA.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
				AND Items.ItemCode = 'LSA '
		GROUP BY Items.ItemCode, Items.EDLType, PREC.ATOCategory

		UNION
		
		-- Subtracting Detail (PRDT) from last month accums when getting amounts for partial last month
		-- Subtract Items besides GR, FBT, and LSA
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
				AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode NOT IN ('GR  ', 'FBT ', 'LSA ')
		GROUP BY Items.ItemCode, Items.EDLType
		
		UNION
	
		-- Subtract GR Deductions subject amount
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(PRDT.SubjectAmt) * -1, 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
				AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'D'
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
			
		-- Add back GR Earnings amount
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
				AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
			
		-- Subtract FBT Earnings and Liabilities
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
				AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @FBTLastDateOfEndMonth
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND (Items.ItemCode = 'FBT ' AND Items.EDLType IN ('E', 'L'))
		GROUP BY Items.ItemCode, Items.EDLType
		
		UNION
		
		-- Add back FBT Deductions
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
				NULL 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
				AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @FBTLastDateOfEndMonth
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND (Items.ItemCode = 'FBT ' AND Items.EDLType = 'D')
		GROUP BY Items.ItemCode, Items.EDLType

		UNION
		
		-- Subtract LSA items
		SELECT	Items.ItemCode, 
				Items.EDLType, 
				SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
				(CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END) 
		FROM dbo.bPRDT PRDT (nolock)
		JOIN EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
										AND PRSQ.Employee = PRDT.Employee
		JOIN dbo.bPREC PREC (nolock) ON PREC.PRCo = PRDT.PRCo AND PRDT.EDLType = 'E' AND PREC.EarnCode = PRDT.EDLCode
		WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee AND 
				PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
				AND PRSQ.CMRef IS NOT NULL
				AND PRDT.OldMth IS NOT NULL
				AND Items.ItemCode = 'LSA '
		GROUP BY Items.ItemCode, Items.EDLType, PREC.ATOCategory

		)
		
SELECT * FROM AmountData



GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGEmplItemAmountsGet] TO [public]
GO
