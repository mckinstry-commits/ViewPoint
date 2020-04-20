SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      view [dbo].[brvPRDedNotTaken] as
SELECT PRED.PRCo, PRED.Employee, PRED.Frequency, 
          PRED.RateAmt, 
          PREH.LastName, PREH.FirstName, PREH.MidName,
          PRED.DLCode,
          EarnCode = 0,PREH.ActiveYN, PRPC.PREndDate, Record = 'D'
   
   FROM PRED
   	join PRPC on PRED.PRCo=PRPC.PRCo 
   	Join PREH on PRED.PRCo=PREH.PRCo and PRED.Employee=PREH.Employee and PREH.PRGroup = PRPC.PRGroup
      	Join PRDL on PRED.PRCo = PRDL.PRCo and PRED.DLCode = PRDL.DLCode
    
   WHERE  PREH.ActiveYN = 'Y' and PRED.RateAmt <> 0 and PRED.OverCalcs in ('A','R') and PRDL.Method in ('A','N') and PRDL.DLType = 'D'
     AND not exists (select distinct PRCo, PREndDate, Employee from PRDT 
                           where PRED.PRCo = PRDT.PRCo
   				and PRDT.EDLType = 'D' and PRED.DLCode = PRDT.EDLCode
                                   and PRED.Employee = PRDT.Employee 
     				and PRDT.PREndDate=PRPC.PREndDate)
   
   
   UNION ALL
   
   Select PRAE.PRCo, PRAE.Employee, PRAE.Frequency, 
          PRAE.RateAmt,  
          PREH.LastName, PREH.FirstName, PREH.MidName,0,
          PRAE.EarnCode,  
          PREH.ActiveYN, PRPC.PREndDate, 'E'
   
   FROM PRAE
      	Join PRPC on PRAE.PRCo = PRPC.PRCo 
      	Join PREH on PRAE.PRCo=PREH.PRCo and PRAE.Employee=PREH.Employee and PREH.PRGroup = PRPC.PRGroup
           Join PREC on PRAE.PRCo= PREC.PRCo and PRAE.EarnCode = PREC.EarnCode
   
   WHERE  PREH.ActiveYN = 'Y' and PRAE.RateAmt < 0 and PREC.Method = 'A'
     AND not exists (select distinct PRCo, PREndDate, Employee from PRDT where PRAE.PRCo = PRDT.PRCo
   					and PRDT.EDLType = 'E' and PRDT.EDLCode = PRAE.EarnCode 
   					and PRAE.Employee = PRDT.Employee 
         					and PRDT.PREndDate=PRPC.PREndDate)

GO
GRANT SELECT ON  [dbo].[brvPRDedNotTaken] TO [public]
GRANT INSERT ON  [dbo].[brvPRDedNotTaken] TO [public]
GRANT DELETE ON  [dbo].[brvPRDedNotTaken] TO [public]
GRANT UPDATE ON  [dbo].[brvPRDedNotTaken] TO [public]
GO
