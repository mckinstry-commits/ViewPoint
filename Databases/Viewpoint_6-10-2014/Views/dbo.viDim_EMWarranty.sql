SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE view [dbo].[viDim_EMWarranty]
as 

--EM Warranty Dimension
select 
bEMWF.KeyID as 'WarrantyKeyID',
bEMCO.KeyID AS EMCoID,
WarrantyDesc,
case when bEMWF.Status='A' then 'Active'
	 when bEMWF.Status='I' then 'Inactive'
end as WarrantyStatus
from bEMWF
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bEMWF.EMCo
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = bEMWF.EMCo


GO
GRANT SELECT ON  [dbo].[viDim_EMWarranty] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMWarranty] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMWarranty] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMWarranty] TO [public]
GRANT SELECT ON  [dbo].[viDim_EMWarranty] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_EMWarranty] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_EMWarranty] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_EMWarranty] TO [Viewpoint]
GO
