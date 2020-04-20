SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvPR941Form]
AS

/*****************************************************************************************

Author:			Unknown
Date Created:	Unknown
Reports:		PR 941 Federal Form (PR941FillForm.rpt)

Purpose:		Returns rows from employee accumulations (PREA); includes several derived
				columns used in the report for date-based record selection and
				calculations.

Revision History      
Date		Author	Issue	Description
01/22/2013	Czeslaw	146669	Deleted unused column EmpCount from SELECT statement, and
							added new columns PRQuarter and PRMonthOrdinalInQtr;
							reformatted query.

*****************************************************************************************/

SELECT
	'PRCo'					= PREA.PRCo,
	'Employee'				= PREA.Employee,
	'Mth'					= PREA.Mth,
	'EDLType'				= PREA.EDLType,
	'EDLCode'				= PREA.EDLCode,
	'Amount'				= PREA.Amount,
	'SubjectAmt'			= PREA.SubjectAmt,
	'EligibleAmt'			= PREA.EligibleAmt,
	'PRYear'				= YEAR(PREA.Mth),
	'PRQuarter'				= (CASE
									WHEN MONTH(PREA.Mth) IN (1,2,3) THEN 1
									WHEN MONTH(PREA.Mth) IN (4,5,6) THEN 2
									WHEN MONTH(PREA.Mth) IN (7,8,9) THEN 3
									WHEN MONTH(PREA.Mth) IN (10,11,12) THEN 4
									ELSE 0 END),
	'PRMonth'				= MONTH(PREA.Mth),
	'PRMonthOrdinalInQtr'	= (CASE
									WHEN MONTH(PREA.Mth) IN (1,4,7,10) THEN 1
									WHEN MONTH(PREA.Mth) IN (2,5,8,11) THEN 2
									WHEN MONTH(PREA.Mth) IN (3,6,9,12) THEN 3
									ELSE 0 END)
FROM dbo.PREA PREA
GO
GRANT SELECT ON  [dbo].[brvPR941Form] TO [public]
GRANT INSERT ON  [dbo].[brvPR941Form] TO [public]
GRANT DELETE ON  [dbo].[brvPR941Form] TO [public]
GRANT UPDATE ON  [dbo].[brvPR941Form] TO [public]
GRANT SELECT ON  [dbo].[brvPR941Form] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPR941Form] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPR941Form] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPR941Form] TO [Viewpoint]
GO
