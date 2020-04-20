SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvPRFlash_PRRO] as
   
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase1, PRRH.Phase1Units, 	PRRH.Phase1CostType, PRRH.Status, 
           PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 	PRRO.EarnCode, PRRO.Phase1Value,Record='1'
   from PRRO
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
    
   Union All
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo,
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase2, PRRH.Phase2Units, 	PRRH.Phase2CostType, PRRH.Status, 
           PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 	PRRO.EarnCode, PRRO.Phase1Value,Record='2'
   from PRRO 	
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   Union All
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase3, PRRH.Phase3Units, 
   	PRRH.Phase3CostType, PRRH.Status, PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 	PRRO.EarnCode, PRRO.Phase1Value,Record='3'
   from PRRO 
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   Union All
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase4, PRRH.Phase4Units, 	PRRH.Phase4CostType, PRRH.Status, PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 
   	PRRO.EarnCode, PRRO.Phase1Value,Record='4'
   from PRRO 
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   Union All
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase5, PRRH.Phase5Units, 	PRRH.Phase5CostType, PRRH.Status, PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 
   	PRRO.EarnCode, PRRO.Phase1Value,Record='5'
   from PRRO 
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   Union All
    
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase6, PRRH.Phase6Units, 
   	PRRH.Phase6CostType, PRRH.Status, PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 
   	PRRO.EarnCode, PRRO.Phase1Value,Record='6'
   from PRRO 
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   Union All
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase7, PRRH.Phase7Units, 	PRRH.Phase7CostType, PRRH.Status, PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 	PRRO.EarnCode, PRRO.Phase1Value,Record='7'
   from PRRO 
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   Union All
   select PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 
   	PRRH.Job, PRRH.Shift, PRRH.PhaseGroup, PRRH.Phase8, PRRH.Phase8Units, 	PRRH.Phase8CostType, PRRH.Status, PRRO.Employee, PRRO.LineSeq, PRRO.Craft, PRRO.Class, 
   	PRRO.EarnCode, PRRO.Phase1Value,Record='8'
   from PRRO 
   	join PRRH on 
   		PRRO.PRCo = PRRH.PRCo and PRRO.Crew = PRRH.Crew and 
   		PRRO.PostDate = PRRH.PostDate and PRRO.SheetNum = PRRH.SheetNum
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPRFlash_PRRO] TO [public]
GRANT INSERT ON  [dbo].[brvPRFlash_PRRO] TO [public]
GRANT DELETE ON  [dbo].[brvPRFlash_PRRO] TO [public]
GRANT UPDATE ON  [dbo].[brvPRFlash_PRRO] TO [public]
GO
