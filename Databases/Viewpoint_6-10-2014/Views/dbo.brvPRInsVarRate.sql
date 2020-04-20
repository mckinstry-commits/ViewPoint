SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[brvPRInsVarRate]
 
 as
 
 Select PRTA.PRCo, PRTA.PRGroup, PRTA.PREndDate, PRTA.Employee, PRTA.PaySeq, PRTH.PostDate, AddonEC=PRTA.EarnCode, VarSTRate=min(PRTA.Rate)
      From PRTA
     Join PRTH on PRTH.PRCo=PRTA.PRCo and PRTH.PRGroup=PRTA.PRGroup and PRTH.PREndDate=PRTA.PREndDate and PRTH.Employee=PRTA.Employee and PRTH.PaySeq=PRTA.PaySeq and PRTH.PostSeq=PRTA.PostSeq
     Join PREC PREC_TH on PREC_TH.PRCo=PRTH.PRCo and PREC_TH.EarnCode=PRTH.EarnCode
     Join PREC PREC_TA on PREC_TA.PRCo=PRTA.PRCo and PREC_TA.EarnCode=PRTA.EarnCode
 Where PREC_TA.Method='V'  and PREC_TH.Factor=1.0
 Group by PRTA.PRCo, PRTA.PRGroup, PRTA.PREndDate, PRTA.Employee, PRTA.PaySeq, PRTH.PostDate, PRTA.EarnCode

GO
GRANT SELECT ON  [dbo].[brvPRInsVarRate] TO [public]
GRANT INSERT ON  [dbo].[brvPRInsVarRate] TO [public]
GRANT DELETE ON  [dbo].[brvPRInsVarRate] TO [public]
GRANT UPDATE ON  [dbo].[brvPRInsVarRate] TO [public]
GRANT SELECT ON  [dbo].[brvPRInsVarRate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRInsVarRate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRInsVarRate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRInsVarRate] TO [Viewpoint]
GO
