SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











/************************************************************************

vrptPRSuperannuation



Purpose:
Extract Superannuation data for reporting.
Superannuation data is defined by a deduction or liability code as follows:
a.	Employer Compulsory Sacrifice Guarantee:	EDLType = “L”, ATO Category = “S" Superannuation
b.	Employer Extra Contribution:	EDLType = “L”, ATO Category = “SE" Superannuation-Extra
c.	Employee Salary Sacrifice:	EDLType = “D”, ATO Category = “SE" Superannuation-Extra, PreTax = “Y”
d.	Employee Contribution:	EDLType = “D”, ATO Category = “SE" Superannuation-Extra, PreTax = “N”


The YTD calculations are base on a fiscal year of July 1st - June 30th

Parameter Name @BegPREndDate and @EndPREndDate reflect the reporting period and are  
independent of payroll ending date.  The value of the employee paid date(PRSQ.PaidDate)
determines the selection for reporting purposes.


Maintenance Log:
Date		Issue	Programmer	
08/09/2010	137166	C. Wirtz			New
*************************************************************************/
CREATE PROCEDURE	[dbo].[vrptPRSuperannuation]
--(		 @PRCompany			bCompany
--		,@PRGroup			bGroup		
--		,@BegPREndDate		bDate
--		,@EndPREndDate		bDate
--		,@Employee			bEmployee
--		,@EmployerExtraLiabilityCode 	bEDLCode)


(		 @PRCompany			bCompany = 204
		,@PRGroup			bGroup = 0
		,@BegPREndDate		bDate = '2010-12-19 00:00:00'
		,@EndPREndDate		bDate = '2010-12-31 00:00:00'
		,@Employee			bEmployee = 1)

AS

DECLARE @BegEmp bEmployee			--Calculated
DECLARE @EndEmp bEmployee			--Calculated
DECLARE @BegPRGroup bGroup			--Calculated
DECLARE @EndPRGroup bGroup			--Calculated


--Calculate the Austrialian's tax year based on the Beginning Reporting Period(July 1 through June 30 of the following year)
DECLARE @BeginTaxYear bDate
IF DATEPART (mm,@BegPREndDate) > 6
	SET @BeginTaxYear = Cast('07/01/' + CAST(DATEPART (yyyy,@BegPREndDate) as char(4)) as datetime)
ELSE
	SET @BeginTaxYear = Cast('07/01/' + CAST((DATEPART (yyyy,@BegPREndDate) -1) as char(4)) as datetime)


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
END

--SET Payroll group selection range.  A parameter value of 0 returns all payroll groups. 
--Otherwise, the specific payroll group is only selected
If @PRGroup = 0  
BEGIN
	SET	@BegPRGroup = 0
	SET	@EndPRGroup = 99
END
ELSE
BEGIN
	SET	@BegPRGroup = @PRGroup
	SET	@EndPRGroup = @PRGroup
END;

--NOTE: PRGroup is a valid selection parameter for retriving data but 
--      for YTD calculations and reporting it will be at the employee level

--Table EmployeeSuperannuationYTD is an extraction of supreannuation data to be used 
--in Year To Date(YTD) calculations (Starting on July 1).
--Australia's federal fiscal tax year is July 1 through June 30 of the following year.
--NOTE: The reporting period is determine by when the employee was paid(PRSQ.PaidDate)
--  be careful not to confuse this period with the PR End Date (PREndDate)
With EmployeeSuperannuationYTD (PRCo,Employee,EDLType,EDLCode,ATOCategory,PreTax,EDLCodeYTDAmount,BeginTaxYear) AS
(
SELECT PRDT.PRCo,PRDT.Employee,PRDT.EDLType,PRDT.EDLCode,PRDL.ATOCategory,PRDL.PreTax
,SUM(CASE PRDT.UseOver WHEN 'N' THEN PRDT.Amount ELSE PRDT.OverAmt END ),@BeginTaxYear 
FROM PRDT PRDT 
INNER JOIN PRDL PRDL 
	ON PRDT.PRCo = PRDL.PRCo and PRDT.EDLType=PRDL.DLType and PRDT.EDLCode = PRDL.DLCode
INNER JOIN PRSQ PRSQ
	ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate 
		AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
WHERE PRDT.PRCo = @PRCompany 
	and PRDT.PRGroup >= @BegPRGroup and PRDT.PRGroup <= @EndPRGroup
	and PRDT.Employee >= @BegEmp and PRDT.Employee <=  @EndEmp 
	and PRSQ.PaidDate >= @BeginTaxYear and PRSQ.PaidDate < @BegPREndDate
	and PRDL.ATOCategory in ( 'S','SE' )
 GROUP BY    PRDT.PRCo,PRDT.Employee,PRDT.EDLType,PRDT.EDLCode,PRDL.ATOCategory,PRDL.PreTax
 )
,

SuperannuationDetail AS
(
 SELECT 
 RecordType = 2
,HQCO.Name AS CompanyName
,HQCO.VendorGroup
,PRDT.Employee
,PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.PaySeq, PRDT.EDLType, PRDT.EDLCode
,PRDL.PreTax
,PRDL.ATOCategory
,PRSQ.PaidDate
,PRSQ.PaidMth
,PRDT.Hours, PRDT.SubjectAmt, PRDT.EligibleAmt, PRDT.UseOver
--, PRDT.OverAmt
,PREH.LastName, PREH.FirstName, PREH.MidName, PREH.SortName,PREH.PRDept
,PRGR.Description AS PRGRDescription
,PRDL.LimitPeriod

--Reporting period range is defined by parameters @BegPREndDate and @EndPREndDate
--Calculate contributions to Superannuation Schemes for the employer and employee

--Calculate Employee Pre-tax Contributions for a reporting period(Salary Sacrifice Implemented as negitive earnings code)  
,EmployeeContrbutionPreTax  = CASE WHEN (PRDL.ATOCategory = 'SE' and PRDT.EDLType = 'D' and PRDL.PreTax = 'Y'and @BegPREndDate <= PRSQ.PaidDate  and @EndPREndDate >= PRSQ.PaidDate) 
THEN(CASE PRDT.UseOver WHEN 'N' THEN PRDT.Amount ELSE PRDT.OverAmt END ) ELSE 0.0 END

--Calculate Employer Extra Contribution for a reporting period	
,EmployerExtraContribution = CASE WHEN (PRDL.ATOCategory = 'SE' and PRDT.EDLType = 'L'and @BegPREndDate <= PRSQ.PaidDate  and @EndPREndDate >= PRSQ.PaidDate) 
THEN(CASE PRDT.UseOver WHEN 'N' THEN PRDT.Amount ELSE PRDT.OverAmt END ) ELSE 0.0 END

--Calculate Employer Compulsory Contribution for a reporting period
,EmployerCompulsoryContribution = CASE WHEN (PRDL.ATOCategory = 'S' and @BegPREndDate <= PRSQ.PaidDate  and @EndPREndDate >= PRSQ.PaidDate) 
THEN(CASE PRDT.UseOver WHEN 'N' THEN PRDT.Amount ELSE PRDT.OverAmt END ) ELSE 0.0 END

--Calculated Employee After-tax Contribution for a reporting period
,EmployeeContrbutionAfterTax = CASE WHEN (PRDL.ATOCategory = 'SE' and PRDT.EDLType = 'D' and PRDL.PreTax = 'N' and @BegPREndDate <= PRSQ.PaidDate  and @EndPREndDate >= PRSQ.PaidDate) 
THEN(CASE PRDT.UseOver WHEN 'N' THEN PRDT.Amount ELSE PRDT.OverAmt END ) ELSE 0.0 END


--Calculate each YTD for each contribution type
,EmployerCompulsoryContributionYTD	= CASE WHEN PRDL.ATOCategory = 'S'  and PRDT.EDLType = 'L' THEN ISNull(e.EDLCodeYTDAmount,0.00) ELSE 0.0 END
,EmployerExtraContributionYTD		= CASE WHEN PRDL.ATOCategory = 'SE' and PRDT.EDLType = 'L' THEN ISNull(e.EDLCodeYTDAmount,0.00) ELSE 0.0 END
,EmployeeContrbutionPreTaxYTD		= CASE WHEN PRDL.ATOCategory = 'SE' and PRDT.EDLType = 'D' and PRDL.PreTax = 'Y' THEN ISNull(e.EDLCodeYTDAmount,0.00) ELSE 0.0 END
,EmployeeContrbutionAfterTaxYTD		= CASE WHEN PRDL.ATOCategory = 'SE' and PRDT.EDLType = 'D' and PRDL.PreTax = 'N' THEN ISNull(e.EDLCodeYTDAmount,0.00) ELSE 0.0 END
,TotalYTD = ISNull(e.EDLCodeYTDAmount,0.00)

,EDLCodeDescription =	PRDL.Description
,SuperMemberID =	PRED.MembershipNumber
,VendorOfficial =	PRDL.Vendor
,VendorName= APVM_PRDL.Name
,VendorSortName= APVM_PRDL.SortName
,PRDT.Amount
,PRDT.OverAmt
,PaidAmount=CASE PRDT.UseOver WHEN 'N' THEN PRDT.Amount ELSE PRDT.OverAmt END 
,APVM_PRDL.Vendor AS PRDLVendor
,PRDL.Description AS PRDLDescription
,PRAUSuperSchemes.Name AS SchemeName
,UPPER(PRAUSuperSchemes.Name) AS SchemeNameSort
,PRAUSuperSchemes.SchemeID

FROM  dbo.PRDT PRDT 
INNER JOIN	dbo.PRED PRED
	ON PRDT.PRCo=PRED.PRCo AND PRDT.Employee=PRED.Employee AND PRDT.EDLCode=PRED.DLCode  AND PRDT.EDLType <> 'E' 
INNER JOIN  dbo.HQCO HQCO 
	ON HQCO.HQCo=PRDT.PRCo 
INNER JOIN dbo.PREH PREH 
	ON (PRDT.PRCo=PREH.PRCo) AND (PRDT.Employee=PREH.Employee) 
INNER JOIN dbo.PRGR PRGR 
	ON (PRDT.PRCo=PRGR.PRCo) AND (PRDT.PRGroup=PRGR.PRGroup) 
LEFT OUTER JOIN dbo.PRDL PRDL 
	ON (PRDT.PRCo=PRDL.PRCo) AND (PRDT.EDLCode=PRDL.DLCode) 
LEFT OUTER JOIN	dbo.APVM APVM_PRDL
	ON APVM_PRDL.VendorGroup = HQCO.VendorGroup AND APVM_PRDL.Vendor = PRDL.Vendor
LEFT OUTER JOIN  EmployeeSuperannuationYTD e
	ON PRDT.PRCo = e.PRCo AND PRDT.Employee = e.Employee AND PRDT.EDLType = e.EDLType AND PRDT.EDLCode = e.EDLCode AND PRDT.EDLType <> 'E' 
LEFT OUTER JOIN HQAUSuperSchemes PRAUSuperSchemes
	ON PRDL.SchemeID = PRAUSuperSchemes.SchemeID
INNER JOIN PRSQ PRSQ
	ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate 
		AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
		

WHERE  PRDT.PRCo=@PRCompany 
AND (PRDT.PRGroup>=@BegPRGroup AND PRDT.PRGroup<=@EndPRGroup) 
AND (PRSQ.PaidDate >=  @BegPREndDate AND PRSQ.PaidDate <= @EndPREndDate) 
AND (PRDT.Employee>=@BegEmp AND PRDT.Employee<=@EndEmp) 
AND PRDL.ATOCategory in ( 'S','SE' )
)

--Superannuation is reported to the PaidDate and PREndDate level
--Aggregate the data to the PaidDate and PREndDate level.
--This will simplify processing and increase performance in the crystal report PRSuperannuation.rpt
SELECT 
MAX(CompanyName) AS CompanyName,Employee,PRCo, PREndDate,PaidDate,PaidMth,SuperMemberID,SchemeID
,LastName, FirstName, MidName, SortName
,MAX(PRGRDescription) AS PRGRDescription

,SUM(EmployeeContrbutionPreTax) AS  EmployeeContrbutionPreTax	
,SUM(EmployerExtraContribution) AS EmployerExtraContribution
,SUM(EmployerCompulsoryContribution) AS EmployerCompulsoryContribution
,SUM(EmployeeContrbutionAfterTax) AS EmployeeContrbutionAfterTax

--Calculate each YTD for each contribution type
,SUM(EmployerCompulsoryContributionYTD) AS EmployerCompulsoryContributionYTD
,SUM(EmployerExtraContributionYTD) AS EmployerExtraContributionYTD
,SUM(EmployeeContrbutionPreTaxYTD) AS EmployeeContrbutionPreTaxYTD
,SUM(EmployeeContrbutionAfterTaxYTD) AS EmployeeContrbutionAfterTaxYTD
,MAX(SchemeName)  AS SchemeName
,MAX(SchemeNameSort) AS SchemeNameSort

FROM SuperannuationDetail
GROUP BY 
Employee
,PRCo, PREndDate
,PaidDate
,PaidMth
,SuperMemberID
,SchemeID
,LastName, FirstName, MidName, SortName





GO
GRANT EXECUTE ON  [dbo].[vrptPRSuperannuation] TO [public]
GO
