SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_JCDept]

as

select   bJCDM.KeyID as JCDeptID
        ,bJCDM.JCCo
        ,bJCCO.KeyID as JCCoID
        ,bJCDM.Department
        ,bJCDM.Description
        ,bJCDM.GLCo
        ,bJCDM.OpenRevAcct
        ,bJCDM.ClosedRevAcct
From bJCDM
Join bJCCO on bJCCO.JCCo = bJCDM.JCCo
Join vDDBICompanies on vDDBICompanies.Co=bJCDM.JCCo


GO
GRANT SELECT ON  [dbo].[viDim_JCDept] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCDept] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCDept] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCDept] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCDept] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCDept] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCDept] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCDept] TO [Viewpoint]
GO
