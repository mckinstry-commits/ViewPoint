SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_JCContractItem]

/**************************************************
 * Alterd: DH 3/17/08
 * Modified:      
 * Usage:  Dimension View of Contract Items from Contract Master
 *          for use in SSAS Cubes. 
 *
 ********************************************************/

as

select  bJCCI.KeyID as ContractItemID,
		bJCCM.KeyID as ContractID,
		bJCCI.JCCo,
		bJCCO.KeyID as JCCoID,
        bJCCI.Contract,
		bJCCI.Item,
        ltrim(bJCCI.Item)+' '+isnull(bJCCI.Description,'') as ItemDescription,
		case when bJCCI.BillType='P' then 'Progress'
			 when bJCCI.BillType='T' then 'T&M'
			 when bJCCI.BillType='B' then 'Both'
			 when bJCCI.BillType='N' then 'None'
		end as ItemBillType,
        bJCSI.KeyID as SICodeID,
        isnull(bJCCI.SIRegion,0) as SIRegion,
        bJCCI.SICode,
		bJCCI.SIRegion+' '+bJCCI.SICode+' '+isnull(bJCSI.Description,'') as SIRegionAndCodeDescription,
		isnull(bJBBG.KeyID,0) as BillGroupID,
		isnull(bJBBG.BillGroup,'Blank') as BillGroup,
		case when bJBBG.BillGroup is not null then isnull(bJBBG.Description,'') else 'Blank' end  as BillGroupDescription
		
From bJCCI
Join bJCCO on bJCCO.JCCo=bJCCI.JCCo
Join bJCCM on bJCCM.JCCo=bJCCI.JCCo and bJCCM.Contract=bJCCI.Contract
Left Join bJBBG on bJBBG.JBCo=bJCCI.JCCo and bJBBG.Contract=bJCCI.Contract and bJBBG.BillGroup=bJCCI.BillGroup
Left Join bJCSI on bJCSI.SIRegion=bJCCI.SIRegion and bJCSI.SICode=bJCCI.SICode
Join vDDBICompanies on vDDBICompanies.Co=bJCCI.JCCo


GO
GRANT SELECT ON  [dbo].[viDim_JCContractItem] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCContractItem] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCContractItem] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCContractItem] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCContractItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCContractItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCContractItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCContractItem] TO [Viewpoint]
GO
