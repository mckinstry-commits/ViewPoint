SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   view [dbo].[brvPRDeptCostLiab]
   
   as
   
   select a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.Phase,
     Dept=(case when a.Job is null or a.Type = 'M' or 
     a.Job is not null and a.JCDept is null then ('PR' + a.PRDept) else ('JC'+a.JCDept) end),  
     JCCo=isnull(a.JCCo,0), a.JCDept, a.PRDept, a.Job, a.Type,
     ExpMth = case when c.MultiMth = 'Y' then (case when a.PostDate<=
     c.CutoffDate then c.BeginMth else c.EndMth end) else c.BeginMth end, l.LiabCode, d.LiabType, h.Description, l.Amt
     From PRTH a 
     
      join PRPC c on a.PRCo=c.PRCo and a.PRGroup=c.PRGroup and a.PREndDate=c.PREndDate
      join PRCO on a.PRCo=PRCO.PRCo
      join PRTL l on a.PRCo=l.PRCo and a.PRGroup=l.PRGroup and a.PREndDate=l.PREndDate and a.Employee=l.Employee 
      and  a.PaySeq=l.PaySeq and a.PostSeq=l.PostSeq 
      join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode
      join HQLT h on h.LiabType=d.LiabType
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPRDeptCostLiab] TO [public]
GRANT INSERT ON  [dbo].[brvPRDeptCostLiab] TO [public]
GRANT DELETE ON  [dbo].[brvPRDeptCostLiab] TO [public]
GRANT UPDATE ON  [dbo].[brvPRDeptCostLiab] TO [public]
GRANT SELECT ON  [dbo].[brvPRDeptCostLiab] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRDeptCostLiab] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRDeptCostLiab] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRDeptCostLiab] TO [Viewpoint]
GO
