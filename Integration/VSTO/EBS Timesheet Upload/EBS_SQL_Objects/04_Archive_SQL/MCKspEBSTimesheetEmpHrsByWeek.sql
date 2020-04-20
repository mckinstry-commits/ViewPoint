USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspEBSTimesheetEmpHrsByWeek' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspEBSTimesheetEmpHrsByWeek'
	DROP PROCEDURE dbo.MCKspEBSTimesheetEmpHrsByWeek
End
GO

Print 'CREATE PROCEDURE dbo.MCKspEBSTimesheetEmpHrsByWeek'
GO


CREATE Procedure [dbo].[MCKspEBSTimesheetEmpHrsByWeek]
AS
/*
	CREATED: 12/19/2017
	PURPOSE: Get employee total hours by week EBS timesheet detail data
	HISTORY:
	01.11.18	- group Company tabs; one row per employee w/ total Hours per week
*/
Begin

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- get detail data
SELECT
		 ISNULL(PREH.PRCo, 1) AS 'Co'  

		, CAST(ebs.EMPLOYEENUMBER AS INT) AS 'Employee'

		, SUM((ebs.ACTUALHOURS/60)) as 'WeekHrs'

FROM [SESQL08].[EZTrack].[dbo].vMcKPosting ebs 
--FROM [SESQL08].[EZTrack].[dbo].vMcKPosting_Testing_20171126 ebs --USED AS Testing Table Only
	LEFT OUTER JOIN PREH PREH 
			-- used bPREH for TESTING ONLY
		ON ebs.EMPLOYEENUMBER = CAST(PREH.Employee as nvarchar)
	LEFT OUTER JOIN HQCO HQCO
		ON PREH.PRCo = HQCO.HQCo
	LEFT OUTER JOIN JCJM 
		ON CASE WHEN CHARINDEX('-',ebs.LEVEL5) = 6 THEN ' '+ ebs.LEVEL5 
			ELSE ebs.LEVEL5 END = JCJM.Job COLLATE SQL_Latin1_General_CP1_CI_AS
	LEFT OUTER JOIN HQCO HQCOJob 
		ON JCJM.JCCo = HQCOJob.HQCo

WHERE HQCO.udTESTCo = 'N'      
	AND (JCJM.JCCo is null or HQCOJob.udTESTCo = 'N')
	AND ((PREH.ActiveYN = 'Y') or (PREH.ActiveYN IS NULL))

Group by PREH.PRCo, ebs.EMPLOYEENUMBER
Order by PREH.PRCo, ebs.EMPLOYEENUMBER

End


GO


Grant EXECUTE ON dbo.MCKspEBSTimesheetEmpHrsByWeek TO [MCKINSTRY\Viewpoint Users]