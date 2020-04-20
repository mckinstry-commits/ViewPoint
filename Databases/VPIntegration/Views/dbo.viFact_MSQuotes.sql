SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE View

[dbo].[viFact_MSQuotes]

as

Select	  --Detail.MSCo
		  bMSCO.KeyID as MSCoID
		, bMSQH.Quote
		, bMSQH.QuoteType
		--, Detail.Customer
		, isnull(bARCM.KeyID,0) as CustID
		, bHQUM.KeyID as UMID
		, bMSQH.CustJob
		, bMSQH.CustPO
		--, Detail.JCCo
		--, Detail.Job
		, isnull(bJCJM.KeyID,0) as JobID
		--, Detail.Material
		, bHQMT.KeyID as HQMaterialID
		--, Detail.Location
		, bINLM.KeyID as INLocationID
		, isnull(bAPVM.KeyID,0) as MaterialVendorID
		--, Detail.LocGroup
		--, Detail.MatlGroup
		--, Detail.Category
		--, Detail.PhaseGroup
		--, Detail.Phase
		, isnull(bJCJP.KeyID,0) as JobPhaseID
		, isnull(CustJob.CustJobID,0) as 'CustJobID'
		, isnull(CustPO.CustPOID,0) as 'CustPOID'
		--, Detail.UM
		, case when Detail.Status = 0 then Detail.QuoteUnits end as UnitsBid
		, case when Detail.Status = 1 then Detail.QuoteUnits end as UnitsOrdered
		, case when Detail.Status = 2 then Detail.QuoteUnits end as UnitsCompleted
		, Detail.UnitPrice
		, case when Detail.Status = 0 then Detail.QuoteUnits*Detail.UnitPrice end as AmountBid
		, case when Detail.Status = 1 then Detail.QuoteUnits*Detail.UnitPrice end as AmountOrdered
		, case when Detail.Status = 2 then Detail.QuoteUnits*Detail.UnitPrice end as AmountCompleted

		  

From bMSQD Detail
Inner Join bMSQH With (nolock)
	on  bMSQH.MSCo = Detail.MSCo
	and bMSQH.Quote = Detail.Quote

Inner Join bHQMT With (NoLock)	
	on  bHQMT.MatlGroup = Detail.MatlGroup
	and bHQMT.Material = Detail.Material
	and bHQMT.Type = 'S'

Inner Join  bHQUM
	on bHQUM.UM = bHQMT.StdUM	

Inner Join bINLM With (NoLock)
	on  bINLM.INCo = Detail.MSCo
	and	bINLM.Loc = Detail.FromLoc

Inner Join bMSCO With (NoLock)
	on bMSCO.MSCo = Detail.MSCo

Left Outer Join bARCM With (NoLock)
	on  bARCM.CustGroup = bMSQH.CustGroup
	and bARCM.Customer = bMSQH.Customer

Left Outer Join bJCJM With (NoLock)
	on  bJCJM.JCCo = bMSQH.JCCo	
	and bJCJM.Job = bMSQH.Job
	
Left Outer Join bJCJP With (NoLock)
	on  bJCJP.JCCo = bMSQH.JCCo
	and	bJCJP.Job = bMSQH.Job
	and bJCJP.PhaseGroup = Detail.PhaseGroup
	and bJCJP.Phase = Detail.Phase

Left Outer Join bAPVM With (NoLock)
	on  bAPVM.VendorGroup = Detail.VendorGroup
	and bAPVM.Vendor = Detail.MatlVendor	

Left Outer Join viDim_MSCustomerJob CustJob
	on  CustJob.MSCo = bMSQH.MSCo
	and	CustJob.CustGroup = bMSQH.CustGroup
	and CustJob.Customer = bMSQH.Customer
	and CustJob.CustJob = bMSQH.CustJob

Left Outer Join viDim_MSCustomerPO CustPO
	on  CustPO.MSCo = bMSQH.MSCo
	and	CustPO.CustGroup = bMSQH.CustGroup
	and CustPO.Customer = bMSQH.Customer
	and CustPO.CustPO = bMSQH.CustPO

Inner Join vDDBICompanies on vDDBICompanies.Co=Detail.MSCo				

	








GO
GRANT SELECT ON  [dbo].[viFact_MSQuotes] TO [public]
GRANT INSERT ON  [dbo].[viFact_MSQuotes] TO [public]
GRANT DELETE ON  [dbo].[viFact_MSQuotes] TO [public]
GRANT UPDATE ON  [dbo].[viFact_MSQuotes] TO [public]
GO
