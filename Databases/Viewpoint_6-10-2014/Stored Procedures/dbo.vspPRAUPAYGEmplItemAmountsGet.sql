SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGEmplItemAmountsGet    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGEmplItemAmountsGet]
/***********************************************************/
-- CREATED BY: EN 6/21/2011
-- MODIFIED BY: EN 02/27/2013  TFS-39858
--				EN 5/14/2013 User Story 39860 / Task 42416 - mods to vspPR_AU_ETP_LimitsAndRatesGet output params
--				EN 5/15/2013 User Story 39860 / Task 42416 - mods to vspPR_AU_ETP_RedundancyTaxFreeGet params
--				EN 5/20/2013 User Story 49517 / Task 50627 - Do NOT include ETP in Gross Payments which includes not backing out Lump Sum D from Gross Payments
--				EN 5/20/2013 User Story 50989 / Task 50990 - **CLEANUP** No need to dis-include ETP earnings in Gross Payments since they are no longer included in the vPRAUEmployerATOItems list
-- USAGE:
-- Gets the PAYG ATO/Super Amounts for a specific employee.  
--
-- INPUT PARAMETERS
--   @PRCo					PR Company
--   @TaxYear				Tax Year
--	 @Employee				Employee
--	 @FirstMonthIsPartialYN
--	 @FromDate
--	 @PartialMonthThruDate
--	 @PRAUBeginMonth
--	 @PRAUEndMonth
--	 @FBTBeginMonth
--	 @FBTEndMonth
--	 @EndDate				Ending Date of pay date range to update
--	 @LastDateOfEndMonth
--	 @FBTLastDateOfEndMonth
--
-- OUTPUT PARAMETERS
--   @errmsg	Error message if error occurs	
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
 @errmsg varchar(4000) OUTPUT
)
AS
SET NOCOUNT ON

DECLARE @rcode int
SET @rcode = 0

-- Search for amounts
DECLARE @EmployerItems TABLE (ItemCode char(4) NOT NULL,
							  EDLType char(1) NOT NULL,
							  EDLCode bEDLCode NOT NULL)

INSERT @EmployerItems
		SELECT	ItemCode, EDLType, EDLCode 
		FROM dbo.vPRAUEmployerATOItems 
		WHERE	PRCo = @PRCo AND TaxYear = @TaxYear
		UNION
		SELECT	ItemCode, DLType AS [EDLType], DLCode AS [EDLCode] 
		FROM dbo.vPRAUEmployerSuperItems 
		WHERE	PRCo = @PRCo AND TaxYear = @TaxYear

DECLARE @AmountData TABLE (ItemCode char(4) NOT NULL, 
						   EDLType char(1) NOT NULL, 
						   Amount bDollar NOT NULL, 
						   LSAType char(1) NULL)
 
-- Search for amounts
INSERT @AmountData
	-- Using Detail (PRDT) when first month of summary is a partial month
	-- This would never be the first summary for the employee/tax year 
	-- Items besides GR, FBT, and LSA
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
			NULL 
	FROM dbo.bPRDT PRDT (nolock)
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
		
	-- GR Earnings amount (-)  Taxable Allowances as well as Lump Sum A, B, and E reduce the reported Gross Payments amount
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
			NULL 
	FROM dbo.bPRDT PRDT (nolock)
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
	JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
									AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
									AND PRSQ.Employee = PRDT.Employee
	JOIN dbo.PREC PREC ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode
	WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
			AND @FirstMonthIsPartialYN = 'Y' 
			AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
			AND PRSQ.CMRef IS NOT NULL
			AND PRDT.OldMth IS NOT NULL
			AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
			--AND PREC.ATOCategory NOT IN ('ETP', 'ETPR', 'ETPV', 'ETPU', 'ETPD')
	GROUP BY Items.ItemCode, Items.EDLType

	--UNION
		
	---- GR Earnings amount (+)  Include ETP, ETPR (Lump Sum D exclusion in code to follow), ETPV, ETPU, and ETPD in reported Gross Payments amount
	--SELECT	Items.ItemCode, 
	--		Items.EDLType, 
	--		SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
	--		NULL 
	--FROM dbo.bPRDT PRDT (nolock)
	--JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
	--JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
	--								AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
	--								AND PRSQ.Employee = PRDT.Employee
	--JOIN dbo.PREC PREC ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode
	--WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee
	--		AND @FirstMonthIsPartialYN = 'Y' 
	--		AND PRSQ.PaidDate BETWEEN @FromDate AND @PartialMonthThruDate
	--		AND PRSQ.CMRef IS NOT NULL
	--		AND PRDT.OldMth IS NOT NULL
	--		AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
	--		AND PREC.ATOCategory IN ('ETP', 'ETPR', 'ETPV', 'ETPU', 'ETPD')
	--GROUP BY Items.ItemCode, Items.EDLType

	UNION
		
	-- FBT Earnings and Liabilities (+)
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
			NULL 
	FROM dbo.bPRDT PRDT (nolock)
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	FROM @EmployerItems Items
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
	FROM @EmployerItems Items
	JOIN dbo.bPREA PREA (nolock)ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
	WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
			AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
			AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'D'
	GROUP BY Items.ItemCode, Items.EDLType

	UNION
		
	-- GR Earnings amount (-)  Taxable Allowances as well as Lump Sum A, B, and E reduce the reported Gross Payments amount
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(PREA.Amount) * -1, 
			NULL 
	FROM @EmployerItems Items
	JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
	JOIN dbo.PREC PREC ON PREC.PRCo = PREA.PRCo AND PREC.EarnCode = PREA.EDLCode
	WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
			AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
			AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
			--AND PREC.ATOCategory NOT IN ('ETP', 'ETPR', 'ETPV', 'ETPU', 'ETPD')
	GROUP BY Items.ItemCode, Items.EDLType

	--UNION
		
	---- GR Earnings amount (+)  Include ETP, ETPR (Lump Sum D exclusion in code to follow), ETPV, ETPU, and ETPD in reported Gross Payments amount
	--SELECT	Items.ItemCode, 
	--		Items.EDLType, 
	--		SUM(PREA.Amount), 
	--		NULL 
	--FROM @EmployerItems Items
	--JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
	--JOIN dbo.PREC PREC ON PREC.PRCo = PREA.PRCo AND PREC.EarnCode = PREA.EDLCode
	--WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
	--		AND PREA.Mth BETWEEN @PRAUBeginMonth AND @PRAUEndMonth 
	--		AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
	--		AND PREC.ATOCategory IN ('ETP', 'ETPR', 'ETPV', 'ETPU', 'ETPD')
	--GROUP BY Items.ItemCode, Items.EDLType

	UNION
			
	-- FBT Earnings and Liabilities (+)
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(PREA.Amount), 
			NULL 
	FROM @EmployerItems Items
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
	FROM @EmployerItems Items
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
	FROM @EmployerItems Items
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
		
	-- Add back GR Earnings amounts for Taxable Allowances as well as Lump Sum A, B, and E
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END), 
			NULL 
	FROM dbo.bPRDT PRDT (nolock)
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
	JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
									AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
									AND PRSQ.Employee = PRDT.Employee
	JOIN dbo.PREC PREC ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode
	WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
			AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
			AND PRSQ.CMRef IS NOT NULL
			AND PRDT.OldMth IS NOT NULL
			AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
			--AND PREC.ATOCategory NOT IN ('ETP', 'ETPR', 'ETPV', 'ETPU', 'ETPD')
	GROUP BY Items.ItemCode, Items.EDLType

	--UNION
		
	---- Subtract GR Earnings amount for ATO Categories ETP, ETPR (Lump Sum D exclusion in code to follow), ETPV, ETPU, and ETPD
	--SELECT	Items.ItemCode, 
	--		Items.EDLType, 
	--		SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
	--		NULL 
	--FROM dbo.bPRDT PRDT (nolock)
	--JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
	--JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup 
	--								AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.PaySeq = PRDT.PaySeq 
	--								AND PRSQ.Employee = PRDT.Employee
	--JOIN dbo.PREC PREC ON PREC.PRCo = PRDT.PRCo AND PREC.EarnCode = PRDT.EDLCode
	--WHERE	PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
	--		AND PRSQ.PaidDate BETWEEN DATEADD(Day, 1, @ThruDate) AND @LastDateOfEndMonth
	--		AND PRSQ.CMRef IS NOT NULL
	--		AND PRDT.OldMth IS NOT NULL
	--		AND Items.ItemCode = 'GR  ' AND Items.EDLType = 'E'
	--		AND PREC.ATOCategory IN ('ETP', 'ETPR', 'ETPV', 'ETPU', 'ETPD')
	--GROUP BY Items.ItemCode, Items.EDLType

	UNION
		
	-- Subtract FBT Earnings and Liabilities
	SELECT	Items.ItemCode, 
			Items.EDLType, 
			SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END) * -1, 
			NULL 
	FROM dbo.bPRDT PRDT (nolock)
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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
	JOIN @EmployerItems Items ON Items.EDLType = PRDT.EDLType AND Items.EDLCode = PRDT.EDLCode
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

-- If employee was terminated for reason of genuine redundancy or approved early retirement,
-- exclude Lump Sum D (Tax-Free) portion of ETPR payments from Gross Payments.
DECLARE	@SeparationRedundancyRetirement bYN,
		@HireDate bDate,
		@SeparationDate bDate,
		@TaxFreePortion bDollar,
		@ETPRTaxablePortion bDollar

SELECT @SeparationRedundancyRetirement = SeparationRedundancyRetirement,
	   @HireDate = (CASE WHEN RecentRehireDate IS NULL THEN HireDate ELSE RecentRehireDate END),
	   @SeparationDate = RecentSeparationDate

FROM dbo.bPREH
WHERE PRCo = @PRCo AND Employee = @Employee

IF @SeparationRedundancyRetirement = 'Y'
BEGIN
	DECLARE	@Return_Value int

	-- Retrieve ATO-provided information stored in table vPRAULimitsAndRates	
	DECLARE	@ETPCap bDollar,
			@WholeIncomeCap bDollar,
			@RedundancyTaxFreeBasis bDollar,
			@RedundancyTaxFreeYears bDollar,
			@UnderPreservationAgePct bPct,
			@OverPreservationAgePct bPct,
			@ExcessCapPct bPct,
			@AnnualLeaveLoadingPct bPct,
			@LeaveFlatRatePct bPct,
			@LeaveFlatRateLimit bDollar

	EXEC	@Return_Value = [dbo].[vspPR_AU_ETP_LimitsAndRatesGet]
			@ThruDate,
			@ETPCap OUTPUT,
			@WholeIncomeCap OUTPUT,
			@RedundancyTaxFreeBasis OUTPUT,
			@RedundancyTaxFreeYears OUTPUT,
			@UnderPreservationAgePct OUTPUT,
			@OverPreservationAgePct OUTPUT,
			@ExcessCapPct OUTPUT,
			@AnnualLeaveLoadingPct OUTPUT,
			@LeaveFlatRatePct OUTPUT,
			@LeaveFlatRateLimit OUTPUT,
			@errmsg OUTPUT
	
	IF @Return_Value = 1 
	BEGIN
		SET @rcode = 1
		GOTO vspExit
	END

	-- get the Tax-Free component of the Genuine Redundancy or Approved Early Retirement ETP
	DECLARE @UseSubjectAmtYN bYN,
			@SubjectAmt bDollar,
			@RedundancyTaxFreePortion bDollar,
			@RedundancyTaxablePortion bDollar

	SET @UseSubjectAmtYN = 'N'
	SET @SubjectAmt = 0

	EXEC	@Return_Value = [dbo].[vspPR_AU_ETP_RedundancyTaxFreeGet]
			@PRCo,
			@Employee,
			@UseSubjectAmtYN,
			@SubjectAmt, 
			@HireDate, 
			@SeparationDate,
			@RedundancyTaxFreeBasis, 
			@RedundancyTaxFreeYears,
			@RedundancyTaxFreePortion OUTPUT,
			@RedundancyTaxablePortion OUTPUT,
			@ErrorMsg = @errmsg OUTPUT

	IF @Return_Value = 1 
	BEGIN
		SET @rcode = 1
		GOTO vspExit
	END

	---- subtract the Tax-Free component from any ETPR amounts included above in the AmountData
	--INSERT @AmountData 
	--SELECT 'GR  ' AS ItemCode, 
	--	   'E' AS EDLType, 
	--	   @RedundancyTaxFreePortion * -1 AS Amount, 
	--	   NULL AS LSAType

	-- add an AmountData entry to assign the Tax-Free component as Lump Sum D
	INSERT @AmountData 
	SELECT 'LSD ' AS ItemCode, 
		   'E' AS EDLType, 
		   @RedundancyTaxFreePortion AS Amount, 
		   NULL AS LSAType
END


-- RETURN RESULTSET
SELECT * FROM @AmountData 	


vspExit:
	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGEmplItemAmountsGet] TO [public]
GO
