SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          view [dbo].[brvEmpAcc] as select PRTH.PRCo, PRTH.Employee, Date=PRTH.PREndDate, PRTH.PostDate,
   Accident=null, AccidentDate ='1/1/1950', Preventable=null, 
   AccidentType=null, PRTH.Hours, PRTH.Job, PRTH.Crew, PRTH.Craft, PRTH.Class, PRTH.PaySeq, PRTH.PostSeq
    
   From
   PRTH
   
   
   Union all 
   
   select HRRM.PRCo, HRRM.PREmp,  '1/1/1950', null, HRAT.Accident,HRAT.AccidentDate, HRAI.PreventableYN,
   HRAI.Type, null,null, PRCrew.Crew,null,null,null,null
   From 
   HRRM
   
   Join HRAI on HRAI.HRCo=HRRM.HRCo and HRAI.HRRef=HRRM.HRRef
   Join HRAT on HRAT.HRCo=HRAI.HRCo and HRAT.Accident=HRAI.Accident
   Left join (select PRTH.PRCo, PRTH.Employee, PRTH.PostDate, Crew=Min(PRTH.Crew), Job=Min(PRTH.Job) 
   from PRTH Group by PRTH.PRCo, PRTH.Employee, PRTH.PostDate) as PRCrew
     on PRCrew.PRCo=HRRM.PRCo and HRRM.PREmp=PRCrew.Employee and  HRAT.AccidentDate=PRCrew.PostDate

GO
GRANT SELECT ON  [dbo].[brvEmpAcc] TO [public]
GRANT INSERT ON  [dbo].[brvEmpAcc] TO [public]
GRANT DELETE ON  [dbo].[brvEmpAcc] TO [public]
GRANT UPDATE ON  [dbo].[brvEmpAcc] TO [public]
GRANT SELECT ON  [dbo].[brvEmpAcc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEmpAcc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEmpAcc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEmpAcc] TO [Viewpoint]
GO
