SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[brptEEODot]  
(
	@PRCo bCompany
	, @PRGroup bGroup
	, @BeginPRDate bDate = '01/01/1950'
	, @EndPRDate bDate = '12/31/2050'
	, @BeginJCCo bCompany
	, @EndJCCo bCompany
	, @BeginJob bJob
	, @EndJob bJob
	, @BeginEEORegion varchar(8)=''
	, @EndEEORegion varchar (8)='zzzzzzzz'
	, @RptType char(1) = 'J'  --J=Job, R=Region, C=Company   
)  
/*==================================================================================      

Author:   
??  

Create date:   
?? - possibly 8/28/99    

Usage:   
This proc is designed to drive its related Department of Labor EEO-1 report
(http://www1.eeoc.gov/employers/eeo1survey/index.cfm). The report shows the ethnic, 
occupational category, and category status (all found in PREH) of each employee who
worked during the given parameters of the report. 

The Department of Labor EEO-1 report, designed to meet the requirement of the Department of Labor, 
prints employee counts in the appropriate Job Category and EEO Race Category.  The Job Categories 
are created in the PR Occupational Categories and assigned by employee in the PR Employees. 
The EEO Race Categories are created in the Race Codes and assigned by employee in the PR Employees.  
In order for information to print correctly, the Occupational Category and Race Code must be properly 
assigned to each employee.  The EEO Race Categories and resulting report have been modified to meet 
the Federal Requirements for 9/30/2007.  The report optionally prints the Work Hours of Employment 
by Job and Race Category when run by Job or Region.  The report can be run by Company, Region or Job.  
The Region is defined by Job in the JC Job Master(on PR Info tab).  The report is based on the PR 
Timecards entered for the Beginning and Ending Payroll Ending Dates.  When run by Job or Region, 
the employee is tallied on the Job or Region where the most posted hours occurred.  Employees where 
the majority of their time isn't posted to jobs will be tallied to the Job and Region with the most 
posted time.  Employees not posted to jobs at all will not be tallied when running the report by Job 
or Region.

Things to keep in mind regarding this report and proc: 
The report uses a combination of field and report side formulas to determine how the data
is grouped. Also, race codes and occupational categories are customer defined, but the status
field is not. There is lot of summarizing and a fairly large set of formulaic running totals in the 
report, so modify carefully. 

Parameters:
@PRCo			- Payroll company
@PRGroup		- Payroll group (report can look at a single or all groups)
@BeginPRDate	- Beginning PRTH.PREndDate range
@EndPRDate		- Ending PRTH.PREndDate range
@BeginJCCo		- Beginning Jobcost Company
@EndJCCo		- Ending Jobcost Company
@BeginJob		- Beginning Job
@EndJob			- Ending Job
@BeginEEORegion	- Beginning JCJM.EEORegion value
@EndEEORegion	- Ending JCJM.EEORegion value
@RptType		- Used by report to determine what the sorting level is

Related reports:   
PR Department of Labor EEO-1 Report (ID#: 795)      

Revision History      
Date  Author  Issue     Description
09/26/02 E.T.	CL-??????	/	V1-??????? Modified Stored Procedure to allow all groups or just one
11/13/02 NF		CL-??????	/	V1-??????? Modified Stored Procedure to populate JCCo for Job and Region ReportTypes
11/13/02 NF		CL-??????	/	V1-??????? Modified Stored Procedure updating Joins to SQL94 standards
02/27/02 NF		CL-??????	/	V1-??????? Modified Stored Procedure updating all Joins to SQL94 standards
11/11/04 NF		CL-25897	/	V1-??????? Added with(nolock) to the from and join statements
02/28/05 NF		CL-26875	/	V1-??????? Report Title changed to PR Department of Labor EEO-1 Report
02/28/05 NF		CL-25771	/	V1-??????? Corrections made for running the report by Region and Job
07/18/06 CR		CL-123841	/	V1-??????? modifications to report and proc for EEO report revision

04/02/2011	ScottAlvey	CL-125319	/	V1-D-04084	Report calculates wrong employee totals
	If an employee is in multiple payroll groups for a reporting time period, the report will 
	count the employee for each group it is in and not just once. In the final select statement
	below in the first portion of the union statement I added the folowing group by section (there
	was none before):

	a.RecordType
	, a.CategoryType
	, a.PRCo
	, a.EEORegion
	, a.JCCo
	, a.Job
	, a.Employee
	, a.OccupCatEEOClass
	, a.Race
	, a.Sex
	, a.Apprentice
	, a.Trainees

	I also wrapped the following in max() functions:

	HQCO.Name
	a.PRGroup
	a.PREndDate
	JCJM.Description
	PRPC.BeginDate
	PROP.Description
	PROP.ReportSeq
	PRRC.Description
	PRRC.EEOCat

	and the following in sum() functions:

	a.MaxHrs
	a.Hours

	This gives the report the ability to merge data into a single PRGroup value and since the
	report does not show details down to the individual PR Group values we can 
	use this code to correct the report. No changes on the report side were made.

==================================================================================*/  

as  

Create table #Emps  
(
	RecordType char(1) null  /* C=count, H=Hours */  
	, CategoryType char(1) null /* C=Category, E=EEO Class */  
	, MaxHrs  int null /*1=one with max hours to include 0=not biggest exclude*/  
	, PRCo tinyint null  
	, PRGroup tinyint null
	, PREndDate smalldatetime null
	, EEORegion varchar(8) null
	, JCCo tinyint null
	, Job varchar(10) null
	, Employee int null
	, OccupCatEEOClass varchar(10) null
	, Race varchar(2) null
	, Sex varchar(1) null
	, Apprentice int null
	, Trainees int null
	, Hours numeric(16,2) null
)

/****************************/  
/*  insert Category counts */  
/***************************/  

insert into #Emps  

select 
	distinct 'C'
	, 'C'
	, 0
	, PREH.PRCo
	, PRTH.PRGroup
	, max(PRTH.PREndDate)
	, (case when @RptType='R' then JCJM.EEORegion else ' ' end)
	, (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end)
	, (case when @RptType='J' then PRTH.Job else ' ' end)
	, PREH.Employee
	, PREH.OccupCat
	, PREH.Race
	, PREH.Sex
	, Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end)
	, Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end)
	, Hours=sum(PRTH.Hours)  
from 
	PRTH with(nolock)  
join 
	PREH with(nolock)on  
		PREH.PRCo=PRTH.PRCo 
		and PREH.Employee=PRTH.Employee  
left outer join 
	JCJM with(nolock)on  
		PRTH.JCCo=JCJM.JCCo 
		and PRTH.Job=JCJM.Job  
where -- if report is by company null jobs should be included - else get rid of them
	IsNull(PRTH.Job,' ') = (case when @RptType = 'C' then IsNull(PRTH.Job,' ') else PRTH.Job end)  
	and PRTH.PRCo=@PRCo 
	and PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end)  
	and 
		(
			PRTH.PREndDate>=@BeginPRDate 
			and PRTH.PREndDate<=@EndPRDate 
		)
	and (
			IsNull(PRTH.JCCo,0)>=@BeginJCCo 
			and IsNull(PRTH.JCCo,0)<=@EndJCCo 
		)
	and  
		(
			IsNull(PRTH.Job,'')>=@BeginJob 
			and IsNull(PRTH.Job,'')<=@EndJob 
		)
	and  
		(
			IsNull(JCJM.EEORegion,'')>=@BeginEEORegion 
			and IsNull(JCJM.EEORegion,'')<=@EndEEORegion 
		) 
group by 
	PREH.PRCo
--	, PRTH.PREndDate
	, PRTH.PRGroup
	, (case when @RptType='R' then JCJM.EEORegion else ' ' end)
	, (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end)
	, (case when @RptType='J' then PRTH.Job else ' ' end)
	, PREH.Employee
	, PREH.OccupCat
	, PREH.Race
	, PREH.Sex  
	
/***************************************/  
/* update records don't have most hours*/ 
/***************************************/  

update #Emps
  
set 
	MaxHrs=1  
from 
	(
		select 
			#Emps.PRCo
			, #Emps.Employee
			, #Emps.Hours
			, MinEEORegion=min(EEORegion)
			, MinJCCo=min(JCCo)
			, MinJob=min(Job)  
		From 
			#Emps  
		Group By 
			#Emps.PRCo
			, #Emps.Employee
			, #Emps.Hours
	) as a  
join 
	(
		select 
			#Emps.PRCo
			, #Emps.Employee
			, Hours=max(#Emps.Hours) 
		From 
			#Emps  
		Group By 
			#Emps.PRCo
			, #Emps.Employee
	) as b on
		a.PRCo=b.PRCo  
		and a.Employee=b.Employee  
		and a.Hours=b.Hours  
where 
	#Emps.PRCo=a.PRCo   
	and #Emps.Employee=a.Employee  
	and #Emps.EEORegion=a.MinEEORegion  
	and #Emps.JCCo=a.MinJCCo  
	and #Emps.Job=a.MinJob  


/****************************/  
/*  insert Category Hours */  
/***************************/  

insert into #Emps  

select 
	'H'
	, 'C'
	, 0
	, PREH.PRCo
	, PRTH.PRGroup
	, max(PRTH.PREndDate)
	, (case when @RptType='R' then JCJM.EEORegion else ' ' end)
	, (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end)
	, (case when @RptType='J' then PRTH.Job else ' ' end)
	, PREH.Employee
	, PREH.OccupCat
	, PREH.Race
	, PREH.Sex
	, Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end)
	, Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end)
	, Hours=sum(PRTH.Hours)  
from 
	PRTH with(nolock)  
join 
	PREH with(nolock) on 
		PREH.PRCo=PRTH.PRCo 
		and PREH.Employee=PRTH.Employee  
left outer join 
	JCJM with(nolock) on 
		PRTH.JCCo=JCJM.JCCo 
		and PRTH.Job=JCJM.Job  
where -- if report is by company null jobs should be included - else get rid of them   
	IsNull(PRTH.Job,'') = (case when @RptType = 'C' then IsNull(PRTH.Job,'') else PRTH.Job end)  
	and PRTH.PRCo=@PRCo 
	and PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end)  
	and 
		(
			PRTH.PREndDate>=@BeginPRDate 
			and PRTH.PREndDate<=@EndPRDate 
		)
	and 
		(
			IsNull(PRTH.JCCo,0)>=@BeginJCCo 
			and IsNull(PRTH.JCCo,0)<=@EndJCCo 
		)
	and
		(
			IsNull(PRTH.Job,'')>=@BeginJob 
			and IsNull(PRTH.Job,'')<=@EndJob 
		)
	and  
		(
			IsNull(JCJM.EEORegion,'')>=@BeginEEORegion 
			and IsNull(JCJM.EEORegion,'')<=@EndEEORegion  
		)
group by 
	PREH.PRCo
	, PRTH.PRGroup
	, (case when @RptType='R' then JCJM.EEORegion else ' ' end)
	, (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end)
	, (case when @RptType='J' then PRTH.Job else ' ' end)
	, PREH.Employee
	, PREH.OccupCat
	, PREH.Race
	, PREH.Sex  
	
/***************************************/  
/* update records don't have most hours*/ 
/***************************************/  

update #Emps 
	
set 
	MaxHrs=1  
from 
	(
		select 
			#Emps.PRCo
			, #Emps.Employee
			, #Emps.Hours
			, MinEEORegion=min(EEORegion)
			, MinJCCo=min(JCCo)
			, MinJob=min(Job)  
		From 
			#Emps  
		Group By 
			#Emps.PRCo
			, #Emps.Employee
			, #Emps.Hours
	) as a  
join 
	(
		select 
			#Emps.PRCo
			, #Emps.Employee
			, Hours=max(#Emps.Hours) 
		From 
			#Emps  
		Group By 
			#Emps.PRCo
			, #Emps.Employee
	) as b on 
		a.PRCo=b.PRCo  
		and a.Employee=b.Employee  
		and a.Hours=b.Hours  
where 
	#Emps.PRCo=a.PRCo   
	and #Emps.Employee=a.Employee  
	and #Emps.EEORegion=a.MinEEORegion  
	and #Emps.JCCo=a.MinJCCo  
	and #Emps.Job=a.MinJob  
   
/****************************/  
/*  select the results */  
/***************************/  

select 
	RecordType=a.RecordType
	, CategoryType=a.CategoryType
	, MaxHrs=sum(a.MaxHrs)
	, Company=a.PRCo
	, CoName=max(HQCO.Name)
	, PRGroup=max(a.PRGroup)
	, WeekBegin=max(PRPC.BeginDate)
	, PREndDate=max(a.PREndDate)
	, EEORegion=a.EEORegion
	, JCCo=a.JCCo
	, Job=a.Job
	, JobDesc=max(JCJM.Description)
	, Employee=a.Employee
	, OccupCatEEOClass=a.OccupCatEEOClass
	, OccupCatDesc=max(PROP.Description)
	, OccupOrder=max(PROP.ReportSeq)
	, Race=a.Race
	, RaceDesc=max(PRRC.Description)
	, RaceEEOCat=max(PRRC.EEOCat)
	, Sex=a.Sex
	, Apprentice=a.Apprentice
	, Trainees=a.Trainees
	,  Hours=sum(a.Hours)
	, RT=0
	, BeginPRDate=@BeginPRDate
	, EndPRDate=@EndPRDate
	, BeginJCCo=@BeginJCCo
	, EndJCCo=@EndJCCo
	, BeginJob=@BeginJob
	, EndJob=@EndJob
	, BeginEEORegion=@BeginEEORegion
	, EndEEORegion=@EndEEORegion
	, RptType=@RptType
	, Date1='1950'
	, Date2='1950'  

from 
	#Emps a with(nolock)  
Left Join 
	PROP with(nolock) on 
		PROP.PRCo=a.PRCo 
		and PROP.OccupCat=a.OccupCatEEOClass  
Left Join 
	JCJM with(nolock) on 
		JCJM.JCCo=a.JCCo 
		and JCJM.Job=a.Job  
Join 
	PRPC with(nolock) on 
		PRPC.PRCo=a.PRCo 
		and PRPC.PRGroup=a.PRGroup 
		and PRPC.PREndDate=a.PREndDate  
Join 
	HQCO with(nolock) on 
		HQCO.HQCo=a.PRCo  
Left Join 
	PRRC with(nolock) on 
		PRRC.PRCo=a.PRCo 
		and PRRC.Race=a.Race 

group by
	a.RecordType
	, a.CategoryType
	, a.PRCo
	, a.EEORegion
	, a.JCCo
	, a.Job
	, a.Employee
	, a.OccupCatEEOClass
	, a.Race
	, a.Sex
	, a.Apprentice
	, a.Trainees

Union all  

select 
	'T'
	, null
	, 0
	, PRTH.PRCo
	, ''
	, 0
	, '1/1/1950'
	, '1/1/1950'
	, (case when @RptType='R' then JCJM.EEORegion else ' ' end)
	, ''
	, ''
	, ''
	, 0
	, ''
	, ''
	, 0
	, ''
	, ''
	, PRRC.EEOCat
	, PREH.Sex
	, Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end)
	, Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end)
	, 0
	, RT= count(distinct PREH.Employee)
	, BeginPRDate=@BeginPRDate
	, EndPRDate=@EndPRDate
	, BeginJCCo=@BeginJCCo
	, EndJCCo=@EndJCCo
	, BeginJob=@BeginJob
	, EndJob=@EndJob
	, BeginEEORegion=@BeginEEORegion
	, EndEEORegion=@EndEEORegion
	, RptType=@RptType
	, Date1 =  Year(DateAdd(Year, -1, @BeginPRDate))
	, Date2 =  year(@BeginPRDate)   
from 
	PRTH with(nolock)  
join 
	PREH with(nolock) on 
		PREH.PRCo=PRTH.PRCo 
		and PREH.Employee=PRTH.Employee  
left outer join 
	JCJM with(nolock) on 
		PRTH.JCCo=JCJM.JCCo 
		and PRTH.Job=JCJM.Job  
left Join 
	PROP with (nolock) on 
		PREH.PRCo=PROP.PRCo 
		and PREH.OccupCat=PROP.OccupCat  
left join 
	PRRC with (nolock) on 
		PREH.PRCo=PRRC.PRCo 
		and PREH.Race=PRRC.Race  
join 
	HQCO with (nolock) on 
		PRTH.PRCo=HQCO.HQCo  
where 
	PRTH.PRCo=@PRCo 
	and PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end) 
	and Year(PRTH.PREndDate) = Year(DateAdd(Year, -1, @BeginPRDate))  
	and 
		(
			IsNull(PRTH.JCCo,0)>=@BeginJCCo 
			and IsNull(PRTH.JCCo,0)<=@EndJCCo 
		)
	and  
		(
			IsNull(PRTH.Job,'')>=@BeginJob 
			and IsNull(PRTH.Job,'')<=@EndJob 
		)
	and  
		(
			IsNull(JCJM.EEORegion,'')>=@BeginEEORegion 
			and IsNull(JCJM.EEORegion,'')<=@EndEEORegion  
		)
group by 
	PRTH.PRCo
	, PRTH.PRGroup
	, (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end)
	, (case when @RptType='R' then JCJM.EEORegion else ' ' end)
	, (case when @RptType='J' then PRTH.Job else ' ' end)
	, PREH.Sex
	, PRRC.EEOCat  










/*end */  
GO
GRANT EXECUTE ON  [dbo].[brptEEODot] TO [public]
GO
