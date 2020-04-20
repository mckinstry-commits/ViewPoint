SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_JCDeptContract_Hierarchy]
/**************************************************
 * Alterd: DH 4/25/08
 * Modified:      
 * Usage:  Selects and orders results from JC Contract Items (bJCCI) by
 *         JC Department, Contract, and Item.  Used in SSAS JC Cube as a 
 *         pre-defined drillup/drilldown path.
 * 
 ***************************************************/

as

Select   bJCCI.KeyID as DeptContractHierarchyID
        ,bJCCI.JCCo
        ,bJCCO.KeyID as JCCoID
        ,bHQCO.Name as CompanyName
        ,bJCCI.Contract
        ,bJCCM.KeyID as ContractID
        ,bJCCM.Contract+' '+bJCCM.Description as ContractAndDescription
        ,bJCCI.Item
        ,ltrim(bJCCI.Item)+' '+isnull(bJCCI.Description,'') as ItemDesc
        ,bJCDM.KeyID as JCDeptID
        ,bJCDM.Description as DeptDesc
From bJCCI With (NoLock)
Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCI.JCCo
Join bHQCO With (NoLock) on bHQCO.HQCo=bJCCI.JCCo
Join bJCCM With (NoLock) on bJCCM.JCCo=bJCCI.JCCo and bJCCM.Contract=bJCCI.Contract
Join bJCDM With (NoLock) on bJCDM.JCCo=bJCCI.JCCo and bJCDM.Department=bJCCI.Department
Join vDDBICompanies on vDDBICompanies.Co=bJCCI.JCCo

GO
GRANT SELECT ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCDeptContract_Hierarchy] TO [Viewpoint]
GO
