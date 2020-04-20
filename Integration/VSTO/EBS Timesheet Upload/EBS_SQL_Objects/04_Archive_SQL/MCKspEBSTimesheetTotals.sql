USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspEBSTimesheetTotals' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspEBSTimesheetTotals'
	DROP PROCEDURE dbo.MCKspEBSTimesheetTotals
End
GO

Print 'CREATE PROCEDURE dbo.MCKspEBSTimesheetTotals'
GO


CREATE Procedure [dbo].[MCKspEBSTimesheetTotals]
AS
/*
	CREATED: 8/15/2017
	PURPOSE: Adapted query originally made by Theresa Parker to pull EBS timesheet detail data. This is the summary totals.
	HISTORY:
	8.15.17	 - sum totals - Leog 
*/
Begin

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- get detail data
With cte ([1-Co], [2-Employee], [3-PREndDate], [4-DayNum], [5-JCCo], [6-Job], [7-Phase], [8-PAYCODE], [9-Hours], [10-PRGroup])
AS
(
SELECT
		  CASE WHEN PREH.PRCo is null then 1 ELSE PREH.PRCo END AS '1-Co'  
		, ebs.EMPLOYEENUMBER AS '2-Employee'
		, ebs.PERIODEND AS '3-PREndDate'
		, ebs.CHARGEDAYOFWEEK AS '4-DayNum'
		, ISNULL(JCJM.JCCo, ebs.EMPLOYERCODE) AS '5-JCCo'
		, CASE WHEN JCJM.JCCo IS NULL THEN '' 
				ELSE ebs.LEVEL5 END AS '6-Job'
		, CASE WHEN charindex(':',ebs.LEVEL6) = 0 THEN ''
				ELSE substring(ebs.LEVEL6,1,charindex(':',ebs.LEVEL6)-1) END AS '7-Phase'
		, ebs.PAYCODE as '8-PAYCODE'
		, (ebs.ACTUALHOURS/60) as '9-Hours'
		, 1 as '10-PRGroup'
FROM [SESQL08].[EZTrack].[dbo].vMcKPosting ebs
--FROM [SESQL08].[EZTrack].[dbo].vMcKPosting_Testing_20171126 ebs  
		--[SESQL08].[EZTrack].[dbo].vMcKPosting_Testing ebs   FOR TESTING ONLY
	LEFT OUTER JOIN PREH PREH 
		-- LEFT OUTER JOIN bPREH PREH                         FOR TESTING ONLY
		ON ebs.EMPLOYEENUMBER = cast(PREH.Employee as nvarchar)
	LEFT OUTER JOIN HQCO HQCO
		ON PREH.PRCo = HQCO.HQCo
	LEFT OUTER JOIN JCJM 
		ON CASE WHEN charindex('-',ebs.LEVEL5) = 6 THEN ' '+ ebs.LEVEL5 
			ELSE ebs.LEVEL5 END = JCJM.Job COLLATE SQL_Latin1_General_CP1_CI_AS
	LEFT OUTER JOIN HQCO HQCOJob 
		ON JCJM.JCCo = HQCOJob.HQCo
WHERE HQCO.udTESTCo = 'N'      --/*((HQCO.udTESTCo IS NULL) or (*/HQCO.udTESTCo = 'N'/*))*/  
	AND (JCJM.JCCo is null or HQCOJob.udTESTCo = 'N')
	AND ((PREH.ActiveYN = 'Y') or (PREH.ActiveYN IS NULL))
)
Select 
  [1-Co] As Company
--, FORMAT(COUNT([1-Co]), '#,###') As Rows
--, FORMAT(SUM([9-Hours]), '#,###.#00000') As Hours
, COUNT([1-Co]) As Rows
, SUM([9-Hours]) As Hours
From cte
Group by [1-Co]

End

GO

Grant EXECUTE ON dbo.MCKspEBSTimesheetTotals TO [MCKINSTRY\Viewpoint Users]

--exec dbo.MCKspEBSTimesheetTotals