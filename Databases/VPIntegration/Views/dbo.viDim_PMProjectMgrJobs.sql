SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE view [dbo].[viDim_PMProjectMgrJobs]

/**
Usage:  Selects Project Mangers and associated jobs for the PM Project Manager Jobs dimesions and hierarchy
in the PM Cube.
Mod:  1/20/11.  DH  Issue 143242.  Changed the order by clause for ProjectMgrName
****/

as

With PMName
(ProjectMgrName,
 ProjectMgrNameID)

as

(select bJCMP.Name,
        row_number() over (order by (bJCMP.Name))
 From bJCMP With (Nolock)
 Join bJCCO with(nolock) on bJCCO.JCCo = bJCMP.JCCo
 Join vDDBICompanies on vDDBICompanies.Co=bJCMP.JCCo
 Group By bJCMP.Name)


select 
 bJCJM.JCCo
, bJCCO.KeyID as JCCoID
,bJCJM.Job
,bJCJM.KeyID as JobID
,Job + ' '+ Description as 'JobAndName'
,bJCJM.ProjectMgr
,bJCMP.KeyID as ProjMgrID
,PMName.ProjectMgrNameID
,bJCMP.Name as 'ProjectMgrName'
,Row_Number() Over (Order by bJCJM.JCCo, bJCJM.ProjectMgr, bJCJM.Job) as PMJobID

from bJCJM
Join bJCCO with(nolock) on bJCCO.JCCo = bJCJM.JCCo
Join vDDBICompanies on vDDBICompanies.Co=bJCJM.JCCo
join bJCMP with(nolock) on bJCJM.JCCo=bJCMP.JCCo and bJCJM.ProjectMgr=bJCMP.ProjectMgr
join PMName on PMName.ProjectMgrName=bJCMP.Name




GO
GRANT SELECT ON  [dbo].[viDim_PMProjectMgrJobs] TO [public]
GRANT INSERT ON  [dbo].[viDim_PMProjectMgrJobs] TO [public]
GRANT DELETE ON  [dbo].[viDim_PMProjectMgrJobs] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PMProjectMgrJobs] TO [public]
GO
