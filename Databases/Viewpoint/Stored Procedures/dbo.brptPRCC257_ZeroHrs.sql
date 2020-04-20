SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptPRCC257_ZeroHrs    Script Date: 02/28/05 NF *****/
/******New Stored Procedure for Jobs with Zero Hours   *****/ 


  CREATE                proc dbo.brptPRCC257_ZeroHrs
   (@PRCo bCompany, @PRGroup bGroup, @BeginPRDate bDate = '01/01/1950',
   @EndPRDate bDate = '12/31/2050', @BeginJCCo bCompany, @EndJCCo bCompany,
   @BeginJob bJob, @EndJob bJob, @RptType char(1) = 'J'  --@RptType J=Job, C=Company 
   )
   as
   
   Create table #Emps
   
   (RecordType char(1) null,  /* C=count, H=Hours Z=Zero Hr Jobs*/
    CategoryType char(1) null, /* C=Category, E=EEO Class */
    MaxHrs		int	null, /*1=one with max hours to include 0=not biggest exclude*/
    PRCo tinyint null,
    PRGroup	tinyint null,
    PREndDate	smalldatetime null,
    JCCo tinyint null,
    Job varchar(10) null,
    Employee int null,
    OccupCatEEOClass varchar(10) null,
    Race varchar(2) null,
    Sex varchar(1) null,
    Apprentice int null,
    Trainees int null,
    Hours numeric(16,2) null)
      
   /****************************/
   /*  insert Category counts */
   /***************************/
   insert into #Emps
   
   select distinct 'C','C',0, PREH.PRCo,PRTH.PRGroup,max(PRTH.PREndDate),
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end), 
    PREH.Employee, PREH.OccupCat, PREH.Race, PREH.Sex,
    Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end),
    Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end),
    Hours=sum(PRTH.Hours)
   from PRTH with(nolock)
      join PREH with(nolock)on 	PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
      left outer join JCJM with(nolock)on 	PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
   where 
       
   /* if report is by company null jobs should be included - else get rid of them */
    IsNull(PRTH.Job,' ') = (case when @RptType = 'C' then IsNull(PRTH.Job,' ') else PRTH.Job end)
    and PRTH.PRCo=@PRCo and 
    PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end)
    and PRTH.PREndDate>=@BeginPRDate and
    PRTH.PREndDate<=@EndPRDate and IsNull(PRTH.JCCo,0)>=@BeginJCCo and IsNull(PRTH.JCCo,0)<=@EndJCCo and
    IsNull(PRTH.Job,'')>=@BeginJob and IsNull(PRTH.Job,'')<=@EndJob
   
   group by PREH.PRCo,
    PRTH.PRGroup,
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
   PREH.Employee,PREH.OccupCat,PREH.Race,PREH.Sex
   /* update records don't have most hours*/
   
   update #Emps
   set MaxHrs=1
   where #Emps.Hours=(select Max(e.Hours) from #Emps e with(nolock)
   	where #Emps.PRCo=e.PRCo and #Emps.Employee=e.Employee
   	group by e.PRCo,e.Employee)
      
   /***************************/
   /* insert Occup Cat Class counts */
   /***************************/
   insert into #Emps
   
   select distinct  'C','E',0,PREH.PRCo,PRTH.PRGroup,max(PRTH.PREndDate),
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
    PREH.Employee, PREH.CatStatus, PREH.Race, PREH.Sex,
    Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end),
    Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end),
    Hours=sum(PRTH.Hours)
   from PRTH with(nolock)
     join PREH with(nolock) on PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
     left outer join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
   where 
      
   /* if report is by company null jobs should be included - else get rid of them */
    IsNull(PRTH.Job,'') = (case when @RptType = 'C' then IsNull(PRTH.Job,'') else PRTH.Job end)
    and PRTH.PRCo=@PRCo and 
    PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end)
    and PRTH.PREndDate>=@BeginPRDate and
    PRTH.PREndDate<=@EndPRDate and IsNull(PRTH.JCCo,0)>=@BeginJCCo and IsNull(PRTH.JCCo,0)<=@EndJCCo and
    IsNull(PRTH.Job,'')>=@BeginJob and IsNull(PRTH.Job,'')<=@EndJob 
   
   group by PREH.PRCo,PRTH.PRGroup,
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
   PREH.Employee,PREH.CatStatus,PREH.Race,PREH.Sex
   
   update #Emps
   set MaxHrs=1
   where #Emps.Hours=(select Max(e.Hours) from #Emps e with(nolock)
   	where #Emps.PRCo=e.PRCo and #Emps.Employee=e.Employee
   	group by e.PRCo,e.Employee)
   
   
   /****************************/
   /*  insert Category Hours */
   /***************************/
   
   insert into #Emps
   
   select 'H','C',0,PREH.PRCo,PRTH.PRGroup,PRTH.PREndDate,
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
    PREH.Employee, PREH.OccupCat, PREH.Race, PREH.Sex,
    Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end),
    Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end),
    Hours=sum(PRTH.Hours)
   from PRTH with(nolock)
      join PREH with(nolock) on PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
      left outer join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
   where 
       
   /* if report is by company null jobs should be included - else get rid of them */
   IsNull(PRTH.Job,'') = (case when @RptType = 'C' then IsNull(PRTH.Job,'') else PRTH.Job end)
    and PRTH.PRCo=@PRCo and 
    PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end)
    and PRTH.PREndDate>=@BeginPRDate and
   PRTH.PREndDate<=@EndPRDate and IsNull(PRTH.JCCo,0)>=@BeginJCCo and IsNull(PRTH.JCCo,0)<=@EndJCCo and
   IsNull(PRTH.Job,'')>=@BeginJob and IsNull(PRTH.Job,'')<=@EndJob 
   
   group by PREH.PRCo,PRTH.PRGroup,PRTH.PREndDate,
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
   PREH.Employee,
   PREH.OccupCat,PREH.Race,PREH.Sex
   
   
   /****************************/
   /*  insert EEOClass Hours */
   /***************************/
   
   insert into #Emps
   
   select 'H','E',0,PREH.PRCo,PRTH.PRGroup,PRTH.PREndDate,
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
    PREH.Employee, PREH.CatStatus, PREH.Race, PREH.Sex,
    Apprentice= Max(case PREH.CatStatus when 'A' then 1 else 0 end),
    Trainees= Max(case PREH.CatStatus when 'T' then 1 else 0 end),
    Hours=sum(PRTH.Hours)
   from PRTH with(nolock)
     join PREH with(nolock) on PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
     left outer join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
   where 
      
   /* if report is by company null jobs should be included - else get rid of them */
    IsNull(PRTH.Job,'') = (case when @RptType = 'C' then IsNull(PRTH.Job,'') else PRTH.Job end)
    and PRTH.PRCo=@PRCo and 
    PRTH.PRGroup = (case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end)
    and PRTH.PREndDate>=@BeginPRDate and
    PRTH.PREndDate<=@EndPRDate and IsNull(PRTH.JCCo,0)>=@BeginJCCo and IsNull(PRTH.JCCo,0)<=@EndJCCo
    and IsNull(PRTH.Job,'')>=@BeginJob and IsNull(PRTH.Job,'')<=@EndJob 
   
   group by PREH.PRCo,PRTH.PRGroup,PRTH.PREndDate,
    (case when @RptType='C' then PREH.PRCo else JCJM.JCCo end),
    (case when @RptType='J' then PRTH.Job else ' ' end),
   PREH.Employee,PREH.CatStatus,PREH.Race,PREH.Sex
   	/***************************/
    	/*Section for Zero Hour Jobs*/
	/***************************/
insert into #Emps
   
   select distinct 'Z',NULL,0, NULL,0,NULL,
    JCJM.JCCo ,
    JCJM.Job , 
    NULL, NULL, NULL, NULL,
    NULL,
    NULL,
    Hours=0
   from JCJM with(nolock)
      
   where  not exists  (select distinct JCCo, Job 
                  from PRTH
	          where PRTH.JCCo = JCJM.JCCo and PRTH.Job = JCJM.Job and
                  PRTH.PRCo = @PRCo and PRTH.PREndDate>=@BeginPRDate and
    		  PRTH.PREndDate<=@EndPRDate) 
     and Certified = 'Y'  
     and JCCo>= @BeginJCCo and JCCo<=@EndJCCo and Job>=@BeginJob and Job<=@EndJob
   group by JCJM.JCCo,JCJM.Job
    
   /****************************/
   /*  select the results */
   /***************************/
   select
   
    a.RecordType, a.CategoryType, a.MaxHrs, a.PRCo, CoName=HQCO.Name, a.PRGroup, WeekBegin=PRPC.BeginDate,
    a.PREndDate,  a.JCCo, a.Job,JobDesc=JCJM.Description,  a.Employee,
    a.OccupCatEEOClass,OccupCatDesc=PROP.Description, OccupOrder=PROP.ReportSeq, a.Race, RaceDesc=PRRC.Description,
    RaceEEOCat=PRRC.EEOCat, a.Sex, a.Apprentice, a.Trainees,  a.Hours,  
   BeginPRDate=@BeginPRDate,
   EndPRDate=@EndPRDate,
   BeginJCCo=@BeginJCCo,
   EndJCCo=@EndJCCo,
   BeginJob=@BeginJob,
   EndJob=@EndJob,
   RptType=@RptType
   
     from #Emps a with(nolock)
   
   Left Join PROP with(nolock) on PROP.PRCo=a.PRCo and PROP.OccupCat=a.OccupCatEEOClass
   Left Join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
   Join PRPC with(nolock) on PRPC.PRCo=a.PRCo and PRPC.PRGroup=a.PRGroup and PRPC.PREndDate=a.PREndDate
   Join HQCO with(nolock) on HQCO.HQCo=a.PRCo
   Left Join PRRC with(nolock) on PRRC.PRCo=a.PRCo and PRRC.Race=a.Race
   
   /*end */
GO
GRANT EXECUTE ON  [dbo].[brptPRCC257_ZeroHrs] TO [public]
GO
