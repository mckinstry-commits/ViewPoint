SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[POVMUnionAllPOSM]
AS

Select POVM.VendMatId, 
		POVM.Material, 
		POVM.Description,
		case HQMT.Type 
			when 'S' then 'Standard' 
			when 'E' then 'Equipment' 
		end as 'HQMatlType',
		'Vendor Matl' as Type,
		POVM.VendorGroup,
		POVM.Vendor,
		POVM.MatlGroup
From POVM with (nolock)
Join HQMT with(nolock) on POVM.Material = HQMT.Material and POVM.MatlGroup = HQMT.MatlGroup
Union ALL
Select POSM.VendMatId,
		POSM.Material,
		POSM.Description,
		case HQMT.Type 
			when 'S' then 'Standard' 
			when 'E' then 'Equipment' 
		end as 'HQMatlType',
		'Substitute Matl' as Type,
		POSM.VendorGroup,
		POSM.Vendor,
		POSM.MatlGroup
from POSM
Join HQMT with(nolock) on POSM.Material = HQMT.Material and POSM.MatlGroup = HQMT.MatlGroup



GO
GRANT SELECT ON  [dbo].[POVMUnionAllPOSM] TO [public]
GRANT INSERT ON  [dbo].[POVMUnionAllPOSM] TO [public]
GRANT DELETE ON  [dbo].[POVMUnionAllPOSM] TO [public]
GRANT UPDATE ON  [dbo].[POVMUnionAllPOSM] TO [public]
GRANT SELECT ON  [dbo].[POVMUnionAllPOSM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POVMUnionAllPOSM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POVMUnionAllPOSM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POVMUnionAllPOSM] TO [Viewpoint]
GO
