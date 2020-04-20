SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[EMBFFuelInit] 
/*****************************************
* Created By: DANF 05/08/07
* Modfied By:	GF 02/01/2010 - issue #132064 - do not return previous hour and odometer columns (dead)
*
*
* Provides a view of EM Fuel Entries for 
* EM Fuel Initialize.
*****************************************/
as 

select EMBF.Co,  EMBF.Mth,  EMBF.BatchId,  EMBF.BatchSeq,  EMBF.Source,  EMBF.Equipment,  EMBF.RevCode,  EMBF.EMTrans,  EMBF.BatchTransType,  EMBF.EMTransType,
	EMBF.ComponentTypeCode,  EMBF.Component,  EMBF.Asset,  EMBF.EMGroup,  EMBF.CostCode,  EMBF.EMCostType,  EMBF.ActualDate,  EMBF.Description,  
	EMBF.GLCo,  EMBF.GLTransAcct,  EMBF.GLOffsetAcct,   EMBF.MatlGroup,  EMBF.INCo,  EMBF.INLocation,  
	EMBF.Material,  EMBF.UM,  EMBF.Units,  EMBF.Dollars,  EMBF.UnitPrice,  EMBF.Hours,  EMBF.PerECM,  EMBF.TotalCost,
	EMBF.JCCo,  EMBF.Job,  EMBF.PhaseGrp,  EMBF.JCPhase,  EMBF.JCCostType,   EMBF.OffsetGLCo, 
	EMBF.MeterTrans,  EMBF.MeterReadDate,  EMBF.ReplacedHourReading,
	----#132064
	/*EMBF.PreviousHourMeter,*/  EMBF.CurrentHourMeter,  /*EMBF.PreviousTotalHourMeter,*/  EMBF.CurrentTotalHourMeter,  
	EMBF.ReplacedOdoReading,  /*EMBF.PreviousOdometer,*/  EMBF.CurrentOdometer,  /*EMBF.PreviousTotalOdometer,*/
	----#132064
	EMBF.CurrentTotalOdometer,  EMBF.MeterMiles,  EMBF.MeterHrs,  
	EMBF.TaxType,  EMBF.TaxCode, EMBF.TaxGroup,  EMBF.TaxBasis,  EMBF.TaxRate,  EMBF.TaxAmount, 
	EMBF.UniqueAttchID, EMEM.JCCo as EMEMJCCo, EMEM.Job as EMEMJob, EMEM.Location as EMEMLocation, EMEM.Category As EMEMCategory, EMEM.Department as EMEMDepartment, EMEM.Shop as EMEMShop
from EMBF EMBF with (nolock)
join EMEM EMEM with (nolock) on EMBF.Co = EMEM.EMCo and EMBF.Equipment = EMEM.Equipment



GO
GRANT SELECT ON  [dbo].[EMBFFuelInit] TO [public]
GRANT INSERT ON  [dbo].[EMBFFuelInit] TO [public]
GRANT DELETE ON  [dbo].[EMBFFuelInit] TO [public]
GRANT UPDATE ON  [dbo].[EMBFFuelInit] TO [public]
GO
