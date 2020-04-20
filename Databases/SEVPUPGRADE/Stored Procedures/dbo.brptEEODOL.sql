SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[brptEEODOL]  
(
	@PRCo bCompany
	, @PRGroup bGroup
	, @BeginPRDate bDate = '01/01/1950'
	, @EndPRDate bDate = '12/31/2050'
	, @BeginJCCo bCompany
	, @EndJCCo bCompany
	, @BeginJob bJob
	, @EndJob bJob
	, @RptType char(1) = 'J'  --J=Job, R=Region, C=Company   
   , @CertYN char(1)
)

/*==================================================================================        
  
Author:     
??    
  
Create date:     
?? - possibly 5/22/02      
  
Usage:     
Reports overall employment utilization and breaks out minority employees by race and gender.    
The report may be printed by Job, Region, SMSA code, or for the entire Company.  After Job,   
Region, or SMSA code, the report sorts by Craft and prints one line per EEO Class, which is   
entered in the PR Craft Class Setup form.  This report has a special parameter that complies   
with a New York state requirement, which excludes minority women from the minority percentage   
column and instead accounts for them solely in the Female Percentage column.  All hours will   
print for all jobs requested, but employees will be counted only once on the job (or SMSA   
code, region) where they worked the most hours.  If an EEO class is not set up on the   
craft/class assigned to the PR Employee, the employee will not be included in the report   
totals. Report may be restricted to include only certified employees (except when run by Company   
Totals).  
  
Note: Use PR Department of Labor EEO-1 Report to report to the Department of Labor.  
  
Things to keep in mind regarding this report and proc:   
The report uses a combination of field and report side formulas to determine how the data  
is grouped. Also, race codes and occupational categories are customer defined, but the status  
field is not. There is lot of summarizing and a fairly large set of formulaic running totals in the   
report, so modify carefully.   
  
Parameters:  
@PRCo   - Payroll company  
@PRGroup  - Payroll group (report can look at a single or all groups)  
@BeginPRDate - Beginning PRTH.PREndDate range  
@EndPRDate  - Ending PRTH.PREndDate range  
@BeginJCCo  - Beginning Jobcost Company  
@EndJCCo  - Ending Jobcost Company  
@BeginJob  - Beginning Job  
@EndJob   - Ending Job  
@RptType  - Used by report to determine what the sorting level is  
@CertYN   - Flag to determine if only Certified employee data is shown or all data is shown  
  
Related reports:     
PR Monthly Employment Utilization Report (ID#: 838)        
  
Revision History        
Date  Author  Issue     Description  
05/22/02 DH  CL-14582 / V1-??????? Found a problem when the same employee has more than one entry that equals max hours.  
12/04/02 NF  CL-19436 / V1-??????? Does not print job description  
05/28/05 NF  CL-26874 / V1-??????? changes the name of the report to PR Monthly Employment Utilization Report  
04/02/03 ET  CL-20721 / V1-??????? ansii standard for Crystal 9.0 using tables instead of views & non-ansii joins  
05/08/03 NF  CL-????? / V1-??????? Join statement for JCJM to PRTH should be Left Outer Join  
05/08/03 NF  CL-????? / V1-??????? added max Job to Sum Recap type records  
11/11/04 NF  CL-25913 / V1-??????? Added with(nolock) to the from and join statements  
02/28/05 NF  CL-25345 / V1-??????? Change the PR Group to be able to run for all groups  
09/11/06 NF  CL-122347 / V1-??????? Set JCCo to Max(JCCo) and removed JCCo from group by in the SumRecap section  
  
04/05/2012 Debra McKelveyLinden CL-132461 / V1 D-04023 added HQSM.Description as SMSADesc   
 along with a left outer join on JCJM. Solution - report:  
 @RecapHeading to show the SMSADesc when there is a value in @SumRecap.    
 When there is no value in @SumRecap, the group header will show "SMSA Code: N/A".  
 Also added parameter defaults to Crystal (which should result in no change to the user experience).  
 Solution - SQL:  
 Changed stored procedure brptEEODOL to include HQSM.Description as SMSADesc, and   
 added a left outer join for HQSM on JCJM. Added notes on stored procedure to indicate  
  
04/06/2012 ScottAlvey CL-146231 / V1-D-04810 Report calculates wrong employee totals  
 If an employee is in multiple payroll groups for a reporting time period, the report will   
 count the employee for each group it is in and not just once. In the second pass Insert into #Emps  
 statement I remmed out the e.PRGroup grouping so that it will merge all relatd data into   
 as single group. Due to this change in the grouping I then had to wrap the PRGroup field in a 
 max statement. Lastly in the subselect I remoeved the link from #Emps.Class = e.Class as 
 we do not care about class and craft in the report summary, we just want the line that has the
 most hours. Testing shows that the report will still calculate hours correctly.  
 NO REPORT SIDE CHANGS WERE MADE REGARDING THIS ISSUE  
  
==================================================================================*/          
as        
  
Create table #Emps        
(        
 RecordType char(1) null,  /* D=Details, S=Sum Recap, C=Company*/        
 CountRec char(1) null,    /* Employee count records (Y=Yes, N=No) */        
 SumRecap char(10) null,  /* job, region, company, SMSA */        
 PRCo tinyint null,        
 PRGroup tinyint null,        
 PREndDate smalldatetime null,        
 EEORegion varchar(8) null,        
 SMSACode varchar(10) null,         
 JCCo tinyint null,        
 Job varchar(10) null,        
 Craft varchar(10) null,        
 Employee int null,        
 CertYN  char(1) null,         
 EEOClass varchar(10) null,        
 Race varchar(2) null,        
 Sex varchar(1) null,        
 Hours numeric(16,2) null,        
 MostHours varchar(1) null,        
 MaxHours numeric (16,2) null         
)        
  
/***************************/   
/* FIRST PASS */    
/* insert EEO Detail */        
/***************************/        
insert into #Emps        
  
select  
  'D'  
  , 'N'  
  , (  
   case @RptType        
    when 'J' then PRTH.Job        
    when 'C' then convert(varchar(10),PRTH.PRCo) --then PRTH.Job        
    when 'R' then JCJM.EEORegion        
    when 'S' then JCJM.SMSACode else ''  
   end  
  )  
 , PRTH.PRCo  
 , PRTH.PRGroup
 , PRTH.PREndDate  
 , JCJM.EEORegion  
 , JCJM.SMSACode  
 , IsNull(PRTH.JCCo,PREH.PRCo)  
 , PRTH.Job  
 , PRTH.Craft  
 , PREH.Employee  
 , PREH.CertYN  
 , PRCC.EEOClass  
 , PREH.Race  
 , PREH.Sex  
 , Hours=sum(PRTH.Hours)  
 , 'N'  
 , 0        
from   
 PREH with(nolock)        
Join   
 PRTH with(nolock) on    
  PRTH.PRCo=PREH.PRCo   
  and PRTH.Employee=PREH.Employee        
Join   
 PRCC with(nolock) on   
  PRCC.PRCo=PRTH.PRCo   
  and PRCC.Craft=PRTH.Craft   
  and PRCC.Class=PRTH.Class        
Left Join   
 JCJM with(nolock) on   
  JCJM.JCCo=PRTH.JCCo   
  and JCJM.Job=PRTH.Job        
Where   
 PREH.PRCo=@PRCo   
 and PRTH.PRGroup =  
  (  
   Case When @PRGroup <> 0   
    then   
     @PRGroup   
    else   
     PRTH.PRGroup   
   end  
  )        
 and PRTH.PREndDate>=@BeginPRDate   
 and PRTH.PREndDate<=@EndPRDate        
 and IsNull(PRTH.JCCo,PREH.PRCo)>=@BeginJCCo   
 and IsNull(PRTH.JCCo,PREH.PRCo)<=@EndJCCo        
 and IsNull(PRTH.Job,'')>=@BeginJob   
 and IsNull(PRTH.Job,'')<=@EndJob    
 

  
/*Select only certified employees if the report type is job and the cert parameter = Y        
Else set PRTH.Cert equal to itself, which selects all records*/        
  
 and PRTH.Cert =  
  (  
   case when @RptType='C'   
    then   
     PRTH.Cert   
    else   
     (  
      case when @CertYN='Y'   
       then   
        'Y'   
       else    
        PRTH.Cert   
      end  
     )   
   end  
  )   
  
/* if report is by company null jobs should be included - else get rid of them */        
 and IsNull(PRTH.Job,'') =   
  (  
   case when @RptType = 'C'   
    then   
     IsNull(PRTH.Job,'')   
    else   
     PRTH.Job   
   end  
  )        
  
group by   
 PREH.PRCo  
 , PRTH.PRCo  
 , PRTH.PRGroup  
 , PRTH.PREndDate  
 , JCJM.EEORegion  
 , JCJM.SMSACode  
 , PRTH.JCCo  
 , PRTH.Job  
 , PREH.Employee  
 , PREH.CertYN  
 , PRTH.Craft  
 , PRCC.EEOClass  
 , PREH.Race  
 , PREH.Sex   
 
  --select * from #Emps  
  
/* SECOND PASS */

-- Get the max hours for one employee, craft, and SumRecap (usually job)        
/** 12/4/02 NF.  Inserted JCCo, and max(Job) so that JobDesc will print for all jobs on report. Issue 19436.*/        
  
insert into #Emps        
(  
 RecordType  
 , CountRec  
 , SumRecap  
 , PRCo  
 , PRGroup  
 , JCCo  
 , Job  
 , Craft  
 , EEOClass  
 , Employee  
 , Race  
 , Sex  
 , MaxHours  
 , MostHours  
)        
select   
 'D'  
 , 'Y'  
 , e.SumRecap  
 , e.PRCo  
 , max(e.PRGroup) as PRGroup
 , max(e.JCCo)  
 , max(e.Job)  
 , e.Craft
 , e.EEOClass
 , e.Employee  
 , e.Race  
 , e.Sex  
 , e.Hours
 ,'N'        
from    
 #Emps e        
Where   
 e.Hours =   
  (  
   select   
    max(Hours)   
   From   
    #Emps   
   where   
    #Emps.PRCo=e.PRCo   
    and #Emps.Employee=e.Employee  
  )         
group by   
 e.RecordType  
 , e.SumRecap  
 , e.PRCo  
-- , e.PRGroup  
 , e.Craft  
 , e.EEOClass  
 , e.Employee  
 , e.Race  
 , e.Sex  
 , e.Hours      
  
 -- select * from #Emps
 
 /* THIRD PASS */
  
/** 5/22/02 DH.  Added update statement per Issue #14582        
Update the Most Hours field using the count records (CountRec=Y) where each Emp/Craft Hours = MaxHours        
If employee works same number of maximum hours on two different SumRecaps (Job, SMSA, Region), Craft        
or EEOClass, update most hours on the first SumRecap/Craft/EEOClass employee record  **/        
  
update #Emps   
 Set   
  MostHours ='Y'        
From   
 #Emps e   
 , (  
  Select   
   PRCo  
   , Employee  
   , MaxHours  
   , Craft=min(Craft)  
   , EEOClass=min(EEOClass)  
   , SumRecap=min(SumRecap)        
  From   
   #Emps         
  Where   
   CountRec='Y'   
  Group By   
   PRCo  
   , Employee  
   , MaxHours  
   ) as EmpMaxHr        
Where   
 e.PRCo=EmpMaxHr.PRCo   
 and e.Employee=EmpMaxHr.Employee   
 and e.Craft=EmpMaxHr.Craft        
 and e.EEOClass=EmpMaxHr.EEOClass   
 and e.SumRecap=EmpMaxHr.SumRecap   
 and e.MaxHours=EmpMaxHr.MaxHours   
 and e.CountRec='Y'        
               
--select * from #Emps
  
/****************************/ 
/* FORTH PASS */       
/*  insert Summary Recap */        
/***************************/        
/*Also added max Job to Sum Recap type records. 5/8/03 NF ****/        
/*Also added max JCCo to Sum Recap type records. 9/11/06 NF ****/        
  
insert into #Emps        
(  
 RecordType  
 , SumRecap  
 , PRCo  
 , PRGroup  
 , PREndDate  
 , JCCo  
 , Job  
 , Employee  
 , CertYN  
 , EEOClass  
 , Race  
 , Sex  
 , Hours,MostHours  
)        
select   
 'S'  
 , e.SumRecap  
 , e.PRCo  
 , e.PRGroup  
 , e.PREndDate  
 , max(e.JCCo)  
 , max(e.Job)  
 , e.Employee  
 , e.CertYN  
 , e.EEOClass  
 , e.Race  
 , e.Sex  
 , sum(e.Hours)  
 , e.MostHours   
from   
 #Emps e         
group by    
 e.SumRecap  
 , e.PRCo  
 , e.PRGroup  
 , e.PREndDate  
 , e.Employee  
 , e.CertYN  
 , e.EEOClass  
 , e.Race  
 , e.Sex  
 , e.MostHours        
  
/****************************/  
/* FIFTH PASS */      
/*  insert Company Recap */        
/***************************/        
insert into #Emps        
(  
 RecordType  
 , SumRecap  
 , PRCo  
 , PRGroup  
 , PREndDate  
 , JCCo, Employee  
 , CertYN  
 , EEOClass  
 , Race  
 , Sex  
 , Hours  
 , MostHours  
)        
select    
 'C'  
 , 'zzzzzzzzzz '  
 , e.PRCo  
 , e.PRGroup  
 , e.PREndDate  
 , e.JCCo  
 , e.Employee  
 , e.CertYN  
 , e.EEOClass  
 , e.Race  
 , e.Sex  
 , sum(e.Hours)  
 , e.MostHours  
from     
 #Emps e         
where   
 RecordType='S'        
group by     
 e.PRCo  
 , e.PRGroup  
 , e.PREndDate  
 , e.JCCo  
 , e.Employee  
 , e.CertYN  
 , e.EEOClass  
 , e.Race  
 , e.Sex,e.MostHours        
  
/* FINAL PASS */
/*Results*/   
       
select        
 a.RecordType  
 , a.SumRecap  
 , a.PRCo  
 , CoName=HQCO.Name  
 , a.PRGroup  
 , WeekBegin=PRPC.BeginDate  
 , a.PREndDate  
 , a.EEORegion  
 , a.SMSACode  
 , a.JCCo  
 , a.Job  
 , JobDesc=JCJM.Description  
 , a.Employee  
 , a.CertYN  
 , a.Craft  
 , PRCM.Description  
 , a.EEOClass  
 , a.Race  
 , RaceDesc=PRRC.Description  
 , RaceEEOCat=PRRC.EEOCat  
 , a.Sex  
 , a.Hours  
 , a.MostHours  
 , HQSM.Description as SMSADesc /* DML ADD CL-132461*/  
 , BeginPRDate=@BeginPRDate  
 , EndPRDate=@EndPRDate  
 , BeginJCCo=@BeginJCCo  
 , EndJCCo=@EndJCCo  
 , BeginJob=@BeginJob  
 , EndJob=@EndJob  
 , RptType=@RptType        
from   
 #Emps a with(nolock)        
Left Join   
 JCJM with(nolock) on   
  JCJM.JCCo=a.JCCo   
  and JCJM.Job=a.Job         
Left Join   
 PRPC with(nolock) on   
  PRPC.PRCo=a.PRCo   
  and PRPC.PRGroup=a.PRGroup   
  and PRPC.PREndDate=a.PREndDate        
Left Join   
 PRCM with(nolock) on   
  PRCM.PRCo=a.PRCo   
  and PRCM.Craft=a.Craft        
Join   
 HQCO with(nolock) on   
  HQCO.HQCo=a.PRCo       
Left Outer Join   
 HQSM with (nolock) on   
  JCJM.SMSACode=HQSM.SMSACode /*DML ADD*/        
Left Join   
 PRRC with(nolock) on   
  PRRC.PRCo=a.PRCo   
  and PRRC.Race=a.Race        
order by   
 a.PRCo  
 , a.PRGroup  
 , a.SumRecap        
/*end */ 
GO
GRANT EXECUTE ON  [dbo].[brptEEODOL] TO [public]
GO
