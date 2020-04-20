SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE View [dbo].[viDim_HRAccidents]

/********************************************************
 *   
 * Usage:  Dimension View of Accidents defined in 
 * the HR Module
 *
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 07/22/09 129902		C Wirtz		New
 * 11/04/10 135047		H Huynh		Join bHRCO for company security
 *
 ********************************************************/

AS
Select
	bHRCO.KeyID as HRCoID	 
	,bHRAT.KeyID as AccidentID
	,bHRAT.Accident
	,case when JobSiteYN='Y' then 'Job Site'
		  when EmployerPremYN='Y' then 'Employer Site'
		  else 'Unknown'
	 end as AccidentSite
	,'Acc#:  '+ bHRAT.Accident+' Date:  '+Convert(varchar(8),AccidentDate,1)+' '+bHRAT.Location as AccidentDescription

From bHRAT With (NoLock)
Join bHRCO With (NoLock) on bHRCO.HRCo =  bHRAT.HRCo
Join vDDBICompanies With (NoLock)on vDDBICompanies.Co=bHRAT.HRCo



Union All

select   null
		,0 as AccidentID
        ,'Unassigned' as Accident
		,null
		,null



GO
GRANT SELECT ON  [dbo].[viDim_HRAccidents] TO [public]
GRANT INSERT ON  [dbo].[viDim_HRAccidents] TO [public]
GRANT DELETE ON  [dbo].[viDim_HRAccidents] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HRAccidents] TO [public]
GO
