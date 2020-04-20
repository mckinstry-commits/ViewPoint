SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	Extract Non-Job Earnings data related to the
	associated Crew timesheet.  
	
	NOTE:
	This view was written remove the SQL from Crystal report
	PR Crew Timesheet Entry List and apply the Nolock option 
	in SQL Server to advoid data base contention issues.
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	2/26/08	125224	New
********************************************************************/
CREATE view [dbo].[vrvPRCrewNonJobEarnings] as
--** 

 SELECT PRRN.Employee, PREHName.Suffix
, PREHName.LastName, PREHName.FirstName, PREHName.MidName
, PRRN.Class, PRRN.EarnCode
, PREC.Description
, PRRN.Hours, PRRN.StdPayRate, PRRN.PRCo
, PRRN.Crew
, PRRN.PostDate AS PostDatePRRN
, PRRN.SheetNum
, PRRH.PostDate AS PostDatePRRH
 FROM   ((PRRN PRRN (Nolock)
INNER JOIN PRRH PRRH (Nolock) 
	ON (((PRRN.PRCo=PRRH.PRCo) AND (PRRN.Crew=PRRH.Crew)) 
		AND (PRRN.PostDate=PRRH.PostDate)) AND (PRRN.SheetNum=PRRH.SheetNum)) 
INNER JOIN PREHName PREHName (Nolock) 
	ON (PRRN.PRCo=PREHName.PRCo) AND (PRRN.Employee=PREHName.Employee)) 
INNER JOIN PREC PREC (Nolock)
	ON (PRRN.PRCo=PREC.PRCo) AND (PRRN.EarnCode=PREC.EarnCode)
 


GO
GRANT SELECT ON  [dbo].[vrvPRCrewNonJobEarnings] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCrewNonJobEarnings] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCrewNonJobEarnings] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCrewNonJobEarnings] TO [public]
GO
