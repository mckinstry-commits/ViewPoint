SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE view [dbo].[viFact_MSSales] AS    
    
/**************************************************    
 * Created:  05-7-2010 MB    
 * Modified: 03-7-2012 HH TK-13093 #145998 filter on non-voided MS Tickets
 * Usage:  MS Cube
 *    
 **************************************************/  


select   
bMSCO.KeyID as 'MSCoID',  
bINLM.KeyID as 'LocID',  
bHQMT.KeyID as 'MaterialID',
bHQUM.KeyID as 'UMID'  ,
isnull(bARCM.KeyID,0) as 'CustomerID',
isnull(bJCJM.KeyID,0) as 'JobID',
isnull(HaulPhaseCT.KeyID,0) as 'HaulPhaseCTID',
isnull(MatlPhaseCT.KeyID,0) as 'MatlPhaseCTID',
isnull(bJCCT.KeyID,0) as 'JCCostTypeID',
isnull(HaulVendor.KeyID,0) as 'HaulVendorID',
isnull(MatlVendor.KeyID,0) as 'MaterialVendorID',
isnull(CustJob.CustJobID,0) as 'CustJobID',
isnull(CustPO.CustPOID,0) as 'CustPOID',
isnull(EMCategory.KeyID,0)		AS 'EMCategoryID',
isnull(Equipment.KeyID,0)		AS 'EquipmentID',
datediff(dd, '1/1/1950', bMSTD.SaleDate) as SaleDateID ,
isnull(Cast(cast(FiscalMonth.GLCo as varchar(3))
	   +cast(Datediff(dd,'1/1/1950',FiscalMonth.Mth) as varchar(10)) as int),0)
as 'FiscalMthID' ,
isnull(bMSTT.KeyID,0) as VendorTruckTypeID,
bMSTD.MatlTotal  as 'Sales',    
bMSTD.MatlUnits  as 'UnitsSold',    
bMSTD.MatlCost as 'MaterialCost',  
bMSTD.Loads as 'HaulLoads', 
bMSTD.Miles as 'HaulMiles', 
bMSTD.Hours as 'HaulHours',
bMSTD.HaulTotal as 'HaulCharge',
case when bMSTD.PayCode is not null then bMSTD.PayTotal 
     when bMSTD.RevCode is not null then bMSTD.RevTotal end as 'HaulCost' ,
case when bMSTD.MSInv is not null 
		then isnull(bMSTD.MatlTotal,0) + isnull(bMSTD.HaulTotal,0) end as 'InvoicedAmount',
isnull(bMSTD.MatlTotal,0) + isnull(bMSTD.HaulTotal,0) as 'TicketAmount'		 
		
   
  
from bMSTD    
join bMSCO
	on bMSCO.MSCo = bMSTD.MSCo    
	
join bINLM     
	on bMSTD.MSCo = bINLM.INCo     
	AND bMSTD.FromLoc = bINLM.Loc     
	
join  bHQMT
	on  bMSTD.MatlGroup = bHQMT.MatlGroup
	and bMSTD.Material = bHQMT.Material
	and bHQMT.Type = 'S'

Inner Join  bHQUM
	on bHQUM.UM = bHQMT.StdUM	
	
left join bARCM 
	on  bMSTD.Customer = bARCM.Customer
	and bMSTD.CustGroup = bARCM.CustGroup

left join bJCJM With (NoLock)
	on  bJCJM.JCCo = bMSTD.JCCo
	and	bJCJM.Job = bMSTD.Job
	
left join bJCCH HaulPhaseCT With (NoLock)
	on  HaulPhaseCT.JCCo = bMSTD.JCCo
	and	HaulPhaseCT.Job = bMSTD.Job
	and HaulPhaseCT.PhaseGroup = bMSTD.PhaseGroup
	and HaulPhaseCT.Phase = bMSTD.HaulPhase	
	and HaulPhaseCT.CostType = bMSTD.HaulJCCType

left join bJCCH MatlPhaseCT With (NoLock)
	on  MatlPhaseCT.JCCo = bMSTD.JCCo
	and	MatlPhaseCT.Job = bMSTD.Job
	and MatlPhaseCT.PhaseGroup = bMSTD.PhaseGroup
	and MatlPhaseCT.Phase = bMSTD.MatlPhase	
	and MatlPhaseCT.CostType = bMSTD.MatlJCCType	
	
LEFT OUTER JOIN bGLFP FiscalMonth With (NoLock)
	ON FiscalMonth.GLCo=bMSCO.GLCo
	AND FiscalMonth.Mth=bMSTD.Mth	
	
Left Outer Join bAPVM HaulVendor With (NoLock)
	on  HaulVendor.VendorGroup = bMSTD.VendorGroup
	and HaulVendor.Vendor = bMSTD.HaulVendor	

Left outer Join bAPVM MatlVendor
	on  MatlVendor.VendorGroup = bMSTD.VendorGroup
	and MatlVendor.Vendor = bMSTD.MatlVendor	

Left Outer Join viDim_MSCustomerJob CustJob
	on  CustJob.MSCo = bMSTD.MSCo
	and	CustJob.CustGroup = bMSTD.CustGroup
	and CustJob.Customer = bMSTD.Customer
	and CustJob.CustJob = bMSTD.CustJob

Left Outer Join viDim_MSCustomerPO CustPO
	on  CustPO.MSCo = bMSTD.MSCo
	and	CustPO.CustGroup = bMSTD.CustGroup
	and CustPO.Customer = bMSTD.Customer
	and CustPO.CustPO = bMSTD.CustPO	

LEFT OUTER JOIN bEMEM Equipment 
	ON  bMSTD.EMCo			= Equipment.EMCo
	AND bMSTD.Equipment	= Equipment.Equipment

LEFT OUTER JOIN  bEMCM EMCategory 
	ON  bMSTD.EMCo			= EMCategory.EMCo
	AND Equipment.Category	= EMCategory.Category

Left Join bJCCT With (NoLock) 
	on bJCCT.PhaseGroup=bMSTD.PhaseGroup 
	and bJCCT.CostType=bMSTD.HaulJCCType

Left Outer Join bMSVT 
	on  bMSVT.VendorGroup = bMSTD.VendorGroup
	and	bMSVT.Vendor = bMSTD.HaulVendor
	and bMSVT.Truck = bMSTD.Truck

Left Outer Join bMSTT
	on bMSTT.MSCo=bMSTD.MSCo
	and bMSTT.TruckType = bMSVT.TruckType	
	
join vDDBICompanies ON vDDBICompanies.Co = bMSCO.MSCo 

Where bMSTD.Void = 'N'

GO
GRANT SELECT ON  [dbo].[viFact_MSSales] TO [public]
GRANT INSERT ON  [dbo].[viFact_MSSales] TO [public]
GRANT DELETE ON  [dbo].[viFact_MSSales] TO [public]
GRANT UPDATE ON  [dbo].[viFact_MSSales] TO [public]
GO
