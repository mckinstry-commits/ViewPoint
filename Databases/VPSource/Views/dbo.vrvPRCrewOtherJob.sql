SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	Extract Other Job Earnings data related to the
	associated Crew timesheet.  
	
	NOTE:
	This view was written remove the SQL from Crystal report
	PR Crew Timesheet Entry List and apply the Nolock option 
	in SQL Server to advoid data base contention issues.
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	2/26/08	125224	New
********************************************************************/
CREATE  view [dbo].[vrvPRCrewOtherJob] as
--** 

 SELECT PRRO.Employee, PREHName.Suffix
, PREHName.LastName, PREHName.FirstName, PREHName.MidName
, PRRO.Class, PRRO.EarnCode
, PREC.Description
, PRRO.Phase1Value, PRRO.Phase2Value, PRRO.Phase3Value, PRRO.Phase4Value
, PRRO.Phase5Value, PRRO.Phase6Value, PRRO.Phase7Value, PRRO.Phase8Value
, PRRO.PRCo, PRRO.Crew, PRRO.PostDate, PRRO.SheetNum
, PRRH.Phase1, PRRH.Phase2, PRRH.Phase3, PRRH.Phase4
, PRRH.Phase5, PRRH.Phase6, PRRH.Phase7, PRRH.Phase8
 FROM   ((PRRO PRRO (Nolock) 
INNER JOIN PRRH PRRH (Nolock) 
	ON (((PRRO.PRCo=PRRH.PRCo) AND (PRRO.Crew=PRRH.Crew)) 
		AND (PRRO.PostDate=PRRH.PostDate)) AND (PRRO.SheetNum=PRRH.SheetNum)) 
INNER JOIN PREHName PREHName (Nolock) 
	ON (PRRO.PRCo=PREHName.PRCo) AND (PRRO.Employee=PREHName.Employee)) 
INNER JOIN PREC PREC (Nolock) 
	ON (PRRO.PRCo=PREC.PRCo) AND (PRRO.EarnCode=PREC.EarnCode)



GO
GRANT SELECT ON  [dbo].[vrvPRCrewOtherJob] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCrewOtherJob] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCrewOtherJob] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCrewOtherJob] TO [public]
GO
