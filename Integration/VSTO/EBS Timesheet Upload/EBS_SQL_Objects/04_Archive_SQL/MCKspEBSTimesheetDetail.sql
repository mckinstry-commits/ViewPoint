USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspEBSTimesheetDetail' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspEBSTimesheetDetail'
	DROP PROCEDURE dbo.MCKspEBSTimesheetDetail
End
GO

Print 'CREATE PROCEDURE dbo.MCKspEBSTimesheetDetail'
GO


CREATE Procedure [dbo].[MCKspEBSTimesheetDetail]
--(
	--@company dbo.bCompany
--)
AS
/*
	CREATED: 8/15/2017
	PURPOSE: Pulls EBS timesheet detail data
	HISTORY:
	8.15.17	- unmodified query originally made by Theresa Parker
	8.29.17	- add @co input param for filtered results
	11.30.17	- pull sample data from vMcKPosting_Testing_20171126 for VSTO code changes
*/
Begin

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--Declare @co varchar(3) = convert(varchar, @company);

-- get detail data

SELECT
		  CASE WHEN PREH.PRCo is null then 1 
				ELSE PREH.PRCo END AS '1-Co'  
		, CAST(ebs.EMPLOYEENUMBER AS INT) AS '2-Employee'
		--CAST('2006-04-25T15:50:59.997' AS datetime)
		--, CAST(ebs.PERIODEND AS nvarchar(30)) AS '3-PREndDate'
		, CONVERT(VARCHAR(10), ebs.PERIODEND, 101) AS '3-PREndDate'
		, ebs.CHARGEDAYOFWEEK AS '4-DayNum'
		, CAST(ISNULL(JCJM.JCCo, ebs.EMPLOYERCODE) AS INT) AS '5-JCCo'
		, CASE WHEN JCJM.JCCo IS NULL THEN '' 
				ELSE ebs.LEVEL5 END AS '6-Job'
		, CASE WHEN charindex(':',ebs.LEVEL6) = 0 THEN ''
				ELSE substring(ebs.LEVEL6,1,charindex(':',ebs.LEVEL6)-1) END AS '7-Phase'
		, ebs.PAYCODE as '8-PAYCODE'
		, (ebs.ACTUALHOURS/60) as '9-Hours'
		, 1 as '10-PRGroup'
FROM [SESQL08].[EZTrack].[dbo].vMcKPosting ebs  
--FROM [SESQL08].[EZTrack].[dbo].vMcKPosting_Testing_20171126 ebs  -- USED AS Testing Table Only
			--[SESQL08].[EZTrack].[dbo].vMcKPosting_Testing ebs     USED AS Testing Table Only
	LEFT OUTER JOIN PREH PREH 
			-- used bPREH for TESTING ONLY
		ON ebs.EMPLOYEENUMBER = cast(PREH.Employee as nvarchar)
	LEFT OUTER JOIN HQCO HQCO
		ON PREH.PRCo = HQCO.HQCo
	LEFT OUTER JOIN JCJM 
		ON CASE WHEN charindex('-',ebs.LEVEL5) = 6 THEN ' '+ ebs.LEVEL5 
			ELSE ebs.LEVEL5 END = JCJM.Job COLLATE SQL_Latin1_General_CP1_CI_AS
	LEFT OUTER JOIN HQCO HQCOJob 
		ON JCJM.JCCo = HQCOJob.HQCo
WHERE HQCO.udTESTCo = 'N'      --/*((HQCO.udTESTCo IS NULL) or (*/HQCO.udTESTCo = 'N'/*))*/  
--WHERE ((HQCO.udTESTCo IS NULL) or (HQCO.udTESTCo = 'N')) 
	AND (JCJM.JCCo is null or HQCOJob.udTESTCo = 'N')
	AND ((PREH.ActiveYN = 'Y') or (PREH.ActiveYN IS NULL))
	--AND PREH.PRCo=1
END

--exec dbo.MCKspEBSTimesheetDetail 20

GO


Grant EXECUTE ON dbo.MCKspEBSTimesheetDetail TO [MCKINSTRY\Viewpoint Users]