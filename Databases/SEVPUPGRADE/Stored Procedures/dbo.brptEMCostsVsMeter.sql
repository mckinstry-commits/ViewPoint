SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[brptEMCostsVsMeter]
(@emco bCompany, @begMth bMonth='01/01/1950', @endMth bMonth='01/01/2050', @begEquip varchar(10)='', @endEquip varchar(10)='zzzzzzzzzz')
/*CREATED BY   11/11/99 Laurie Colter 'MR'=Meter Readings EMMR table   'CD'=Cost Details EMCD table*/ 
/* Modifed by NF 11/11/04Issue 25898 Added with(nolock) to the from and join statements 
*				TRL Issue 137147, replaced EMMR with brvEMMR
*
*/

as 

create table #EMCostsVsMeter
(EMCo  tinyint null,
RecordType  Varchar(2) null,
Mth  smalldatetime null,
Trans  int null,
BatchId  int null,
InUseBatchID  int null,
Source char(10) null,
Equipment    varchar(10) null,
MRPostingDate   smalldatetime null,
MRReadingDate   smalldatetime null,
MRPrevHrMeter  numeric (12,2) null,
MRCurrHrMeter  numeric (12,2) null,
MRPrevTotalHrMeter  numeric (12,2) null,
MRCurrTotalHrMeter  numeric (12,2) null,
MRHours  numeric (12,2) null,
MRPrevOdo  numeric (12,2) null,
MRCurrOdo  numeric (12,2) null,
MRPrevTotalOdo  numeric (12,2) null,
MRCurrTotalOdo  numeric (12,2) null,
MRMiles  numeric (12,2) null,
CDEMTrans int null,
CDEMGroup  tinyint null,
CDComponent  varchar(10) null,
CDComponentTypeCode  varchar(10) null,
CDAsset  varchar (20) null,
CDWorkOrder  varchar (10) null,
CDWOItem  smallint null,
CDCostCode  varchar (10) null,
CDEMCostType  tinyint null,
CDPostedDate  smalldatetime null,
CDActualDate  smalldatetime null,
CDEMTransType  varchar(10) null,
CDDescription  varchar (60) null,
CDGLCo  tinyint null,
CDGLTransAcct  char (20) null,
CDGLOffsetAcct char (20) null,
CDReversalStatus tinyint null,
CDPRCo  tinyint null,
CDPREmployee  int null,
CDAPCo  tinyint null, 
CDAPTrans  int null,
CDAPLine  int null,
CDVendorGrp  tinyint null,
CDAPVendor  int null,
CDAPRef  varchar (15) null,
CDMatlGroup  tinyint null,
CDINCo  tinyint null,
CDINLocation  varchar (20) null,
CDMaterial  varchar (20) null,
CDSerialNo  varchar (20) null,
CDUM  varchar (3) null,
CDUnits numeric(12,2) null,
CDDollars  numeric (12,2) null,
CDUnitPrice  numeric (12,2) null,
CDPerECM  char (1) null,
CDTotalCost  numeric (12,2) null,
CDAllocCode  tinyint null,
CDTaxCode  varchar (10) null,
CDTaxGroup  tinyint null,
CDTaxBasis  numeric (12,2) null,
CDTaxRate  numeric (12,2) null,
CDTaxAmount  numeric (12,2) null,
CDMeterTrans int null,
CDCurrentHourMeter numeric (12,2) null,
CDCurrentTotalHourMeter  numeric (12,2) null,
CDCurrentOdometer  numeric (12,2) null,
CDCurrentTotalOdometer  numeric (12,2) null,
CDPO VARCHAR(30) null,
CDPOItem smallint null)

set nocount off

/*Insert EMMR- Meter readings*/
insert into #EMCostsVsMeter 
(RecordType, EMCo, Mth, Trans, BatchId, InUseBatchID, Source, Equipment, MRPostingDate, MRReadingDate, 
MRPrevHrMeter, MRCurrHrMeter, MRPrevTotalHrMeter,MRCurrTotalHrMeter, MRHours, 
MRPrevOdo, MRCurrOdo, MRPrevTotalOdo, MRCurrTotalOdo,MRMiles)

Select 'MR',EMCo, ReadingDateMth, EMTrans, BatchId, InUseBatchID, Source,Equipment, PostingDate,ReadingDate, 
PreviousHourMeter = CurrentHourMeter-[Hours], CurrentHourMeter, PreviousTotalHourMeter=CurrentTotalHourMeter-[Hours], CurrentTotalHourMeter, [Hours], 
PreviousOdometer=CurrentOdometer-Miles, CurrentOdometer, PreviousTotalOdometer=CurrentTotalOdometer-Miles, CurrentTotalOdometer,Miles
From dbo.brvEMMR with(nolock)
where  EMCo=@emco and Equipment>=@begEquip and Equipment<=@endEquip and ReadingDateMth>=@begMth and ReadingDateMth<=@endMth

/*Insert EMCD- Cost Detail*/
insert into #EMCostsVsMeter 
(RecordType, EMCo, Mth, CDEMTrans, BatchId, InUseBatchID, Source, Equipment, CDEMGroup, CDComponent, CDComponentTypeCode,CDAsset, 
CDWorkOrder,CDWOItem,CDCostCode,CDEMCostType,CDPostedDate,CDActualDate,CDEMTransType,CDDescription,
CDGLCo,CDGLTransAcct,CDGLOffsetAcct,CDReversalStatus,
CDPRCo,CDPREmployee,CDAPCo, CDAPTrans,CDAPLine,CDVendorGrp,
CDAPVendor,CDAPRef,CDMatlGroup,CDINCo,CDINLocation, CDMaterial, CDSerialNo, CDUM,
CDUnits,CDDollars,CDUnitPrice,CDPerECM,CDTotalCost,CDAllocCode,CDTaxCode,CDTaxGroup,
CDTaxBasis,CDTaxRate,CDTaxAmount,CDMeterTrans,CDCurrentHourMeter,
CDCurrentTotalHourMeter,CDCurrentOdometer,CDCurrentTotalOdometer,CDPO,CDPOItem)

Select 'CD',EMCD.EMCo, EMCD.Mth, EMCD.EMTrans, EMCD.BatchId, EMCD.InUseBatchID, EMCD.Source, EMCD.Equipment, EMCD.EMGroup, EMCD.Component, EMCD.ComponentTypeCode,EMCD.Asset, 
EMCD.WorkOrder,EMCD.WOItem,EMCD.CostCode,EMCD.EMCostType,EMCD.PostedDate,EMCD.ActualDate,EMCD.EMTransType,EMCD.Description,
EMCD.GLCo,EMCD.GLTransAcct,
EMCD.GLOffsetAcct,EMCD.ReversalStatus,EMCD.PRCo,EMCD.PREmployee,
EMCD.APCo, EMCD.APTrans,EMCD.APLine,EMCD.VendorGrp,
EMCD.APVendor,EMCD.APRef,EMCD.MatlGroup,EMCD.INCo,EMCD.INLocation, EMCD.Material, EMCD.SerialNo,EMCD.UM,EMCD.Units,EMCD.Dollars,EMCD.UnitPrice,EMCD.PerECM,
EMCD.TotalCost,EMCD.AllocCode,EMCD.TaxCode,EMCD.TaxGroup,
EMCD.TaxBasis,EMCD.TaxRate,EMCD.TaxAmount,EMCD.MeterTrans,EMCD.CurrentHourMeter,
EMCD.CurrentTotalHourMeter,EMCD.CurrentOdometer,EMCD.CurrentTotalOdometer,EMCD.PO,
EMCD.POItem 
From dbo.EMCD with(nolock)
where EMCo=@emco and Equipment>=@begEquip and Equipment<=@endEquip and Mth>=@begMth and Mth<=@endMth

Select a.*, HQCO.HQCo,  CompanyName=HQCO.Name, EMDescription=EMEM.Description, PRLastName=PREH.LastName, PRFirstName=PREH.FirstName, PRMidName=PREH.MidName,
APVendName=APVM.Name, MatlDescription=HQMT.Description
From #EMCostsVsMeter a with(nolock)
join dbo.HQCO with(nolock) on HQCO.HQCo = a.EMCo
join dbo.EMEM with(nolock) on EMEM.EMCo=a.EMCo and EMEM.Equipment = a.Equipment
left join dbo.APVM with(nolock) on APVM.VendorGroup=a.CDVendorGrp and APVM.Vendor=a.CDAPVendor
left join dbo.PREH with(nolock) on PREH.PRCo=a.CDPRCo and PREH.Employee=a.CDPREmployee
left join dbo.HQMT with(nolock) on HQMT.MatlGroup=a.CDMatlGroup and HQMT.Material=a.CDMaterial
where a.EMCo=@emco and a.Mth between @begMth and @endMth and a.Equipment between @begEquip and @endEquip

DROP TABLE #EMCostsVsMeter
GO
GRANT EXECUTE ON  [dbo].[brptEMCostsVsMeter] TO [public]
GO
