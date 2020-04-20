SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRROEEmployeePayPeriods] as 
SELECT DISTINCT TOP 250000
	a.PRCo,
	b.Employee,
	a.PREndDate
FROM dbo.PRPC a
JOIN dbo.PREH b
ON a.PRCo=b.PRCo AND a.PRGroup=b.PRGroup
ORDER BY a.PREndDate DESC
GO
GRANT SELECT ON  [dbo].[PRROEEmployeePayPeriods] TO [public]
GRANT INSERT ON  [dbo].[PRROEEmployeePayPeriods] TO [public]
GRANT DELETE ON  [dbo].[PRROEEmployeePayPeriods] TO [public]
GRANT UPDATE ON  [dbo].[PRROEEmployeePayPeriods] TO [public]
GRANT SELECT ON  [dbo].[PRROEEmployeePayPeriods] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRROEEmployeePayPeriods] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRROEEmployeePayPeriods] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRROEEmployeePayPeriods] TO [Viewpoint]
GO
