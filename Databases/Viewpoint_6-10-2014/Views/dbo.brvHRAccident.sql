SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  view [dbo].[brvHRAccident] as
   
   select HQCO.Name, HQCO.City, HQCO.State, HQCO.Address, HQCO.Zip,
   HRATAccident = '', HRAISeq=0, LastName='', FirstName='',PositionCode='',
   JobTitle='', AccidentDate='12/1/2050 12:00:00AM', Fatality='', Days=0, HRALType='',
   HRRef=0, AccidentType='R', HRAIType='O', 
   Location='', PRCo=0, HRAIAccident='',HRALSeq=0,HRALDaySeq=0,
   IllnessInjury='', IllnessType='', HQCo=HQCO.HQCo,
   OSHALocation=' ', IllnessInjuryDesc=''
   
   from HQCO 
   Inner Join HRAT on HRAT.HRCo=HQCO.HQCo
   
   Union all
   
    SELECT HQCO.Name, HQCO.City, HQCO.State, HQCO.Address, HQCO.Zip,
   HRAT.Accident, HRAI.Seq, HRRM.LastName, HRRM.FirstName, HRRM.PositionCode,
   HRPC.JobTitle, HRAT.AccidentDate, HRAI.FatalityYN, HRAL.Days, HRAL.Type, 
   HRRM.HRRef, HRAI.AccidentType, HRAI.Type, 
   HRAT.Location, HRRM.PRCo, HRAI.Accident, HRAL.Seq, HRAL.DaySeq, 
   HRAI.IllnessInjury, HRAI.IllnessType, HRAT.HRCo, 
   HRAI.OSHALocation, HRAI.IllnessInjuryDesc
    FROM   HRRM  
   LEFT OUTER JOIN HRAI ON HRRM.HRCo=HRAI.HRCo AND HRRM.HRRef=HRAI.HRRef
   LEFT OUTER JOIN HQCO ON HRRM.PRCo=HQCO.HQCo 
   LEFT OUTER JOIN HRPC ON HRRM.HRCo=HRPC.HRCo AND 
   HRRM.PositionCode=HRPC.PositionCode
   LEFT OUTER JOIN HRAT ON HRAI.HRCo=HRAT.HRCo AND 
   HRAI.Accident=HRAT.Accident
   LEFT OUTER JOIN HRAL ON HRAI.HRCo=HRAL.HRCo AND 
   HRAI.Accident=HRAL.Accident AND HRAI.Seq=HRAL.Seq
    WHERE  HRAI.AccidentType='R' AND HRAI.Type='O'
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvHRAccident] TO [public]
GRANT INSERT ON  [dbo].[brvHRAccident] TO [public]
GRANT DELETE ON  [dbo].[brvHRAccident] TO [public]
GRANT UPDATE ON  [dbo].[brvHRAccident] TO [public]
GRANT SELECT ON  [dbo].[brvHRAccident] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvHRAccident] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvHRAccident] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvHRAccident] TO [Viewpoint]
GO
