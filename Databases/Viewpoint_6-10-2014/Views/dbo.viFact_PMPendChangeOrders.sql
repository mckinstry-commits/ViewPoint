SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE view [dbo].[viFact_PMPendChangeOrders]
as

with PMPendChangeOrders
(PMCo,
Contract,
Project,
PCOType,
PCO,
PCOItem,
ACO,
ACOItem,
/*PhaseGroup,
Phase,
CostType,*/
PendingAmt,
EstCost)
as



( SELECT PMCo, bPMOI.Contract, Project, PCOType, PCO, PCOItem, ACO, ACOItem,
 /*PhaseGroup=0, Phase = '', CostType=0,*/
  case when bPMOI.Approved='Y' then bPMOI.ApprovedAmt
        when bPMOI.Approved='N' then
           case when bPMOI.FixedAmountYN='Y' 
                then bPMOI.FixedAmount 
           else PendingAmount end 
    end
    as PendingAmount
  ,EstCost=0
 FROM   bPMOI 
   INNER JOIN bJCJM With (nolock) ON bPMOI.PMCo=bJCJM.JCCo AND bPMOI.Project=bJCJM.Job 
 Join bPMSC on bPMSC.Status=bPMOI.Status
Where bPMOI.InterfacedDate is null and bPMSC.IncludeInProj<>'N'
  /*LEFT OUTER JOIN bPMSC With (nolock) ON bPMOP.PendingStatus=bPMSC.Status
 where  bPMSC.CodeType<>'F'*/

union all

select L.PMCo, I.Contract, L.Project, L.PCOType, L.PCO, L.PCOItem, L.ACO, L.ACOItem,
/*PhaseGroup, Phase, CostType,*/ 0, EstCost

from bPMOL L With (nolock)
inner join bPMOI I With (nolock) on L.PMCo=I.PMCo and L.Project=I.Project and L.PCOType=I.PCOType and L.PCO=I.PCO 
									and L.PCOItem=I.PCOItem 
									and isnull(L.ACO,'')=isnull(I.ACO,'') and isnull(L.ACOItem,'')=isnull(I.ACOItem,'')
Join bPMSC on bPMSC.Status=I.Status
Where I.InterfacedDate is null and bPMSC.IncludeInProj<>'N'

union all

Select bPMOA.PMCo, bPMOI.Contract, bPMOA.Project, bPMOA.PCOType, bPMOA.PCO, bPMOA.PCOItem, Null, Null,
       0, sum(bPMOA.AddOnAmount) as EstCost
From bPMOA
Join bPMPA on bPMPA.PMCo=bPMOA.PMCo and bPMPA.Project=bPMOA.Project and bPMPA.AddOn=bPMOA.AddOn and bPMPA.Phase is not null
Join bPMOI on bPMOI.PMCo=bPMOA.PMCo and bPMOI.Project=bPMOA.Project and bPMOI.PCOType=bPMOA.PCOType
		   and bPMOI.PCO=bPMOA.PCO and bPMOI.PCOItem=bPMOA.PCOItem and bPMOI.ACO is null and bPMOI.ACOItem is null
 Join bPMSC on bPMSC.Status=bPMOI.Status
Where bPMOI.InterfacedDate is null and bPMSC.IncludeInProj<>'N' and bPMOI.Approved='N'
Group By bPMOA.PMCo, bPMOI.Contract, bPMOA.Project, bPMOA.PCOType, bPMOA.PCO, bPMOA.PCOItem

/*left outer join bPMSC With (nolock) on bPMOP.PendingStatus=bPMSC.Status
     
where bPMSC.CodeType <> 'F'*/
)

Select 
         bPMCO.KeyID as PMCoID
        ,bJCCM.KeyID as ContractID
		,bJCCM.Contract+' '+isnull(bJCCM.Description,'') as ContractAndDescription
        ,bJCJM.KeyID as JobID
		,bJCJM.Job +' '+ bJCJM.Description as JobAndDescription
        ,isnull(bJCMP.KeyID,0) as ProjMgrID
		,isnull(bPMOI.KeyID,0) as PCOItemID
		,isnull(bPMOP.KeyID,0) as PCOID
		,viDim_PMProjectMgrJobs.PMJobID
		,bPMDT.KeyID as PMDocTypeID
        ,'PCO Type:  '+isnull(PMPendChangeOrders.PCOType,'None') as PCOType
		,'PCO:  '+isnull(PMPendChangeOrders.PCO,'None') as PCO
		,'PCO:  '+isnull(PMPendChangeOrders.PCO,'None')+' '+isnull(bPMOP.Description,'') as PCOandDescription
		,'PCO Item:  '+isnull(PMPendChangeOrders.PCOItem,'None') as PCOItem
		,'PCO Item:  '+bPMOI.Description+' / Status: '+isnull(bPMSC.Description,'') as COItemDescriptionAndStatus
		,bPMOI.Status as COItemStatus
		,bPMSC.Description as COItemStatusDescription
		,'ACO: '+isnull(PMPendChangeOrders.ACO,'None')+' / ACO Item: '+isnull(PMPendChangeOrders.ACOItem,'') as ACOandACOItem
		/*,bJCJP.PhaseGroup
		,bJCJP.Phase
		,bJCCT.CostType*/
		,PMPendChangeOrders.PendingAmt as ContractChangeAmt
		,PMPendChangeOrders.EstCost
		,Case when bPMOP.PendingStatus < 2 then 1 else null end as PendingChgOrderCount
		,Case when bPMOP.PendingStatus=0 then '0-Pending'
			  when bPMOP.PendingStatus=1 then '1-Partial'
			  when bPMOP.PendingStatus=2 then '2-Approved'
			  when bPMOP.PendingStatus=3 then '3-Final'
			  when bPMOP.PendingStatus is null and PMPendChangeOrders.ACO is not null then '2-Approved'
		 End as PendingStatus
		,Row_Number() Over (Order by PMPendChangeOrders.PMCo, PMPendChangeOrders.Project,
                            PMPendChangeOrders.PCOType, PMPendChangeOrders.PCO, PMPendChangeOrders.PCOItem,
							PMPendChangeOrders.ACO, PMPendChangeOrders.ACOItem) as PendingCOID

From PMPendChangeOrders
Join vDDBICompanies on vDDBICompanies.Co=PMPendChangeOrders.PMCo
Left Outer Join bPMOP With (nolock) on PMPendChangeOrders.PMCo=bPMOP.PMCo and PMPendChangeOrders.Project=bPMOP.Project
				 and PMPendChangeOrders.PCOType=bPMOP.PCOType and PMPendChangeOrders.PCO=bPMOP.PCO 
inner join bPMOI With (nolock) on PMPendChangeOrders.PMCo=bPMOI.PMCo and PMPendChangeOrders.Project=bPMOI.Project 
							   and isnull(PMPendChangeOrders.PCOType,'')=isnull(bPMOI.PCOType,'') and isnull(PMPendChangeOrders.PCO,'')=isnull(bPMOI.PCO,'') 
							   and isnull(PMPendChangeOrders.PCOItem,'')=isnull(bPMOI.PCOItem,'') and isnull(PMPendChangeOrders.ACO,'')=isnull(bPMOI.ACO,'') 
							   and isnull(PMPendChangeOrders.ACOItem,'')=isnull(bPMOI.ACOItem,'')
Left Outer Join bPMSC With (nolock) on bPMSC.Status=bPMOI.Status
Inner Join bPMCO With (nolock) on PMPendChangeOrders.PMCo=bPMCO.PMCo
Inner Join bHQCO With (nolock) on PMPendChangeOrders.PMCo=bHQCO.HQCo
Inner Join bJCCM With (nolock) on PMPendChangeOrders.PMCo=bJCCM.JCCo and PMPendChangeOrders.Contract=bJCCM.Contract
Inner Join bJCJM With (nolock) on PMPendChangeOrders.PMCo=bJCJM.JCCo and PMPendChangeOrders.Project=bJCJM.Job
Left Outer Join bJCMP With (nolock) on bJCJM.JCCo=bJCMP.JCCo and bJCJM.ProjectMgr=bJCMP.ProjectMgr
/*left outer join bJCJP on PMPendChangeOrders.PMCo=bJCJP.JCCo and PMPendChangeOrders.Project=bJCJP.Job and 
                 PMPendChangeOrders.PhaseGroup=bJCJP.PhaseGroup and PMPendChangeOrders.Phase=bJCJP.Phase
left outer join bJCCT on PMPendChangeOrders.PhaseGroup=bJCCT.PhaseGroup and PMPendChangeOrders.CostType=bJCCT.CostType*/
left outer join viDim_PMProjectMgrJobs on PMPendChangeOrders.PMCo=viDim_PMProjectMgrJobs.JCCo and 
  bJCJM.ProjectMgr=viDim_PMProjectMgrJobs.ProjectMgr and 
  bJCJM.Job=viDim_PMProjectMgrJobs.Job
Left Outer Join bPMDT on bPMDT.DocType=PMPendChangeOrders.PCOType



GO
GRANT SELECT ON  [dbo].[viFact_PMPendChangeOrders] TO [public]
GRANT INSERT ON  [dbo].[viFact_PMPendChangeOrders] TO [public]
GRANT DELETE ON  [dbo].[viFact_PMPendChangeOrders] TO [public]
GRANT UPDATE ON  [dbo].[viFact_PMPendChangeOrders] TO [public]
GRANT SELECT ON  [dbo].[viFact_PMPendChangeOrders] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_PMPendChangeOrders] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_PMPendChangeOrders] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_PMPendChangeOrders] TO [Viewpoint]
GO
