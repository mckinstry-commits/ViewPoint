SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHQPRAUPAYGExport]
/************************************************************************
* CREATED: EN 4/05/2011    
* MODIFIED:	
*
* Purpose of Stored Procedure
*
*	Return supplier/payer/payee data used to export PAYG info for specified PR Company/Tax Year into electronic file.
*	If this is an amended report, employees being reported will be limited to those needing an 
*	amended annual report (ie. vPRAUEmployees.AmendedEFile = 'Y').
*
* Data required for return:
*			PayerFileReference
*			IncomeType
*			AmendmentIndicator
*			TaxYear
*			Employee
*			PayeeSurname
*			PayeeGivenName
*			PayeeAddress
*			PayeeCity
*			PayeeState
*			PayeePostalCode
*			PayeeBirthDate
*			PayeeTaxFileNumber
*			PeriodBeginDate 
*			PeriodEndDate
*			T
*			GR
*			C
*			FBT
*			S
*			AD
*			LSA
*			LSB
*			LSD
*			LSE
*			EF
*			LSAType
*			TotalAllowances
*			TotalFees
*			TotalGiving    
*************************************************************************/

    (@PRCo bCompany, @TaxYear varchar(4), @AmendedEFileYN bYN)

AS
SET NOCOUNT ON


IF @AmendedEFileYN IS NULL
BEGIN
	SELECT @AmendedEFileYN = 'N'
END

-- declare FBT threshold and gross up rate
DECLARE @FBTThreshold bDollar, @FBTLowerGrossupRate bRate
SELECT @FBTThreshold = 2000.00, @FBTLowerGrossupRate = 1.8692

;
-- determine the employees to report
WITH PAYGSummary (PRCo, TaxYear, Employee)
AS
	(
	SELECT DISTINCT ItemAmounts.PRCo, ItemAmounts.TaxYear, ItemAmounts.Employee
	FROM PRAUEmployeeItemAmounts ItemAmounts
	JOIN PRAUEmployees Employees ON Employees.PRCo = ItemAmounts.PRCo 
									AND Employees.TaxYear = ItemAmounts.TaxYear
									AND Employees.Employee = ItemAmounts.Employee
	WHERE ItemAmounts.PRCo = @PRCo 
		  AND ItemAmounts.TaxYear = @TaxYear 
		  AND ((@AmendedEFileYN = 'Y' AND Employees.AmendedEFile = 'Y') OR @AmendedEFileYN = 'N')
	)
,
-- get the item amounts by ItemCode
PAYGCategory (Employee, ItemCode, LSAType, T, GR, C, FBT, S, AD, LSA, LSB, LSD, LSE, EF) 
AS
	(
	SELECT  Summary.Employee, 
			ItemAmounts.ItemCode,
			ItemAmounts.LSAType,
			(CASE WHEN ItemCode = 'T' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS T,
			(CASE WHEN ItemCode = 'GR' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS GR,
			(CASE WHEN ItemCode = 'C' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS C,
			(CASE WHEN ItemCode = 'FBT' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS FBT,
			(CASE WHEN ItemCode = 'S' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS S,
			(CASE WHEN ItemCode = 'AD' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS AD,
			(CASE WHEN ItemCode = 'LSA' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS LSA,
			(CASE WHEN ItemCode = 'LSB' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS LSB,
			(CASE WHEN ItemCode = 'LSD' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS LSD,
			(CASE WHEN ItemCode = 'LSE' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS LSE,
			(CASE WHEN ItemCode = 'EF' THEN ISNULL(SUM(ItemAmounts.Amount),0) ELSE 0 END) AS EF
	FROM PRAUEmployeeItemAmounts ItemAmounts
	INNER JOIN PAYGSummary Summary ON Summary.PRCo = ItemAmounts.PRCo 
								AND Summary.TaxYear = ItemAmounts.TaxYear 
								AND Summary.Employee = ItemAmounts.Employee 
	WHERE ItemAmounts.ItemCode IN ('T', 'GR', 'C', 'FBT','S', 'AD', 'LSA', 'LSB', 'LSD', 'LSE', 'EF')
	GROUP BY Summary.Employee, ItemAmounts.ItemCode, ItemAmounts.LSAType
	)
,
-- reconfigure item amounts to one row
PAYGCategoryByEmp	(Employee, T, GR, C, FBT, S, AD,
					 LSA, LSB, LSD, LSE, EF, LSAType)
AS
	(
	SELECT	Employee, 
			SUM(T) AS T, 
			SUM(GR)AS GR, 
			SUM(C) AS C, 
			(CASE WHEN SUM(FBT) <= @FBTThreshold THEN 0.00 ELSE ROUND(SUM(FBT) * @FBTLowerGrossupRate, 0, 1) END) AS FBT, 
			SUM(S) AS S, 
			SUM(AD) AS AD,
			SUM(LSA) AS LSA, 
			SUM(LSB) AS LSB, 
			SUM(LSD) AS LSD, 
			SUM(LSE) AS LSE, 
			SUM(EF) AS EF,
			MAX(LSAType) AS LSAType
	FROM PAYGCategory
	GROUP BY Employee
	)
,
-- compute Allowance totals
PAYGEmployeeAllowanceAmounts (Employee, ItemCode, TotalAllowances)
AS
	(
	SELECT	Summary.Employee, MiscAmounts.ItemCode, SUM(ROUND(MiscAmounts.Amount, 0, 1)) 
	FROM PRAUEmployeeMiscItemAmounts MiscAmounts
	INNER JOIN PAYGSummary Summary ON Summary.PRCo = MiscAmounts.PRCo 
								AND Summary.TaxYear = MiscAmounts.TaxYear 
								AND Summary.Employee = MiscAmounts.Employee 
	WHERE ItemCode = 'A'
	GROUP BY Summary.Employee, MiscAmounts.ItemCode
	)
,
-- compute Fee totals
PAYGEmployeeFeeAmounts (Employee, ItemCode, TotalFees)
AS
	(
	SELECT	Summary.Employee, MiscAmounts.ItemCode, SUM(ROUND(MiscAmounts.Amount, 0, 1)) 
	FROM PRAUEmployeeMiscItemAmounts MiscAmounts
	INNER JOIN PAYGSummary Summary ON Summary.PRCo = MiscAmounts.PRCo 
								AND Summary.TaxYear = MiscAmounts.TaxYear 
								AND Summary.Employee = MiscAmounts.Employee 
	WHERE ItemCode = 'F'
	GROUP BY Summary.Employee, MiscAmounts.ItemCode
	)
,
-- compute Giving totals
PAYGEmployeeGivingAmounts (Employee, ItemCode, TotalGiving)
AS
	(
	SELECT	Summary.Employee, MiscAmounts.ItemCode, SUM(ROUND(MiscAmounts.Amount, 0, 1)) 
	FROM PRAUEmployeeMiscItemAmounts MiscAmounts
	INNER JOIN PAYGSummary Summary ON Summary.PRCo = MiscAmounts.PRCo 
								AND Summary.TaxYear = MiscAmounts.TaxYear 
								AND Summary.Employee = MiscAmounts.Employee 
	WHERE ItemCode = 'G'
	GROUP BY Summary.Employee, MiscAmounts.ItemCode
	)
,
-- collate all data into one summary
PAYGPaySummary 
AS
	(
	SELECT	Summary.PRCo AS [PayerFileReference],
			(CASE WHEN Employees.PensionAnnuity = 'Y' THEN 'P' ELSE 'S' END) AS [IncomeType],
			(CASE WHEN @AmendedEFileYN = 'Y' THEN 'A' ELSE 'O' END) AS [AmendmentIndicator],
			Employees.TaxYear,
			Employees.Employee,
			Employees.Surname AS [PayeeSurname],
			Employees.GivenName AS [PayeeGivenName],
			Employees.Address AS [PayeeAddress],
			Employees.City AS [PayeeCity],
			Employees.State AS [PayeeState],
			Employees.Postcode AS [PayeePostalCode],
			Employees.BirthDate AS [PayeeBirthDate],
			Employees.TaxFileNumber AS [PayeeTaxFileNumber],
			
			Employer.BeginDate AS [PeriodBeginDate], 
			Employer.EndDate AS [PeriodEndDate],
		
			EmplCategory.T,
			EmplCategory.GR,
			EmplCategory.C,
			EmplCategory.FBT,
			EmplCategory.S,
			EmplCategory.AD,
			EmplCategory.LSA,
			EmplCategory.LSB,
			EmplCategory.LSD,
			EmplCategory.LSE,
			EmplCategory.EF,
			EmplCategory.LSAType,
		
			(CASE WHEN Allowances.TotalAllowances IS NULL THEN 0 ELSE Allowances.TotalAllowances END) AS [TotalAllowances],
			(CASE WHEN Fees.TotalFees IS NULL THEN 0 ELSE Fees.TotalFees END) AS [TotalFees],
			(CASE WHEN Giving.TotalGiving IS NULL THEN 0 ELSE Giving.TotalGiving END) AS [TotalGiving]
	FROM PAYGSummary Summary
	JOIN dbo.PRAUEmployees Employees 
		ON Employees.PRCo = Summary.PRCo AND Employees.TaxYear = Summary.TaxYear 
		   AND Employees.Employee = Summary.Employee
	JOIN PRAUEmployer Employer
		ON Employer.PRCo = Summary.PRCo AND Employer.TaxYear = Summary.TaxYear 
	LEFT OUTER JOIN PAYGCategoryByEmp EmplCategory
		ON EmplCategory.Employee = Summary.Employee
	LEFT OUTER JOIN PAYGEmployeeAllowanceAmounts Allowances
		ON Allowances.Employee = Summary.Employee
	LEFT OUTER JOIN PAYGEmployeeFeeAmounts Fees
		ON Fees.Employee = Summary.Employee
	LEFT OUTER JOIN PAYGEmployeeGivingAmounts Giving
		ON Giving.Employee = Summary.Employee
)


--return the final results
SELECT * FROM PAYGPaySummary


GO
GRANT EXECUTE ON  [dbo].[vspHQPRAUPAYGExport] TO [public]
GO
