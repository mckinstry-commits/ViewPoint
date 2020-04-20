SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE View [dbo].[viDim_HRCodeMaster]
/**************************************************
 * ALTERd: CWW 06/15/09
 * Modified:      
 *
 * Usage:  Dimension View of Code Types defined in 
 * the HR Module
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 06/15/09 129902      C Wirtz		New
 * 11/04/10 135047		H Huynh		Join bHRCO for company security
 *
 ********************************************************/
as 


select	bHRCO.KeyID as HRCoID
		,bHRCM.KeyID as CodeMasterID
		,bHRCM.Code
		,bHRCM.Type
		,bHRCM.Description
from bHRCM
Inner Join bHRCO With (NoLock) on bHRCO.HRCo = bHRCM.HRCo
Inner Join vDDBICompanies on vDDBICompanies.Co=bHRCM.HRCo

union all

Select	Null
		,0
		,Null
		,Null
		,'Unassigned'


GO
GRANT SELECT ON  [dbo].[viDim_HRCodeMaster] TO [public]
GRANT INSERT ON  [dbo].[viDim_HRCodeMaster] TO [public]
GRANT DELETE ON  [dbo].[viDim_HRCodeMaster] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HRCodeMaster] TO [public]
GRANT SELECT ON  [dbo].[viDim_HRCodeMaster] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_HRCodeMaster] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_HRCodeMaster] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_HRCodeMaster] TO [Viewpoint]
GO
