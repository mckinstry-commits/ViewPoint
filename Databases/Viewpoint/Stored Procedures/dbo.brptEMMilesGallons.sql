SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc [dbo].[brptEMMilesGallons]
--Drop Proc brptEMMilesGallons
	(@emco bCompany, @begMth bMonth='01/01/1950', @endMth bMonth='01/01/2050', @begEquip varchar(10)='', @endEquip varchar(10)='zzzzzzzzzz')

/* 
Created by:
12/31/99 Laurie Colter 'MR'=Meter Readings EMMR table   'CD'=Cost Details EMCD table  'ST'=Miles By State EMST Table
Modified by: 
05/26/04	E.T.	added WITH (NOLOCK) and index on #EMMilesGallons temp table 
05/13/10	TRL		replaced EMMR with brvEMMR
06/16/10	TRL		EMCD description col changed, expanded soure descriptions
04/21/11	CCZAPLA	Changed datatype for column #EMMilesGallons.STState from char(2) to varchar(4) to match source column EMSD.State
*/

AS
declare @FuelCostType as tinyint
select @FuelCostType=isnull(FuelCostType,0) from EMCO where EMCo=@emco

create table #EMMilesGallons
(EMCo  tinyint null,
RecordType  Varchar (2) null,
Mth  smalldatetime null,
Equipment  varchar (10) null,
STState varchar(4) null,
STOnRdLoad numeric (9,2) null, 
STOnRdUnLoad numeric (9,2) null,
STOffRoad numeric (9,2) null,
MRSource char (60) null,
MRPrevHrMtr  numeric (12,2) null,
MRCurrHrMtr  numeric (12,2) null,
MRPrevTotalHrMtr  numeric (12,2) null,
MRCurrTotalHrMtr  numeric (12,2) null,
MRHours  numeric (12,2) null,
MRPrevOdo  numeric (12,2) null,
MRCurrOdo  numeric (12,2) null,
MRPrevTotalOdo  numeric (12,2) null,
MRCurrTotalOdo  numeric (12,2) null,
MRMiles  numeric (12,2) null,
CDEMGroup  tinyint null,
CDCostCode  varchar (10) null,
CDCostType  tinyint null,
CDSource char (10) null,
CDTransType  varchar (10) null,
CDDesc  varchar (60) null,
CDMatlGroup tinyint null,
CDMaterial  varchar (20) null,
CDUM  varchar (3) null,
CDUnits numeric (12,2) null,
CDDollars  numeric (12,2) null,
CDUnitPrice  numeric (12,2) null,
CDPerECM  char (1) null,
CDTotalCost  numeric (12,2) null,
CDTaxCode  varchar (10) null,
CDTaxGroup  tinyint null,
CDTaxBasis  numeric (12,2) null,
CDTaxRate  numeric (12,2) null,
CDTaxAmount  numeric (12,2) null,
CDCurrHrMtr numeric (12,2) null,
CDCurrTotHrMtr  numeric (12,2) null,
CDCurrOdo  numeric (12,2) null,
CDCurrTotOdo  numeric (12,2) null)
create index biEMMilesGallons on #EMMilesGallons (EMCo,Mth, Equipment)

create table #EMEquip(
Equipment  varchar (10) null,
Gallons numeric(12,2) null,
TotalMiles numeric(14,2) null,
MPG numeric(8,2) null)
create clustered index biEMGallons on #EMEquip (Equipment)

set nocount off

/* populate #EMEquip - put one record for each piece of equipment */
insert into #EMEquip 
select Equipment,0,0,0 from EMEM WITH (NOLOCK) where EMEM.EMCo=@emco and EMEM.Equipment>=@begEquip and EMEM.Equipment<=@endEquip 

/*Insert EMMR- Meter readings*/
insert into #EMMilesGallons
(RecordType, EMCo, Mth, MRSource, Equipment,  
MRPrevHrMtr, MRCurrHrMtr, MRPrevTotalHrMtr,MRCurrTotalHrMtr, MRHours, 
MRPrevOdo, MRCurrOdo, MRPrevTotalOdo, MRCurrTotalOdo,MRMiles)

Select 'MR',EMCo, ReadingDateMth, Source, Equipment,
PreviousHourMeter = CurrentHourMeter-[Hours], CurrentHourMeter, PreviousTotalHourMeter=CurrentTotalHourMeter-[Hours], CurrentTotalHourMeter, [Hours], 
PreviousOdometer=CurrentOdometer-Miles, CurrentOdometer, PreviousTotalOdometer=CurrentTotalOdometer-Miles, CurrentTotalOdometer,Miles
from dbo.brvEMMR WITH (NOLOCK) 
where EMCo=@emco and Equipment>=@begEquip and Equipment<=@endEquip and ReadingDateMth>=@begMth and ReadingDateMth<=@endMth

/*Insert EMST- Miles By State*/
insert into #EMMilesGallons (RecordType, EMCo, Mth, Equipment, STState, STOnRdLoad, STOnRdUnLoad, STOffRoad)
Select 'ST',  EMSD.Co,  EMSD.Mth,  EMSM.Equipment,  EMSD.State, EMSD.OnRoadLoaded, EMSD.OnRoadUnLoaded, EMSD.OffRoad
From dbo.EMSD WITH (NOLOCK) 
Inner Join dbo.EMSM WITH (NOLOCK) on EMSM.Co = EMSD.Co and EMSM.Mth = EMSD.Mth and EMSM.EMTrans = EMSD.EMTrans
where EMSD.Co=@emco and EMSM.Equipment>=@begEquip and EMSM.Equipment<=@endEquip and EMSD.Mth>=@begMth and EMSD.Mth<=@endMth

/*update miles */
update #EMEquip
set TotalMiles=(select sum(isnull(EMSD.OnRoadLoaded,0)+isnull(EMSD.OnRoadUnLoaded,0)+isnull(EMSD.OffRoad,0)) 
from dbo.EMSD WITH (NOLOCK) 
Inner Join dbo.EMSM WITH (NOLOCK) on EMSM.Co = EMSD.Co and EMSM.Mth = EMSD.Mth  and EMSM.EMTrans = EMSD.EMTrans
where EMSM.Equipment=#EMEquip.Equipment and EMSD.Co=@emco  and EMSD.Mth>=@begMth and EMSD.Mth<=@endMth)

/*Insert EMCD- Cost Detail*/
insert into #EMMilesGallons
(RecordType, EMCo, Mth, CDSource, Equipment, 
CDEMGroup, CDCostCode, CDCostType, CDTransType, CDDesc, CDMatlGroup, CDMaterial, CDUM,
CDUnits, CDDollars, CDUnitPrice, CDPerECM, CDTotalCost, CDTaxCode, CDTaxGroup,
CDTaxBasis, CDTaxRate, CDTaxAmount, CDCurrHrMtr, CDCurrTotHrMtr, CDCurrOdo, CDCurrTotOdo)

Select 'CD', EMCD.EMCo, EMCD.Mth, EMCD.Source, EMCD.Equipment, EMCD.EMGroup, EMCD.CostCode, EMCD.EMCostType,
EMCD.EMTransType, EMCD.Description,  EMCD.MatlGroup, EMCD.Material, EMCD.UM, EMCD.Units, EMCD.Dollars, 
EMCD.UnitPrice, EMCD.PerECM, EMCD.TotalCost, EMCD.TaxCode, EMCD.TaxGroup,  EMCD.TaxBasis, EMCD.TaxRate, 
EMCD.TaxAmount, EMCD.CurrentHourMeter, EMCD.CurrentTotalHourMeter, EMCD.CurrentOdometer, EMCD.CurrentTotalOdometer
From dbo.EMCD WITH (NOLOCK) 
where EMCD.EMCo=@emco and EMCD.Equipment>=@begEquip and EMCD.Equipment<=@endEquip and EMCD.Mth>=@begMth and EMCD.Mth<=@endMth


/*update gallons */
update #EMEquip
set Gallons=(select isnull(sum(EMCD.Units),0) 
from dbo.EMCD WITH (NOLOCK) 
where EMCD.Equipment=#EMEquip.Equipment and EMCostType=@FuelCostType and EMCD.EMCo=@emco  and EMCD.Mth>=@begMth and EMCD.Mth<=@endMth)

/* select results */
Select a.*, HQCO.HQCo,  CoName=HQCO.Name, EquipDesc=EMEM.Description, FuelType=EMEM.FuelType, EqCategory=EMEM.Category, 
EMGroup=EMEM.EMGroup,MatlDesc=HQMT.Description,MPG=case when b.Gallons =0  then 0 else b.TotalMiles/b.Gallons end, b.Gallons, b.TotalMiles
From #EMMilesGallons a WITH (NOLOCK) 
join dbo.HQCO WITH (NOLOCK) on HQCO.HQCo = a.EMCo
join dbo.EMEM WITH (NOLOCK) on EMEM.EMCo=a.EMCo and EMEM.Equipment = a.Equipment
left join #EMEquip b WITH (NOLOCK) on b.Equipment = a.Equipment
left join dbo.HQMT WITH (NOLOCK) on HQMT.MatlGroup=a.CDMatlGroup and HQMT.Material=a.CDMaterial
where a.EMCo=@emco and (a.Mth between @begMth and @endMth) and (a.Equipment between @begEquip and @endEquip)



GO
GRANT EXECUTE ON  [dbo].[brptEMMilesGallons] TO [public]
GO
