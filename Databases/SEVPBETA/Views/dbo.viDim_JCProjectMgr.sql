SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE view [dbo].[viDim_JCProjectMgr]
as

With PMName
(ProjectMgrName,
 ProjectMgrNameID)

as

(select bJCMP.Name,
        row_number() over (order by (select 1))
 From bJCMP With (Nolock)
 Group By bJCMP.Name)

select  0 as ProjMgrID,
        Null as ProjectMgr,
        'Unassigned' as Name,
		0 as ProjectMgrNameID,
	    Null as JCCo,
	    0 as JCCoID
        
union all

select   bJCMP.KeyID as ProjMgrID,
         bJCMP.ProjectMgr,
         bJCMP.Name,
		 PMName.ProjectMgrNameID,
         bJCMP.JCCo,
         bJCCO.KeyID as JCCoID

From bJCMP With (Nolock)
Join bJCCO With (Nolock) on bJCCO.JCCo = bJCMP.JCCo
Join vDDBICompanies on vDDBICompanies.Co=bJCMP.JCCo
Join PMName on PMName.ProjectMgrName=bJCMP.Name



GO
GRANT SELECT ON  [dbo].[viDim_JCProjectMgr] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCProjectMgr] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCProjectMgr] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCProjectMgr] TO [public]
GO
