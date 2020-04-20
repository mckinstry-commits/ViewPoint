SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvPRDrillDown] AS

/**************************************************************************************

Author:			Unknown
Date Created:	Unknown
Reports:		PR Drilldown (PRDrillDown.rpt)

Purpose:		Returns employee header, accumulations, payment history, and employee
				pay sequence data for main (container) report in PR Drilldown.

Revision History      
Date		Author	Issue	Description
10/21/2010	CWW		140257	Added view vrvPREA_YearEndMonths to handle countries with
							reporting/tax-year ends other than December. Australia's 
							tax-year end is typically June 30.
05/12/2011	DML		134586	Added PRSQ; restructured for ease of use.
10/15/2011	CUC		B-10714	Reformatted for legibility; renamed column Ck# to CMRef;
							added PRGroup to join conditions within OUTER APPLY.

**************************************************************************************/

SELECT
	'src'				= 'EH',
	'PRCo'				= PREH.PRCo,
	'SortType'			= 1,
	'Employee'			= PREH.Employee,
	'Mth'				= '12/1/2050',
	'EDLType'			= NULL,
	'Code'				= PREH.Employee,
	'SubjectAmt'		= NULL,
	'EligibleAmt'		= NULL,
	'Hours'				= NULL,
	'Amount'			= NULL,
	'PRDate'			= NULL,
	'PaidDate'			= NULL,
	'Bank'				= NULL,
	'CMRef'				= NULL,
	'Vd'				= NULL,
	'VoidMemo'			= NULL,
	'PMeth'				= NULL,
	'CType'				= NULL,
	'Earnings'			= NULL,
	'NonTrue'			= NULL,
	'Dedns'				= NULL,
	'PaySeq'			= NULL,
	'PaidAmt'			= NULL,
	'PRGroup'			= NULL,
	'YearEndMth'		= NULL,
	'YearEndBeginMth'	= NULL,
	'QuarterOfYear'		= NULL,
	'PeriodOfYear'		= NULL,
	'YearEndMthOffset'	= NULL,
	'UniqueAttchID'		= NULL,
	'AttachmentID'		= NULL,
	'Description'		= NULL,
	'FormName'			= NULL
FROM dbo.PREH PREH
          
UNION      
           
SELECT
	'src'				= 'EA',
	'PRCo'				= PREA.PRCo,
	'SortType'			= 2,
	'Employee'			= PREA.Employee,
	'Mth'				= PREA.Mth,
	'EDLType'			= PREA.EDLType,
	'Code'				= PREA.EDLCode,
	'SubjectAmt'		= PREA.SubjectAmt,
	'EligibleAmt'		= PREA.EligibleAmt,
	'Hours'				= PREA.[Hours],
	'Amount'			= PREA.Amount,
	'PRDate'			= NULL,
	'PaidDate'			= NULL,
	'Bank'				= NULL,
	'CMRef'				= NULL,
	'Vd'				= NULL,
	'VoidMemo'			= NULL,
	'PMeth'				= NULL,
	'CType'				= NULL,
	'Earnings'			= NULL,
	'NonTrue'			= NULL,
	'Dedns'				= NULL,
	'PaySeq'			= NULL,
	'PaidAmt'			= NULL,
	'PRGroup'			= NULL,
	'YearEndMth'		= P.YearEndMth,
	'YearEndBeginMth'	= P.YearEndBeginMth,
	'QuarterOfYear'		= P.QuarterOfYear,
	'PeriodOfYear'		= P.PeriodOfYear,
	'YearEndMthOffset'	= P.YearEndMthOffset,
	'UniqueAttchID'		= NULL,
	'AttachmentID'		= NULL,
	'Description'		= NULL,
	'FormName'			= NULL
FROM dbo.PREA PREA
JOIN dbo.vrvPREA_YearEndMonths P ON PREA.PRCo = P.PRCo AND PREA.Mth = P.Mth

UNION

SELECT
	'src'				= 'PH',
	'PRCo'				= PRPH.PRCo,
	'SortType'			= 1,
	'Employee'			= PRPH.Employee,
	'Mth'				= PRPH.PaidMth,
	'EDLType'			= NULL,
	'Code'				= NULL,
	'SubjectAmt'		= NULL,
	'EligibleAmt'		= NULL, 
	'Hours'				= PRPH.[Hours],
	'Amount'			= NULL,
	'PRDate'			= PRPH.PREndDate,
	'PaidDate'			= PRPH.PaidDate,
	'Bank'				= PRPH.CMAcct,
	'CMRef'				= PRPH.CMRef,
	'Vd'				= PRPH.Void,
	'VoidMemo'			= PRPH.VoidMemo,
	'PMeth'				= PRPH.PayMethod,
	'CType'				= PRPH.ChkType,
	'Earnings'			= PRPH.Earnings,
	'NonTrue'			= PRPH.NonTrueAmt,
	'Dedns'				= PRPH.Dedns,
	'PaySeq'			= PRPH.PaySeq,
	'PaidAmt'			= PRPH.PaidAmt,
	'PRGroup'			= PRPH.PRGroup,
	'YearEndMth'		= P.YearEndMth,
	'YearEndBeginMth'	= P.YearEndBeginMth,
	'QuarterOfYear'		= P.QuarterOfYear,
	'PeriodOfYear'		= P.PeriodOfYear,
	'YearEndMthOffset'	= P.YearEndMthOffset,
	'UniqueAttchID'		= NULL,
	'AttachmentID'		= NULL,
	'Description'		= NULL,
	'FormName'			= NULL
FROM dbo.PRPH PRPH
JOIN dbo.vrvPREA_YearEndMonths P ON PRPH.PRCo = P.PRCo AND PRPH.PaidMth = P.Mth      
    
UNION    
    
SELECT
	'src'				= 'SQ',
	'PRCo'				= PRSQ.PRCo,
	'SortType'			= 1,
	'Employee'			= PRSQ.Employee,
	'Mth'				= PRSQ.PaidMth,
	'EDLType'			= NULL,
	'Code'				= NULL,
	'SubjectAmt'		= NULL,
	'EligibleAmt'		= NULL, 
	'Hours'				= PRSQ.[Hours],
	'Amount'			= NULL,
	'PRDate'			= PRSQ.PREndDate,
	'PaidDate'			= PRSQ.PaidDate,
	'Bank'				= PRSQ.CMAcct,
	'CMRef'				= PRSQ.CMRef,
	'Vd'				= NULL,
	'VoidMemo'			= NULL,
	'PMeth'				= PRSQ.PayMethod,
	'CType'				= PRSQ.ChkType,
	'Earnings'			= PRSQ.Earnings,
	'NonTrue'			= NULL,
	'Dedns'				= PRSQ.Dedns,
	'PaySeq'			= PRSQ.PaySeq,
	'PaidAmt'			= NULL,
	'PRGroup'			= PRSQ.PRGroup,
	'YearEndMth'		= P.YearEndMth,
	'YearEndBeginMth'	= P.YearEndBeginMth,
	'QuarterOfYear'		= P.QuarterOfYear,
	'PeriodOfYear'		= P.PeriodOfYear,
	'YearEndMthOffset'	= P.YearEndMthOffset,
	'UniqueAttchID'		= PRSQ.UniqueAttchID,
	'AttachmentID'		= ATTCH.MaxAttachmentID,
	'Description'		= HQAT.[Description],
	'FormName'			= HQAT.FormName
FROM dbo.PRSQ PRSQ
JOIN dbo.vrvPREA_YearEndMonths P ON PRSQ.PRCo = P.PRCo AND PRSQ.PaidMth = P.Mth
LEFT JOIN dbo.PRPH PRPH ON PRSQ.PRCo = PRPH.PRCo
					AND PRSQ.PRGroup = PRPH.PRGroup
					AND PRSQ.PREndDate = PRPH.PREndDate
					AND PRSQ.Employee = PRPH.Employee
					AND PRSQ.PaySeq = PRPH.PaySeq
					AND PRSQ.CMRef = PRPH.CMRef
OUTER APPLY (
	SELECT a.UniqueAttchID, MAX(a.AttachmentID) AS MaxAttachmentID
	FROM dbo.HQAT a    
	JOIN dbo.PRSQ b ON a.UniqueAttchID = b.UniqueAttchID
	WHERE b.PRCo = PRSQ.PRCo
		AND b.PRGroup = PRSQ.PRGroup
		AND b.PREndDate = PRSQ.PREndDate
		AND b.Employee = PRSQ.Employee
		AND b.PaySeq = PRSQ.PaySeq
		AND b.CMRef = PRSQ.CMRef
		AND b.UniqueAttchID = PRSQ.UniqueAttchID
	GROUP BY a.UniqueAttchID
) ATTCH
LEFT JOIN dbo.HQAT ON ATTCH.UniqueAttchID = HQAT.UniqueAttchID AND ATTCH.MaxAttachmentID = HQAT.AttachmentID
GO
GRANT SELECT ON  [dbo].[brvPRDrillDown] TO [public]
GRANT INSERT ON  [dbo].[brvPRDrillDown] TO [public]
GRANT DELETE ON  [dbo].[brvPRDrillDown] TO [public]
GRANT UPDATE ON  [dbo].[brvPRDrillDown] TO [public]
GRANT SELECT ON  [dbo].[brvPRDrillDown] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRDrillDown] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRDrillDown] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRDrillDown] TO [Viewpoint]
GO
