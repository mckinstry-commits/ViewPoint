USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[vcpMCK_PR401k]    Script Date: 1/8/2015 10:04:43 AM ******/
DROP PROCEDURE [dbo].[vcpMCK_PR401k]
GO

/****** Object:  StoredProcedure [dbo].[vcpMCK_PR401k]    Script Date: 1/8/2015 10:04:43 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







 CREATE procedure [dbo].[vcpMCK_PR401k]
	( @PRCo int =1
	, @Loans varchar(20)='140,141,142'
	, @PRGroups varchar(10)='1'
	, @PREndDate smalldatetime='2014-8-10'
	)
	
	AS	

/* This assumes that YTD is calendar year; if that is not the case, this will need to be altered */
Declare @Year int = year(@PREndDate), @CurrentMonth smalldatetime

/* Select employees for the report run */
select 
	  e.PRCo
	, e.Employee
	, e.PRGroup
	, e.ActiveYN
	, e.TermDate
	, e.ud401kEligYN
	, e.ud401kElgDate
	, e.ud401kElgEndDate
	, a.LoanAmt as LoanAmtThisYear /* this will show the total for the year, not just through the PREndDate */
into #employees
from PREH e
left join (
	select PREA.PRCo, PREA.Employee
		, SUM(case when PREA.EDLType='D' and charindex(','+CONVERT(varchar(5),PREA.EDLCode)+',',','+REPLACE(@Loans, ' ','')+',',1)<>0 then PREA.Amount else 0 end) as LoanAmt
		, SUM(case when PREA.EDLType='E' then PREA.Amount else 0 end) as EarningsAmt
	from PREA 
	where PREA.PRCo=@PRCo 
		and YEAR(PREA.Mth)=@Year 
		--and PREA.EDLType='D' 
		--and charindex(','+CONVERT(varchar(5),PREA.EDLCode)+',',','+REPLACE(@Loans, ' ','')+',',1)<>0
	group by PREA.PRCo, PREA.Employee
	) a on e.PRCo=a.PRCo and e.Employee=a.Employee
where e.PRCo=@PRCo    
	and (
		   charindex(','+CONVERT(varchar(1),e.PRGroup)+',',','+REPLACE(@PRGroups, ' ','')+',',1)<>0
		OR a.LoanAmt<>0
		)
	and (
		   e.ActiveYN='Y'
		OR (e.ActiveYN='N' AND year(e.TermDate)=@Year)	
		OR (e.ActiveYN='N' AND a.EarningsAmt<>0)	
		)
	and (
		   e.ud401kEligYN='Y'
		OR (YEAR(isnull(e.ud401kElgDate,'1950-01-01'))<=@Year /*AND YEAR(isnull(e.ud401kElgDateEnd,'2050-01-01'))>=@Year*/)
		OR isnull(a.LoanAmt,0)<>0
		)

/* Determine the accounting month for the PREndDates in the month of @PREndDate */
/* For "year to date", the info will come from PRDT for current month, and PREA for all prior months */
select @CurrentMonth=isnull(max(sq.PaidMth),@PREndDate)
from PRSQ sq
join #employees e on sq.PRCo=e.PRCo and sq.Employee=e.Employee
where sq.PRCo=@PRCo
	and sq.PREndDate=@PREndDate

/* Create the table to collect the hours & amounts */
create table #values (PRCo int, Employee int, EDLType varchar(1), EDLCode int
					, HoursPREndDate decimal(16,2), HoursYearToDate decimal(16,2)
					, AmountPREndDate decimal(16,2), AmountYearToDate decimal(16,2)
					, EligPREndDate decimal(16,2), EligYearToDate decimal(16,2)
					, EligPlanPREndDate decimal(16,2), EligPlanYearToDate decimal(16,2)
					)

/* Select PREA records into temp table*/
insert into #values (PRCo, Employee, EDLType, EDLCode
				, HoursYearToDate, AmountYearToDate, EligYearToDate, EligPlanYearToDate)
select a.PRCo
	, a.Employee
	, a.EDLType
	, a.EDLCode
	, sum(a.Hours) as HoursUpToLastMonth
	, sum(a.Amount) as AmountUpToLastMonth 
	, sum(a.EligibleAmt) as EligUpToLastMonth
	, SUM(case when a.Mth between e.ud401kElgDate and ISNULL(e.ud401kElgEndDate,'2050-12-31') 
		  then a.Amount else 0 end) as EligPlanUpToLastMonth
from PREA a
join #employees e on a.PRCo=e.PRCo and a.Employee=e.Employee
where a.PRCo=@PRCo
	and a.Mth<@CurrentMonth
	and YEAR(a.Mth)=@Year
group by 	a.PRCo
	, a.Employee
	, a.EDLType
	, a.EDLCode

/* Select PRDT records into temp table */
insert into #values (PRCo, Employee, EDLType, EDLCode, HoursPREndDate, HoursYearToDate, AmountPREndDate, AmountYearToDate
				, EligPREndDate, EligYearToDate, EligPlanPREndDate, EligPlanYearToDate)
select d.PRCo, d.Employee, d.EDLType, d.EDLCode
	, (case when d.PREndDate=@PREndDate then d.Hours else 0 end) as HoursPREndDate
	, (d.Hours) as HoursMonth
	, (case when d.PREndDate=@PREndDate then d.Amount else 0 end) as AmountPREndDate
	, (d.Amount) as AmountMonth
	, (case when d.PREndDate=@PREndDate then d.EligibleAmt else 0 end) as EligAmountPREndDate
	, (d.EligibleAmt) as EligAmountMonth
	, (case when d.PREndDate=@PREndDate and x.PaidDate between x.ud401kElgDate and ISNULL(x.ud401kElgEndDate,'2050-12-31') 
		  then d.Amount else 0 end) as EligPlanPREndDate
	, (case when x.PaidDate between x.ud401kElgDate and ISNULL(x.ud401kElgEndDate,'2050-12-31') 
		  then d.Amount else 0 end) as EligPlanMonth
from PRDT d
join ( 
	/* Limits to only PREndDates in the current month */
	select q.PRCo, q.PRGroup, q.PREndDate, q.Employee, q.PaySeq
		, max(q.PaidDate) as PaidDate
		, MAX(e.ud401kElgDate) as ud401kElgDate
		, MAX(e.ud401kElgEndDate) as ud401kElgEndDate
	from PRSQ q
	join #employees e on q.PRCo=e.PRCo and q.Employee=e.Employee
	where q.PRCo=@PRCo
		and q.PaidMth=@CurrentMonth
		and q.PREndDate<=@PREndDate
	group by q.PRCo, q.PRGroup, q.PREndDate, q.Employee, q.PaySeq
	) x on d.PRCo=x.PRCo and d.PRGroup=x.PRGroup and d.PREndDate=x.PREndDate and d.Employee=x.Employee and d.PaySeq=x.PaySeq
	
/* Final selection information, unformatted except for dates */






select 
	  /* 01 */PayrollDate = CAST(MONTH(@PREndDate) as varchar(2))+'/'+CAST(DAY(@PREndDate) as varchar(2))+'/'+CAST(YEAR(@PREndDate) as varchar(4))
	, /* 02 */SSN = e.SSN
	, /* 03 */EmployeeID = e.Employee
	, /* 04 */FirstName = e.FirstName
	, /* 05 */MiddleName = e.MidName
	, /* 06 */LastName = e.LastName
	, /* 07 */DateOfBirth = isnull(	CAST(MONTH(e.BirthDate) as varchar(2))+'/'+CAST(DAY(e.BirthDate) as varchar(2))+'/'+CAST(YEAR(e.BirthDate) as varchar(4)),'')
	, /* 08 */DateOfHire = isnull(	CAST(MONTH(e.HireDate) as varchar(2))+'/'+CAST(DAY(e.HireDate) as varchar(2))+'/'+CAST(YEAR(e.HireDate) as varchar(4)),'')
	, /* 09 */RehireDate = isnull(	null,'')
	, /* 10 */DateOfTermination =	isnull(	CAST(MONTH(e.TermDate) as varchar(2))+'/'+CAST(DAY(e.TermDate) as varchar(2))+'/'+CAST(YEAR(e.TermDate) as varchar(4)) ,'')
	, /* 11 */Address = LEFT(e.Address,30) 
	, /* 12 */Address2 = isnull(LEFT(e.Address2,30),'')
	, /* 13 */City = LEFT(e.City,30) 
	, /* 14 */State = e.State
	, /* 15 */Zip = replace(e.Zip,'-','') 
	, /* 16 */CountryCode = '' 
	, /* 17 */ForeignStateProvince = '' 
	, /* 18 */Sex = e.Sex 
	, /* 18.5 */ MaritalStatus = e.FileStatus 
	, /* 19 */Email = left(e.Email,100) 
	, /* 20 */GroupCode = CAST(e.PRCo as varchar(3)) 
	, /* 21 */EmployeeType = case when e.PRGroup=2 then 'U' else 'H' end 
	, /* 22 */EmployeeStatus = case when e.ActiveYN='N' then 'T' else 'H' end
	, /* 23 */PreTaxContPct = isnull(dl100.RateAmt,0)
	, /* 24 */PreTaxContRate = 0 /* skipped per customer */
	, /* 25 */PreTaxContAmt = vv.PreTaxContAmt
	, /* 26 */PreTaxContYTD = vv.PreTaxContAmtYTD
	, /* 27 */PreTaxCatchup = vv.PreTaxCatchup
	, /* 28 */PreTaxCatchupYTD = vv.PreTaxCatchupYTD
	, /* 29 */RothAfterTaxPct = isnull(dl102.RateAmt,0)
	, /* 30 */RothAfterTaxDollar = 0 /* skipped per customer */
	, /* 31 */RothAfterTaxAmt = vv.RothAfterTaxAmt
	, /* 32 */RothAfterTaxYTD = vv.RothAfterTaxAmtYTD
	, /* 33 */RothAfterTaxCatchup = vv.RothAfterTaxCatchup
	, /* 34 */RothAfterTaxCatchupYTD = vv.RothAfterTaxCatchupYTD
	, /* 35 */AfterTaxPct = 0 /* skipped per customer */
	, /* 36 */AfterTaxAmt = 0 /* skipped per customer */
	, /* 37 */AfterTaxYTD = 0 /* skipped per customer */
	, /* 38 */EmployerMatchPeriod = vv.EmployerMatch
	, /* 39 */EmployerMatchYTD = vv.EmployerMatchYTD
	, /* 40 */EmployerCont = 0 /* skipped per customer */
	, /* 41 */EmployerContYTD =0 /* skipped per customer */
	, /* 42 */HoursPeriod = vv.HoursPeriod
	, /* 43 */HoursYTD = vv.HoursYTD
	--, /* 44 */PlanComp = vv.EligPeriod
	--, /* 45 */PlanCompYTD = vv.EligYTD
	, /* 44 */PlanComp = vv.EligPlanPeriod
	, /* 45 */PlanCompYTD = vv.EligPlanYTD
	, /* 46 */GrossComp = vv.GrossPeriod
	, /* 47 */GrossCompYTD = vv.GrossYTD
	, /* 48 */LoanFrequency = 'W' /* Hard-coded per customer */
	, /* 49 */LoanNumber1 = ''--isnull(l1.LoanNumber,'')
	, /* 50 */LoanPayment1 = isnull(l1.LoanPayment,0)
	, /* 51 */LoanNumber2 = ''--isnull(l2.LoanNumber,'')
	, /* 52 */LoanPayment2 = isnull(l2.LoanPayment,0)
	, /* 53 */LoanNumber3 = ''--isnull(l3.LoanNumber,'')
	, /* 54 */LoanPayment3 = isnull(l3.LoanPayment,0)
	-- Add a field to the end of the file to include the company transfer – term reason -  value is equal to “11”
	, /* 55 */TermReason = ISNULL(cast(e.udTermReason as varchar(3)),'   ') 
into #results
from #employees ee
join (
	select PREH.*, PRED.FileStatus
	from PREH
	left join PRED on PREH.PRCo=PRED.PRCo and PREH.Employee=PRED.Employee and PRED.DLCode=1
	) e on ee.PRCo=e.PRCo and ee.Employee=e.Employee --2044 employees
left join PRED dl100 on e.PRCo=dl100.PRCo and e.Employee=dl100.Employee and dl100.DLCode=100
left join PRED dl102 on e.PRCo=dl102.PRCo and e.Employee=dl102.Employee and dl102.DLCode=102
left join (
	select v.PRCo, v.Employee
		, PreTaxContAmt = sum(case when v.EDLType='D' and v.EDLCode=100 then AmountPREndDate else 0 end )
		, PreTaxContAmtYTD = sum(case when v.EDLType='D' and v.EDLCode=100 then AmountYearToDate else 0 end )
		, PreTaxCatchup = sum(case when v.EDLType='D' and v.EDLCode=101 then AmountPREndDate else 0 end )
		, PreTaxCatchupYTD = sum(case when v.EDLType='D' and v.EDLCode=101 then AmountYearToDate else 0 end )
		, RothAfterTaxAmt = sum(case when v.EDLType='D' and v.EDLCode=102 then AmountPREndDate else 0 end )
		, RothAfterTaxAmtYTD = sum(case when v.EDLType='D' and v.EDLCode=102 then AmountYearToDate else 0 end )
		, RothAfterTaxCatchup = sum(case when v.EDLType='D' and v.EDLCode=103 then AmountPREndDate else 0 end )
		, RothAfterTaxCatchupYTD = sum(case when v.EDLType='D' and v.EDLCode=103 then AmountYearToDate else 0 end )
		, EmployerMatch = sum(case when v.EDLType='L' and v.EDLCode=300 then AmountPREndDate else 0 end )
		, EmployerMatchYTD = sum(case when v.EDLType='L' and v.EDLCode=300 then AmountYearToDate else 0 end )
		, HoursPeriod = SUM(case when hyn.HoursYN='Y' then v.HoursPREndDate else 0 end)
		, HoursYTD = SUM(case when hyn.HoursYN='Y' then v.HoursYearToDate else 0 end)
		, EligPeriod = SUM(case when hyn.HoursYN='Y'  then v.EligPREndDate else 0 end)
		, EligYTD = SUM(case when hyn.HoursYN='Y'  then v.EligYearToDate else 0 end)
		/*   */
		, EligPlanPeriod = SUM(case when hyn.HoursYN='Y' and hyn.EligPlanYN='Y' then v.EligPlanPREndDate else 0 end)
		, EligPlanYTD = SUM(case when hyn.HoursYN='Y' and hyn.EligPlanYN='Y' then v.EligPlanYearToDate else 0 end)
		, GrossPeriod = SUM(case when gyn.GrossYN='Y' then v.AmountPREndDate else 0 end)
		, GrossYTD = SUM(case when gyn.GrossYN='Y' then v.AmountYearToDate else 0 end)
	from #values v	
	left join (
		select PRCo, EDLCode, HoursYN='Y'
			, max(case when DLCode=100 then 'Y' else 'N' end) as EligPlanYN
		from PRDB
		where DLCode in (100,101,102,103,104) and EDLType='E'
		group by PRCo, EDLCode
		) hyn on v.PRCo=hyn.PRCo and v.EDLType='E' and v.EDLCode=hyn.EDLCode
	left join (
		select PRCo, EDLCode, GrossYN='Y'
		from PRDB
		where DLCode in (1) and EDLType='E'
		group by PRCo, EDLCode
		) gyn on v.PRCo=gyn.PRCo and v.EDLType='E' and v.EDLCode=gyn.EDLCode
	group by v.PRCo, v.Employee
	) vv on e.PRCo=vv.PRCo and e.Employee=vv.Employee
left join (
	select PRCo
		, Employee
		, substring(CAST(v.EDLCode as varchar(3)),2,2) as LoanNumber
		, isnull(sum(v.AmountPREndDate),0) as LoanPayment
		, ROW_NUMBER() OVER(partition by PRCo, Employee order by PRCo, Employee, substring(CAST(v.EDLCode as varchar(3)),2,2)) as RowNum
	from #values v
	where EDLType='D'
		and EDLCode in (140,141,142,143)
	group by PRCo
		, Employee
		, substring(CAST(v.EDLCode as varchar(3)),2,2)
	having isnull(sum(v.AmountPREndDate),0)<>0
	) l1 on e.PRCo=l1.PRCo and e.Employee=l1.Employee and l1.RowNum=1
left join (
	select PRCo
		, Employee
		, substring(CAST(v.EDLCode as varchar(3)),2,2) as LoanNumber
		, isnull(sum(v.AmountPREndDate),0) as LoanPayment
		, ROW_NUMBER() OVER(partition by PRCo, Employee order by PRCo, Employee, substring(CAST(v.EDLCode as varchar(3)),2,2)) as RowNum
	from #values v
	where EDLType='D'
		and EDLCode in (140,141,142,143)
	group by PRCo
		, Employee
		, substring(CAST(v.EDLCode as varchar(3)),2,2)
	having isnull(sum(v.AmountPREndDate),0)<>0
	) l2 on e.PRCo=l2.PRCo and e.Employee=l2.Employee and l2.RowNum=2
left join (
	select PRCo
		, Employee
		, substring(CAST(v.EDLCode as varchar(3)),2,2) as LoanNumber
		, isnull(sum(v.AmountPREndDate),0) as LoanPayment
		, ROW_NUMBER() OVER(partition by PRCo, Employee order by PRCo, Employee, substring(CAST(v.EDLCode as varchar(3)),2,2)) as RowNum
	from #values v
	where EDLType='D'
		and EDLCode in (140,141,142,143)
	group by PRCo
		, Employee
		, substring(CAST(v.EDLCode as varchar(3)),2,2)
	having isnull(sum(v.AmountPREndDate),0)<>0
	) l3 on e.PRCo=l3.PRCo and e.Employee=l3.Employee and l3.RowNum=3
order by e.Employee

/*
Format the results
dbo.fFixedWidth(<1>,<2>,<3>,<4>,<5>,<6>)

1.	Field or variable you want to format:  Will accept VARCHAR or anything that can be implicitly converted to VARCHAR
2.	Desired length: If your specification calls for a field 10 characters long, this would be 10
3.	Justify: (L)eft or (R)ight justification when results are output
4.	Pad Character: Character to use when padding remaining fixed width spaces.  Typically blank space for text, or ‘0’ for number fields
5.	Implied Decimal: If specification requires implied decimal.  Y will remove decimal from output but preserve decimal places. I.e. 235.99 becomes 23599
6.	Decimal Justification: If input is a negative number (i.e. -235 or 235-) will move negative sign to start or end of formatted string.  So -235 would become -00235 using above example.
*/	
select 
	  PayrollDate			=dbo.fFixedWidth(r.PayrollDate,				10,	'R',	' ',	'N',	'L')
	, SSN					=dbo.fFixedWidth(r.SSN,						11,	'R',	' ',	'N',	'L')
	, EmployeeID			=dbo.fFixedWidth(r.EmployeeID,				30,	'R',	' ',	'N',	'L')
	, FirstName				=dbo.fFixedWidth(r.FirstName,				15,	'L',	' ',	'N',	'L')
	, MiddleName			=dbo.fFixedWidth(r.MiddleName,				30,	'L',	' ',	'N',	'L')
	, LastName				=dbo.fFixedWidth(r.LastName,				10,	'L',	' ',	'N',	'L')
	, DateOfBirth			=dbo.fFixedWidth(r.DateOfBirth,				10,	'R',	' ',	'N',	'L')
	, DateOfHire			=dbo.fFixedWidth(r.DateOfHire,				10,	'R',	' ',	'N',	'L')
	, RehireDate			=dbo.fFixedWidth(r.RehireDate,				10,	'R',	' ',	'N',	'L')
	, DateOfTermination		=dbo.fFixedWidth(r.DateOfTermination,		10,	'R',	' ',	'N',	'L')
	, Address				=dbo.fFixedWidth(r.Address,					60,	'L',	' ',	'N',	'L')
	, Address2				=dbo.fFixedWidth(r.Address2,				60,	'L',	' ',	'N',	'L')
	, City					=dbo.fFixedWidth(r.City,					30,	'L',	' ',	'N',	'L')
	, State					=dbo.fFixedWidth(r.State,					4,	'L',	' ',	'N',	'L')
	, Zip					=dbo.fFixedWidth(r.Zip,						12,	'L',	' ',	'N',	'L')
	, CountryCode			=dbo.fFixedWidth(r.CountryCode,				2,	'L',	' ',	'N',	'L')
	, ForeignStateProvince	=dbo.fFixedWidth(r.ForeignStateProvince,	30,	'L',	' ',	'N',	'L')
	, Sex					=dbo.fFixedWidth(r.Sex,						1,	'R',	' ',	'N',	'L')
	, MaritalStatus			=dbo.fFixedWidth(r.MaritalStatus,			1,	'R',	' ',	'N',	'L')
	, Email					=dbo.fFixedWidth(r.Email,					60,	'L',	' ',	'N',	'L')
	, GroupCode				=dbo.fFixedWidth(r.GroupCode,				3,	'L',	' ',	'N',	'L')
	, EmployeeType			=dbo.fFixedWidth(r.EmployeeType,			1,	'R',	' ',	'N',	'L')
	, EmployeeStatus		=dbo.fFixedWidth(r.EmployeeStatus,			1,	'R',	' ',	'N',	'L')
	, PreTaxContPct			=dbo.fFixedWidth(r.PreTaxContPct,			16,	'R',	' ',	'N',	'L')
	, PreTaxContRate		=dbo.fFixedWidth(r.PreTaxContRate,			12,	'R',	' ',	'N',	'L')
	, PreTaxContAmt			=dbo.fFixedWidth(r.PreTaxContAmt,			12,	'R',	' ',	'N',	'L')
	, PreTaxContYTD			=dbo.fFixedWidth(r.PreTaxContYTD,			12,	'R',	' ',	'N',	'L')
	, PreTaxCatchup			=dbo.fFixedWidth(r.PreTaxCatchup,			12,	'R',	' ',	'N',	'L')
	, PreTaxCatchupYTD		=dbo.fFixedWidth(r.PreTaxCatchupYTD,		12,	'R',	' ',	'N',	'L')
	, RothAfterTaxPct		=dbo.fFixedWidth(r.RothAfterTaxPct,			16,	'R',	' ',	'N',	'L')
	, RothAfterTaxDollar	=dbo.fFixedWidth(r.RothAfterTaxDollar,		10,	'R',	' ',	'N',	'L')
	, RothAfterTaxAmt		=dbo.fFixedWidth(r.RothAfterTaxAmt,			12,	'R',	' ',	'N',	'L')
	, RothAfterTaxYTD		=dbo.fFixedWidth(r.RothAfterTaxYTD,			12,	'R',	' ',	'N',	'L')
	, RothAfterTaxCatchup	=dbo.fFixedWidth(r.RothAfterTaxCatchup,		12,	'R',	' ',	'N',	'L')
	, RothAfterTaxCatchupYTD=dbo.fFixedWidth(r.RothAfterTaxCatchupYTD,	12,	'R',	' ',	'N',	'L')
	, AfterTaxPct			=dbo.fFixedWidth(r.AfterTaxPct,				6,	'R',	' ',	'N',	'L')
	, AfterTaxAmt			=dbo.fFixedWidth(r.AfterTaxAmt,				10,	'R',	' ',	'N',	'L')
	, AfterTaxYTD			=dbo.fFixedWidth(r.AfterTaxYTD,				10,	'R',	' ',	'N',	'L')
	, EmployerMatchPeriod	=dbo.fFixedWidth(r.EmployerMatchPeriod,		12,	'R',	' ',	'N',	'L')
	, EmployerMatchYTD		=dbo.fFixedWidth(r.EmployerMatchYTD,		12,	'R',	' ',	'N',	'L')
	, EmployerCont			=dbo.fFixedWidth(r.EmployerCont,			10,	'R',	' ',	'N',	'L')
	, EmployerContYTD		=dbo.fFixedWidth(r.EmployerContYTD,			10,	'R',	' ',	'N',	'L')
	, HoursPeriod			=dbo.fFixedWidth(r.HoursPeriod,				10,	'R',	' ',	'N',	'L')
	, HoursYTD				=dbo.fFixedWidth(r.HoursYTD,				10,	'R',	' ',	'N',	'L')
	, PlanComp				=dbo.fFixedWidth(r.PlanComp,				12,	'R',	' ',	'N',	'L')
	, PlanCompYTD			=dbo.fFixedWidth(r.PlanCompYTD,				12,	'R',	' ',	'N',	'L')
	, GrossComp				=dbo.fFixedWidth(r.GrossComp,				12,	'R',	' ',	'N',	'L')
	, GrossCompYTD			=dbo.fFixedWidth(r.GrossCompYTD,			12,	'R',	' ',	'N',	'L')
	, LoanFrequency			=dbo.fFixedWidth(r.LoanFrequency,			1,	'R',	' ',	'N',	'L')
	, LoanNumber1			=dbo.fFixedWidth(r.LoanNumber1,				3,	'R',	' ',	'N',	'L')
	, LoanPayment1			=dbo.fFixedWidth(r.LoanPayment1,			12,	'R',	' ',	'N',	'L')
	, LoanNumber2			=dbo.fFixedWidth(r.LoanNumber2,				3,	'R',	' ',	'N',	'L')
	, LoanPayment2			=dbo.fFixedWidth(r.LoanPayment2,			12,	'R',	' ',	'N',	'L')
	, LoanNumber3			=dbo.fFixedWidth(r.LoanNumber3,				3,	'R',	' ',	'N',	'L')
	, LoanPayment3			=dbo.fFixedWidth(r.LoanPayment3,			12,	'R',	' ',	'N',	'L')
	, TermReason			=dbo.fFixedWidth(r.TermReason,				3,	'R',	' ',	'N',	'L')
from #results r







GO


