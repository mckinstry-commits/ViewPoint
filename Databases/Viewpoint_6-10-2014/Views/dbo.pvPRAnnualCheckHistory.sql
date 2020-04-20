SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[pvPRAnnualCheckHistory]
AS

Select c.PRCo, 
c.Employee, 
e.KeyID,
Year(c.PaidDate) as 'PaidYear', 
sum(c.Earnings) as 'YTDEarnings', 
Sum(c.Dedns) as 'YTDDedns', 
sum(c.Hours) as 'YTDHours',
sum(c.Earnings) - Sum(c.Dedns) as 'NetAmount'

from PRSQ c
inner join PREH e on e.PRCo = c.PRCo and e.Employee = c.Employee
Where c.PayMethod <> 'X' and c.CMRef is not Null

Group by Year(c.PaidDate), c.PRCo, c.Employee, e.KeyID
GO
GRANT SELECT ON  [dbo].[pvPRAnnualCheckHistory] TO [public]
GRANT INSERT ON  [dbo].[pvPRAnnualCheckHistory] TO [public]
GRANT DELETE ON  [dbo].[pvPRAnnualCheckHistory] TO [public]
GRANT UPDATE ON  [dbo].[pvPRAnnualCheckHistory] TO [public]
GRANT SELECT ON  [dbo].[pvPRAnnualCheckHistory] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPRAnnualCheckHistory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPRAnnualCheckHistory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPRAnnualCheckHistory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPRAnnualCheckHistory] TO [Viewpoint]
GO
