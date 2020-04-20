SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCProjFutureCOGridFill    Script Date: 8/28/99 9:35:05 AM ******/
CREATE  proc [dbo].[bspJCProjFutureCOGridFill]
/****************************************************************************
* CREATED BY:	GF 03/05/99
* MODIFIED BY:	TV - 23061 added isnulls
*				DANF - 6.X recode
*				CHS	09/16/08 - 126236
*				GF 01/06/2009 - issue #129669 include future addon costs
*
*
* USAGE:
* Fills Future CO view grid collection in JC Projections entry
*
* INPUT PARAMETERS:
* Company, Job, PhaseGroup, Phase, CostType
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@jcco bCompany, @job bJob, @phasegroup tinyint, @phase bPhase, @costtype tinyint)
as

---- Future projection query from PM
select l.PCOType as PCOType,t.Description as PCOTypeDesc,l.PCO as PCO,p.Description as PCODesc,
	l.PCOItem as PCOItem,i.Description as PCOItemDesc, l.ACO as ACO, h.Description as ACODesc,
	l.ACOItem as ACOItem,i.Description as ACOItemDesc, i.Status as Status,
	s.Description as StatusDesc, isnull(l.EstUnits,0) as EstUnits,
	l.UM as UM, isnull(l.EstHours,0) as EstHours,
	UnitCost = (case when isnull(l.EstUnits,0)=0 then 0 else (isnull(l.EstCost,0)/isnull(l.EstUnits,0)) end),
	isnull(l.EstCost,0) as EstCost, s.IncludeInProj, 
	'ProjectionsOption' = case when s.IncludeInProj = 'Y' then 'Display in Projections'
						when s.IncludeInProj = 'N' then '(none)'
						when s.IncludeInProj = 'C' then 'Display & Calculate'
						else 'Test' end,
	null as AddOn, null as AddOnDesc

from bPMOL as l with (nolock)
join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
join bPMSC s with (nolock) on s.Status=i.Status
left join bPMDT t with (nolock) on t.DocType=i.PCOType
left join bPMOH h with (nolock) on h.PMCo=l.PMCo and h.Project=l.Project and isnull(h.ACO,'')=isnull(l.ACO,'')
left join bPMOP p with (nolock) on p.PMCo=l.PMCo and p.Project=l.Project and isnull(p.PCOType,'')=isnull(l.PCOType,'')
and isnull(p.PCO,'')=isnull(l.PCO,'')
where l.PMCo=@jcco and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
and l.CostType=@costtype and l.InterfacedDate is null
and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y') = 'Y'

union

select d.PCOType as PCOType,t.Description as PCOTypeDesc,d.PCO as PCO,p.Description as PCODesc,
	d.PCOItem as PCOItem,i.Description as PCOItemDesc, null as ACO, null as ACODesc,
	null as ACOItem, null as ACOItemDesc, i.Status as Status, s.Description as StatusDesc,
	0 as EstUnits, null as UM, 0 as EstHours, 0 as UnitCost,
	d.AmtToDistribute as EstCost, s.IncludeInProj, 
	'ProjectionsOption' = case when s.IncludeInProj = 'Y' then 'Display in Projections'
						when s.IncludeInProj = 'N' then '(none)'
						when s.IncludeInProj = 'C' then 'Display & Calculate'
						else '' end,
	d.AddOn as AddOn, a.Description as AddOnDesc
from bPMOB as d with (nolock)
join bPMOI i with (nolock) on i.PMCo=d.PMCo and i.Project=d.Project and i.PCOType=d.PCOType
and i.PCO=d.PCO and i.PCOItem=d.PCOItem
join bPMSC s with (nolock) on s.Status=i.Status
left join bPMDT t with (nolock) on t.DocType=i.PCOType
left join bPMOP p with (nolock) on p.PMCo=d.PMCo and p.Project=d.Project
and p.PCOType=d.PCOType and p.PCO=d.PCO
left join bPMPA a with (nolock) on a.PMCo=d.PMCo and a.Project=d.Project and a.AddOn=d.AddOn
where d.PMCo=@jcco and d.Project=@job and d.PhaseGroup=@phasegroup and d.Phase=@phase
and d.CostType=@costtype and i.ACO is null
and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y') = 'Y'

GO
GRANT EXECUTE ON  [dbo].[bspJCProjFutureCOGridFill] TO [public]
GO
