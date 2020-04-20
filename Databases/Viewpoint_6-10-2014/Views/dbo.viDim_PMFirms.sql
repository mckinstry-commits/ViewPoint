SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[viDim_PMFirms]
as 
select bPMFM.KeyID as FirmID
	,bPMFM.VendorGroup
	,FirmNumber
	,FirmName
	,bPMFT.KeyID as FirmTypeID
	,bPMFM.FirmType
	,bPMFT.Description as FirmTypeDescription
	,bPMFM.SortName
	,MailCity
	,MailState
	--,bPMFM.Vendor
	--,bAPVM.Name as VendorName
	
from bPMFM  
--left outer join bAPVM with (nolock) on bPMFM.VendorGroup=bAPVM.VendorGroup and bPMFM.Vendor=bAPVM.Vendor
left outer join bPMFT with (nolock) on bPMFT.FirmType=bPMFM.FirmType

GO
GRANT SELECT ON  [dbo].[viDim_PMFirms] TO [public]
GRANT INSERT ON  [dbo].[viDim_PMFirms] TO [public]
GRANT DELETE ON  [dbo].[viDim_PMFirms] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PMFirms] TO [public]
GRANT SELECT ON  [dbo].[viDim_PMFirms] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_PMFirms] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_PMFirms] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_PMFirms] TO [Viewpoint]
GO
