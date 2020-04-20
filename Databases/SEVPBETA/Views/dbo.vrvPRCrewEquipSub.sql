SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	Extract equipment usage data related to the
	associated Crew timesheet.  
	
	NOTE:
	This view was written so the Nolock option in SQL Server
	could be applied and advoid data base contention issues.
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	2/26/08	125224	New
********************************************************************/
CREATE  view [dbo].[vrvPRCrewEquipSub] as
--** 

 SELECT PRRQ.Employee
, EMEM.Description, PRRQ.EMCo, PRRQ.Equipment, PRRQ.PRCo, PRRQ.Crew
, PRRQ.PostDate AS PostDatePRRQ
, PRRQ.SheetNum
, PRRQ.Phase1Usage, PRRQ.Phase2Usage, PRRQ.Phase3Usage, PRRQ.Phase4Usage
, PRRQ.Phase5Usage, PRRQ.Phase6Usage, PRRQ.Phase7Usage, PRRQ.Phase8Usage
, PRRQ.Phase1CType, PRRQ.Phase2CType, PRRQ.Phase3CType, PRRQ.Phase4CType
, PRRQ.Phase5CType, PRRQ.Phase6CType, PRRQ.Phase7CType, PRRQ.Phase8CType
, PRRH.Phase1, PRRH.Phase2, PRRH.Phase3, PRRH.Phase4
, PRRH.Phase5, PRRH.Phase6, PRRH.Phase7, PRRH.Phase8
, PRRQ.Phase1Rev, PRRQ.Phase2Rev, PRRQ.Phase3Rev, PRRQ.Phase4Rev
, PRRQ.Phase5Rev, PRRQ.Phase6Rev, PRRQ.Phase7Rev, PRRQ.Phase8Rev
, PRRH.PostDate AS PostDatePRRH
 FROM    (PRRQ PRRQ (Nolock)
LEFT OUTER JOIN PRRH PRRH (Nolock)
	ON (((PRRQ.PRCo=PRRH.PRCo) AND (PRRQ.Crew=PRRH.Crew)) 
		AND (PRRQ.PostDate=PRRH.PostDate)) AND (PRRQ.SheetNum=PRRH.SheetNum)) 
LEFT OUTER JOIN EMEM EMEM (Nolock)
	ON (PRRQ.EMCo=EMEM.EMCo) AND (PRRQ.Equipment=EMEM.Equipment)
 



GO
GRANT SELECT ON  [dbo].[vrvPRCrewEquipSub] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCrewEquipSub] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCrewEquipSub] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCrewEquipSub] TO [public]
GO
