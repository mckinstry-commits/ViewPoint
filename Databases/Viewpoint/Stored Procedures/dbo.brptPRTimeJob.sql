SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           proc [dbo].[brptPRTimeJob]
       (@PRCo bCompany, @PRGroup bGroup = 0 , @BeginPRDate bDate = '01/01/1950',
       @EndPRDate bDate = '12/31/2050' , @BeginJCCo bCompany , @EndJCCo bCompany, @BegJob bJob, @EndJob bJob)
     /* 8/26 added with Recompile and nolocks to speed up procedure E.T.*/
     /*  Issue 25973 Corrected to uses Views not Tables  NF 11/11/04 */
   
     With Recompile
       as
       create table #PRTime
       (PRCo		tinyint 	null,
       PRGroup		tinyint 	null,
       PREndDate		smalldatetime	null,
       Employee		int		null,
       PaySeq		numeric		null,
       PostSeq		numeric		null,
       Type		varchar(1) 	null,
       PostDate		smalldatetime	null,
       JCCo		tinyint 	null,
       Job			varchar(10)	null,
       Phase		varchar(20)	null,
       JCDept		varchar(10)	null,
       JCDeptDesc		varchar(30)	null,
       GLCo		tinyint 	null,
       PRDept		varchar(10)	null,
       PRDeptDesc		varchar(30)	null,
       Crew		varchar(10)	null,
       Cert		char(1)		null,
       Craft		varchar(10)	null,
       Class		varchar(10)	null,
       EarnCode		numeric		null,
       ECDesc		varchar(30)	null,
       ECMethod		varchar	(1)	Null,
       ECFactor		numeric (12,6)	null,
       TrueEarns		char(1)		null,
       Shift		tinyint 	null,
       Hours		numeric (12,2)	null,
       Rate		numeric	(12,6)	null,
       Amt			numeric (12,2)	null,
       /*AddonEC		numeric		null,
       AddonRate	numeric	(12,6)		null,
       AddonAmt	numeric	(12,2)		null,*/
       LiabCode		numeric		null,
       LiabDesc		varchar(30)	null,
       LiabRate		numeric (12,6)	null,
       LiabAmt		numeric (12,2)	null,
       LiabType		smallint	null,
       LiabTypeDesc	varchar(30)	null,
       CodeType		Varchar(1)	null
       )
     
       /* insert PRTH details*/
       insert into #PRTime
     
       (PRCo,PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate,JCCo,Job,Phase,JCDept,
       GLCo,PRDept,Crew,Cert,Craft,Class,EarnCode,Shift,Hours,Rate,Amt,ECDesc,ECMethod,ECFactor,TrueEarns,
       CodeType)
     
       select PRTH.PRCo,PRTH.PRGroup, 
       /*(case when PRTH.PRGroup >= @PRGroup then PRTH.PRGroup else 1 end),*/
       PRTH.PREndDate,PRTH.Employee,PRTH.PaySeq,PRTH.PostSeq,PRTH.Type,
       PRTH.PostDate,PRTH.JCCo,PRTH.Job,PRTH.Phase,PRTH.JCDept,PRTH.GLCo,
       PRTH.PRDept,PRTH.Crew,PRTH.Cert,
       PRTH.Craft,PRTH.Class,PRTH.EarnCode,PRTH.Shift,PRTH.Hours,PRTH.Rate,PRTH.Amt,
       PREC.Description,PREC.Method,PREC.Factor,PREC.TrueEarns,'E'
     
       from PRTH PRTH with(nolock)
       Join PREC with(nolock) on PREC.PRCo=PRTH.PRCo and PREC.EarnCode=PRTH.EarnCode
       Join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job  --added by Hong-Soo 08/17
     
       where PRTH.PRCo=@PRCo and PRTH.PRGroup= (Case When @PRGroup <> 0 then @PRGroup else PRTH.PRGroup end) and
       PRTH.PREndDate>=@BeginPRDate and
       PRTH.PREndDate<=@EndPRDate and IsNull(PRTH.JCCo,0)>=@BeginJCCo and IsNull(PRTH.JCCo,0)<=@EndJCCo
       and PRTH.Job between @BegJob and @EndJob  and PRTH.Type = 'J'
     
     
       /*insert Addon details from PRTA*/
       insert into #PRTime
       (PRCo,PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate,JCCo,Job,Phase,JCDept,
       GLCo,PRDept,Crew,Cert,Craft,Class,EarnCode,Rate,Amt,ECDesc,ECMethod,ECFactor,TrueEarns,CodeType)
     
       select PRTH.PRCo,PRTH.PRGroup,PRTH.PREndDate,PRTH.Employee,PRTH.PaySeq,PRTH.PostSeq,
       PRTH.Type,PRTH.PostDate,PRTH.JCCo,PRTH.Job,PRTH.Phase,PRTH.JCDept,PRTH.GLCo,
       PRTH.PRDept,PRTH.Crew,PRTH.Cert,PRTH.Craft,PRTH.Class,
       PRTA.EarnCode, PRTA.Rate, PRTA.Amt, PREC.Description,PREC.Method,PREC.Factor,PREC.TrueEarns,'A'
     
       from PRTA PRTA with(nolock)
       Join PRTH with(nolock) on PRTH.PRCo=PRTA.PRCo and PRTH.PRGroup=PRTA.PRGroup and
          PRTH.PREndDate=PRTA.PREndDate and
          PRTH.Employee=PRTA.Employee and PRTH.PaySeq=PRTA.PaySeq and PRTH.PostSeq=PRTA.PostSeq
          Join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job  --added by Hong-Soo 08/17
          Join PREC PREC with(nolock) on PREC.PRCo=PRTA.PRCo and PREC.EarnCode=PRTA.EarnCode
     
       where PRTH.PRCo=@PRCo and PRTH.PRGroup=(Case When @PRGroup <> 0 then @PRGroup else PRTH.PRGroup end) and
       PRTH.PREndDate>=@BeginPRDate and
       PRTH.PREndDate<=@EndPRDate and Isnull(PRTH.JCCo,0)>=@BeginJCCo and Isnull(PRTH.JCCo,0)<=@EndJCCo
       and PRTH.Job between @BegJob and @EndJob and PRTH.Type = 'J'
     
     
       /*insert Timecard liabilities from PRTL*/
       insert into #PRTime
       (PRCo,PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate,JCCo,Job,Phase,JCDept,
       GLCo,PRDept,Crew,Cert,Craft,Class,LiabCode,LiabDesc,LiabRate,LiabAmt,LiabType,LiabTypeDesc,
       CodeType)
     
        select PRTH.PRCo,PRTH.PRGroup,PRTH.PREndDate,PRTH.Employee,PRTH.PaySeq,PRTH.PostSeq,
        PRTH.Type,PRTH.PostDate,PRTH.JCCo,PRTH.Job,PRTH.Phase,PRTH.JCDept,PRTH.GLCo,PRTH.PRDept,
        PRTH.Crew,PRTH.Cert,PRTH.Craft,PRTH.Class,PRTL.LiabCode,
        (case PRDL.DLType when 'L' then PRDL.Description else '' end),PRTL.Rate,PRTL.Amt,
        PRDL.LiabType, HQLT.Description, 'L'
     
       from PRTH PRTH with(nolock)
       Left Join PRTL PRTL with(nolock) on PRTH.PRCo=PRTL.PRCo and PRTH.PRGroup=PRTL.PRGroup 
   	and PRTH.PREndDate=PRTL.PREndDate and PRTH.Employee=PRTL.Employee and PRTH.PaySeq=PRTL.PaySeq 
   	and PRTH.PostSeq=PRTL.PostSeq
       Join PRDL PRDL with(nolock) on PRDL.PRCo=PRTL.PRCo and PRDL.DLCode=PRTL.LiabCode
       Join HQLT with(nolock) on HQLT.LiabType=PRDL.LiabType
       Join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job  --added by Hong-Soo 08/17
     
       where PRTH.PRCo=@PRCo and PRTH.PRGroup=(Case When @PRGroup <> 0 then @PRGroup else PRTH.PRGroup end) and 
       PRTH.PREndDate>=@BeginPRDate and
       PRTH.PREndDate<=@EndPRDate and isnull(PRTH.JCCo,0)>=@BeginJCCo and isnull(PRTH.JCCo,0)<=@EndJCCo
       and PRTH.Job between @BegJob and @EndJob and PRTH.Type = 'J'
     
     
       /*select results*/
       select
     
       a.PRCo,a.PRGroup,a.PREndDate,a.Employee,
       PREH.LastName, PREH.FirstName, PREH.MidName, PREH.Suffix, PREH.SortName,
       a.PaySeq,a.PostSeq,a.Type,
       a.PostDate,a.JCCo,a.Job,JobDesc=JCJM.Description,a.Phase,a.JCDept,JCDeptDesc=JCDM.Description,
       a.GLCo,a.PRDept,PRDeptDesc=PRDP.Description,a.Crew,a.Cert,a.Craft,a.Class,
       a.EarnCode,a.ECDesc,a.ECMethod,a.ECFactor,a.TrueEarns,a.Shift,a.Hours,a.Rate,a.Amt,
       /*a.AddonEC,a.AddonRate,a.AddonAmt,*/a.LiabCode,a.LiabDesc,a.LiabRate,a.LiabAmt,
       a.LiabType,a.LiabTypeDesc,a.CodeType,CoName=HQCO.Name,
     
       BeginPRDate=@BeginPRDate,
       EndPRDate=@EndPRDate,
       BeginJCCo=@BeginJCCo,
       EndJCCo=@EndJCCo
     
       from #PRTime a with(nolock)
       Join PREH with(nolock) on PREH.PRCo=a.PRCo and PREH.Employee=a.Employee
       Join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job= a.Job
       Join JCDM  with(nolock) on JCDM.JCCo=a.JCCo and JCDM.Department=a.JCDept
       Join PRDP  with(nolock) on PRDP.PRCo=a.PRCo and PRDP.PRDept=a.PRDept
       Join HQCO with(nolock) on HQCO.HQCo=a.PRCo

GO
GRANT EXECUTE ON  [dbo].[brptPRTimeJob] TO [public]
GO
