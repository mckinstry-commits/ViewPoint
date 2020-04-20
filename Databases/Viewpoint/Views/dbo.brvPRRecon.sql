SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         View [dbo].[brvPRRecon]
     /* 
     View used by PRRecon.rpt and PRTimecardwAddonsLiab.rpt   Date Created 3/14/2002 by CR
   
     */
     
     as
     
     Select PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.Employee, PRTH.PaySeq, PRTH.PostSeq,PRTH.PostDate,  
     PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase,PRTH.Craft, PRTH.Class, PRTH.EarnCode,
     PRTH.Amt, PRTH.Hours,AddonEarn=sum(AddonEarn), AddonLiab=sum(AddonLiab)
     
     From PRTH
     
     Left Outer Join (select PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq,  AddonEarn=sum(Amt) From PRTA Group By 
             PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq) as AE 
     on AE.PRCo=PRTH.PRCo and AE.PRGroup=PRTH.PRGroup and AE.PREndDate=PRTH.PREndDate and AE.Employee=PRTH.Employee
           and AE.PaySeq=PRTH.PaySeq and AE.PostSeq=PRTH.PostSeq 
     Left Outer Join (select PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq,  AddonLiab=sum(Amt) From PRTL Group By 
             PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq) as AL 
     on AL.PRCo=PRTH.PRCo and AL.PRGroup=PRTH.PRGroup and AL.PREndDate=PRTH.PREndDate and AL.Employee=PRTH.Employee
           and AL.PaySeq=PRTH.PaySeq and AL.PostSeq=PRTH.PostSeq 
      Group by PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.Employee, PRTH.PaySeq, PRTH.PostSeq,PRTH.PostDate,PRTH.JCCo,
      PRTH.Job,PRTH.PhaseGroup, PRTH.Phase,PRTH.Craft, PRTH.Class,PRTH.EarnCode,PRTH.Amt,PRTH.Hours

GO
GRANT SELECT ON  [dbo].[brvPRRecon] TO [public]
GRANT INSERT ON  [dbo].[brvPRRecon] TO [public]
GRANT DELETE ON  [dbo].[brvPRRecon] TO [public]
GRANT UPDATE ON  [dbo].[brvPRRecon] TO [public]
GO
