SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvPRFlash_RRRE] as
   select
   	PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 	PRRH.Job,PRRH.PhaseGroup, Phase = PRRH.Phase1,  PhaseUnits=PRRH.Phase1Units, 	CostType=PRRH.Phase1CostType, Record='1',PRRH.Status, PRRE.Employee, PRRE.LineSeq, 	PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase1RegHrs, OT_Hrs=PRRE.Phase1OTHrs, 
   	Dbl_Hrs= PRRE.Phase1DblHrs, PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
       left outer join PRRH on 
   	PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           	PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   UNION ALL
   select
   	PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 	PRRH.Job, PRRH.PhaseGroup, Phase = PRRH.Phase2, PhaseUnits=PRRH. Phase2Units, 	CostType=PRRH.Phase2CostType, Record='2',PRRH.Status, PRRE.Employee, PRRE.LineSeq, 	PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase2RegHrs, OT_Hrs=PRRE.Phase2OTHrs, 
   	Dbl_Hrs= PRRE.Phase2DblHrs, PRRE.RegRate,  PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           		PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum
   where PRRH.Status < 4  
   
   UNION ALL
   select
   	PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, 	PRRH.Job,PRRH. PhaseGroup, Phase = PRRH.Phase3, PhaseUnits=PRRH.Phase3Units, 	CostType=PRRH. Phase3CostType,Record='3', PRRH.Status, PRRE.Employee, PRRE.LineSeq, 	PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase3RegHrs, 	OT_Hrs=PRRE.Phase3OTHrs, 	Dbl_Hrs= PRRE.Phase3DblHrs, PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           		PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   UNION ALL
   select
   PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, PRRH.Job,PRRH.PhaseGroup, Phase = PRRH.Phase4, PhaseUnits=PRRH. Phase4Units, CostType=PRRH.Phase4CostType, Record='4', PRRH.Status, PRRE.Employee, PRRE.LineSeq, PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase4RegHrs, OT_Hrs=PRRE.Phase4OTHrs,
   Dbl_Hrs= PRRE.Phase4DblHrs, PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           		PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   UNION ALL
    
   select
   PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, PRRH.Job,PRRH.PhaseGroup, Phase = PRRH.Phase5, PhaseUnits=PRRH.Phase5Units, CostType=PRRH.Phase5CostType, Record='5', PRRH.Status, PRRE.Employee, PRRE.LineSeq, PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase5RegHrs, OT_Hrs=PRRE.Phase5OTHrs,
   Dbl_Hrs= PRRE.Phase5DblHrs, PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           		PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   UNION ALL
   select
   PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, PRRH.Job,PRRH.PhaseGroup, Phase = PRRH.Phase6,  PhaseUnits=PRRH.Phase6Units, CostType=PRRH.Phase6CostType, Record='6',PRRH.Status, PRRE.Employee, PRRE.LineSeq, PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase6RegHrs, OT_Hrs=PRRE.Phase6OTHrs,
   Dbl_Hrs= PRRE.Phase6DblHrs, PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           	PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   UNION ALL
   select
   PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, PRRH.Job,PRRH.PhaseGroup, Phase = PRRH.Phase7, PhaseUnits=PRRH. Phase7Units, CostType=PRRH.Phase7CostType,Record='7',PRRH.Status, PRRE.Employee, PRRE.LineSeq, PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase7RegHrs, OT_Hrs=PRRE.Phase7OTHrs,
   Dbl_Hrs= PRRE.Phase7DblHrs, PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           		PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   UNION ALL
   select
   PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.PRGroup, PRRH.JCCo, PRRH.Job,PRRH.PhaseGroup, Phase = PRRH.Phase8, PhaseUnits=PRRH.Phase8Units, CostType=PRRH. Phase8CostType,Record='8',PRRH.Status, PRRE.Employee, PRRE.LineSeq, PRRE.Craft, PRRE.Class, RegHrs = PRRE.Phase8RegHrs, OT_Hrs=PRRE.Phase8OTHrs,
   Dbl_Hrs= PRRE.Phase8DblHrs,PRRE.RegRate, PRRE.OTRate, PRRE.DblRate
   from PRRE  
   	left outer join PRRH on 
   		PRRH.PRCo = PRRE.PRCo and PRRH.Crew = PRRE.Crew and
           		PRRH.PostDate = PRRE.PostDate and PRRH.SheetNum = PRRE.SheetNum 
   where PRRH.Status < 4
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPRFlash_RRRE] TO [public]
GRANT INSERT ON  [dbo].[brvPRFlash_RRRE] TO [public]
GRANT DELETE ON  [dbo].[brvPRFlash_RRRE] TO [public]
GRANT UPDATE ON  [dbo].[brvPRFlash_RRRE] TO [public]
GRANT SELECT ON  [dbo].[brvPRFlash_RRRE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRFlash_RRRE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRFlash_RRRE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRFlash_RRRE] TO [Viewpoint]
GO
