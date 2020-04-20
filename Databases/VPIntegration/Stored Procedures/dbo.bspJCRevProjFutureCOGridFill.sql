SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE proc [dbo].[bspJCRevProjFutureCOGridFill]
/****************************************************************************
* CREATED BY: 	DANF 03/05/99
* MODIFIED BY:	CHS	09/16/08 - 126236
*				GF 09/29/2008 - issue #126236 changes to include in projections.
*
*
* USAGE:
* 	Fills Future CO view grid collection in JC Revenue Projections entry
*
* INPUT PARAMETERS:
*	Company, Contract, Item
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@jcco bCompany, @contract bContract, @item bContractItem, @RevenueProjectionDate bDate)
as

select oi.ContractItem,
    		'PM' as Source,
    		oi.ACO,
    		oh.Description as ACODesc,
    		oi.ACOItem,
    		oi.Description as ACOItemDesc,
    		oi.PCOType,
    		dt.Description as PCOTypeDesc,
    		oi.PCO,
    		p.Description as PCODesc,
    		oi.PCOItem,
    		oi.Description as PCOItemDesc,
    		oi.Status,
    		sc.Description as StatusDesc, 
    		isnull(oi.Units,0) as Units,
    		oi.UM,
    		isnull(oi.UnitPrice,0) as UnitPrice,
    		oi.PendingAmount as Amount,
			'ProjectionsOption' = 
				   case when sc.IncludeInProj = 'Y' then 'Display in Projections'
						when sc.IncludeInProj = 'N' then '(none)'
						when sc.IncludeInProj = 'C' then 'Display & Calculate'
						else '' end

			from dbo.PMOI oi with (nolock)
			left join dbo.PMOH oh with (nolock) on oh.PMCo=oi.PMCo and oh.Project=oi.Project and oh.ACO=oi.ACO
			join dbo.PMSC sc with (nolock) on sc.Status = oi.Status
			left join dbo.PMDT dt with (nolock) on dt.DocType = oi.PCOType
    		left join dbo.PMOP p on p.PMCo=oi.PMCo and p.Project=oi.Project and isnull(p.PCOType,'')=isnull(oi.PCOType,'')
     		and isnull(p.PCO,'')=isnull(oi.PCO,'')
			where oi.PMCo = @jcco and oi.Contract = @contract and oi.ContractItem = @item
			and oi.ApprovedAmt is null and oi.FixedAmountYN <> 'Y'
			and isnull(dt.IncludeInProj,'N') = 'Y' and isnull(sc.IncludeInProj,'N') in ('Y','C')
    	union
    	select 
    	    oi.ContractItem,
    		'PM',
    		oi.ACO,
    		oh.Description,
    		oi.ACOItem,
    		oi.Description,
    		oi.PCOType,
    		dt.Description,
    		oi.PCO,
    		p.Description,
    		oi.PCOItem,
    		oi.Description,
    		oi.Status,
    		sc.Description, 
    		isnull(oi.Units,0),
    		oi.UM,
    		isnull(oi.UnitPrice,0),
    		oi.FixedAmount,
			'ProjectionsOption' = 
				   case when sc.IncludeInProj = 'Y' then 'Display in Projections'
						when sc.IncludeInProj = 'N' then '(none)'
						when sc.IncludeInProj = 'C' then 'Display & Calculate'
						else '' end
 
			from dbo.PMOI oi with (nolock)
			left join dbo.PMOH oh with (nolock) on oh.PMCo=oi.PMCo and oh.Project=oi.Project and oh.ACO=oi.ACO
			join dbo.PMSC sc with (nolock) on sc.Status = oi.Status
			left join dbo.PMDT dt with (nolock) on dt.DocType = oi.PCOType
    		left join dbo.PMOP p on p.PMCo=oi.PMCo and p.Project=oi.Project and isnull(p.PCOType,'')=isnull(oi.PCOType,'')
     		and isnull(p.PCO,'')=isnull(oi.PCO,'')
  			where oi.PMCo = @jcco and oi.Contract = @contract and oi.ContractItem = @item
			and oi.ApprovedAmt is  null and oi.FixedAmountYN = 'Y' 
			and isnull(dt.IncludeInProj,'N') = 'Y' and isnull(sc.IncludeInProj,'N') in ('Y','C')
    	union
    	select 
    		oi.ContractItem,
    		'PM',
    		oi.ACO,
    		oh.Description,
    		oi.ACOItem,
    		oi.Description,
    		oi.PCOType,
    		dt.Description,
    		oi.PCO,
    		p.Description,
    		oi.PCOItem,
    		oi.Description,
    		oi.Status,
    		sc.Description, 
    		isnull(oi.Units,0),
    		oi.UM,
    		isnull(oi.UnitPrice,0),
    	 	isnull(oi.ApprovedAmt,0), 
			'ProjectionsOption' = 
				   case when sc.IncludeInProj = 'Y' then 'Display in Projections'
						when sc.IncludeInProj = 'N' then '(none)'
						when sc.IncludeInProj = 'C' then 'Display & Calculate'
						else '' end

			from dbo.PMOI oi with (nolock)
			left join dbo.PMOH oh with (nolock) on oh.PMCo=oi.PMCo and oh.Project=oi.Project and oh.ACO=oi.ACO
			join dbo.PMSC sc with (nolock) on sc.Status = oi.Status
			left join dbo.PMDT dt with (nolock) on dt.DocType = oi.PCOType
    		left join dbo.PMOP p on p.PMCo=oi.PMCo and p.Project=oi.Project and isnull(p.PCOType,'')=isnull(oi.PCOType,'')
     		and isnull(p.PCO,'')=isnull(oi.PCO,'') 
			where oi.PMCo = @jcco and oi.Contract = @contract and oi.ContractItem = @item
			and oi.InterfacedDate is null and oi.ApprovedAmt is not null 
			and isnull(dt.IncludeInProj,'N') = 'Y' and isnull(sc.IncludeInProj,'N') in ('Y','C')
    	union
    	select 
    		i.Item,
    		'JC',
    		null,
    		null,
    		null,
    		null,
    		null,
    		null,
    		null,
    		null,
    		null,
    		null,
    		null,
    		null, 
    		isnull(i.ContractUnits,0),
    		c.UM,
    		isnull(i.ContUnitPrice,0),
    		isnull(i.ContractAmt,0),
			''

    		from dbo.JCOI i with (nolock)
    		join dbo.JCOH h with (nolock)
    		on  i.JCCo=h.JCCo and i.Job=h.Job and i.ACO = h.ACO and i.Contract = h.Contract
    		join bJCCI c with (nolock)
    		on  i.JCCo=c.JCCo and i.Contract = c.Contract and i.Item = c.Item
    		where i.JCCo=@jcco and i.Contract=@contract and i.Item=@item
    		and h.ApprovalDate>@RevenueProjectionDate

GO
GRANT EXECUTE ON  [dbo].[bspJCRevProjFutureCOGridFill] TO [public]
GO
