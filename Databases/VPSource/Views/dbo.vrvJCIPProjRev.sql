SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvJCIPProjRev]

/************
*   CREATED:  DH 7/8/11 (D-02251)
*   MODIFIED:
*   
*   USAGE: Used by the JC Projections - Revenue Report.  Returns amounts from JCIP and
*		  the EstRev_Mth field from the function vf_rptJCEstRevenue.  
*
*************/

AS

SELECT	 JCCo
		, Contract
		, Item
		, Mth
		, ContractUnits
		, ContractAmt 
		, ProjUnits
		, ProjDollars 
		, BilledUnits
		, BilledAmt 
		, EstRev.EstRevenue_Mth
		, EstUnits_Mth
   FROM dbo.JCIP
   CROSS APPLY vf_rptJCEstRevenue (JCIP.JCCo,JCIP.Contract,JCIP.Item,JCIP.Mth) EstRev
   
   
   
   
GO
GRANT SELECT ON  [dbo].[vrvJCIPProjRev] TO [public]
GRANT INSERT ON  [dbo].[vrvJCIPProjRev] TO [public]
GRANT DELETE ON  [dbo].[vrvJCIPProjRev] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCIPProjRev] TO [public]
GO
