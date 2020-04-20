SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE View [dbo].[viDim_HRBenefitCodes]

/********************************************************
 *   
 * Usage:  Dimension View of Benefits defined in 
 * the HR Module
 *
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/12/09 129902      C Wirtz		New
 * 11/04/10 135047		H Huynh		Join bHRCO for company security
 *
 ********************************************************/

AS


Select
	bHRCO.KeyID as HRCoID
	,bHRBC.KeyID as BenefitCodeID
	,bHRBC.BenefitCode                    
	,bHRBC.Description
	,bHRBC.PlanName
	,bHRBC.PlanNumber
From bHRBC With (NoLock)
Join bHRCO With (NoLock) on bHRCO.HRCo = bHRBC.HRCo
Join vDDBICompanies With (NoLock)on vDDBICompanies.Co=bHRBC.HRCo

Union All

Select  Null
		,0 as BenefitCodeID
		,Null as BenefitCode
        ,'Unassigned' as Description
		,null
		,null


GO
GRANT SELECT ON  [dbo].[viDim_HRBenefitCodes] TO [public]
GRANT INSERT ON  [dbo].[viDim_HRBenefitCodes] TO [public]
GRANT DELETE ON  [dbo].[viDim_HRBenefitCodes] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HRBenefitCodes] TO [public]
GRANT SELECT ON  [dbo].[viDim_HRBenefitCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_HRBenefitCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_HRBenefitCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_HRBenefitCodes] TO [Viewpoint]
GO
