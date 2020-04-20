SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
  
CREATE view [dbo].[vrvPRPayPeriod] as   
  
With EmployeeCheckData    
    
as    
    
(select PRSQ.PRCo, PRSQ.PRGroup, PRSQ.Employee, PRSQ.PREndDate, PRPdBeginDate=PRPC.BeginDate    
From PRSQ    
Join PRPC on PRPC.PRCo=PRSQ.PRCo and PRPC.PRGroup=PRSQ.PRGroup and PRPC.PREndDate=PRSQ.PREndDate    
Group By PRSQ.PRCo, PRSQ.PRGroup, PRSQ.Employee, PRSQ.PREndDate, PRPC.BeginDate)    
    
Select e.PRCo,e.PRGroup,  e.Employee, e.PREndDate, min(e.PRPdBeginDate) as PRPdBeginDate From EmployeeCheckData e    
Group By e.PRCo, e.PRGroup, e.Employee, e.PREndDate  
  
  
GO
GRANT SELECT ON  [dbo].[vrvPRPayPeriod] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPayPeriod] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPayPeriod] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPayPeriod] TO [public]
GO
