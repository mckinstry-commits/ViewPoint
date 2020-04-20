SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vrptPR941SchB]
(
	@Co				bCompany,
	@QtrEndMonth	bDate,
	@FedDedn		bEDLCode	= -1, --Since 0 is an allowed value for DLCode in V6, use -1 as default, meaning "select no data"
	@FICAMedDedn	bEDLCode	= -1,
	@FICASSDedn		bEDLCode	= -1,
	@FICAMedLiab	bEDLCode	= -1,
	@FICASSLiab		bEDLCode	= -1,
	@EICDedCode		bEDLCode	= -1,
	@AddlMedTaxDedn	bEDLCode	= -1
)

AS

/******************************************************************************************

Author:			CR
Date Created:	04/22/2008
Issue:			127652
Reports:		PR 941 Schedule B (PR941SchB.rpt)

Purpose:		Returns employee pay sequence information for all quarters of the year,
				designating each month as first, second, or third month in a quarter.
				Result set includes one dummy row for each of first, second, and third
				month, insuring that each ordinal month has at least one row; this is
				required by the Crystal file as currently structured, to insure proper
				positioning of each month's data on the page.

Revision History      
Date		Author	Issue		Description
01/07/2013	Czeslaw	147760 		(D-06384) Added parameter @AddlMedTaxDedn for Additional
								Medicare Tax, effective 01/01/2013; made implicit
								inner join to PRDT explicit; added Name and FedTaxID
								column selections to dummy rows, and deleted nonsensical,
								unused PaidMth column selection; reformatted procedure for
								readability and adherence to current coding standards.

******************************************************************************************/

SET NOCOUNT ON

/* First month in quarter (all quarters of the year) */

SELECT 
	'Month'			= 1,
	'PRCo'			= PRSQ.PRCo,
	'PRGroup'		= PRSQ.PRGroup,
	'PREndDate'		= PRSQ.PREndDate,
	'Employee'		= PRSQ.Employee,
	'PaySeq'		= PRSQ.PaySeq,
	'CMCo'			= PRSQ.CMCo,
	'CMAcct'		= PRSQ.CMAcct,
	'PayMethod'		= PRSQ.PayMethod,
	'CMRef'			= PRSQ.CMRef,
	'CMRefSeq'		= PRSQ.CMRefSeq,
	'EFTSeq'		= PRSQ.EFTSeq,
	'ChkType'		= PRSQ.ChkType,
	'PaidDate'		= (CASE WHEN PRSQ.PayMethod='X' AND PRSQ.PaidDate IS NULL THEN PRSQ.PREndDate ELSE PRSQ.PaidDate END),
	'PaidMth'		= PRSQ.PaidMth,
	'Hours'			= PRSQ.[Hours],
	'Earnings'		= PRSQ.Earnings,
	'Dedns'			= PRSQ.Dedns,
	'SUIEarnings'	= PRSQ.SUIEarnings,
	'PostToAll'		= PRSQ.PostToAll,
	'Processed'		= PRSQ.Processed,
	'CMInterface'	= PRSQ.CMInterface,
	'EDLType'		= PRDT.EDLType,
	'EDLCode'		= PRDT.EDLCode,
	'Amount'		= PRDT.Amount,
	'UseOver'		= PRDT.UseOver,
	'OverAmt'		= PRDT.OverAmt,
	'Name'			= HQCO.Name,
	'FedTaxId'		= HQCO.FedTaxId
FROM dbo.PRSQ PRSQ
JOIN dbo.PRDT PRDT ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRSQ.PRCo
WHERE PRSQ.PRCo = @Co
AND YEAR(PRSQ.PaidMth) = YEAR(@QtrEndMonth)
AND MONTH(PRSQ.PaidMth) IN (1,4,7,10)
AND PRDT.EDLType <> 'E'

UNION ALL

SELECT 
	'Month'			= 1,
	'PRCo'			= PRCO.PRCo,
	'PRGroup'		= NULL,
	'PREndDate'		= NULL,
	'Employee'		= NULL,
	'PaySeq'		= NULL,
	'CMCo'			= NULL,
	'CMAcct'		= NULL,
	'PayMethod'		= NULL,
	'CMRef'			= NULL,
	'CMRefSeq'		= NULL,
	'EFTSeq'		= NULL,
	'ChkType'		= NULL,
	'PaidDate'		= NULL,
	'PaidMth'		= NULL,
	'Hours'			= NULL,
	'Earnings'		= NULL,
	'Dedns'			= NULL,
	'SUIEarnings'	= NULL,
	'PostToAll'		= NULL,
	'Processed'		= NULL,
	'CMInterface'	= NULL,
	'EDLType'		= NULL,
	'EDLCode'		= NULL,
	'Amount'		= NULL,
	'UseOver'		= NULL,
	'OverAmt'		= NULL,
	'Name'			= HQCO.Name,
	'FedTaxId'		= HQCO.FedTaxId
FROM dbo.PRCO PRCO
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRCO.PRCo
WHERE PRCO.PRCo = @Co

UNION ALL


/* Second month in quarter (all quarters of the year) */

SELECT
	'Month'			= 2,
	'PRCo'			= PRSQ.PRCo,
	'PRGroup'		= PRSQ.PRGroup,
	'PREndDate'		= PRSQ.PREndDate,
	'Employee'		= PRSQ.Employee,
	'PaySeq'		= PRSQ.PaySeq,
	'CMCo'			= PRSQ.CMCo,
	'CMAcct'		= PRSQ.CMAcct,
	'PayMethod'		= PRSQ.PayMethod,
	'CMRef'			= PRSQ.CMRef,
	'CMRefSeq'		= PRSQ.CMRefSeq,
	'EFTSeq'		= PRSQ.EFTSeq,
	'ChkType'		= PRSQ.ChkType,
	'PaidDate'		= (CASE WHEN PRSQ.PayMethod='X' AND PRSQ.PaidDate IS NULL THEN PRSQ.PREndDate ELSE PRSQ.PaidDate END),
	'PaidMth'		= PRSQ.PaidMth,
	'Hours'			= PRSQ.[Hours],
	'Earnings'		= PRSQ.Earnings,
	'Dedns'			= PRSQ.Dedns,
	'SUIEarnings'	= PRSQ.SUIEarnings,
	'PostToAll'		= PRSQ.PostToAll,
	'Processed'		= PRSQ.Processed,
	'CMInterface'	= PRSQ.CMInterface,
	'EDLType'		= PRDT.EDLType,
	'EDLCode'		= PRDT.EDLCode,
	'Amount'		= PRDT.Amount,
	'UseOver'		= PRDT.UseOver,
	'OverAmt'		= PRDT.OverAmt,
	'Name'			= HQCO.Name,
	'FedTaxId'		= HQCO.FedTaxId
FROM dbo.PRSQ PRSQ
JOIN dbo.PRDT PRDT ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRSQ.PRCo
WHERE PRSQ.PRCo = @Co
AND YEAR(PRSQ.PaidMth) = YEAR(@QtrEndMonth)
AND MONTH(PRSQ.PaidMth) IN (2,5,8,11)
AND PRDT.EDLType <> 'E'

UNION ALL

SELECT 
	'Month'			= 2,
	'PRCo'			= PRCO.PRCo,
	'PRGroup'		= NULL,
	'PREndDate'		= NULL,
	'Employee'		= NULL,
	'PaySeq'		= NULL,
	'CMCo'			= NULL,
	'CMAcct'		= NULL,
	'PayMethod'		= NULL,
	'CMRef'			= NULL,
	'CMRefSeq'		= NULL,
	'EFTSeq'		= NULL,
	'ChkType'		= NULL,
	'PaidDate'		= NULL,
	'PaidMth'		= NULL,
	'Hours'			= NULL,
	'Earnings'		= NULL,
	'Dedns'			= NULL,
	'SUIEarnings'	= NULL,
	'PostToAll'		= NULL,
	'Processed'		= NULL,
	'CMInterface'	= NULL,
	'EDLType'		= NULL,
	'EDLCode'		= NULL,
	'Amount'		= NULL,
	'UseOver'		= NULL,
	'OverAmt'		= NULL,
	'Name'			= HQCO.Name,
	'FedTaxId'		= HQCO.FedTaxId
FROM dbo.PRCO PRCO
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRCO.PRCo
WHERE PRCO.PRCo = @Co

UNION ALL


/* Third month in quarter (all quarters of the year) */

SELECT 
	'Month'			= 3,
	'PRCo'			= PRSQ.PRCo,
	'PRGroup'		= PRSQ.PRGroup,
	'PREndDate'		= PRSQ.PREndDate,
	'Employee'		= PRSQ.Employee,
	'PaySeq'		= PRSQ.PaySeq,
	'CMCo'			= PRSQ.CMCo,
	'CMAcct'		= PRSQ.CMAcct,
	'PayMethod'		= PRSQ.PayMethod,
	'CMRef'			= PRSQ.CMRef,
	'CMRefSeq'		= PRSQ.CMRefSeq,
	'EFTSeq'		= PRSQ.EFTSeq,
	'ChkType'		= PRSQ.ChkType,
	'PaidDate'		= (CASE WHEN PRSQ.PayMethod='X' AND PRSQ.PaidDate IS NULL THEN PRSQ.PREndDate ELSE PRSQ.PaidDate END),
	'PaidMth'		= PRSQ.PaidMth,
	'Hours'			= PRSQ.[Hours],
	'Earnings'		= PRSQ.Earnings,
	'Dedns'			= PRSQ.Dedns,
	'SUIEarnings'	= PRSQ.SUIEarnings,
	'PostToAll'		= PRSQ.PostToAll,
	'Processed'		= PRSQ.Processed,
	'CMInterface'	= PRSQ.CMInterface,
	'EDLType'		= PRDT.EDLType,
	'EDLCode'		= PRDT.EDLCode,
	'Amount'		= PRDT.Amount,
	'UseOver'		= PRDT.UseOver,
	'OverAmt'		= PRDT.OverAmt,
	'Name'			= HQCO.Name,
	'FedTaxId'		= HQCO.FedTaxId
FROM dbo.PRSQ PRSQ
JOIN dbo.PRDT PRDT ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRSQ.PRCo
WHERE PRSQ.PRCo = @Co
AND YEAR(PRSQ.PaidMth) = YEAR(@QtrEndMonth)
AND MONTH(PRSQ.PaidMth) IN (3,6,9,12)
AND PRDT.EDLType <> 'E'

UNION ALL

SELECT 
	'Month'			= 3,
	'PRCo'			= PRCO.PRCo,
	'PRGroup'		= NULL,
	'PREndDate'		= NULL,
	'Employee'		= NULL,
	'PaySeq'		= NULL,
	'CMCo'			= NULL,
	'CMAcct'		= NULL,
	'PayMethod'		= NULL,
	'CMRef'			= NULL,
	'CMRefSeq'		= NULL,
	'EFTSeq'		= NULL,
	'ChkType'		= NULL,
	'PaidDate'		= NULL,
	'PaidMth'		= NULL,
	'Hours'			= NULL,
	'Earnings'		= NULL,
	'Dedns'			= NULL,
	'SUIEarnings'	= NULL,
	'PostToAll'		= NULL,
	'Processed'		= NULL,
	'CMInterface'	= NULL,
	'EDLType'		= NULL,
	'EDLCode'		= NULL,
	'Amount'		= NULL,
	'UseOver'		= NULL,
	'OverAmt'		= NULL,
	'Name'			= HQCO.Name,
	'FedTaxId'		= HQCO.FedTaxId
FROM dbo.PRCO PRCO
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRCO.PRCo
WHERE PRCO.PRCo = @Co
GO
GRANT EXECUTE ON  [dbo].[vrptPR941SchB] TO [public]
GO
