SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE view [dbo].[JCContractOverrideCost] as 
/*******************************************************************************
* Created By:	GF 10/02/2008 - issue #126236 new view for contract override cost to display future CO
* Modified By:
*
*
* Used by the JC Override form Cost tab to return Future CO Amt and Future Include CO Amt
*
*
**********************************************************************************/

select top 100 percent jm.JCCo as 'JCCo', jm.Job as 'Job',

   	(isnull((select sum(ol.EstCost)
			from PMOL ol with (nolock)
   			join PMOI oi with (nolock) on ol.PMCo=oi.PMCo and ol.Project=oi.Project
			and isnull(ol.PCOType,'')=isnull(oi.PCOType,'')
			and isnull(ol.PCO,'')=isnull(oi.PCO,'') and isnull(ol.PCOItem,'')=isnull(oi.PCOItem,'')
			and isnull(ol.ACO,'')=isnull(oi.ACO,'') and isnull(ol.ACOItem,'')=isnull(oi.ACOItem,'')
   			join PMSC sc with (nolock) on sc.Status = oi.Status
   			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType
   			where ol.PMCo = jm.JCCo and ol.Project = jm.Job
			and ol.InterfacedDate is null
   			and isnull(dt.IncludeInProj,'N') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') in ('Y','C')), 0))
			as 'FutureCOAmt',

   	(isnull((select sum(ol.EstCost)
			from PMOL ol with (nolock)
   			join PMOI oi with (nolock) on ol.PMCo=oi.PMCo and ol.Project=oi.Project
			and isnull(ol.PCOType,'')=isnull(oi.PCOType,'')
			and isnull(ol.PCO,'')=isnull(oi.PCO,'') and isnull(ol.PCOItem,'')=isnull(oi.PCOItem,'')
			and isnull(ol.ACO,'')=isnull(oi.ACO,'') and isnull(ol.ACOItem,'')=isnull(oi.ACOItem,'')
   			join PMSC sc with (nolock) on sc.Status = oi.Status
   			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType
   			where oi.PMCo = jm.JCCo and oi.Project = jm.Job
			and ol.InterfacedDate is null
   			and isnull(dt.IncludeInProj,'N') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') = 'C'), 0))
			as 'IncludedCOAmt'



from JCJM jm with (nolock)
group by jm.JCCo, jm.Job
order by jm.JCCo, jm.Job

GO
GRANT SELECT ON  [dbo].[JCContractOverrideCost] TO [public]
GRANT INSERT ON  [dbo].[JCContractOverrideCost] TO [public]
GRANT DELETE ON  [dbo].[JCContractOverrideCost] TO [public]
GRANT UPDATE ON  [dbo].[JCContractOverrideCost] TO [public]
GRANT SELECT ON  [dbo].[JCContractOverrideCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCContractOverrideCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCContractOverrideCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCContractOverrideCost] TO [Viewpoint]
GO
