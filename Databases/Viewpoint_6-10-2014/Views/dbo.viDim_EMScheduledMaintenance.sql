SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_EMScheduledMaintenance]
--
--/**************************************************
-- *
-- *
-- ********************************************************/
--
as

--Declare @DaysVariance int
--set @DaysVariance = 7
--
--declare @AsOfDate datetime
--set @AsOfDate = Getdate()


--declare @MeterDaysVariance decimal (15,2)
--set @MeterDaysVariance = 1;



With EMMain
as
(SELECT 
EMCO.KeyID as 'EMCoID',
EMSH.EMCo,
EMEM.KeyID as 'EquipmentID',
EMEM.Equipment,
EMEM.Equipment + ' - '+ EMEM.Description as 'EquipmentDescription',
case EMEM.Status
	when 'A' then 'Active'
	when 'I' then 'Inactive'
	when 'D' then 'Down'
end as 'EquipStatusDesc',
EMEM.Department, 
EMEM.Location, 
EMEM.Category, 
CONVERT(VARCHAR,CONVERT(MONEY,EMEM.OdoReading + EMEM.ReplacedOdoReading),1)  
	+ ' miles as of '  + CONVERT(varchar,EMEM.OdoDate,1) as 'OdometerReading',--+ EMEM.OdoDate
EMEM.VINNumber, 
EMEM.JCCo, 
EMEM.Job,
CONVERT(VARCHAR,CONVERT(MONEY,EMEM.HourReading + EMEM.ReplacedHourReading),1)  
	+ ' miles as of '  + CONVERT(varchar,EMEM.HourDate,1) as 'HourReading',
'SMG: ' + EMSH.StdMaintGroup + ' ' + EMSH.Description as 'StdMaintGrp',
--EMSI.StdMaintItem,
cast(EMSI.StdMaintItem as varchar) + '  /  ' + EMSI.Description as 'StdMaintItem',
EMSH.Basis,
case EMSH.Basis
when 'F' then 
	case len(FixedDateMonth) when 1 then '0' + CAST(FixedDateMonth AS varchar(1))  else CAST(FixedDateMonth AS varchar(2)) end +
	case len(FixedDateMonth) when 1 then '0' + CAST(FixedDateMonth AS varchar(1))  else CAST(FixedDateMonth AS varchar(2)) end
when 'H' then 'Hours'
when 'G' then 'Gallons'
when 'M' then 'Miles'
else EMSH.Basis end as 'BasisDesc',
case EMSH.Basis
when 'F' then  ''
when 'H' then 'HRS'
when 'M' then 'MI'
when 'G' then 'GAL'
else '' end as 'EMSHType',
EMSH.FixedDateMonth,
EMSH.FixedDateDay,
case len(FixedDateDay) when 1 then '0' + CAST(FixedDateDay AS varchar(1))  else CAST(FixedDateDay AS varchar(2)) end as 'txtFixedDateDay',
case len(FixedDateMonth) when 1 then '0' + CAST(FixedDateMonth AS varchar(1))  else CAST(FixedDateMonth AS varchar(2)) end as 'txtFixedDateMonth',
EMSH.Interval,
EMSH.IntervalDays,
dateadd(day,EMSH.FixedDateDay - 1,dateadd(month,EMSH.FixedDateMonth - 1,dateadd(year,(Datepart(Year,Getdate()) - 1753),'1/1/1753'))) as 'FixedDateDateThisyr',
isnull(EMSI.LastDoneDate, '1/1/1950') as 'sqlLastDoneDate',
EMSI.LastDoneDate ,
EMEM.HourReading + EMEM.ReplacedHourReading as 'HourAndReplacement',
EMSH.Variance,
EMSI.LastHourMeter,
EMEM.OdoReading + EMEM.ReplacedOdoReading as 'OdoAndReplace',
EMSI.LastOdometer,
EMEM.FuelUsed, 
EMSI.LastGallons,
EMSI.InOutFlag,
EMSI.EstHrs,
EMSP.Material,
EMSP.Description,
EMSP.UM,
EMSP.QtyNeeded,
case EMSP.PSFlag when 'S' then 'Stocked' else 'Purchased' end as 'PurStk',
EMSP.Required
FROM   dbo.bEMSH EMSH 
INNER JOIN dbo.bEMCO EMCO
	ON EMCO.EMCo=EMSH.EMCo
INNER JOIN dbo.bEMEM EMEM 
	ON EMSH.EMCo=EMEM.EMCo 
	AND EMSH.Equipment=EMEM.Equipment 
INNER JOIN dbo.bEMSI EMSI 
	ON EMSH.EMCo=EMSI.EMCo 
	AND EMSH.Equipment=EMSI.Equipment 
	AND EMSH.StdMaintGroup=EMSI.StdMaintGroup 
INNER JOIN dbo.bHQCO HQCO 
	ON EMSH.EMCo=HQCO.HQCo 
LEFT OUTER JOIN dbo.bEMSP EMSP 
	ON EMSI.EMCo=EMSP.EMCo 
	AND EMSI.Equipment=EMSP.Equipment 
	AND EMSI.StdMaintGroup=EMSP.StdMaintGroup 
	AND EMSI.StdMaintItem=EMSP.StdMaintItem 
LEFT OUTER JOIN dbo.bJCJM JCJM 
	ON EMEM.JCCo=JCJM.JCCo 
	AND EMEM.Job=JCJM.Job 
LEFT OUTER JOIN dbo.bEMCM EMCM 
	ON EMEM.EMCo=EMCM.EMCo 
	AND EMEM.Category=EMCM.Category 
LEFT OUTER JOIN dbo.bEMDM EMDM 
	ON EMEM.EMCo=EMDM.EMCo 
	AND EMEM.Department=EMDM.Department 
LEFT OUTER JOIN dbo.bEMLM EMLM 
	ON EMEM.EMCo=EMLM.EMCo 
	AND EMEM.Location=EMLM.EMLoc
Inner Join vDDBICompanies on vDDBICompanies.Co=EMSH.EMCo)

select 
EMCo,
EMCoID,
Equipment,
EquipmentDescription,
StdMaintGrp,
StdMaintItem,
Datediff(mm,'1/1/1950',Getdate()) as 'AsOfMonthID',
EquipStatusDesc,
Department,
Category,
OdometerReading,
VINNumber,
JCCo,
Job,
HourReading,
Case Basis  
	when 'F' then 'Scheduling Info:  due ' + txtFixedDateMonth + '/' + txtFixedDateDay + ' every year'
	else 'Scheduling Info:  every ' + CAST(isnull(Interval,0) AS varchar) + ' ' + BasisDesc + ' or every ' + isnull(Cast(IntervalDays as varchar),0) + ' days'
end as 'StdMaintGroupDueInfo',
Case InOutFlag when 'I' then 'IN' else 'OUT' end as 'EMSIFlag',
LastOdometer,
LastHourMeter,
LastGallons,
LastDoneDate,
datediff(dd,'1/1/1950',LastDoneDate) as 'LastDoneDateID',
Case  
when Basis = 'F' then 
				case when LastDoneDate <  FixedDateDateThisyr then CONVERT(varchar,FixedDateDateThisyr,1)
					 else CONVERT(varchar,DateAdd(year,1,FixedDateDateThisyr),1) end
when Basis = 'H' then CAST((HourAndReplacement + Interval) AS varchar(12)) 
when Basis = 'M' then CAST((OdoAndReplace + Interval) AS varchar(12)) 
when Basis = 'G' then CAST((LastGallons + Interval) AS varchar(12)) 
else CAST((LastDoneDate + IntervalDays) AS varchar(12)) --'hh'--LastDoneDate + IntervalDays 
end as 'NextDueAlwaysPrint',
EMSHType,
Case  
when Basis = 'F' then 
				case when LastDoneDate <  FixedDateDateThisyr then CONVERT(varchar,FixedDateDateThisyr,1)
					 else CONVERT(varchar,DateAdd(year,1,FixedDateDateThisyr),1) end
when Basis = 'H' then 
				case when (HourAndReplacement + Variance) * 1 >= LastHourMeter + Interval then convert(varchar,LastHourMeter + Interval)
				     when IntervalDays <> 0 then
							case when sqlLastDoneDate <> '1/1/1950' then
					            case when Getdate() - sqlLastDoneDate + 7 >= IntervalDays then CONVERT(varchar,DateAdd(day,IntervalDays,sqlLastDoneDate),1) else '' end---ToText(Currentdate,DateFormat) end
							else Convert(varchar,GetDate(),1) end
				else '' end
when Basis = 'M' then 
				case when (OdoAndReplace + Variance)* 1 >= LastOdometer + Interval then convert(varchar,LastOdometer + Interval)
					 when IntervalDays <> 0 then
							case when sqlLastDoneDate <> '1/1/1950' then
					            case when Getdate() - sqlLastDoneDate + 7 >= IntervalDays then CONVERT(varchar,DateAdd(day,IntervalDays,sqlLastDoneDate),1) else '' end---ToText(Currentdate,DateFormat) end
							else Convert(varchar,GetDate(),1) end
				else '' end
when Basis = 'G' then 
				case when (FuelUsed + Variance)* 1 >= LastGallons + Interval then convert(varchar,LastGallons + Interval)
					 when IntervalDays <> 0 then
							case when sqlLastDoneDate <> '1/1/1950' then
					            case when Getdate() - sqlLastDoneDate + 7 >= IntervalDays then CONVERT(varchar,DateAdd(day,IntervalDays,sqlLastDoneDate),1) else '' end---ToText(Currentdate,DateFormat) end
							else Convert(varchar,GetDate(),1) end
				else '' end
 end as 'NextDueWVariance',
Material + ' / ' + [Description] as 'MaterialDesc',
UM,
QtyNeeded,
PurStk,
[Required]
from EMMain


GO
GRANT SELECT ON  [dbo].[viDim_EMScheduledMaintenance] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMScheduledMaintenance] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMScheduledMaintenance] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMScheduledMaintenance] TO [public]
GRANT SELECT ON  [dbo].[viDim_EMScheduledMaintenance] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_EMScheduledMaintenance] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_EMScheduledMaintenance] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_EMScheduledMaintenance] TO [Viewpoint]
GO
