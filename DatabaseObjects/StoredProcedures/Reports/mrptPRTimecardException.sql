USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mrptPRTimecardException]    Script Date: 1/8/2015 3:10:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[mrptPRTimecardException]
(@BeginDate bDate ='1/1/1950',@EndDate bDate='1/1/2050',
@Company tinyint=1,@PRGroup tinyint=1
)
/***********************************************************
CREATED:	12/15/2014
PURPOSE:	MCK PR Weekly TImecard Exceptions
MODIFIED:	from SQL query from report request information
			1/5/2015 add Company and PRGroup parameters.
			1/7/2015 change from Theresa Parker sql for 'Exempt - Total Hours not equal to 40'
			1/7/2015 add additional logic from Theresa for 'GL Co Error'
TEST:		mrptPRTimecardException '01/24/2014','12/31/2014',1,1
grant all on mrptPRTimecardException to public
************************************************************/
/*
declare @BeginDate varchar (19) = '2014-11-24 00:00:00'
declare @EndDate varchar (19) = '2014-11-30 00:00:00'
*/
WITH RECOMPILE
AS
set nocount on
/*
DECLARE @BeginDate bDate ,@EndDate bDate,@Company tinyint,@PRGroup tinyint
SELECT @BeginDate  ='1/1/1950',@EndDate ='1/1/2050',@Company =1,@PRGroup =1
--*/
select eh.PRCo
, eh.PRGroup
, eh.Employee
, eh.LastName + ', ' + eh.FirstName as EmployeeName
, eh.PRDept
, dp.Description
, eh.udExempt as ExemptStatus

, Case when max(tb.BatchId) is null then ' ' else max(tb.BatchId) end as BatchId

, CASE WHEN (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 1 and PostDate between @BeginDate and @EndDate) is null then 0.00 
	ELSE (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 1 and PostDate between @BeginDate and @EndDate) END as RegHours
	
, CASE WHEN (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 2 and PostDate between @BeginDate and @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 2 and PostDate between @BeginDate and @EndDate) END as OTHours
	
, CASE WHEN (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 3 and PostDate between @BeginDate and @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 3 and PostDate between @BeginDate and @EndDate) END as DTHours

, CASE WHEN (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode not in (1,2,3) and PostDate between @BeginDate and @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode not in (1,2,3) and PostDate between @BeginDate and @EndDate) END as OtherHours
	
, CASE WHEN (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and PostDate between @BeginDate and @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and PostDate between @BeginDate and @EndDate) END as TotalHours

----Posted
, CASE WHEN sum(th.Hours) is not null then 'Y' ELSE 'N' END as PostedYN

, Case when max(th.BatchId) is null then ' ' else max(th.BatchId) end as PostedBatchId 

, CASE WHEN (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 1 and PREndDate = @EndDate) is null then 0.00 
	ELSE (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 1 and PREndDate = @EndDate) END as PostedRegHours
	
, CASE WHEN (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 2 and PREndDate = @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 2 and PREndDate = @EndDate) END as PostedOTHours
	
, CASE WHEN (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 3 and PREndDate = @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 3 and PREndDate = @EndDate) END as PostedDTHours

, CASE WHEN (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode not in (1,2,3) and PREndDate = @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode not in (1,2,3) and PREndDate = @EndDate) END as PostedOtherHours
	
, CASE WHEN (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and PREndDate = @EndDate) is null then 0.00
	ELSE (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and PREndDate = @EndDate) END as TotalPostedHours

--Errors
,  CASE
	WHEN (sum(tb.Hours) is null and sum(th.Hours) is null) or (sum(tb.Hours) = 0 and sum(th.Hours) is null) or
		 (sum(tb.Hours) = 0     and sum(th.Hours) = 0    ) or (sum(tb.Hours) = 0 and sum(th.Hours) = 0)
		then 'Missing Timecard' 
	WHEN eh.PRGroup = 2 and (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 1 and PREndDate = @EndDate) > 40 or
		 eh.PRGroup = 2 and (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 1 and PostDate between @BeginDate and @EndDate) > 40  
		then 'Union - Over 40 Regular Hours' 
    WHEN eh.PRGroup = 1 and udExempt = 'N' and (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and EarnCode = 1 and PREndDate = @EndDate) > 40 or
		 eh.PRGroup = 1 and udExempt = 'N' and (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and EarnCode = 1 and PostDate between @BeginDate and @EndDate) > 40
		then 'Non Exempt - Over 40 Regular Hours'
	/*1/7/2015 WHEN eh.PRGroup = 1 and udExempt = 'E' and sum(th.Hours) <> 40 or
	     eh.PRGroup = 1 and udExempt = 'E' and sum(tb.Hours) <> 40 
		then 'Exempt - Total Hours not equal to 40'
		*/
    WHEN eh.PRGroup = 1 and udExempt = 'E' and 
                        CASE WHEN (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and PostDate between @BeginDate and @EndDate) is null then 0.00
                        ELSE (select SUM(Hours) from PRTB where eh.PRCo = Co and eh.Employee = Employee and PostDate between @BeginDate and @EndDate) END +
                        CASE WHEN (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and PREndDate = @EndDate) is null then 0.00
                        ELSE (select SUM(Hours) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and PREndDate = @EndDate) END <> 40  
                  then 'Exempt - Total Hours not equal to 40'         --end 1/7/2015

	WHEN (select MIN(Rate) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and Hours > 0 and PREndDate = @EndDate) < 15 or
		 (select MIN(Rate) from PRTB where eh.PRCo = Co and eh.Employee = Employee and Hours > 0 and PostDate between @BeginDate and @EndDate) < 15
		then 'Rate is < $15'
	WHEN (select MAX(Rate) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and Hours > 0 and PREndDate = @EndDate) > 150 or
		 (select MAX(Rate) from PRTB where eh.PRCo = Co and eh.Employee = Employee and Hours > 0 and PostDate between @BeginDate and @EndDate) > 150
		then 'Rate is > $150'
	ELSE ' '
	END 
   as Errors 
,--1/7/2015
   CASE
      WHEN ((select COUNT(*) from PRTH where eh.PRCo = PRCo and eh.Employee = Employee and PREndDate = @EndDate and JCCo <> GLCo) > 0 or
            (select COUNT(*) from PRTB where eh.PRCo = Co and eh.Employee = Employee and PostDate between @BeginDate and @EndDate and JCCo <> GLCo) > 0)
            and eh.PRCo = eh.GLCo
            then 'JC Co and GL Co Do Not Match' 
      ELSE ' '
      END 
   as 'GL Co Error'

from PREH eh 
		left outer join (select * from PRTB PRTB where PostDate between @BeginDate and @EndDate) as tb on eh.PRCo = tb.Co and eh.Employee = tb.Employee
		left outer join (select * from PRTH PRTH where PREndDate = @EndDate) as th on eh.PRCo = th.PRCo and eh.Employee = th.Employee
		left outer join PRDP dp on eh.PRCo = dp.PRCo and eh.PRDept = dp.PRDept

where 
--1/5/2015 eh.PRCo in (1,20) 
eh.PRCo=@Company and
(case when @PRGroup =0 then @PRGroup else eh.PRGroup end)=@PRGroup --1/5/2015
and eh.ActiveYN = 'Y'
group by eh.PRCo, eh.Employee, 
eh.LastName + ', ' + eh.FirstName 
, eh.PRGroup, eh.PRDept, dp.Description, eh.udExempt
,eh.GLCo --1/7/2015
order by eh.PRCo, eh.PRGroup, eh.LastName + ', ' + eh.FirstName






