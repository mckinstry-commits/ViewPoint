SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRCobra]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning Cobra enrollment and eligibility
 *         data for use as Measures in SSAS Cubes. 
 *
 * The granularity will be at the dependent level 
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/06/09 129902     C Wirtz		New
 *
 ********************************************************/

AS
--Extract specific accident information 
With HRCobraExtract
as

(Select	 
	'COBRA Starting' as RecType
	,bHRRC.HRCo
	,bHRRC.HRRef
	,bHRRC.DependSeq
	,bHRRC.COBRAStart
	,bHRRC.COBRAEnd
	,bHRRC.DateDeclined
	,CalculatedEndDate = 
		case When ((bHRRC.DiscontinueDate is not null) and bHRRC.DiscontinueDate < bHRRC.COBRAEnd)  
					Then bHRRC.DiscontinueDate Else bHRRC.COBRAEnd End
	,COBRAStartingCount = 1
	,COBRAEndingCount = null
	,EventDate = bHRRC.COBRAStart
From bHRRC With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRRC.HRCo 

Union All
Select	 
	'COBRA Ending' as RecType
	,bHRRC.HRCo
	,bHRRC.HRRef
	,bHRRC.DependSeq
	,bHRRC.COBRAStart
	,bHRRC.COBRAEnd
	,bHRRC.DateDeclined
	,CalculatedEndDate = 
		case When ((bHRRC.DiscontinueDate is not null) and bHRRC.DiscontinueDate < bHRRC.COBRAEnd)  
					Then bHRRC.DiscontinueDate Else bHRRC.COBRAEnd End
	,COBRAStartingCount = null
	,COBRAEndingCount = 1
	,EventDate = 
		case When ((bHRRC.DiscontinueDate is not null) and bHRRC.DiscontinueDate < bHRRC.COBRAEnd)  
					Then bHRRC.DiscontinueDate Else bHRRC.COBRAEnd End
From bHRRC With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRRC.HRCo 
),
HRCobra
as
(Select	 
	 c.HRCo
	,c.HRRef
	,c.DependSeq
	,c.COBRAStartingCount 
	,c.COBRAEndingCount 
	,EventDateID =  DateDiff(d,'1/1/1950',isnull(c.EventDate,'1/1/1950'))



From HRCobraExtract c
)


--Build the Keys
select 
	bHRCO.KeyID as HRCoID
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
	,isnull(bHRPC.KeyID,0) as PositionCodeID
	,HRCobra.DependSeq
	,HRCobra.COBRAStartingCount 
	,HRCobra.COBRAEndingCount 
	,HRCobra.EventDateID 

From HRCobra Inner Join bHRCO With (NoLock)
	ON HRCobra.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HRCobra.HRCo = bHRRM.HRCo and HRCobra.HRRef = bHRRM.HRRef 
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup
left Outer Join bHRPC With (NoLock)
	ON HRCobra.HRCo = bHRPC.HRCo and bHRRM.PositionCode = bHRPC.PositionCode 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=HRCobra.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HRCobra] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRCobra] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRCobra] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRCobra] TO [public]
GO
