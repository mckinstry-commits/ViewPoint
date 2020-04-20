SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE                view [dbo].[brvPRTimeJob] as 
   -- Issue #26833 02/09/05 change stored procedure brptPRTimeJob to view brvPRTimeJob
	-- Issue 120044 02/7/06 NF   add PRTH.Class to the group by for each Union statement 
  select
  
  PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.Employee, LastName=max(PREH.LastName), FirstName=max(PREH.FirstName), MidName=max(PREH.MidName), 
  Suffix=max(PREH.Suffix),
  SortName=max(PREH.SortName), Type=max(PRTH.Type),  PRTH.JCCo, PRTH.Job, JobDesc=max(JCJM.Description),
  PRTH.Phase, JCDept=max(PRTH.JCDept), JCDeptDesc=max(JCDM.Description), GLCo=max(PRTH.GLCo), PRDept=max(PRTH.PRDept), PRDeptDesc=max(PRDP.Description), 
  Crew=max(PRTH.Crew),
  Cert=max(PRTH.Cert), PRTH.Craft, Class=max(PRTH.Class), PRTH.EarnCode, ECDesc=max(PREC.Description), ECMethod=max(PREC.Method), ECFactor=PREC.Factor,
  TrueEarns=max(PREC.TrueEarns), Shift=max(PRTH.Shift), Hours=sum(PRTH.Hours),Rate= max(PRTH.Rate), Amt=sum(PRTH.Amt), LiabCode=NULL, LiabDesc=NULL, 
  LiabRate=0, LiabAmt=0,
  LiabType=0, LiabTypeDesc=NULL, CodeType='E', CoName=max(HQCO.Name)
  
  from PRTH with(nolock)
  	Join PREC with(nolock) on PREC.PRCo=PRTH.PRCo and PREC.EarnCode=PRTH.EarnCode
  	Left outer Join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
  	Join PREH with(nolock) on PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
  	Join PRDP  with(nolock) on PRDP.PRCo=PRTH.PRCo and PRDP.PRDept=PRTH.PRDept
  	Join HQCO with(nolock) on HQCO.HQCo=PRTH.PRCo
  	Left outer Join JCDM  with(nolock) on JCDM.JCCo=PRTH.JCCo and JCDM.Department=PRTH.JCDept
  where PRTH.Phase is not NULL
  group by PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.Phase, PRTH.Employee, PRTH.Craft, PRTH.Class, PRTH.EarnCode, PREC.Factor
  
  UNION ALL
  
  select
  
  PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.Employee, LastName=max(PREH.LastName), FirstName=max(PREH.FirstName), MidName=max(PREH.MidName), 
  Suffix=max(PREH.Suffix), 
  NULL, max(PRTH.Type), PRTH.JCCo, PRTH.Job, max(JCJM.Description),
  PRTH.Phase, max(PRTH.JCDept), max(JCDM.Description), max(PRTH.GLCo), max(PRTH.PRDept), max(PRDP.Description), max(PRTH.Crew),
  max(PRTH.Cert), PRTH.Craft, max(PRTH.Class), PRTA.EarnCode, max(PREC.Description), max(PREC.Method), PREC.Factor,
  max(PREC.TrueEarns), NULL, 0, max(PRTA.Rate), sum(PRTA.Amt), NULL, NULL, NULL, NULL, 
  NULL, NULL, 'A', max(HQCO.Name)
  
  from PRTH with(nolock)
  	Left outer Join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
  	Join PREH with(nolock) on PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
  	Join PRDP  with(nolock) on PRDP.PRCo=PRTH.PRCo and PRDP.PRDept=PRTH.PRDept
  	Join HQCO with(nolock) on HQCO.HQCo=PRTH.PRCo
  	Left outer Join JCDM  with(nolock) on JCDM.JCCo=PRTH.JCCo and JCDM.Department=PRTH.JCDept
  	Join PRTA with(nolock) on PRTH.PRCo=PRTA.PRCo and PRTH.PRGroup=PRTA.PRGroup 
               and  PRTH.PREndDate=PRTA.PREndDate and PRTH.Employee=PRTA.Employee and PRTH.PaySeq=PRTA.PaySeq 
               and PRTH.PostSeq=PRTA.PostSeq
 	Join PREC with(nolock) on PREC.PRCo=PRTA.PRCo and PREC.EarnCode=PRTA.EarnCode
  where PRTH.Phase is not NULL
  group by PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.Phase, PRTH.Employee, PRTH.Craft, PRTH.Class, PRTA.EarnCode, PREC.Factor
  
  UNION ALL
  
  select
  
  PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.Employee, LastName=max(PREH.LastName), FirstName=max(PREH.FirstName), MidName=max(PREH.MidName), 
  Suffix=max(PREH.Suffix),
  NULL, max(PRTH.Type), PRTH.JCCo, PRTH.Job, max(JCJM.Description),
  PRTH.Phase, max(PRTH.JCDept), max(JCDM.Description), max(PRTH.GLCo), max(PRTH.PRDept), max(PRDP.Description), max(PRTH.Crew),
  max(PRTH.Cert), PRTH.Craft, max(PRTH.Class), NULL, NULL, NULL, NULL,
  NULL, NULL, 0, 0, 0, max(PRTL.LiabCode),(case max(PRDL.DLType) when 'L' then max(PRDL.Description) else ' ' end), max(PRTL.Rate), sum(PRTL.Amt), 
  max(PRDL.LiabType), max(HQLT.Description), 'L', max(HQCO.Name)
  
  from PRTH with(nolock)
  	Left Join bPRTL PRTL with(nolock) on PRTH.PRCo=PRTL.PRCo and PRTH.PRGroup=PRTL.PRGroup and PRTH.PREndDate=PRTL.PREndDate and PRTH.Employee=PRTL.Employee and PRTH.PaySeq=PRTL.PaySeq and PRTH.PostSeq=PRTL.PostSeq	
  	Left outer Join JCJM with(nolock) on PRTH.JCCo=JCJM.JCCo and PRTH.Job=JCJM.Job
  	Join PREH with(nolock) on PREH.PRCo=PRTH.PRCo and PREH.Employee=PRTH.Employee
  	left Join PRDP  with(nolock) on PRDP.PRCo=PRTH.PRCo and PRDP.PRDept=PRTH.PRDept
  	Join HQCO with(nolock) on HQCO.HQCo=PRTH.PRCo
  	Left outer Join JCDM  with(nolock) on JCDM.JCCo=PRTH.JCCo and JCDM.Department=PRTH.JCDept
  	Join PRDL with(nolock) on PRDL.PRCo=PRTL.PRCo and PRDL.DLCode=PRTL.LiabCode
  	Join HQLT with(nolock) on HQLT.LiabType=PRDL.LiabType
  where PRTH.Phase is not NULL
  group by PRTH.PRCo, PRTH.PRGroup,PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.Phase, PRTH.Employee, PRTH.Craft, PRTH.Class, PRTH.EarnCode
  
  
  
 
 




GO
GRANT SELECT ON  [dbo].[brvPRTimeJob] TO [public]
GRANT INSERT ON  [dbo].[brvPRTimeJob] TO [public]
GRANT DELETE ON  [dbo].[brvPRTimeJob] TO [public]
GRANT UPDATE ON  [dbo].[brvPRTimeJob] TO [public]
GRANT SELECT ON  [dbo].[brvPRTimeJob] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRTimeJob] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRTimeJob] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRTimeJob] TO [Viewpoint]
GO
