SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_APVendor]

/**************************************************
 * Altered: DH 6/19/08
 * Modified:      
 * Usage:  Dimension View from AP Vendor Master for use in SSAS Cubes. 
 *         
 *
 ********************************************************/

as

Select	bAPVM.KeyID as APVendorID,
		bAPVM.SortName as VendorSortName,
		bAPVM.Name as VendorName,
		isnull(APVM_Master.KeyID,0) as APMasterVendorID,
		APVM_Master.SortName as MasterVendorSortName,
		APVM_Master.Name as MasterVendorName
From bAPVM
Left Join bAPVM APVM_Master on APVM_Master.VendorGroup=bAPVM.VendorGroup
		  and APVM_Master.Vendor=bAPVM.MasterVendor

union all

/*Default 0 ID that links back to Fact Views for non-AP transactions (or AP transactions without Vendors*/

Select	0 as APVendorID,
		Null as VendorSortName,
		'Unassigned' as VendorName,
		Null as APMasterVendorID,
		Null as MasterVendorSortName,
		Null as MasterVendorName


GO
GRANT SELECT ON  [dbo].[viDim_APVendor] TO [public]
GRANT INSERT ON  [dbo].[viDim_APVendor] TO [public]
GRANT DELETE ON  [dbo].[viDim_APVendor] TO [public]
GRANT UPDATE ON  [dbo].[viDim_APVendor] TO [public]
GO
