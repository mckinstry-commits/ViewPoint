SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***********************************************************************
*	Created: 1/24/2011
*	Author : HH
*	Purpose: This view lists following risks from bidders/vendors 
*			 in PC Potential Projects:
*			 - relation between CurrentCapacity/BondingCapacity and 
*				vendor subcontract agreements and payments
*			 - Compliances (since SLCT's logic is dependant from / covered by 
*				APVC, only information in SLCT is essential)
*
*	Reports: PCSubcontractRisk.rpt
*
*	Mods:	 
***********************************************************************/


CREATE VIEW [dbo].[vrvPCSubcontractRisk]
AS
WITH ctePCBidVendors (JCCo, PotentialProject, BidPackage, VendorGroup, Vendor) AS
(
	SELECT DISTINCT JCCo
				, PotentialProject
				, BidPackage
				, VendorGroup
				, Vendor 
	FROM PCBidPackageBidList
)    
SELECT cte.*
		, vm.Name
		, pcq.Qualified
		, pcq.BondCapacity
		, slh.SL
		, (SELECT Sum(isnull(PaidAmount,0)) 
				FROM brvSLLedgerDetail b
				WHERE cte.JCCo = b.SLCo and slh.SL = b.SL) 
			AS SubcontractAgreement
		, (SELECT Sum(isnull(PaidAmount,0)) 
				FROM brvSLLedgerDetail b
				WHERE cte.JCCo = b.SLCo and slh.SL = b.SL and b.PaidDate IS NOT NULL) 
			AS InvoicesPaid
		, (SELECT Sum(isnull(PaidAmount,0)) 
				FROM brvSLLedgerDetail b
				WHERE cte.JCCo = b.SLCo and slh.SL = b.SL and b.PaidDate IS NULL) 
			AS LeftToPay			
		, pcq.BondCapacity - (SELECT Sum(isnull(PaidAmount,0)) 
									FROM brvSLLedgerDetail b 
									WHERE cte.JCCo = b.SLCo and slh.SL = b.SL and b.PaidDate IS NULL) 
			AS CurrentCapacity
		--, vc.CompCode AS APComCode
		--, ct.CompCode AS ComCode
		--, ct.Description AS ComCodeDesc
		--, cp.CompType
		--, ct.ExpDate
		--, ct.Verify
		--, ct.Complied
FROM ctePCBidVendors cte
INNER JOIN APVM vm 
	on cte.VendorGroup = vm.VendorGroup and cte.Vendor = vm.Vendor
INNER JOIN PCQualifications pcq 
	on pcq.VendorGroup = cte.VendorGroup and pcq.Vendor = cte.Vendor
INNER JOIN SLHD slh
	on slh.VendorGroup = cte.VendorGroup and slh.Vendor = cte.Vendor and slh.JCCo = cte.JCCo
--INNER JOIN APVC vc
--	on vc.Vendor = cte.Vendor and vc.VendorGroup = cte.VendorGroup 
--INNER JOIN SLCT ct
--	on slh.Vendor = cte.Vendor and ct.VendorGroup = cte.VendorGroup and cte.JCCo = ct.SLCo and ct.SL = slh.SL
--INNER JOIN HQCP cp
--	on cp.CompCode = ct.CompCode




GO
GRANT SELECT ON  [dbo].[vrvPCSubcontractRisk] TO [public]
GRANT INSERT ON  [dbo].[vrvPCSubcontractRisk] TO [public]
GRANT DELETE ON  [dbo].[vrvPCSubcontractRisk] TO [public]
GRANT UPDATE ON  [dbo].[vrvPCSubcontractRisk] TO [public]
GO
