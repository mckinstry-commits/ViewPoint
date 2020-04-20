


ALTER proc [dbo].[mrptPRTimeByEarnCode]

(
	@PRCo bCompany
	, @PRGroup bGroup
	, @PREndDate smalldatetime
	, @SortCriteria varchar(20) = ' '
	, @SortOrder char(1)
	, @BegPostingDate smalldatetime ='01/01/1950' 
	, @EndPostingDate smalldatetime ='12/31/2050'
	, @BegEmp int
	, @EndEmp int
	, @CertJobOnly char(1)
	, @Type char(1) = ' '
	, @BeginningJob bJob 
	, @EndingJob bJob	
	, @BeginningJCCo tinyint
	, @EndingJCCo tinyint
	, @SMCo bCompany -- V1-B-10098
	, @SMWorkOrder int -- V1-B-10098
	, @BegPaySeq tinyint=0,@EndPaySeq tinyint=255
	,--6/3/2014
	@EndPREndDate smalldatetime
	,--11/13/2014
	@BatchId int =0
	
)
/**********************************
CREATED:	5/27/2014 
PURPOSE:	MCK PR Time Card History Report
MODIFIED:	add Beg/End PaySeq
			6/3/2014 add Beg/End PREndDate
			6/3/2014 add PREndDate to column to print total for each PREndDate in report
			11/13/2014 add parameter for BatchId Restriction Blank for all
TEST:		mrptPRTimeByEarnCode	101	, 2	,'1/01/2013'	,  ' '	,'S'	, '01/01/1950' 	,'12/31/2050'
	, 0	, 999999	, 'N'	,   ' '	, ''	,'zzzzzzzzzz'	, 0	, 255	, 0	, 0,0,255,'6/3/2014',17
	--select * from bPRTH
grant all on mrptPRTimeByEarnCode to public
************************************/      
/*==================================================================================      

Author: 
??  

Create date:    
?? 

Usage:
Provide data to the Earn Code summary subreport of both versions of the PR Timecard Entry Reports

Things to keep in mind regarding this report and proc: 

Related reports:
PR Time Card Entry (ID: 855)
PR Timecard Entry List - Landscape (ID: 858)   

Revision History      
Date		Author			Issue						Description
07/16/2003	DH			CL-###### / V1-#-#####	Removed case statements from where clause to 
	improve performance.  Added new variables to select @SortCriteria, which is passed
	from the report
11/11/2004	NF			CL-025927 / V1-#-#####  Added with(nolock) to the from and join statements
08/31/2005	NF			CL-027534 / V1-#-#####	Added TimeCard Type to restrict records to match the main report.
08/31/2005	CW			CL-136956 / V1-#-#####	Added BeginningJob, EndingJob, BeginningJCCo and EndingJCCo parameters.
	This allows the stored procedure to report for specific jobs within a job cost company.
08/31/2005	HH			CL-140755 / V1-#-#####	Added isnull-check to JCJM.JCCo and JCJM.Job in where clause 
	(since left outer join)
08/31/2005	ScottAlvey	CL-###### / V1-B-10098	add SM Work Order as a field to show and as a filter
	and clean up code structure


==================================================================================*/ 
   
as

declare 
	@BegCrew varchar(10)
	, @EndCrew varchar(10)
	, @BegJCCo tinyint
	, @EndJCCo tinyint
	, @BegJob varchar(10)
	, @EndJob varchar(10)

select 
	@BegCrew=(case when @SortOrder='C' then @SortCriteria else '' end)
	, @EndCrew=(case when @SortOrder='C' then @SortCriteria else 'zzzzzzzzzz' end)
	, @BegJCCo=(case when @SortOrder='J'  and @SortCriteria <> '' then cast(Left(@SortCriteria, 3) as tinyint) else 0 end)
	, @EndJCCo=(case when @SortOrder='J'  and @SortCriteria <> '' then cast(Left(@SortCriteria, 3) as tinyint) else 255 end)
	, @BegJob=(case when @SortOrder='J' and @SortCriteria <> '' then substring(@SortCriteria,4,20) else ' ' end)
	, @EndJob=(case when @SortOrder='J' and @SortCriteria <> '' then substring(@SortCriteria,4,20) else 'zzzzzzzzzz' end)



set nocount on

select 
	PREC.EarnCode
	, PREC.Description
	,PRTH.PREndDate
	, Hours = sum(PRTH.Hours)
	, EarnCodeAmt = sum(PRTH.Amt) 
	, PRTH.Type --,JCJM.Job 
From 
	bPRTH PRTH  with(nolock)
Join 
	bPREH PREH  with(nolock) on
		PREH.PRCo=PRTH.PRCo 
		and PREH.Employee=PRTH.Employee
Join 
	bPREC PREC  with(nolock) on 
		PREC.PRCo=PRTH.PRCo 
		and PREC.EarnCode = PRTH.EarnCode
left outer join 
	bJCJM JCJM  with(nolock) on 
		PRTH.JCCo = JCJM.JCCo 
		and PRTH.Job = JCJM.Job
Where 
	PRTH.PRCo=@PRCo 
	and PRTH.PRGroup=@PRGroup 
	--6/3/2014 and PRTH.PREndDate=@PREndDate
	and PRTH.PREndDate between @PREndDate and @EndPREndDate
	and PRTH.Employee>=@BegEmp and PRTH.Employee<=@EndEmp
	and isnull(PRTH.Crew,'')>=@BegCrew and isnull(PRTH.Crew,'')<=@EndCrew
	and isnull(PRTH.JCCo,0)>=@BegJCCo and isnull(PRTH.JCCo,0)<=@EndJCCo
	and isnull(PRTH.Job,'')>=@BegJob and isnull(PRTH.Job,'')<=@EndJob
	and isnull(PRTH.Job,'')=(case when @SortOrder = 'J' and @SortCriteria = '' then '' else isnull(PRTH.Job,'') end)
	and isnull(JCJM.Certified,'')=(case when @CertJobOnly = 'Y' then  'Y' else isnull(JCJM.Certified,'') end) 
	and PRTH.Type = (case when @Type <> ' ' then  @Type else PRTH.Type end)
	and PRTH.PostDate>=@BegPostingDate and PRTH.PostDate<=@EndPostingDate 
	and isnull(JCJM.JCCo,'') >= @BeginningJCCo and isnull(JCJM.JCCo,'') <= @EndingJCCo
	and isnull(JCJM.Job,'') >= @BeginningJob and isnull(JCJM.Job,'') <= @EndingJob
	and (case when @SMCo = 0 then @SMCo else PRTH.SMCo end) = @SMCo -- V1-B-10098
	and (case when @SMWorkOrder = 0 then @SMWorkOrder else PRTH.SMWorkOrder end) = @SMWorkOrder -- V1-B-10098
	and PRTH.PaySeq between @BegPaySeq and @EndPaySeq
	--11/13/2014
	and (case when @BatchId  =0 then @BatchId else PRTH.BatchId end) =@BatchId 
Group By 
	PREC.EarnCode
	, PREC.Description
	, PRTH.Type --,JCJM.Job
	,PRTH.PREndDate





GO


