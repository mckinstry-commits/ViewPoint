USE [Viewpoint]
GO

IF EXISTS ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='MCKspEBSTimesheetEmpHrsByWeek' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )

Begin
	print 'DROP PROCEDURE dbo.MCKspEBSTimesheetEmpHrsByWeek'
	DROP PROCEDURE dbo.MCKspEBSTimesheetEmpHrsByWeek
End
GO

Print 'CREATE PROCEDURE dbo.MCKspEBSTimesheetEmpHrsByWeek'
GO

CREATE Procedure [dbo].[MCKspEBSTimesheetEmpHrsByWeek]
AS
/*
	PURPOSE: Get employee total hours by week EBS timesheet detail data
	CREATED: 12/19/2017
	HISTORY:
	08.14.18 LG - exclude company 90 #101986
	01.11.18 LG - Group Company tabs; one row per employee w/ total Hours per week
	12.19.17	LG - group employee total hours by week
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

BEGIN

	SELECT
			  ISNULL(PREH.PRCo, 1) AS 'Co'  
			, CAST(ebs.EMPLOYEENUMBER AS INT) AS 'Employee'
			, SUM((ebs.ACTUALHOURS/60)) as 'WeekHrs'
	FROM [SESQL08].[EZTrack].[dbo].vMcKPosting ebs 
	--FROM [SESQL08].[EZTrack].[dbo].vMcKPosting_Testing_20171126 ebs --USED AS Testing Table Only
		LEFT OUTER JOIN PREH PREH -- used bPREH for TESTING ONLY
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
		AND PREH.PRCo <> 90 -- #101986
	Group by PREH.PRCo, ebs.EMPLOYEENUMBER
	Order by PREH.PRCo, ebs.EMPLOYEENUMBER

END

SET NOCOUNT OFF

GO


Grant EXECUTE ON dbo.MCKspEBSTimesheetEmpHrsByWeek TO [MCKINSTRY\Viewpoint Users]

GO
