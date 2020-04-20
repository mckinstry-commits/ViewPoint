SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE View [dbo].[viDim_HRPositionCode]

/********************************************************
 *   
 * Usage:  Dimension View of Position Codes defined in 
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


Select  bHRCO.KeyID as HRCoID
		,bHRPC.KeyID as PositionCodeID
		,bHRPC.PositionCode as PositionCode
		,bHRPC.JobTitle as PositionCodeTitle
		,bHRPC.PartTimeYN as PositionPartTimeYN
		,Case bHRPC.Type  
			When 'E' then 'Exempt'
			When 'N' then 'Non-Exempt'
			When 'U' then 'Union'
			Else 'Unknown'
		End  as PositionType
		,bHRPC.ClosingDate as PositionClosingDate
		,datediff(dd,'1/1/1950',bHRPC.ClosingDate) as PositionClosingDateID
		,PositionOpened = Case When isnull(bHRPC.OpenJobs,0) > 0  --If the position is opened set the value to 1
			and (bHRPC.ClosingDate is null or bHRPC.ClosingDate > GetDate()) then 1 Else 0 End  
		,bHRPC.BegSalary as BeginningSalary
		,bHRPC.EndSalary as EndingSalary
		,bHRPC.OpenJobs as NumberOpenPositions
From bHRPC  With (NoLock)
Inner Join bHRCO With (NoLock) ON bHRPC.HRCo = bHRCO.HRCo 
Join vDDBICompanies With (NoLock)on vDDBICompanies.Co=bHRPC.HRCo

Union All

select  Null
		,0 as PositionCodeID
		,Null as PositionCode
        ,'Unassigned' as PositionCodeTitle
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null


--add
--Number of Open positions
--beginning and ending salary range


GO
GRANT SELECT ON  [dbo].[viDim_HRPositionCode] TO [public]
GRANT INSERT ON  [dbo].[viDim_HRPositionCode] TO [public]
GRANT DELETE ON  [dbo].[viDim_HRPositionCode] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HRPositionCode] TO [public]
GO
