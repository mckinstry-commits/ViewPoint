SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCContractOverride] as 
/*******************************************************************************
* Created:	DANF 2005/01/18
* Modified: GG 04/10/08 - added top 100 percent and order by 
*			GF 10/02/2008 - issue #126236 included future CO in projections option
*
*
* Used by the JC Override form to return Future Change Orders and Current Contract Amount.
*
*
**********************************************************************************/
select top 100 percent cm.JCCo as 'JCCo', cm.Contract as 'Contract',

   	(isnull((select sum(oi.PendingAmount)
   			from PMOI oi with (nolock)
   			join PMSC sc with (nolock) on sc.Status = oi.Status
   			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType
   			where oi.PMCo = cm.JCCo and oi.Contract = cm.Contract
   			and isnull(oi.ACOItem,'') = '' and oi.FixedAmountYN <> 'Y'
   			and isnull(dt.IncludeInProj,'Y') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') in ('Y','C')), 0)
   	+ isnull((select sum(oi.FixedAmount) 
   			from PMOI oi with (nolock)
   			join PMSC sc with (nolock) on sc.Status = oi.Status
   			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType
     		where oi.PMCo = cm.JCCo and oi.Contract = cm.Contract
   			and isnull(oi.ACOItem,'') = '' and oi.FixedAmountYN = 'Y' 
   			and isnull(dt.IncludeInProj,'Y') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') in ('Y','C')),0)
	+ isnull((select sum(oi.ApprovedAmt) 
			from PMOI oi with (nolock)
			join PMSC sc with (nolock) on sc.Status = oi.Status
			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType 
			where oi.PMCo = cm.JCCo and oi.Contract = cm.Contract 
			and not exists(select PMCo from PMOL ol with (nolock) where oi.PMCo = ol.PMCo 
				and oi.Project = ol.Project and isnull(oi.PCOType,'') = isnull(ol.PCOType,'')
				and isnull(oi.PCO,'') = isnull(ol.PCO,'') and isnull(oi.PCOItem,'') = isnull(ol.PCOItem,'') 
				and isnull(oi.ACO,'') = isnull(ol.ACO,'') and isnull(oi.ACOItem,'') = isnull(ol.ACOItem,'') 
				and ol.InterfacedDate is not null) and oi.ApprovedAmt is not null
				and isnull(dt.IncludeInProj,'Y') = 'Y' 
				and isnull(sc.IncludeInProj,'N') in ('Y','C')),0))
			as 'Future Change Orders',

   	(isnull((select sum(oi.PendingAmount)
   			from PMOI oi with (nolock)
   			join PMSC sc with (nolock) on sc.Status = oi.Status
   			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType
   			where oi.PMCo = cm.JCCo and oi.Contract = cm.Contract
   			and isnull(oi.ACOItem,'') = '' and oi.FixedAmountYN <> 'Y'
   			and isnull(dt.IncludeInProj,'Y') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') = 'C'), 0)
   	+ isnull((select sum(oi.FixedAmount) 
   			from PMOI oi with (nolock)
   			join PMSC sc with (nolock) on sc.Status = oi.Status
   			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType
     		where oi.PMCo = cm.JCCo and oi.Contract = cm.Contract
   			and isnull(oi.ACOItem,'') = '' and oi.FixedAmountYN = 'Y' 
   			and isnull(dt.IncludeInProj,'Y') = 'Y' 
   			and isnull(sc.IncludeInProj,'N') = 'C'),0)
	+ isnull((select sum(oi.ApprovedAmt) 
			from PMOI oi with (nolock)
			join PMSC sc with (nolock) on sc.Status = oi.Status
			left join PMDT dt with (nolock) on dt.DocType = oi.PCOType 
			where oi.PMCo = cm.JCCo and oi.Contract = cm.Contract 
			and not exists(select PMCo from PMOL ol with (nolock) where oi.PMCo = ol.PMCo 
				and oi.Project = ol.Project and isnull(oi.PCOType,'') = isnull(ol.PCOType,'')
				and isnull(oi.PCO,'') = isnull(ol.PCO,'') and isnull(oi.PCOItem,'') = isnull(ol.PCOItem,'') 
				and isnull(oi.ACO,'') = isnull(ol.ACO,'') and isnull(oi.ACOItem,'') = isnull(ol.ACOItem,'') 
				and ol.InterfacedDate is not null) and oi.ApprovedAmt is not null
				and isnull(dt.IncludeInProj,'Y') = 'Y' 
				and isnull(sc.IncludeInProj,'N') = 'C'),0))
			as 'IncludedCOAmt'


from JCCM cm with (nolock)
join JCIP ip with (nolock) on cm.JCCo = ip.JCCo and cm.Contract = ip.Contract  
group by cm.JCCo, cm.Contract
order by cm.JCCo, cm.Contract

GO
GRANT SELECT ON  [dbo].[JCContractOverride] TO [public]
GRANT INSERT ON  [dbo].[JCContractOverride] TO [public]
GRANT DELETE ON  [dbo].[JCContractOverride] TO [public]
GRANT UPDATE ON  [dbo].[JCContractOverride] TO [public]
GRANT SELECT ON  [dbo].[JCContractOverride] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCContractOverride] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCContractOverride] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCContractOverride] TO [Viewpoint]
GO
