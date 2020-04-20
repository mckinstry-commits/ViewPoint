SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









/**********************************************************
* Copyright 2013 Viewpoint Construction Software. All rights reserved.
* Purpose:
* 
* Created: CWirtz	3/17/11 Issue 
* Modified: JayR 5/17/2013 Removed copyright symbol as it interferes with database compares.
* Maintenance Log
* Issue#		Date	Coder		Description
* 
Test Harness
DECLARE	@return_value int

EXEC	@return_value = [dbo].[vrptPRPAYGPaymentSummary]
		@PRCo = 213,
		@TaxYear = N'2011',
		@SummarySeq = 0,
		@Employee = 0,
		@TaxOfficeOriginal = N'Y',
		@PayeeCopy = N'N',
		@PAYGPayerCopy = N'N'

SELECT	'Return Value' = @return_value


******************************************************************/

CREATE PROCEDURE [dbo].[vrptPRPAYGPaymentSummary]
         (@PRCo bCompany = null
         ,@TaxYear char(4) = null
         ,@SummarySeq tinyint = null
         ,@Employee bEmployee =null
         ,@TaxOfficeOriginal char (1) = null
         ,@PayeeCopy char (1) = null
         ,@PAYGPayerCopy char(1) = null)

AS      
         
DECLARE @BegEmp bEmployee			--Calculated
DECLARE @EndEmp bEmployee			--Calculated
DECLARE @BegSummarySeq tinyint		--Calculated
DECLARE @EndSummarySeq tinyint		--Calculated

--SET employee selection range.  A parameter value of 0 returns all employees. 
--Otherwise, the specific employee is only selected
If @Employee = 0  
BEGIN
	SET	@BegEmp = 0
	SET	@EndEmp = 999999

END
ELSE
BEGIN
	SET	@BegEmp = @Employee
	SET	@EndEmp = @Employee
END;

--SET reporting range using the Summary Sequence.  
--If @SummarySeq equals 0 the maximum summary sequence will be selected.  
--Otherwise, it will return a specific range for an individual employee
--Note: If a specific employee was not selected but the Summary Seq parameter for the employee was selected the 
--Summary Seq parameter will be ignored and the maximum summary sequence will be selected.
If @SummarySeq = 0  OR (@Employee = 0)
BEGIN
	SET	@BegSummarySeq = 0
	SET	@EndSummarySeq = 255

END
ELSE
BEGIN 
	SET	@BegSummarySeq = @SummarySeq
	SET	@EndSummarySeq = @SummarySeq
END;
        
-- Determine the employee's reporting range (PRAUEmployeeItemAmounts.SummarySeq) 
WITH PAYGSummarySeq(PRCo, TaxYear, Employee, SummarySeq)
AS
(
SELECT PRCo, TaxYear, Employee, MAX(SummarySeq)
FROM PRAUEmployeeItemAmounts
 WHERE		@PRCo = PRAUEmployeeItemAmounts.PRCo 
			and @TaxYear = PRAUEmployeeItemAmounts.TaxYear
         	and PRAUEmployeeItemAmounts.Employee BETWEEN @BegEmp AND @EndEmp 
         	and PRAUEmployeeItemAmounts.SummarySeq BETWEEN @BegSummarySeq AND @EndSummarySeq 

GROUP BY PRCo, TaxYear, Employee
)
--SELECT * FROM PAYGSummarySeq
--Report FBT from April 1st -March 30th  
--NOTE: The first summary of FBT processing includes dollar amounts from April 1st to the end of the regular summary. 
--Since the FBT amount must be greater than 2000 for the year before it is reported to the ATO,
--The amount is aggregated from the start of the first payment summary up to the largest summary selected.
,FBTMultipleSummaries (PRCo, TaxYear, Employee, SummarySeq,FBTAmount)
AS
(
	SELECT 
	a.PRCo, a.TaxYear, a.Employee,MAX(m.SummarySeq) AS SummarySeq, Sum (a.Amount) AS FBTAmount 
	FROM PRAUEmployeeItemAmounts a
		INNER JOIN PAYGSummarySeq m
				ON a.PRCo = m.PRCo AND a.TaxYear = m.TaxYear 
				AND a.Employee = m.Employee --AND a.SummarySeq = m.SummarySeq
	WHERE a.ItemCode ='FBT' and a.SummarySeq <= m.SummarySeq
	GROUP BY a.PRCo, a.TaxYear, a.Employee
)

--select * from FBTMultipleSummaries

--For crystal reporting I need to return all the PAYGCategory records as one record(denormalized version of the data)
--rather than multiple records.  
--CTEs PAYGCategory and PAYGCategoryByEmp effectively pivots the data from table PRAUEmployeeItemAmounts
,
PAYGCategory(PRCo, TaxYear, Employee, SummarySeq, ItemCode
,BeginDate ,EndDate
,T, GR, C, FBT, S, AD, LSA, LSB, LSD, LSE, EF ,LSAType) AS
(
	SELECT a.PRCo, a.TaxYear, a.Employee, a.SummarySeq, ItemCode ,BeginDate ,EndDate
	,T = CASE WHEN ItemCode = 'T' Then ISNULL(Amount,0) Else 0 End
	,GR = CASE WHEN ItemCode = 'GR' Then ISNULL(Amount,0) Else 0 End
	,C = CASE WHEN ItemCode = 'C' Then ISNULL(Amount,0) Else 0 End
	,FBT = CASE WHEN ItemCode = 'FBT' Then ISNULL(n.FBTAmount,0) Else 0 End  
	,S = CASE WHEN ItemCode = 'S' Then ISNULL(Amount,0) Else 0 End
	,AD = CASE WHEN ItemCode = 'AD' Then ISNULL(Amount,0) Else 0 End
	,LSA = CASE WHEN ItemCode = 'LSA' Then ISNULL(Amount,0) Else 0 End
	,LSB = CASE WHEN ItemCode = 'LSB' Then ISNULL(Amount,0) Else 0 End
	,LSD= CASE WHEN ItemCode = 'LSD' Then ISNULL(Amount,0) Else 0 End
	,LSE = CASE WHEN ItemCode = 'LSE' Then ISNULL(Amount,0) Else 0 End
	,EF = CASE WHEN ItemCode = 'EF' Then ISNULL(Amount,0) Else 0 End
	,LSAType
FROM PRAUEmployeeItemAmounts a
	INNER JOIN PAYGSummarySeq m
		ON a.PRCo = m.PRCo AND a.TaxYear = m.TaxYear 
			AND a.Employee = m.Employee AND a.SummarySeq = m.SummarySeq
	LEFT OUTER JOIN FBTMultipleSummaries n
		ON a.PRCo = n.PRCo AND a.TaxYear = n.TaxYear 
			AND a.Employee = n.Employee AND a.SummarySeq = n.SummarySeq

WHERE	ItemCode IN ('T', 'GR', 'C', 'FBT','S', 'AD', 'LSA', 'LSB', 'LSD', 'LSE', 'EF')
)

--select * from PAYGCategory
,
PAYGCategoryByEmp AS
(
	SELECT 
		 PRCo, TaxYear, Employee, SummarySeq 
		,MAX(BeginDate) AS BeginDate ,MAX(EndDate) AS EndDate
		,SUM(T) AS T, SUM(GR)AS GR, SUM(C) AS C, SUM(FBT) AS FBT, SUM(S) AS S, SUM(AD) AS AD
		,SUM(LSA) AS LSA, SUM(LSB) AS LSB, SUM(LSD) AS LSD, SUM(LSE) AS LSE, SUM(EF) AS EF
		,MAX(LSAType) AS LSAType
	FROM PAYGCategory
	GROUP BY PRCo, TaxYear, Employee, SummarySeq
)
--select * from PAYGCategoryByEmp
--Find the maximum number of Allowances, Association fees, and WorkPlace Giving 
--which will be used to determine second page conditions.
--ItemCode determines category for Allowances, Association fees, and WorkPlace Giving.
,
PAYGItemCodeOverflow AS
(
	SELECT 
		PRCo, TaxYear, Employee, SummarySeq, ItemCode, MAX(RowNumber) AS MaxRowNumber
	FROM vrvPRPAYGEmployeeMiscItems
	GROUP BY PRCo, TaxYear, Employee, SummarySeq, ItemCode
)
,
--For crystal reporting I need to return all the records as one record(denormalized version of the data)
--rather than multiple records because the report only has summary values.  
--CTEs PAYGEmployeeMiscItems  and PAYGEmployeeMiscItemsPage1 effectively pivots the data from table PRAUEmployeeMiscItemAmounts
PAYGEmployeeMiscItems 
(PRCo, TaxYear, Employee, SummarySeq, ItemCode, RowNumber
,AllowanceAmt1,AllowanceDesc1,AllowanceAmt2,AllowanceDesc2,Allowance2ndPageInd
,UnionAmt1,UnionDesc1,UnionAmt2,UnionDesc2,Union2ndPageInd
,WorkplaceGivingAmt1,WorkplaceGivingDesc1,WorkplaceGiving2ndPageInd
) AS
(
SELECT 
a.PRCo,a.TaxYear, a.Employee, a.SummarySeq, a.ItemCode, a.RowNumber
,AllowanceAmt1 = CASE WHEN a.ItemCode = 'A' AND n.MaxRowNumber > 2  THEN 0 
					  WHEN a.ItemCode = 'A' AND a.RowNumber = 1 THEN ISNULL(a.Amount,0)ELSE 0 END
,AllowanceDesc1 = CASE WHEN a.ItemCode = 'A' AND n.MaxRowNumber > 2 THEN 'VARIOUS'
					   WHEN a.ItemCode = 'A' AND a.RowNumber = 1 THEN a.AllowanceDesc ELSE '' END
,AllowanceAmt2 = CASE WHEN a.ItemCode = 'A' AND n.MaxRowNumber > 2 THEN 0
					  WHEN a.ItemCode = 'A' AND a.RowNumber = 2 THEN ISNULL(a.Amount,0)ELSE 0 END
,AllowanceDesc2 = CASE WHEN a.ItemCode = 'A' AND n.MaxRowNumber > 2 THEN 'VARIOUS'
					   WHEN a.ItemCode = 'A' AND a.RowNumber = 2 THEN a.AllowanceDesc ELSE '' END
,Allowance2ndPageInd =	CASE WHEN (a.ItemCode = 'A' AND n.MaxRowNumber > 2 )  THEN 'Y' ELSE 'N' END
,UnionAmt1 = CASE WHEN a.ItemCode = 'F' AND n.MaxRowNumber > 2 THEN 0
				  WHEN a.ItemCode = 'F' AND a.RowNumber = 1 THEN ISNULL(a.Amount,0)ELSE 0 END
,UnionDesc1 = CASE WHEN a.ItemCode = 'F' AND n.MaxRowNumber > 2 THEN 'VARIOUS'
				   WHEN a.ItemCode = 'F' AND a.RowNumber = 1 THEN a.OrganizationName ELSE '' END
,UnionAmt2 = CASE WHEN a.ItemCode = 'F' AND n.MaxRowNumber > 2 THEN 0
				  WHEN a.ItemCode = 'F' AND a.RowNumber = 2 THEN ISNULL(a.Amount,0)ELSE 0 END
,UnionDesc2 = CASE WHEN a.ItemCode = 'F' AND n.MaxRowNumber > 2 THEN 'VARIOUS'
                   WHEN a.ItemCode = 'F' AND a.RowNumber = 2 THEN a.OrganizationName ELSE '' END
,Union2ndPageInd = CASE WHEN  (a.ItemCode = 'F' AND n.MaxRowNumber > 2)  THEN 'Y' ELSE 'N' END
,WorkplaceGivingAmt1 = CASE WHEN a.ItemCode = 'G' AND n.MaxRowNumber > 1 THEN 0
							WHEN a.ItemCode = 'G' AND a.RowNumber = 1 THEN ISNULL(a.Amount,0)ELSE 0 END
,WorkplaceGivingDesc1 = CASE WHEN a.ItemCode = 'G' AND n.MaxRowNumber > 1 THEN 'VARIOUS'
							 WHEN a.ItemCode = 'G' AND a.RowNumber = 1 THEN a.OrganizationName ELSE '' END
,WorkplaceGiving2ndPageInd =CASE WHEN  (a.ItemCode = 'G' AND n.MaxRowNumber > 1)  THEN 'Y' ELSE 'N' END
FROM vrvPRPAYGEmployeeMiscItems a
INNER JOIN PAYGSummarySeq m
	ON a.PRCo = m.PRCo AND a.TaxYear = m.TaxYear 
		AND a.Employee = m.Employee AND a.SummarySeq = m.SummarySeq		
INNER JOIN PAYGItemCodeOverflow n
	ON a.PRCo = n.PRCo AND a.TaxYear = n.TaxYear 
		AND a.Employee = n.Employee AND a.SummarySeq = n.SummarySeq AND a.ItemCode = n.ItemCode				
)
--select * from PAYGEmployeeMiscItems
,
PAYGEmployeeMiscItemsPage1 AS
(
SELECT PRCo, TaxYear, Employee, SummarySeq
	,SUM(AllowanceAmt1)AS AllowanceAmt1,MAX(AllowanceDesc1) AS AllowanceDesc1
	,SUM(AllowanceAmt2) AS AllowanceAmt2,MAX(AllowanceDesc2) AS AllowanceDesc2,MAX(Allowance2ndPageInd) AS Allowance2ndPageInd
	,SUM(UnionAmt1) AS UnionAmt1,MAX(UnionDesc1) AS UnionDesc1
	,SUM(UnionAmt2) AS UnionAmt2,MAX(UnionDesc2) AS UnionDesc2,MAX(Union2ndPageInd) AS Union2ndPageInd
	,SUM(WorkplaceGivingAmt1) AS WorkplaceGivingAmt1,MAX(WorkplaceGivingDesc1) AS WorkplaceGivingDesc1
	,MAX(WorkplaceGiving2ndPageInd) AS WorkplaceGiving2ndPageInd
FROM PAYGEmployeeMiscItems 
	GROUP BY PRCo, TaxYear, Employee, SummarySeq
)
--select * from PAYGEmployeeMiscItemsPage1
,
PAYGPaySummary AS
(
SELECT 	
	 PRAUEmployees.PRCo
	,PRAUEmployees.TaxYear
	,PRAUEmployees.Employee
	,PRAUEmployees.Surname
	,PRAUEmployees.GivenName
	,PRAUEmployees.Address
	,PRAUEmployees.City
	,PRAUEmployees.State
	,PRAUEmployees.Postcode
	,PRAUEmployees.BirthDate
	,PRAUEmployees.TaxFileNumber
	,PRAUEmployees.PensionAnnuity
	,PRAUEmployees.AmendedReport
	,PRAUEmployees.AmendedEFile
		
	,PRAUEmployer.BranchNumber
	,PRAUEmployer.AuthorizedPerson
	,PRAUEmployer.ReportDate As EmployerReportDate
	
	,PRAUEmployerMaster.ABN
	,PRAUEmployerMaster.ContactSurname
	,PRAUEmployerMaster.ContactGivenName	
	,PRAUEmployerMaster.ContactGivenName2 AS MiddleName
	
	,PRAUEmployerMaster.CompanyName
		
	,e.SummarySeq 
	,e.BeginDate 
	,e.EndDate
	,e.T
	,e.GR
	,e.C
	,e.FBT
	,e.S
	,e.AD
	,e.LSA
	,e.LSB
	,e.LSD
	,e.LSE
	,e.EF
	,e.LSAType
	
	,f.AllowanceAmt1
	,f.AllowanceDesc1
	,f.AllowanceAmt2
	,f.AllowanceDesc2
	,ISNULL(f.Allowance2ndPageInd,'N') AS Allowance2ndPageInd
	,f.UnionAmt1
	,f.UnionDesc1
	,f.UnionAmt2
	,f.UnionDesc2
	,ISNULL(f.Union2ndPageInd,'N') AS Union2ndPageInd
	,f.WorkplaceGivingAmt1
	,f.WorkplaceGivingDesc1
	,ISNULL(f.WorkplaceGiving2ndPageInd	,'N') AS WorkplaceGiving2ndPageInd



 FROM      PAYGSummarySeq a
INNER JOIN	dbo.PRAUEmployees  
		ON PRAUEmployees.PRCo = a.PRCo AND PRAUEmployees.TaxYear = a.TaxYear AND PRAUEmployees.Employee = a.Employee
INNER JOIN PRAUEmployer
	ON PRAUEmployees.PRCo = PRAUEmployer.PRCo AND PRAUEmployees.TaxYear = PRAUEmployer.TaxYear 
INNER JOIN PRAUEmployerMaster
	ON PRAUEmployer.PRCo = PRAUEmployerMaster.PRCo AND PRAUEmployer.TaxYear = PRAUEmployerMaster.TaxYear 
LEFT OUTER JOIN PAYGCategoryByEmp e
	ON PRAUEmployees.PRCo = e.PRCo AND PRAUEmployees.TaxYear = e.TaxYear AND PRAUEmployees.Employee = e.Employee AND a.SummarySeq =e.SummarySeq
LEFT OUTER JOIN PAYGEmployeeMiscItemsPage1 f
	ON PRAUEmployees.PRCo = f.PRCo AND PRAUEmployees.TaxYear = f.TaxYear AND PRAUEmployees.Employee = f.Employee AND a.SummarySeq =f.SummarySeq

 
)
--select * from PAYGPaySummary 


--Create a record for each page to be printed
SELECT 
	 PRCo, TaxYear, Employee,Surname,GivenName,Address,City,State,Postcode,BirthDate
	,TaxFileNumber,PensionAnnuity,AmendedReport,AmendedEFile,BranchNumber,AuthorizedPerson
	,EmployerReportDate	,ABN,ContactSurname,ContactGivenName,MiddleName,CompanyName 
	,SummarySeq ,BeginDate ,EndDate,T,GR,C,FBT,S,AD,LSA,LSB,LSD,LSE,EF,LSAType
	,AllowanceAmt1,AllowanceDesc1,AllowanceAmt2,AllowanceDesc2,Allowance2ndPageInd
	,UnionAmt1,UnionDesc1,UnionAmt2,UnionDesc2,Union2ndPageInd
	,WorkplaceGivingAmt1,WorkplaceGivingDesc1,WorkplaceGiving2ndPageInd
	,PageInd = 1,PageType = 'Tax Office original'
	   from  PAYGPaySummary
	   Where @TaxOfficeOriginal='Y' OR (@PayeeCopy='N' AND @PAYGPayerCopy='N') --Always want to return one set of records


UNION ALL

SELECT 
	 PRCo, TaxYear, Employee,Surname,GivenName,Address,City,State,Postcode,BirthDate
	,TaxFileNumber,PensionAnnuity,AmendedReport,AmendedEFile,BranchNumber,AuthorizedPerson
	,EmployerReportDate	,ABN,ContactSurname,ContactGivenName,MiddleName,CompanyName
	,SummarySeq ,BeginDate ,EndDate,T,GR,C,FBT,S,AD,LSA,LSB,LSD,LSE,EF,LSAType
	,AllowanceAmt1,AllowanceDesc1,AllowanceAmt2,AllowanceDesc2,Allowance2ndPageInd
	,UnionAmt1,UnionDesc1,UnionAmt2,UnionDesc2,Union2ndPageInd
	,WorkplaceGivingAmt1,WorkplaceGivingDesc1,WorkplaceGiving2ndPageInd
	,PageInd = 2,PageType = 'Payee''s copy'
	   from  PAYGPaySummary
	   Where @PayeeCopy='Y'
	   

UNION ALL
SELECT 
	 PRCo, TaxYear, Employee,Surname,GivenName,Address,City,State,Postcode,BirthDate
	,TaxFileNumber,PensionAnnuity,AmendedReport,AmendedEFile,BranchNumber,AuthorizedPerson
	,EmployerReportDate	,ABN,ContactSurname,ContactGivenName,MiddleName,CompanyName
	,SummarySeq ,BeginDate ,EndDate,T,GR,C,FBT,S,AD,LSA,LSB,LSD,LSE,EF,LSAType
	,AllowanceAmt1,AllowanceDesc1,AllowanceAmt2,AllowanceDesc2,Allowance2ndPageInd
	,UnionAmt1,UnionDesc1,UnionAmt2,UnionDesc2,Union2ndPageInd
	,WorkplaceGivingAmt1,WorkplaceGivingDesc1,WorkplaceGiving2ndPageInd	
	,PageInd = 3,PageType = 'PAYG payer''s copy'
	   from  PAYGPaySummary
	   Where @PAYGPayerCopy='Y'
	      














GO
GRANT EXECUTE ON  [dbo].[vrptPRPAYGPaymentSummary] TO [public]
GO
