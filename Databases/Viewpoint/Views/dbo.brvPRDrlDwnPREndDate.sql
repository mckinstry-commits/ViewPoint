SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvPRDrlDwnPREndDate] AS

/**************************************************************************************

Author:			CR
Date Created:	04/11/2002
Reports:		PR Drilldown (PRDrillDown.rpt)

Purpose:		Returns employee pay sequence and timecard data for subreport
				PRRegister in report PR Drilldown.

Revision History      
Date		Author	Issue	Description
n/a			CR		23640	Added Case statement.
n/a			CR		25956	Added Attachment info.
05/12/2012	DML		134586	Added more PRTH fields necessary for subreport PRRegister
							in PRDrilldown.rpt
10/15/2011	CUC		B-10714	Added new SELECT statement so that payback deductions are
							included; added new column DednType to permit relative
							ordering of regular deduction (first) and payback deduction
							(second) for a mated pair sharing the same deduction code;
							reformatted for legibility.

**************************************************************************************/

SELECT				--Employee pay sequence detail (top of subreport) for earns, dedns, liabs; includes regular (non-payback) deductions
	'PRCo'			= PRDT.PRCo,
	'PRGroup'		= PRDT.PRGroup,
	'PREndDate'		= PRDT.PREndDate,
	'Employee'		= PRDT.Employee,
	'SortType'		= 1,
	'PaySeq'		= PRDT.PaySeq,
	'PostSeq'		= NULL,
	'PostDate'		= NULL,
	'EDLType'		= PRDT.EDLType,
	'EDLCode'		= PRDT.EDLCode,
	'DednType'		= (CASE WHEN PRDT.EDLType = 'D' THEN '1-RegularDedn' ELSE NULL END),
	'Hours'			= PRDT.[Hours],
	'Amount'		= (CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END),
	'Job'			= NULL,
	'OldAmt'		= PRDT.OldAmt,
	'Phase'			= NULL,
	'UniqueAttchID'	= NULL,
	'AttachmentID'	= NULL,
	'Description'	= NULL,
	'DocName'		= NULL,
	'JCCo'			= NULL,
	'InsState'		= NULL,
	'InsCode'		= NULL,
	'Craft'			= NULL,
	'Class'			= NULL,
	'EarnCode'		= NULL,
	'Rate'			= NULL,
	'Amt'			= NULL
FROM dbo.PRDT PRDT WITH(NOLOCK)
       
UNION ALL

SELECT				--Employee pay sequence detail (top of subreport) for payback deductions only
	'PRCo'			= PRDT.PRCo,
	'PRGroup'		= PRDT.PRGroup,
	'PREndDate'		= PRDT.PREndDate,
	'Employee'		= PRDT.Employee,
	'SortType'		= 1,
	'PaySeq'		= PRDT.PaySeq,
	'PostSeq'		= NULL,
	'PostDate'		= NULL,
	'EDLType'		= PRDT.EDLType,
	'EDLCode'		= PRDT.EDLCode,
	'DednType'		= '2-PaybackDedn',
	'Hours'			= PRDT.[Hours],
	'Amount'		= (CASE WHEN PRDT.PaybackOverYN = 'Y' THEN PRDT.PaybackOverAmt ELSE PRDT.PaybackAmt END),
	'Job'			= NULL,
	'OldAmt'		= NULL,  --OldAmt for given dedn row returned by SELECT above
	'Phase'			= NULL,
	'UniqueAttchID'	= NULL,
	'AttachmentID'	= NULL,
	'Description'	= NULL,
	'DocName'		= NULL,
	'JCCo'			= NULL,
	'InsState'		= NULL,
	'InsCode'		= NULL,
	'Craft'			= NULL,
	'Class'			= NULL,
	'EarnCode'		= NULL,
	'Rate'			= NULL,
	'Amt'			= NULL
FROM dbo.PRDT PRDT WITH(NOLOCK)
WHERE PRDT.EDLType = 'D'
--Include payback row if there is a non-zero payback amount or if payback override flag is set
AND (PRDT.PaybackAmt <> 0 OR PRDT.PaybackOverYN = 'Y')
       
UNION ALL
       
SELECT				--Timecard header information (bottom of subreport)
	'PRCo'			= PRTH.PRCo,
	'PRGroup'		= PRTH.PRGroup,
	'PREndDate'		= PRTH.PREndDate,
	'Employee'		= PRTH.Employee,
	'SortType'		= 2,
	'PaySeq'		= PRTH.PaySeq,
	'PostSeq'		= PRTH.PostSeq,
	'PostDate'		= PRTH.PostDate,
	'EDLType'		= NULL,
	'EDLCode'		= NULL,
	'DednType'		= NULL,
	'Hours'			= PRTH.[Hours],
	'Amount'		= NULL,
	'Job'			= PRTH.Job,
	'OldAmt'		= NULL,
	'Phase'			= PRTH.Phase,
	'UniqueAttchID'	= PRTH.UniqueAttchID,
	'AttachmentID'	= HQAT.AttachmentID,
	'Description'	= HQAT.[Description],
	'DocName'		= HQAT.DocName,
	'JCCo'			= PRTH.JCCo,
	'InsState'		= PRTH.InsState,
	'InsCode'		= PRTH.InsCode,
	'Craft'			= PRTH.Craft,
	'Class'			= PRTH.Class,
	'EarnCode'		= PRTH.EarnCode,
	'Rate'			= PRTH.Rate,
	'Amt'			= PRTH.Amt
FROM dbo.PRTH PRTH WITH(NOLOCK)
LEFT JOIN dbo.HQAT HQAT WITH(NOLOCK) ON PRTH.UniqueAttchID = HQAT.UniqueAttchID
GO
GRANT SELECT ON  [dbo].[brvPRDrlDwnPREndDate] TO [public]
GRANT INSERT ON  [dbo].[brvPRDrlDwnPREndDate] TO [public]
GRANT DELETE ON  [dbo].[brvPRDrlDwnPREndDate] TO [public]
GRANT UPDATE ON  [dbo].[brvPRDrlDwnPREndDate] TO [public]
GO
