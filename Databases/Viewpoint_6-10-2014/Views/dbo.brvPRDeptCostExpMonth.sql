SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                 View [dbo].[brvPRDeptCostExpMonth] as
      
      /************************************
      PR Dept. Costs by Expense Month
      Created 10/10/02 CR
      
      PR costs by earn code for the Expense Month
      
      Reports:  PRDeptCostsbyExpMonth
      ***********************************
       11/1/04 CR Added Job and Type to the View  #23647
       3/28/05 CR Changed the Sort and Dept case statements to use Phase instead of Job #25685
    
      ***********************************/
      
      select a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.EarnCode,Phase=isnull(a.Phase,''),
      Sort=(case when a.Type = 'M' or a.Phase is null then 0 else 1 end), 
      Dept=(case when a.Type = 'M' or a.Phase is null then ('PR' + a.PRDept) else ('JC'+a.JCDept) end), 
      a.JCCo, a.JCDept, a.PRDept, a.PostDate,a.Job,a.Type,
      ExpMth = case when b.MultiMth = 'Y' then (case when a.PostDate<=
      b.CutoffDate then b.BeginMth else b.EndMth end) else b.BeginMth end, a.PostSeq, a.Hours, a.Amt, LiabAmt=null
      From PRTH a
       join PRPC b on a.PRCo=b.PRCo and a.PRGroup=b.PRGroup and a.PREndDate=b.PREndDate
       join PRCO on a.PRCo=PRCO.PRCo
      
      Union all	
      
      select a.PRCo, a.PRGroup, a.PREndDate, a.Employee, b.EarnCode, Phase=isnull(a.Phase,''),
      Sort=(case when a.Type = 'M' or a.Phase is null then 0 else 1 end), 
      Dept=(case when a.Type = 'M' or a.Phase is null then ('PR' + a.PRDept) else ('JC'+a.JCDept) end),
      a.JCCo, a.JCDept, a.PRDept, a.PostDate,a.Job,a.Type,
      ExpMth = case when c.MultiMth = 'Y' then (case when a.PostDate<=
      c.CutoffDate then c.BeginMth else c.EndMth end) else c.BeginMth end, a.PostSeq, Hours= 0, b.Amt, null
      From PRTH a 
      join PRTA b on a.PRCo=b.PRCo and a.PRGroup=b.PRGroup and a.PREndDate=b.PREndDate and a.Employee=b.Employee and
          a.PaySeq=b.PaySeq and a.PostSeq=b.PostSeq 
       join PRPC c on a.PRCo=c.PRCo and a.PRGroup=c.PRGroup and a.PREndDate=c.PREndDate
       join PRCO on a.PRCo=PRCO.PRCo
      
      Union all
      
      select a.PRCo, a.PRGroup, a.PREndDate, a.Employee, null, Phase=isnull(a.Phase,''),
      Sort=(case when a.Type = 'M' or a.Phase is null then 0 else 1 end), 
      Dept=(case when a.Type = 'M' or a.Phase is null then ('PR' + a.PRDept) else ('JC'+a.JCDept) end),
      a.JCCo, a.JCDept, a.PRDept, null,a.Job,a.Type,
      ExpMth = case when c.MultiMth = 'Y' then (case when a.PostDate<=
      c.CutoffDate then c.BeginMth else c.EndMth end) else c.BeginMth end, null, null,null,l.Amt
      From PRTH a 
      
       join PRPC c on a.PRCo=c.PRCo and a.PRGroup=c.PRGroup and a.PREndDate=c.PREndDate
       join PRCO on a.PRCo=PRCO.PRCo
       join PRTL l on a.PRCo=l.PRCo and a.PRGroup=l.PRGroup and a.PREndDate=l.PREndDate and a.Employee=l.Employee 
      and  a.PaySeq=l.PaySeq and a.PostSeq=l.PostSeq

GO
GRANT SELECT ON  [dbo].[brvPRDeptCostExpMonth] TO [public]
GRANT INSERT ON  [dbo].[brvPRDeptCostExpMonth] TO [public]
GRANT DELETE ON  [dbo].[brvPRDeptCostExpMonth] TO [public]
GRANT UPDATE ON  [dbo].[brvPRDeptCostExpMonth] TO [public]
GRANT SELECT ON  [dbo].[brvPRDeptCostExpMonth] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRDeptCostExpMonth] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRDeptCostExpMonth] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRDeptCostExpMonth] TO [Viewpoint]
GO
