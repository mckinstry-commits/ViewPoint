SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[viFact_EMScheduledMaintenance] AS

/*****
Usage:  View selects Key ID's and Measures for the EM Scheduled Maintenance Measures in the EM Cube.
Mod:  1/20/11 DH.  Issue 143243.  Added check to LastDoneDateID for dates less than 1/1/1950

****/

With EMMain
as
(SELECT
EMCO.KeyID as 'EMCoID',
EMDM.KeyID as 'DepartmentKeyID',
EMCM.KeyID as 'CategoryKeyID',
EMEM.KeyID as 'EquipmentID',
EMCC.KeyID as 'CostCodeID',
EMSH.KeyID as 'StdMaintGroupID',
EMCO.GLCo as 'GLCo',
row_number() over (order by EMSI.EMCo, EMSI.Equipment, EMSI.StdMaintGroup, EMSI.StdMaintItem ) as 'StdMaintItemID',
Case when EMSH.Basis = 'H' then isnull(EMSI.LastHourMeter, 0) + isnull(EMSH.Interval, 0) else Null end as 'NextHours',
Case when EMSH.Basis = 'G' then isnull(EMSI.LastGallons,0) + isnull(EMSH.Interval, 0) else Null end as 'NextGallons',
Case when EMSH.Basis = 'M' then isnull(EMSI.LastOdometer, 0) + isnull(EMSH.Interval, 0)  else Null end as 'NextMiles',
isnull(EMSH.Basis,0) as 'Basis',
isnull(EMSH.Interval,0) as 'Interval',
isnull(EMSH.IntervalDays, 0) as 'IntervalDays',
dateadd(day,EMSH.FixedDateDay - 1,dateadd(month,EMSH.FixedDateMonth - 1,dateadd(year,(Datepart(Year,Getdate()) - 1753),'1/1/1753'))) as 'FixedDateDateThisyr',
isnull(EMSI.LastDoneDate, '1/1/1950') as 'sqlLastDoneDate',
--case when Basis <> 'F' then Dateadd(dd,isnull(EMSH.IntervalDays,0),isnull(isnull(EMSI.LastDoneDate, '1/1/1950'),'1/1/1950')) else '1/1/1950' end as 'DueDate',
CASE  
   WHEN EMSI.LastDoneDate IS NULL THEN '1/1/1950'
   WHEN Basis <> 'F' and EMSI.LastDoneDate>='1/1/1950' then Dateadd(dd,isnull(EMSH.IntervalDays,0),CAST(EMSI.LastDoneDate AS DATETIME)) 
   ELSE '1/1/1950' 
   END AS 'DueDate',
EMSI.LastDoneDate ,
isnull(EMEM.HourReading, 0) + isnull(EMEM.ReplacedHourReading, 0) as 'HourAndReplacement',
EMSH.Variance,
isnull(EMSI.LastHourMeter,0) as 'LastHourMeter',
isnull(EMEM.OdoReading,0) + isnull(EMEM.ReplacedOdoReading, 0) as 'OdoAndReplace',
isnull(EMSI.LastOdometer, 0) as 'LastOdometer',
isnull(EMEM.FuelUsed, 0) as 'FuelUsed',
isnull(EMSI.LastGallons,0) as 'LastGallons',
EMSI.StdMaintItem,
EMSI.EstHrs,
EMSI.EstCost 
FROM   dbo.bEMSH EMSH 
join dbo.bEMEM EMEM 
      ON EMSH.EMCo=EMEM.EMCo 
      AND EMSH.Equipment=EMEM.Equipment 
INNER JOIN bEMSI EMSI
      ON EMSH.EMCo=EMSI.EMCo 
      AND EMSH.Equipment=EMSI.Equipment 
      AND EMSH.StdMaintGroup=EMSI.StdMaintGroup 
left join dbo.bEMCC EMCC
	 On EMSI.EMGroup = EMCC.EMGroup
	and EMSI.CostCode = EMCC.CostCode
left join dbo.bEMCM EMCM 
      ON EMEM.EMCo=EMCM.EMCo 
      AND EMEM.Category=EMCM.Category 
left join dbo.bEMDM EMDM 
      ON EMEM.EMCo=EMDM.EMCo 
      AND EMEM.Department=EMDM.Department 
left join dbo.bEMLM EMLM 
      ON EMEM.EMCo=EMLM.EMCo 
      AND EMEM.Location=EMLM.EMLoc
join bEMCO EMCO
      on EMCO.EMCo = EMEM.EMCo
Inner Join vDDBICompanies on vDDBICompanies.Co=EMSH.EMCo

)
select 
EMCoID,
DepartmentKeyID,
CategoryKeyID,
EquipmentID,
CostCodeID,
StdMaintGroupID,
StdMaintItemID,
StdMaintItem,
datediff(dd, '1/1/1950', LastDoneDate) as 'LastDoneDateID',	
Case  
when  Basis = 'F' and DateAdd(day,7,Getdate()) >= FixedDateDateThisyr then 
                                 case when (DateDiff(Month,LastDoneDate, FixedDateDateThisyr) >=6)  then 1
                                  when  (sqlLastDoneDate = '1/1/1950') then 1 
                                          else 0 end
when  Basis = 'H' then 
                                 case when HourAndReplacement >= (LastHourMeter + Interval) then 1
                                          when (HourAndReplacement + Variance) * 1 >= LastHourMeter + Interval then 1
                                          when IntervalDays <> 0 then
                                                case when Getdate() - sqlLastDoneDate + 7 >= IntervalDays then 1 else 0 end
                                          else 0 end
when Basis = 'M' then 
                                  case when OdoAndReplace >= LastOdometer + Interval then 1
                                           when (OdoAndReplace + Variance) * 1 >= LastOdometer + Interval then 1
                                           when IntervalDays <> 0 then
                                                case when Getdate() - sqlLastDoneDate + 7 >= IntervalDays then 1 else 0 end
                                          else 0 end
when Basis = 'G' then 
                                    case when FuelUsed >= LastGallons + Interval then 1
                                           when (FuelUsed + Variance) * 1 >= LastGallons + Interval then 1
                                           when IntervalDays <> 0 then
                                                case when Getdate() - sqlLastDoneDate + 7 >= IntervalDays then 1 else 0 end
                                    else 0 end
else '' end as 'DueItems',
Case  
when Basis = 'H' then CASE WHEN Variance = 0 THEN 0 ELSE ((LastHourMeter + Interval)- HourAndReplacement) / Variance END 
						--Due = LastHourMeter + Interval
						--CurrentHours = HourAndReplacement or (EMEM.HourReading + EMEM.ReplacedHourReading)
						--Variance = Variance
						--Number of Variances to Advance Warning = (Due - CurrentHours)/ Variance
when Basis = 'M' then CASE WHEN Variance = 0 THEN 0 ELSE ((LastOdometer + Interval) - OdoAndReplace) / Variance END

when Basis = 'G' then CASE WHEN Variance = 0 THEN 0 ELSE ((LastGallons + Interval) - FuelUsed) / Variance END

else 0 end as 'VariancesUntilAdvanceWarning',
NextHours,
NextMiles,
NextGallons,
datediff(dd, '1/1/1950',DueDate) as 'DueDateID',
isnull(Cast(cast(EMMain.GLCo as varchar(3))
  +cast(Datediff(dd,'1/1/1950',cast(cast(DATEPART(yy,DueDate) as varchar) 
  + '-'+ DATENAME(m, DueDate) +'-01' as datetime)) as varchar(10)) as int),0) as FiscalMthID,
EstHrs as 'EstHours',
EstCost as 'EstCost'
from EMMain




GO
GRANT SELECT ON  [dbo].[viFact_EMScheduledMaintenance] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMScheduledMaintenance] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMScheduledMaintenance] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMScheduledMaintenance] TO [public]
GRANT SELECT ON  [dbo].[viFact_EMScheduledMaintenance] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_EMScheduledMaintenance] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_EMScheduledMaintenance] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_EMScheduledMaintenance] TO [Viewpoint]
GO
