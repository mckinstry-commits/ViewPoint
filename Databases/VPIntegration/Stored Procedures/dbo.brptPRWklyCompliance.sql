SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[brptPRWklyCompliance]       
(@PRCo tinyint, @PRGroup tinyint, @PREndDate smalldatetime,  @TotalMasterOrFullJob char(1),      
   @SignifJobChar tinyint, @JobCert char(2), @FirstDayOfWeek smalldatetime='1/1/1950', @LastDayOfWeek smalldatetime='12/31/2050', @PrintLiab char(1),       
   @BegJCCo tinyint, @BegJob varchar(10), @EndJCCo tinyint, @EndJob varchar(30), @PRDateHrsYN char(2), @SortOrder char (1))      
--      
--The following declarations are left in the for Debug purpose.  To use this code un-comment      
--the parameters between the @ signs and comment out the production parameters above.      
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         
--(      
--  @PRCo tinyint = 1      
--, @PRGroup tinyint = 1      
--, @PREndDate smalldatetime ='07/06/08'      
--, @TotalMasterOrFullJob char(1) ='F'      
--, @SignifJobChar tinyint = 6      
--, @JobCert char(2) ='N'      
--, @FirstDayOfWeek smalldatetime='07/01/08'      
--, @LastDayOfWeek smalldatetime='07/06/08'      
--, @PrintLiab char(1)= 'Y'      
--, @BegJCCo tinyint = 0      
--, @BegJob varchar(10) = ' '      
--, @EndJCCo tinyint =255      
--, @EndJob varchar(30) ='zzzzzzzzzz'      
--, @PRDateHrsYN char(2) ='Y'      
--, @SortOrder char (1) ='S'      
--)      
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
         
   as      
         
/* mod 4/9/2001 DH.  Added Craft Description and modified deduction while loop to fix issue where deductions       
were not updated to more than one job in more than one JCCo */
/* mod 5/8/2001 DH Added PRDateHrsYN parameter - If Yes, then show only hours posted to selected PR End Date.  Used when running a Revised      
PR Certified to print hours posted in a week prior to the PREndDate */      
/* Issue 26621 changed @FedTaxDedn to a smallint E.T. 12/22/04 */      
/* Issue 23388 Added new statement to select distinct employee, jobs with earnings DH 3/30/2005 */
/* Issue 27052 Add Weekly Reg and OT Hours  DH 3/30/2005 */
/* Issue 29195 Changed insert statement to use @SignifJobChar - was hardcoded to use 6 chars 6/30/2005 */
/* Issue 30213 Added order by statement to Liability cursor JH 10/1/2005 */
/* Issue 129794 Changed stored procedure to return date at the liability Rate. It previously only returned data to the Liability Code level CWW 11/19/2009 */      
/* Mod 12/18/2009 CW Issue 135202 add sort parameter to return data by employee's number or name */      
/* Modified 10/31/2010 CW Issue 140541 Changed linkage of view PRDB from to support new columns EDLCode and EDLType. */
/* Modified 1/10/2012 Czeslaw Issue 137046 Changed final select statement to permit accurate reporting of Craft and Class
for both Employee and payroll detail lines */
/* Modified 4/17/2012 Czeslaw (for DML) Issue 135130 In final select statement added ISNULL function to selected column ci.EarnCode,
allowing reliable conditional suppression of earnings amount fields in Crystal file when database values are NULL; 
accommodates customer use of EarnCode '0' */

   declare @Employee int, @SaveEmp int, @FedTaxDedn smallint, @EDLCode int, @EarnCode int, @Rate numeric (10,4), @Amount numeric (12,2),      
   @GrossEarn numeric (12,2), @Desc varchar(60), @DetOnCert char(2), @DLTotalLine char(2), @JCCo tinyint, @Job varchar (10), @NextJCCo tinyint, @Taxable char(2),      
   @NextJob varchar (10), @RecId int, @MaxRecId int, @openPRDedn tinyint, @openPREarn tinyint, @openJobEarnTotal tinyint, @openJobLiabTotal tinyint, @openPaySeq tinyint,      
   @PaySeq tinyint, @CMRef varchar(10), @CompanyDesc varchar(60), @Craft varchar (10), @Class varchar (10), @openPRLiab tinyint, @LiabTotalLine char(1), @LiabCode int,      
   @EarnTotalLine tinyint      
         
   Set NoCount On      
         
   select @CompanyDesc=Name From HQCO Where HQCo=@PRCo      
        
  /*If user inputs blank First and End dates of week, then select the first and last day of the PREndDate.  If Invalid PR EndDate, then      
  select 12/31/2050 as the first day so that report does not select any data*/      
         
   if @FirstDayOfWeek='1/1/1950'      
       begin      
    select @FirstDayOfWeek = BeginDate From PRPC Where PRCo=@PRCo and PRGroup=(case when @PRGroup<>0 then @PRGroup else PRGroup end) and PREndDate=@PREndDate       
    if @@rowcount=0 select @FirstDayOfWeek = '12/31/2050'      
       end      
         
   if @LastDayOfWeek='12/31/2050'       
       select @LastDayOfWeek=@PREndDate      
         
         
   select @SignifJobChar=(case when @TotalMasterOrFullJob='M' then @SignifJobChar else 10 end)      
         
   create table #CertInformation      
    (JCCo tinyint NULL,      
     Job varchar(10) NULL,      
     JobTotalSort tinyint NULL,      
     Employee int NULL,      
    Craft varchar (10) NULL,      
    Class varchar (10) NULL,      
    RecId int IDENTITY(1,1) Not NULL,      
    PREndDate smalldatetime NULL,      
     CheckNumbers varchar (255) NULL,      
     DetOnCert char(2) NULL,      
    EarnTotalLine tinyint NULL,      
     DedTotalLine char(2) NULL,      
     LiabTotalLine char(2) NULL,      
           WklyHoursLine char(2) NULL,      
     DedCode int NULL,      
     DedDesc varchar(30) NULL,      
     DedAmt numeric(12,2) NULL,      
     GrossEarn numeric (12,2) NULL,      
           WklyRegHrs numeric (12,2) NULL,      
    WklyOTHrs numeric (12,2) NULL,      
     EarnCode int NULL,      
     EarnDesc varchar(30) NULL,      
     EarnRate numeric (10,4) NULL,      
     EarnAmt numeric (12,2) NULL,      
     Taxable char(1) NULL,      
     LiabCode int NULL,      
     LiabDesc varchar (30) NULL,      
     LiabRate numeric (10,4) NULL,      
     LiabAmt numeric(12,2) NULL)      
         
   create clustered index biCertInformationClust on #CertInformation(JCCo, Job, Employee, EarnCode)      
   create nonclustered index biCertInformationJob on #CertInformation (JCCo, Job, Employee, EarnCode)      
   create nonclustered index biCertInformationRecId on #CertInformation (RecId)      
   --create nonclustered index biCertInformationEmployee on #CertInformation (Employee)      
   --create nonclustered index biCertInformationEarnCode on #CertInformation (EarnCode)      
   --create nonclustered index biCertInformationDedCode on #CertInformation (DedCode)      
   --create nonclustered index biCertInformationLiabCode on #CertInformation (LiabCode)      
         
   create table #EarnTemp      
    (JCCo tinyint NULL,      
     Job varchar(10) NULL,      
     Employee int NULL,      
    Craft varchar (10) NULL,      
    Class varchar (10) NULL,      
    PREndDate smalldatetime NULL,      
     EarnCode int NULL,      
     EarnDesc varchar (30) NULL,      
     DetOnCert char(2) NULL,      
     Taxable char(2) NULL,      
    TotalLine tinyint NULL,      
     PRDept varchar(10) NULL,      
     JCDept varchar(10) NULL,      
        
     Crew varchar(10) NULL,      
     PaySeq tinyint NULL,      
     PostSeq int NULL,      
     WkDay tinyint NULL,      
     Hours numeric(10,2) NULL,      
     EarnRate numeric (10,4) NULL,      
     EarnAmt numeric (12,2) NULL)      
           
   --create clustered index biEarnTemp on #EarnTemp (DetOnCert)      
   create nonclustered index biEarnTempCode on #EarnTemp (EarnCode)      
         
   create table #LiabTemp      
   (JCCo tinyint NULL,      
    Job varchar (10) NULL,      
    Employee int NULL,      
    Taxable char(2) NULL,      
    LiabTotalLine char(2) NULL,      
    LiabCode int NULL,      
    LiabDesc varchar (30) NULL,      
    DetOnCert char(2) NULL,      
    LiabRate numeric (10,4) NULL,      
    LiabAmt numeric (12,2) NULL)      
          
        
   create table #EmployeeJobs      
   (JCCo tinyint NULL,      
    Job varchar (10) NULL,      
    Employee int NULL,      
      /*PRGroup tinyint Null,*/      
    GrossEarn numeric (12,2) NULL)      
        
         
   create table #JobTotals      
    (JCCo tinyint NULL,      
     Job varchar(10) NULL,      
     JobEarnTotal numeric(12,2) NULL,      
     JobGrossTotal numeric(12,2) NULL,      
     JobDedTotal numeric(12,2) NULL,      
     JobLiabTotal numeric(12,2) NULL)      
         
  create table #JobsForCert      
   (JCCo tinyint NULL,      
    Job varchar(10) NULL,      
    Contract varchar(10) NULL)      
        
  create clustered index biJobsCert on #JobsForCert (JCCo, Job)       
         
   insert into #EmployeeJobs      
   /*select distinct JCCo, Substring(Job,1,@SignifJobChar), Employee, 0 From      
   PRTH  Where PRCo=@PRCo and PRGroup=@PRGroup and PostDate>=@FirstDayOfWeek and PostDate<=@LastDayOfWeek and      
    Cert='Y' and Amt<>0 and PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else PREndDate end) */      
        
  /* Issue 23388 DH - Select a list of distinct Employees and jobs for the report.        
    Only employees that have true earnings (regular or addons) or non-true earnings flagged to print on report */      
   select distinct JCCo, Substring(Job,1,@SignifJobChar), PRTH.Employee, 0 From      
   PRTH with(nolock)        
   Join PREC e on e.PRCo=PRTH.PRCo and e.EarnCode=PRTH.EarnCode      
   Left Join (Select distinct PRTA.PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, AddonCert='Y' From PRTA      
               Join PREC on PREC.PRCo=PRTA.PRCo and PREC.EarnCode=PRTA.EarnCode      
               Where PRTA.PRCo=@PRCo and PRTA.PRGroup=(case when @PRGroup<>0 then @PRGroup else PRTA.PRGroup end) and PREndDate = @PREndDate and       
                     ((PREC.TrueEarns='Y' and PRTA.Amt<>0) or (PREC.TrueEarns='N' and PREC.CertRpt='Y' and PRTA.Amt>0))) as a      
        on a.PRCo=PRTH.PRCo and a.PRGroup=PRTH.PRGroup and a.PREndDate=PRTH.PREndDate and a.Employee=PRTH.Employee and a.PaySeq=PRTH.PaySeq and a.PostSeq=PRTH.PostSeq      
        
   Where PRTH.PRCo=@PRCo and PRTH.PRGroup=(case when @PRGroup<>0 then @PRGroup else PRTH.PRGroup end) and PRTH.PostDate>=@FirstDayOfWeek and PRTH.PostDate<=@LastDayOfWeek and      
    PRTH.Cert='Y' and PRTH.PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else PRTH.PREndDate end) and      
        ((e.TrueEarns='Y' and PRTH.Amt<>0) or (e.TrueEarns='N' and e.CertRpt='Y' and  PRTH.Amt>0) or a.AddonCert='Y')       
        
  insert into #CertInformation      
  (JCCo, Job, JobTotalSort, Employee, PREndDate, DedCode, DetOnCert,  DedDesc, DedAmt, GrossEarn)      
  select e.JCCo, e.Job, 0, e.Employee, d.PREndDate, d.EDLCode,      
   DetOnCert=(case when d.EDLType='D' then dl.DetOnCert else ec.CertRpt end),      
   Description=(case when d.EDLType='D' then dl.Description else ec.Description end),       
   Amount=sum(case when d.EDLType='D' and d.UseOver='N' then d.Amount when d.EDLType='E' then abs(d.Amount) when d.UseOver='Y' then d.OverAmt end)      
   ,0 From PRDT d      
   Join #EmployeeJobs e on e.Employee=d.Employee       
   Left Outer Join PRDL dl on dl.PRCo=d.PRCo and dl.DLCode=d.EDLCode      
   Left Outer Join PREC ec on ec.PRCo=d.PRCo and ec.EarnCode=d.EDLCode      
   Where d.PRCo=@PRCo and d.PRGroup=(case when @PRGroup<>0 then @PRGroup else d.PRGroup end) and PREndDate=@PREndDate      
   and ((TrueEarns='N' and EDLType='E' and CertRpt='Y' and d.Amount<0) or (EDLType='D' and DetOnCert='Y'))      
        
   Group By e.JCCo, e.Job, e.Employee, d.PREndDate, EDLCode, d.EDLType, dl.DetOnCert, dl.Description, ec.Description, ec.CertRpt      
         
   --insert one line for deductions (and neg non-true earnings) that do not print detail on certified      
   insert into #CertInformation      
   (JCCo, Job, JobTotalSort, Employee, PREndDate, DedCode, DetOnCert,  DedDesc, DedAmt, GrossEarn)      
   select e.JCCo, e.Job, 0, e.Employee, d.PREndDate, 999999, 'N', 'Other',       
   Amount=sum(case when d.EDLType='D' and d.UseOver='N' then d.Amount when d.EDLType='E' then abs(d.Amount) when d.UseOver='Y' then d.OverAmt end)      
   , 0 From PRDT d      
   Join #EmployeeJobs e on e.Employee=d.Employee       
   Left Outer Join PRDL dl on dl.PRCo=d.PRCo and dl.DLCode=d.EDLCode      
   Left Outer Join PREC ec on ec.PRCo=d.PRCo and ec.EarnCode=d.EDLCode      
   Where d.PRCo=@PRCo and d.PRGroup=(case when @PRGroup<>0 then @PRGroup else d.PRGroup end) and PREndDate=@PREndDate      
   and ((TrueEarns='N' and EDLType='E' and CertRpt='N' and d.Amount<0) or (EDLType='D' and DetOnCert='N'))      
   Group By e.JCCo, e.Job, e.Employee, d.PREndDate      
         
   --insert total line for deductions, Gross Earnings      
   insert into #CertInformation      
   (JCCo, Job, JobTotalSort, Employee, PREndDate, DedCode, DetOnCert,  DedDesc, DedAmt, GrossEarn)      
   select e.JCCo, e.Job, 0, e.Employee, d.PREndDate, 999999, 'A', 'Total',       
          DedAmt=sum(case when d.EDLType='D' and d.UseOver='N' then d.Amount       
                          when d.EDLType='E' and TrueEarns='N' and d.Amount<0 then abs(d.Amount)      
                          when d.UseOver='Y' then d.OverAmt end),       
          GrossEarn=sum(case when ec.TrueEarns='Y' then d.Amount      
                             when ec.TrueEarns='N' and d.Amount>0 then d.Amount end)      
   From PRDT d      
   Join #EmployeeJobs e on e.Employee=d.Employee       
   Left Outer Join PRDL dl on dl.PRCo=d.PRCo and dl.DLCode=d.EDLCode      
   Left Outer Join PREC ec on ec.PRCo=d.PRCo and ec.EarnCode=d.EDLCode and d.EDLType='E'      
   Where d.PRCo=@PRCo and d.PRGroup=(case when @PRGroup<>0 then @PRGroup else d.PRGroup end) and PREndDate=@PREndDate and      
         d.EDLType<>'L'      
   --and ((TrueEarns='N' and EDLType='E' and d.Amount<0) or (EDLType='D'))      
   Group By e.JCCo, e.Job, e.Employee, d.PREndDate      
        
    --insert total line for gross earnings      
   /*insert into #EmployeeJobs      
   (JCCo, Job, d.Employee, GrossEarn)      
   select e.JCCo, e.Job, e.Employee, sum(case when d.UseOver='N' then d.Amount else d.OverAmt end)      
   From PRDT d      
   Join #EmployeeJobs e on e.Employee=d.Employee      
   Join PREC ec on ec.PRCo=d.PRCo and ec.EarnCode=d.EDLCode and d.EDLType='E'      
   Where d.PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate       
   and (ec.TrueEarns='Y' or (ec.TrueEarns='N' and ec.CertRpt='Y' and d.Amount>0))      
   Group By e.JCCo, e.Job, e.Employee*/      
        
  --insert line for total hours      
  insert into #CertInformation      
   (JCCo, Job, JobTotalSort, d.Employee, PREndDate, DedCode, WklyHoursLine, WklyRegHrs, WklyOTHrs)      
   select e.JCCo, e.Job, 0, e.Employee, d.PREndDate, 999999, 'Y', sum(case when ec.Factor=1 then d.Hours else 0 end), sum(case when ec.Factor>1 then d.Hours else 0 end)      
   From PRDT d      
   Join #EmployeeJobs e on e.Employee=d.Employee       
   Join PREC ec on ec.PRCo=d.PRCo and ec.EarnCode=d.EDLCode and d.EDLType='E'      
   Where d.PRCo=@PRCo and d.PRGroup=(case when @PRGroup<>0 then @PRGroup else d.PRGroup end) and PREndDate=@PREndDate       
   Group By e.JCCo, e.Job, e.Employee, d.PREndDate      
         
   --update gross earnings on last deduction record for the last employee       
         
   /*Update #CertInformation Set GrossEarn=e.GrossEarn      
   From #CertInformation, #EmployeeJobs e      
   Where #CertInformation.Employee=e.Employee and e.GrossEarn<>0 and #CertInformation.DetOnCert='A'*/      
        
         
   /*Next several insert statements populate the EarnTemp table, which is used later in procedure to update the       
   main #CertInformation table*/      
         
   --gather timecard detail for true earnings or positive non-true earnings between the begin and ending dates inputted for the report      
         
   insert into #EarnTemp      
   (JCCo, Job, Employee, EarnCode, EarnDesc, DetOnCert, Craft, Class, Taxable, EarnRate, PaySeq, PostSeq, WkDay, PRDept, JCDept, Crew, Hours, EarnAmt)      
   select h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, h.EarnCode, e.Description, e.CertRpt, h.Craft, h.Class, 'N', h.Rate, PaySeq, PostSeq, datepart(dw, h.PostDate), PRDept, JCDept, Crew, h.Hours, h.Amt      
   From PRTH h      
   Join PREC e on e.PRCo=h.PRCo and e.EarnCode=h.EarnCode      
    Where h.PRCo=@PRCo and h.PRGroup=(case when @PRGroup<>0 then @PRGroup else h.PRGroup end) and h.PostDate>=@FirstDayOfWeek and h.PostDate<=@LastDayOfWeek and      
    h.Cert='Y' and h.PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else h.PREndDate end) and       
   ((e.TrueEarns='Y' and h.Amt<>0) or (e.TrueEarns='N' and e.CertRpt='Y' and  h.Amt>0))       
         
         
   --gather addon earnings for true earnings or positive non-true earnings between the begin and ending dates inputted for the report      
   insert into #EarnTemp      
   (JCCo, Job, Employee, EarnCode, EarnDesc, DetOnCert, Craft, Class, Taxable, EarnRate, PaySeq, PostSeq, WkDay, PRDept, JCDept, Crew, Hours, EarnAmt)      
   select h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, a.EarnCode, e.Description, e.CertRpt, h.Craft, h.Class, 'N', a.Rate, h.PaySeq, h.PostSeq, datepart(dw, h.PostDate),PRDept, JCDept, Crew, 0,(a.Amt)      
   From PRTH h      
   Join PRTA a on a.PRCo=h.PRCo and a.PRGroup=h.PRGroup and a.PREndDate=h.PREndDate and a.Employee=h.Employee and a.PaySeq=h.PaySeq and a.PostSeq=h.PostSeq      
   Join PREC e on e.PRCo=a.PRCo and e.EarnCode=a.EarnCode      
Where h.PRCo=@PRCo and h.PRGroup=(case when @PRGroup<>0 then @PRGroup else h.PRGroup end) and h.PostDate>=@FirstDayOfWeek and h.PostDate<=@LastDayOfWeek and      
    h.Cert='Y' and h.PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else h.PREndDate end) and       
   ((e.TrueEarns='Y' and h.Amt<>0) or (e.TrueEarns='N' and e.CertRpt='Y' and a.Amt>0))      
         
   --get the federal tax deduction code for the payroll company      
   select @FedTaxDedn=TaxDedn From PRFI Where PRCo=@PRCo      
         
   --update all earnings to taxable that are subject to the fed tax deduction
   UPDATE #EarnTemp 
   SET Taxable='Y' 
   FROM #EarnTemp e 
		JOIN dbo.PRDB d ON d.PRCo=@PRCo 
					   AND e.EarnCode=d.EDLCode 
					   AND d.EDLType = 'E' 
					   AND d.DLCode=@FedTaxDedn

   
         
   --insert Other Taxable earnings, insert a unique rate because we join #EarnTemp back to CertInfo table      
   insert into #EarnTemp      
   (JCCo, Job, Employee, EarnCode, DetOnCert, EarnDesc, TotalLine, EarnAmt)      
   select JCCo, Job, Employee, 999999,'Z', 'Other Taxable', 1, sum(case when DetOnCert='N' and Taxable='Y' then EarnAmt else 0 end)      
   From #EarnTemp       
   Group By JCCo, Job, Employee      
         
   --insert Non Taxable earnings       
   insert into #EarnTemp      
   (JCCo, Job, Employee, EarnCode, DetOnCert, EarnDesc, TotalLine, EarnAmt)      
   select JCCo, Job, Employee, 999999, 'Z', 'Other Non Taxable', 2, sum(case when DetOnCert='N' and Taxable='N' then EarnAmt else 0 end)      
   From #EarnTemp       
   Group By JCCo, Job, Employee      
         
   --insert one project total line for employee      
   insert into #EarnTemp      
   (JCCo, Job, Employee, EarnCode, DetOnCert, EarnDesc, TotalLine, EarnAmt)      
   select JCCo, Job, Employee, 999999,'Z', 'Project Total', 3, sum(EarnAmt)      
   From #EarnTemp       
   Where DetOnCert <>'Z'      
   Group By JCCo, Job, Employee      
         
         
         
         
   /*Loop through EarnTemp table for each Job, Employee, EarnCode and rate      
    Update #CertInformation where earn codes do not exist and liability record exists      
   else insert new earnings line.  This part of the procedure updates the #CertInformation       
   table so that earnings and liabilties print on the same line.  Restricts only earnings that       
   are setup to print detail on certified or one line each for Other Taxable, Other Non-Taxable,       
   and Project Total - signigied by DetOnCert flag=Z*/      
         
   declare bcPREarn cursor for      
   select JCCo, Job, Employee, Craft, Class, EarnCode, Taxable, TotalLine, EarnDesc, DetOnCert, EarnRate, sum(EarnAmt)      
   From #EarnTemp      
   Where DetOnCert='Y' or DetOnCert='Z'      
   Group By JCCo, Job, Employee, Craft, Class, EarnCode, Taxable, TotalLine, EarnDesc, DetOnCert, EarnRate      
   order by JCCo, Job, Employee, EarnCode, EarnRate, TotalLine      
         
         
   open bcPREarn      
   select @openPREarn=1      
         
   Next_Earn:      
         
   fetch next from bcPREarn into      
   @JCCo, @Job, @Employee, @Craft, @Class, @EarnCode, @Taxable, @EarnTotalLine, @Desc, @DetOnCert, @Rate, @Amount      
         
    if @@fetch_status=-1 goto End_Earn      
    if @@fetch_status<>0 goto Next_Earn      
         
   select @RecId=min(RecId) From #CertInformation      
   Where JCCo=@JCCo and Job=@Job and Employee=@Employee and EarnCode Is Null      
   --and @DetOnCert<>'N'       
   --and DetOnCert='Y'      
      
   if @RecId Is Not Null      
    update #CertInformation      
    set EarnCode=@EarnCode, EarnDesc=@Desc, EarnRate=@Rate, EarnAmt=@Amount, Craft=@Craft, Class=@Class, EarnTotalLine=@EarnTotalLine      
    where RecId=@RecId       
   else      
    insert into #CertInformation      
    (JCCo, Job, Employee, Craft, Class, EarnCode, EarnDesc, DetOnCert, Taxable, EarnTotalLine, EarnRate, EarnAmt)      
    Values (@JCCo, @Job, @Employee, @Craft, @Class, @EarnCode, @Desc, @DetOnCert, @Taxable, @EarnTotalLine, @Rate, @Amount)      
         
         
   goto Next_Earn      
         
   End_Earn:      
   close bcPREarn      
   deallocate bcPREarn      
   select @openPREarn=0      
         
         
   /*Populate #CertInformation report for job totals of deductions, liabilities, and earnings*/      
         
  --insert liabilities to print detail on report      
            
    insert into #LiabTemp      
    (JCCo, Job, Employee, Taxable, LiabCode, LiabDesc, DetOnCert, LiabRate , LiabAmt)      
          
    select h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, 'N', l.LiabCode, d.Description, d.DetOnCert, l.Rate, sum(l.Amt) --Issue 129794      
    From PRTH h      
    Join PRTL l on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and      
    h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq      
    Join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode      
       Where h.PRCo=@PRCo and h.PRGroup=(case when @PRGroup<>0 then @PRGroup else h.PRGroup end)      
          and h.PostDate>=@FirstDayOfWeek and h.PostDate<=@LastDayOfWeek and @PrintLiab='Y' and      
     h.Cert='Y' and d.DetOnCert='Y' and h.PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else h.PREndDate end)      
    Group By h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, l.LiabCode,  l.Rate, d.Description, d.DetOnCert    --Issue 129794      
          
          
    --insert Other liabilities, one line for total liabilties that do not print detail on report      
          
    insert into #LiabTemp      
    (JCCo, Job, Employee, Taxable, LiabCode, LiabDesc, DetOnCert, LiabRate , LiabAmt)      
    select h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, 'N', 999999, 'Other', d.DetOnCert, 0, sum(l.Amt)      
    From PRTH h      
    Join PRTL l on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and      
    h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq      
    Join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode      
       Where h.PRCo=@PRCo and h.PRGroup=(case when @PRGroup<>0 then @PRGroup else h.PRGroup end)       
               and h.PostDate>=@FirstDayOfWeek and h.PostDate<=@LastDayOfWeek and @PrintLiab='Y' and      
     h.Cert='Y' and d.DetOnCert='N' and h.PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else h.PREndDate end)      
    Group By h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, d.DetOnCert      
          
          
    --insert Liab Total Line      
    insert into #LiabTemp      
    (JCCo, Job, Employee, Taxable, LiabTotalLine, LiabCode, LiabDesc, LiabRate , LiabAmt)      
    select h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee, 'N', 'Y', 999999, 'Total', 0, sum(l.Amt)      
    From PRTH h      
    Join PRTL l on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and      
    h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq      
    Join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode      
          
     Where h.PRCo=@PRCo and h.PRGroup=(case when @PRGroup<>0 then @PRGroup else h.PRGroup end) and h.PostDate>=@FirstDayOfWeek and h.PostDate<=@LastDayOfWeek and @PrintLiab='Y' and      
     h.Cert='Y' and h.PREndDate = (case when @PRDateHrsYN='Y' then @PREndDate else h.PREndDate end)      
    Group By h.JCCo, Substring(h.Job,1,@SignifJobChar), h.Employee      
        
   declare bcPRLiab cursor for       
   select l.JCCo, l.Job, l.Employee, Taxable, LiabTotalLine, LiabCode, LiabDesc, DetOnCert, LiabRate, LiabAmt      
   From #LiabTemp l      
   Join #EmployeeJobs e on e.Employee=l.Employee and e.JCCo=l.JCCo and e.Job=l.Job       
   order by l.JCCo, l.Job, l.Employee, l.LiabCode, l.LiabRate, l.LiabTotalLine -->Issue 30213      
        
   open bcPRLiab      
   select @openPRLiab=1      
         
   Next_Liab:      
         
   fetch next from bcPRLiab into      
   @JCCo, @Job, @Employee, @Taxable, @LiabTotalLine, @LiabCode, @Desc, @DetOnCert, @Rate, @Amount      
        
    if @@fetch_status=-1 goto End_Liab      
    if @@fetch_status<>0 goto Next_Liab      
         
   select @RecId=min(RecId) From #CertInformation      
   Where JCCo=@JCCo and Job=@Job and Employee=@Employee and LiabCode Is Null      
         
   if @RecId is not null      
    update #CertInformation Set LiabCode=@LiabCode, LiabDesc=@Desc, LiabTotalLine=@LiabTotalLine, LiabRate=@Rate,      
   LiabAmt=@Amount where RecId=@RecId      
   else      
   insert into #CertInformation (JCCo, Job, Employee, LiabCode, LiabDesc, Taxable, LiabTotalLine, DetOnCert, LiabRate, LiabAmt)      
   values (@JCCo, @Job, @Employee, @LiabCode, @Desc, @Taxable, @LiabTotalLine, @DetOnCert, @Rate, @Amount)      
        
  goto Next_Liab      
        
  End_Liab:      
         
  close bcPRLiab      
   deallocate bcPRLiab      
   select @openPRLiab=0      
        
        
   insert into #CertInformation      
   (JCCo, Job, JobTotalSort, DetOnCert, DedCode, DedDesc, WklyHoursLine, DedAmt, GrossEarn, WklyRegHrs, WklyOTHrs)      
   select JCCo, Job, 1, DetOnCert, DedCode, DedDesc, WklyHoursLine, sum(DedAmt), sum(GrossEarn), sum(WklyRegHrs), sum(WklyOTHrs)      
   From #CertInformation Where DedCode Is Not Null      
   Group By JCCo, Job, DetOnCert, DedCode, DedDesc, WklyHoursLine      
   order by JCCo, Job, DetOnCert desc, DedCode, WklyHoursLine      
         
 declare bcJobLiabTotal cursor for select      
    JCCo, Job, LiabCode, LiabDesc, sum(LiabAmt) From #CertInformation      
    Where LiabCode Is Not Null      
    Group By JCCo, Job, LiabCode, LiabTotalLine, LiabDesc      
    order by JCCo, Job, LiabCode, LiabTotalLine      
          
          
    open bcJobLiabTotal      
    select @openJobLiabTotal=1      
          
    Next_JobLiabTotal:      
          
    fetch next from bcJobLiabTotal into @JCCo, @Job, @EDLCode, @Desc, @Amount      
          
     if @@fetch_status=-1 goto End_JobLiabTotal      
     if @@fetch_status<>0 goto Next_JobLiabTotal      
          
    select @RecId=min(RecId) From #CertInformation      
    Where JCCo=@JCCo and Job=@Job and JobTotalSort=1 and LiabCode Is Null      
          
     if @RecId Is Not Null      
      update #CertInformation      
      set LiabCode=@EDLCode, LiabDesc=@Desc, LiabAmt=@Amount, LiabRate=0      
      Where RecId=@RecId      
     else      
      insert into #CertInformation      
      (JCCo, Job, JobTotalSort, LiabCode, LiabDesc, LiabRate, LiabAmt)      
      Values (@JCCo, @Job, 1, @EDLCode, @Desc, 0, @Amount)      
          
    goto Next_JobLiabTotal      
          
    End_JobLiabTotal:      
    close bcJobLiabTotal      
    deallocate bcJobLiabTotal      
    select @openJobLiabTotal=0      
        
   declare bcJobEarnTotal cursor for select      
   JCCo, Job, EarnCode, EarnDesc, sum(EarnAmt) From #CertInformation      
   Where EarnCode Is Not Null      
   Group By JCCo, Job, EarnCode, EarnTotalLine, EarnDesc      
   Order by JCCo, Job, EarnCode, EarnTotalLine      
         
   open bcJobEarnTotal      
   select @openJobEarnTotal=1      
         
   Next_JobEarnTotal:      
         
   fetch next from bcJobEarnTotal into @JCCo, @Job, @EDLCode, @Desc, @Amount      
         
    if @@fetch_status=-1 goto End_JobEarnTotal      
    if @@fetch_status<>0 goto Next_JobEarnTotal      
         
         
   select @RecId=min(RecId) From #CertInformation       
   Where JCCo=@JCCo and Job=@Job and JobTotalSort=1 and EarnCode Is Null      
         
    if @RecId Is Not Null      
     update #CertInformation       
     set EarnCode=@EDLCode, EarnDesc=@Desc, EarnAmt=@Amount, EarnRate=0      
     Where RecId=@RecId      
    else      
     insert into #CertInformation      
     (JCCo, Job, JobTotalSort, EarnCode, EarnDesc, EarnRate, EarnAmt)      
     Values (@JCCo, @Job, 1, @EDLCode, @Desc, 0, @Amount)      
         
   goto Next_JobEarnTotal      
         
   End_JobEarnTotal:      
   close bcJobEarnTotal      
   deallocate bcJobEarnTotal      
   select @openJobEarnTotal=0      
         
   --insert weekday hours for each job      
   insert into #EarnTemp      
   (JCCo, Job, EarnCode, WkDay, EarnRate, Hours, EarnAmt)      
   select JCCo, Job, EarnCode, WkDay,0, sum(Hours), sum(EarnAmt)       
   From #EarnTemp Group By JCCo, Job, EarnCode, WkDay      
         
   --Update Check Numbers field      
   declare bcPaySeq cursor for select      
   Employee, PaySeq, CMRef From PRSQ      
   Where PRCo=@PRCo and PRGroup=(case when @PRGroup<>0 then @PRGroup else PRGroup end) and PREndDate=@PREndDate      
         
   open bcPaySeq      
   select @openPaySeq=1      
         
   Next_PaySeq:      
         
   fetch next from bcPaySeq into @Employee, @PaySeq, @CMRef      
         
    if @@fetch_status=-1 goto End_PaySeq      
    if @@fetch_status<>0 goto Next_PaySeq      
         
    Update #CertInformation Set CheckNumbers=isnull(CheckNumbers,'')+'  '+isnull(ltrim(@CMRef),'')      
    Where Employee=@Employee      
         
   goto Next_PaySeq      
         
   End_PaySeq:      
   close bcPaySeq      
   deallocate bcPaySeq      
   select @openPaySeq=0      
         
         
   --create clustered index biCertInformationClust on #CertInformation(JCCo, Job, Employee, EarnCode)      
      
      
  insert into #JobsForCert      
  select JCCo, Substring(Job,1,@SignifJobChar), min(Contract)      
  From JCJM       
  Where JCCo>=@BegJCCo and JCCo<=@EndJCCo and Job>=@BegJob and Job<=@EndJob      
  and @JobCert=(case when @JobCert='Y' then JCJM.Certified else @JobCert end)      
  Group by JCCo, Substring(Job,1,@SignifJobChar)       

IF @SortOrder = 'S'
BEGIN      
   select ci.JCCo, ci.Job, JobDesc=(case when j.Job is not null then j.Description else c.Description end), JobTotalSort, JobCert=j.Certified, c.Contract, ContDesc=c.Description,      
   ci.Employee, ci.RecId, LastName, FirstName, MidName,e.Suffix, e.SortName, e.Address, e.City, e.State, e.Zip, e.Address2, SSN, Sex, Race, FileStatus, RegExempts, EmpCraftDesc=cm_emp.Description, EmpClassDesc=cc_emp.Description,
   CraftDesc=cm.Description, ClassDesc=cc.Description, cc_emp.EEOClass, CheckNumbers, th.PaySeq, PostSeq, WkDay, /*ci.EarnCode,*/ EarnCode=ISNULL(ci.EarnCode,888888), ci.DetOnCert,      
   ci.Taxable, ci.EarnDesc, ci.EarnRate, th.Hours, ci.EarnAmt, JCDept, JCDeptDesc=dm.Description, th.PRDept,PRDeptDesc=dp.Description, th.Crew, th.Craft, th.Class, DedCode,       
   DedDesc, DedAmt, GrossEarn, WklyRegHrs, WklyOTHrs, LiabCode, LiabDesc, LiabRate, LiabAmt, WklyHoursLine, DedTotalLine, LiabTotalLine, FirstDayOfWeek=@FirstDayOfWeek, LastDayOfWeek=@LastDayOfWeek, CoNum=@PRCo,      
   CompanyName=@CompanyDesc, WeekNo=datediff(wk, j.CertDate,@PREndDate)+1 /*Number of Weeks between Cert Date and PR EndDate, including current PR End Date.*/      
   ,EmployeeSortField = e.SortName       
--   EmployeeSortField is used to control sorting of the employee and needs to accomodate both employee name(PREH.SortName)       
--   or their number(PRTH.employee).        
      
   From #CertInformation ci       
   Join #JobsForCert on #JobsForCert.JCCo=ci.JCCo and #JobsForCert.Job=ci.Job      
   Left Outer Join JCJM j on j.JCCo=#JobsForCert.JCCo and j.Job=#JobsForCert.Job      
   Left Outer Join JCCM c on c.JCCo=#JobsForCert.JCCo and c.Contract=#JobsForCert.Contract      
   Left Outer Join PREH e on e.PRCo=@PRCo and e.Employee=ci.Employee      
   Left Outer Join PRCC cc on cc.PRCo=@PRCo and cc.Craft=ci.Craft and cc.Class=ci.Class
   Left Outer Join PRCC cc_emp on cc_emp.PRCo=@PRCo and cc_emp.Craft=e.Craft and cc_emp.Class=e.Class
   Left Outer Join PRED ed on ed.PRCo=@PRCo and ed.Employee=e.Employee and ed.DLCode=@FedTaxDedn      
   Left Outer Join #EarnTemp th on th.JCCo=ci.JCCo and th.Job=ci.Job and isnull(th.Employee,0)=isnull(ci.Employee,0) and th.EarnCode=ci.EarnCode and th.EarnRate=ci.EarnRate and isnull(th.Craft,' ')=isnull(ci.Craft,' ') and isnull(th.Class,' ')=isnull(ci.Class,' ')
   --Left Outer Join PRSQ sq on sq.PRCo=@PRCo and sq.PRGroup=@PRGroup and sq.PREndDate=@PREndDate and sq.Employee=th.Employee and sq.PaySeq=th.PaySeq       
   Left Outer Join PRDP dp on dp.PRCo=@PRCo and dp.PRDept=th.PRDept      
   Left Outer Join JCDM dm on dm.JCCo=th.JCCo and dm.Department=th.JCDept      
   --Left Outer Join PRCM cm on cm.PRCo=@PRCo and cm.Craft=th.Craft
   Left Outer Join PRCM cm on cm.PRCo=@PRCo and cm.Craft=ci.Craft
   Left Outer Join PRCM cm_emp on cm_emp.PRCo=@PRCo and cm_emp.Craft=e.Craft
   --Left Outer Join PRCC cc on cc.PRCo=@PRCo and cc.Craft=th.Craft and cc.Class=th.Class      
   Where  ci.JCCo>=@BegJCCo and ci.JCCo<=@EndJCCo       
  --and ci.Job>=Substring(@BegJob,1,@SignifJobChar) and ci.Job<=Substring(@EndJob,1,@SignifJobChar)      
   Order By j.JCCo, j.Job, e.SortName, ci.RecId      
END      
ELSE      
BEGIN      
   select ci.JCCo, ci.Job, JobDesc=(case when j.Job is not null then j.Description else c.Description end), JobTotalSort, JobCert=j.Certified, c.Contract, ContDesc=c.Description,      
   ci.Employee, ci.RecId, LastName, FirstName, MidName,e.Suffix, e.SortName, e.Address, e.City, e.State, e.Zip, e.Address2, SSN, Sex, Race, FileStatus, RegExempts, EmpCraftDesc=cm_emp.Description, EmpClassDesc=cc_emp.Description,      
   CraftDesc=cm.Description, ClassDesc=cc.Description, cc_emp.EEOClass, CheckNumbers, th.PaySeq, PostSeq, WkDay, /*ci.EarnCode,*/ EarnCode=ISNULL(ci.EarnCode,888888), ci.DetOnCert,      
   ci.Taxable, ci.EarnDesc, ci.EarnRate, th.Hours, ci.EarnAmt, JCDept, JCDeptDesc=dm.Description, th.PRDept,PRDeptDesc=dp.Description, th.Crew, th.Craft, th.Class, DedCode,       
   DedDesc, DedAmt, GrossEarn, WklyRegHrs, WklyOTHrs, LiabCode, LiabDesc, LiabRate, LiabAmt, WklyHoursLine, DedTotalLine, LiabTotalLine, FirstDayOfWeek=@FirstDayOfWeek, LastDayOfWeek=@LastDayOfWeek, CoNum=@PRCo,      
   CompanyName=@CompanyDesc, WeekNo=datediff(wk, j.CertDate,@PREndDate)+1 /*Number of Weeks between Cert Date and PR EndDate, including current PR End Date.*/      
   ,EmployeeSortField = Substring('000000000000000',1,15-len(cast(ci.Employee  as varchar(15)))) + cast(ci.Employee  as varchar(15))      
--   EmployeeSortField is used to control sorting of the employee and needs to accomodate both employee name(PREH.SortName)       
--   or their number(PRTH.employee).        
--   Therefore, the field is defined as a varchar (15) but it is padded with leading zeros when employee number is converted to a       
--   character string to ensure correct and consistent sorting.      
      
 From #CertInformation ci       
   Join #JobsForCert on #JobsForCert.JCCo=ci.JCCo and #JobsForCert.Job=ci.Job      
   Left Outer Join JCJM j on j.JCCo=#JobsForCert.JCCo and j.Job=#JobsForCert.Job      
   Left Outer Join JCCM c on c.JCCo=#JobsForCert.JCCo and c.Contract=#JobsForCert.Contract      
   Left Outer Join PREH e on e.PRCo=@PRCo and e.Employee=ci.Employee      
   Left Outer Join PRCC cc on cc.PRCo=@PRCo and cc.Craft=ci.Craft and cc.Class=ci.Class
   Left Outer Join PRCC cc_emp on cc_emp.PRCo=@PRCo and cc_emp.Craft=e.Craft and cc_emp.Class=e.Class
   Left Outer Join PRED ed on ed.PRCo=@PRCo and ed.Employee=e.Employee and ed.DLCode=@FedTaxDedn      
   Left Outer Join #EarnTemp th on th.JCCo=ci.JCCo and th.Job=ci.Job and isnull(th.Employee,0)=isnull(ci.Employee,0) and th.EarnCode=ci.EarnCode and th.EarnRate=ci.EarnRate and isnull(th.Craft,' ')=isnull(ci.Craft,' ') and isnull(th.Class,' ')=isnull(ci.Class,' ')      
   --Left Outer Join PRSQ sq on sq.PRCo=@PRCo and sq.PRGroup=@PRGroup and sq.PREndDate=@PREndDate and sq.Employee=th.Employee and sq.PaySeq=th.PaySeq       
   Left Outer Join PRDP dp on dp.PRCo=@PRCo and dp.PRDept=th.PRDept      
   Left Outer Join JCDM dm on dm.JCCo=th.JCCo and dm.Department=th.JCDept      
   --Left Outer Join PRCM cm on cm.PRCo=@PRCo and cm.Craft=th.Craft
   Left Outer Join PRCM cm on cm.PRCo=@PRCo and cm.Craft=ci.Craft
   Left Outer Join PRCM cm_emp on cm_emp.PRCo=@PRCo and cm_emp.Craft=e.Craft
   --Left Outer Join PRCC cc on cc.PRCo=@PRCo and cc.Craft=th.Craft and cc.Class=th.Class      
   Where  ci.JCCo>=@BegJCCo and ci.JCCo<=@EndJCCo       
  --and ci.Job>=Substring(@BegJob,1,@SignifJobChar) and ci.Job<=Substring(@EndJob,1,@SignifJobChar)      
   Order By j.JCCo, j.Job, ci.Employee, ci.RecId      
END

GO
GRANT EXECUTE ON  [dbo].[brptPRWklyCompliance] TO [public]
GO
