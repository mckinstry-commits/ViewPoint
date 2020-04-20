SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==========================================================

Author:  Mike Brewer
Create date: 3/15/2010
Issue: 135792
This procedure is used by PR Record of Employment main report.
It returns one record per employee.

Revision History
Date		Author	Issue					Description
7/27/2011	DML		CL-142356 / V1-B-02678	Change "Last Day For Which Paid" to PREH.TermDate
10/28/2011	Czeslaw	CL-143979 / V1-D-03632	Overhaul, numerous revisions throughout, compare
											versions in SVN repository history for details 

==========================================================*/


CREATE PROCEDURE  [dbo].[vrptPREmployeeROE] (
	@PRCo bCompany,
	@Employee bEmployee,

	@TermReason varchar(25),
	@Recall  int,
	@RecallDate bDate,

	@VacCode bEDLCode,
	@HoliCode bEDLCode,
	@OtherCode Varchar(200),
	@RRSPCode bEDLCode,

	@MaternityStartDate bDate,
	@MaternityAmount bDollar = Null
)

as

---------------------------------------------------
----1
--declare @PRCo bCompany
--set @PRCo = 1

----3
--declare @Employee bEmployee
--set @Employee = 1

----4
--declare @TermReason varchar(25)
--set @TermReason = 'A'

----5
--Declare @Recall varchar (15)
--set @Recall = 1 --Not Returning

----6
--Declare @RecallDate datetime
--set @RecallDate ='1950-01-01 00:00:00'

----7
--declare @VacCode bEDLCode
--set @VacCode = 0

----8
--declare @HoliCode bEDLCode
--set @HoliCode = 0

----9
--declare @OtherCode varchar(200)
--set @OtherCode = '0'

----10
--declare @RRSPCode bEDLCode
--set @RRSPCode = 0

----11
--declare @MaternityStartDate datetime
--set @MaternityStartDate = '1950-01-01 00:00:00'

----12
--declare @MaternityAmount bDollar
--set    @MaternityAmount = 0
--------------------------------------------------------------


--To handle viewpoint's need for default parameter values
 if @RecallDate <= GetDate()
Begin
 set @RecallDate = Null
End


--select @RecallDate   as '@RecallDate'
 if @MaternityStartDate <= convert(datetime,'1950-01-01')
Begin
 set @MaternityStartDate = Null
End


--select @MaternityStartDate   as '@MaternityStartDate'

DECLARE	@PRGroup bGroup

SELECT	@PRGroup = PRGroup
FROM	PREH
WHERE	PRCo = @PRCo
AND		Employee = @Employee


declare @PPT varchar(20)
select  @PPT = case PayFreq
	when 'B' then 'Biweekly'
	when 'M' then 'Monthly'
	when 'S' then 'Semi-monthly'
	when 'W' then 'Weekly' end
  from PRGR
  where PRCo = @PRCo and PRGroup = @PRGroup

-- select @PPT


DECLARE @FirstDayWorked bDate
DECLARE @LastDayPaid bDate
DECLARE @FinalPayperiod bDate

SELECT	@FirstDayWorked = HireDate
FROM	PREH
WHERE	PRCo = @PRCo
AND		Employee = @Employee

/* ORIGINAL [PRE-DML]
select  @LastDayPaid = max(PostDate)from PRTH
where PRCo = @PRCo
and Employee = @Employee
order by 1 desc    */

SELECT	@LastDayPaid = TermDate
FROM	PREH
WHERE	PRCo = @PRCo
AND		Employee = @Employee

SELECT	@FinalPayperiod = MAX(PREndDate)
FROM	PRDT
WHERE	PRCo = @PRCo
AND		PRGroup = @PRGroup
AND		Employee = @Employee
AND		Amount > 0

--select @LastDayPaid as '@LastDayPaid', @FinalPayperiod as '@FinalPayperiod'



declare @MaxPeriodHours bDate		--Beginning PREndDate (first) for total hours calculation
declare @MinPeriodHours bDate		--Ending PREndDate (last) for total hours calculation

declare @MaxPeriodEarnings bDate		--Beginning PREndDate (first) for total earnings calculation
declare @MinPeriodEarnings bDate		--Ending PREndDate (last) for total earnings calculation

declare @TotalInsurableHours bHrs
declare @TotalInsurableEarnings bDollar
declare @RRSPcontribution bDollar


IF @PPT = 'Weekly'
BEGIN

--PREndDate for HOURS, first (MIN)
SELECT @MinPeriodHours = MIN(PREndDate) FROM (
	SELECT	TOP (53) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x
	
--PREndDate for HOURS, last (MAX)
SELECT @MaxPeriodHours = MAX(PREndDate) FROM (
	SELECT	TOP (53) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, first (MIN)
SELECT @MinPeriodEarnings = MIN(PREndDate) FROM (
	SELECT	TOP (27) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, last (MAX)
SELECT @MaxPeriodEarnings = MAX(PREndDate) FROM (
	SELECT	TOP (27) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

END


IF @PPT = 'Biweekly'
BEGIN

--PREndDate for HOURS, first (MIN)
SELECT @MinPeriodHours = MIN(PREndDate) FROM (
	SELECT	TOP (27) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x
	
--PREndDate for HOURS, last (MAX)
SELECT @MaxPeriodHours = MAX(PREndDate) FROM (
	SELECT	TOP (27) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, first (MIN)
SELECT @MinPeriodEarnings = MIN(PREndDate) FROM (
	SELECT	TOP (14) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, last (MAX)
SELECT @MaxPeriodEarnings = MAX(PREndDate) FROM (
	SELECT	TOP (14) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

END


IF @PPT = 'Semi-monthly'
BEGIN

--PREndDate for HOURS, first (MIN)
SELECT @MinPeriodHours = MIN(PREndDate) FROM (
	SELECT	TOP (25) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x
	
--PREndDate for HOURS, last (MAX)
SELECT @MaxPeriodHours = MAX(PREndDate) FROM (
	SELECT	TOP (25) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, first (MIN)
SELECT @MinPeriodEarnings = MIN(PREndDate) FROM (
	SELECT	TOP (13) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, last (MAX)
SELECT @MaxPeriodEarnings = MAX(PREndDate) FROM (
	SELECT	TOP (13) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

END


IF @PPT = 'Monthly'
BEGIN

--PREndDate for HOURS, first (MIN)
SELECT @MinPeriodHours = MIN(PREndDate) FROM (
	SELECT	TOP (13) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x
	
--PREndDate for HOURS, last (MAX)
SELECT @MaxPeriodHours = MAX(PREndDate) FROM (
	SELECT	TOP (13) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, first (MIN)
SELECT @MinPeriodEarnings = MIN(PREndDate) FROM (
	SELECT	TOP (7) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, last (MAX)
SELECT @MaxPeriodEarnings = MAX(PREndDate) FROM (
	SELECT	TOP (7) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

END


IF @PPT = '13 pay periods a year'
BEGIN

--PREndDate for HOURS, first (MIN)
SELECT @MinPeriodHours = MIN(PREndDate) FROM (
	SELECT	TOP (14) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x
	
--PREndDate for HOURS, last (MAX)
SELECT @MaxPeriodHours = MAX(PREndDate) FROM (
	SELECT	TOP (14) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, first (MIN)
SELECT @MinPeriodEarnings = MIN(PREndDate) FROM (
	SELECT	TOP (7) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

--PREndDate for EARNINGS, last (MAX)
SELECT @MaxPeriodEarnings = MAX(PREndDate) FROM (
	SELECT	TOP (7) PREndDate
	FROM	PRPC
	WHERE	PRCo = @PRCo
	AND		PRGroup = @PRGroup
	AND		PREndDate BETWEEN @FirstDayWorked AND @FinalPayperiod
	ORDER BY PREndDate DESC
)x

END

--select @MaxPeriodHours as '@MaxPeriodHours', @MinPeriodHours as '@MinPeriodHours',  @MaxPeriodEarnings as '@MaxPeriodEarnings', @MinPeriodEarnings as '@MinPeriodEarnings'



-- For 'Total Insurable Hours', --15a
SELECT	@TotalInsurableHours = SUM(ISNULL(PRDT.Hours,0))
FROM	PRDT
		INNER JOIN 
		PREC
			ON PRDT.PRCo = PREC.PRCo
			AND PRDT.EDLCode = PREC.EarnCode
		INNER JOIN
		PRSQ
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq	
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate BETWEEN @MinPeriodHours AND @MaxPeriodHours
AND PRDT.EDLType = 'E'
AND PREC.TrueEarns = 'Y'
AND PRSQ.Processed = 'Y'

-- For 'Total Insurable Earnings' --15b
-- Includes all amounts reported (redundantly) in 17a and 17b, as well as
-- any amounts reported under 17c that are designated as "True Earnings" in PREC
SELECT	@TotalInsurableEarnings = SUM(ISNULL(PRDT.Amount,0))
FROM	PRDT
		INNER JOIN
		PREC
			ON PRDT.PRCo = PREC.PRCo
			AND PRDT.EDLCode = PREC.EarnCode
		INNER JOIN
		PRSQ
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate BETWEEN @MinPeriodEarnings AND @MaxPeriodEarnings
AND PRDT.EDLType = 'E'
AND PREC.TrueEarns = 'Y'
AND PRSQ.Processed = 'Y'

-- For 'Total Insurable Earnings' --15b
SELECT	@RRSPcontribution = SUM(ISNULL(PRDT.Amount,0))
FROM	PRDT
		INNER JOIN
		PRSQ
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate BETWEEN @MinPeriodEarnings AND @MaxPeriodEarnings
AND PRDT.EDLType = 'L'
AND PRDT.EDLCode = @RRSPCode
AND PRSQ.Processed = 'Y'

--select @TotalInsurableHours, @TotalInsurableEarnings

--*************************************************************************
--*************************************************************************
--*************************************************************************


DECLARE @VacPay bDollar
DECLARE @StatHoliPay bDollar
DECLARE @OtherMonies bDollar


-- Vacation Pay, 17a ----------------------------------------
-- Vacation pay included in the final pay period because of the separation
SELECT	@VacPay = SUM(ISNULL(PRDT.Amount,0))
FROM	PRDT
		INNER JOIN
		PREC
			ON PRDT.PRCo = PREC.PRCo
			AND PRDT.EDLCode = PREC.EarnCode
		INNER JOIN
		PRSQ
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate = @FinalPayperiod
AND PRDT.EDLType = 'E'
AND PRDT.EDLCode = @VacCode
AND PREC.TrueEarns = 'Y'
AND PRSQ.Processed = 'Y'

-- Statutory Holiday pay, 17b --------------------------------
-- Holiday pay included in the final pay period because of the separation

SELECT	@StatHoliPay = SUM(ISNULL(PRDT.Amount,0))
FROM	PRDT
		INNER JOIN
		PREC
			ON PRDT.PRCo = PREC.PRCo
			AND PRDT.EDLCode = PREC.EarnCode
		INNER JOIN
		PRSQ --Employee Sequence
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq			
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate = @FinalPayperiod
AND PRDT.EDLType = 'E'
AND PRDT.EDLCode = @HoliCode
AND PREC.TrueEarns = 'Y'
AND PRSQ.Processed = 'Y'

-- Other Monies, 17c -------------------------------------------
-- Pension Payments, severance pay, bonus, etc. included in the final pay period because of the separation

-- Strip any space characters out of user-supplied value for @OtherCode

IF @OtherCode IN (NULL,'')
	BEGIN
		SELECT @OtherCode = NULL
	END
ELSE
	BEGIN
		SELECT @OtherCode = REPLACE(@OtherCode,' ','')
	END


SELECT	@OtherMonies = SUM(ISNULL(PRDT.Amount,0))
FROM	PRDT
		INNER JOIN
		PRSQ
			ON  PRDT.PRCo = PRSQ.PRCo
			AND PRDT.PRGroup = PRSQ.PRGroup
			AND PRDT.Employee = PRSQ.Employee
			AND PRDT.PREndDate = PRSQ.PREndDate
			AND PRDT.PaySeq = PRSQ.PaySeq
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.Employee = @Employee
AND PRDT.PREndDate = @FinalPayperiod
AND PRDT.EDLType = 'E'
AND CHARINDEX(',' + CONVERT(VARCHAR(8),PRDT.EDLCode) + ',', ',' + @OtherCode + ',') > 0
AND PRSQ.Processed = 'Y'


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


select
HQCO.HQCo as 'HQCo',
HQCO.[Name] as '4-Name',  --block 4
HQCO.[Address] as '4-Address', --block 4
HQCO.City + ', ' + HQCO.[State] + ' ' + HQCO.Zip  as '4-CityStateZip',  --block 4
HQCO.Phone as 'EmployerPhone',
'Payroll Account Number (BN): ' + HQCO.FedTaxId as '5-CRA',--block 3 or 5
'Pay Period Type: ' + @PPT as '6-PayPeriodType',
PREH.Employee,
HQCO.Zip as '7-PostalCode',  --Employer postal code
PREH.SSN as '8-SSN',  --block 8
Replace(PREH.FirstName  + ' ' + isNull(PREH.MidName, '') + ' ' + PREH.LastName, '  ',' ') as 'EmployeeName',
PREH.[Address] as '9-Address', --block 9
PREH.City + ', ' + PREH.[State]+ ' ' + PREH.Zip as '9-CityStateZip',  --block 9
PREH.Phone as 'EmployeePhone',
@FirstDayWorked as '10-FirstDayWorked', --block 10
@LastDayPaid as '11-LastDayPaid',
@FinalPayperiod as '12-FinalPayPeriod',
PROP.Description  as '13-Occupation',    --block 13
@RecallDate as 'RecallDate',
Case @Recall 
	when 1 then 'Not Returning'
    when 2 then 'Unknown'
    when 3 then 'Returning'  end as '14-Recall',
isnull(@TotalInsurableHours, 0) as '15a-TotalInsurableHours',
isnull(@TotalInsurableEarnings, 0) + isnull(@RRSPcontribution, 0)  as '15b-TotalInsurableEarnings',
case @TermReason
	when 'A' then 'A - Shortage of Work'
	when 'B' then 'B - Strike or Lockout'
	when 'C' then 'C - Return to School'
	when 'D' then 'D - Illness or Injury'
	when 'E' then 'E - Quit'
	when 'F' then 'F - Maternity'
	when 'G' then 'G - Retirement'
	when 'H' then 'H - Work Sharing'
	when 'J' then 'J - Apprentice Training'
	when 'M' then 'M - Dismissal'
	when 'N' then 'N - Leave of Absence'
	when 'P' then 'P - Parental'
	when 'K' then 'K - Other'
	when 'Z' then 'Z - Compassionate Care' end as '16-Reason Code',
isnull(@VacPay, 0) as '17A-VacationPay',
isnull(@StatHoliPay,0) as '17B-StatutoryHolidayPay',
isnull(@OtherMonies,0) as '17C-OtherMonies',
@MinPeriodHours as 'MinPeriodHours',
@MaxPeriodHours as 'MaxPeriodHours',
@MinPeriodEarnings as 'MinPeriodEarnings',
@MaxPeriodEarnings as 'MaxPeriodEarnings',
@PRCo as 'PRCo',
@HoliCode    as 'HoliCode',
@RRSPCode as 'RRSPCode',
@OtherCode as 'OtherCode',
@MaternityStartDate as 'MaternityStartDate',
@MaternityAmount as 'MaternityAmount',
@PRGroup as 'PRGroup',
@PPT as 'PPT'
FROM	PREH
		INNER JOIN
		HQCO
			ON HQCO.HQCo = PREH.PRCo
		LEFT OUTER JOIN
		PROP
			ON PROP.PRCo = PREH.PRCo
			AND	PROP.OccupCat = PREH.OccupCat
WHERE	PREH.PRCo = @PRCo
AND		PREH.Employee = @Employee
GO
GRANT EXECUTE ON  [dbo].[vrptPREmployeeROE] TO [public]
GO
