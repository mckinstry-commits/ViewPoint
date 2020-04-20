SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:	GF 04/26/2007
 * Modfied By:
 *
 * Provides a view of Future PM Change Orders
 *
 *****************************************/

CREATE view [dbo].[PMJCJMFuturePMOI] as
		select oi.PMCo, oi.Project,
		case 
  			when oi.ACO is null and oi.FixedAmountYN <> 'Y' then isnull(oi.PendingAmount,0)
  			when oi.ACO is null and oi.FixedAmountYN = 'Y'  then isnull(oi.FixedAmount,0)
  			when oi.InterfacedDate is null and oi.ACO is not null then isnull(oi.ApprovedAmt,0)
  		else 0 end as 'FutureCOAmt'

from dbo.PMOI oi with (nolock)
join dbo.bPMSC sc with (nolock) on sc.Status=oi.Status
left join dbo.bPMDT dt with (nolock) on dt.DocType=oi.PCOType
where isnull(dt.IncludeInProj,'Y') = 'Y' and isnull(sc.IncludeInProj,'N') in ('Y','C')
and oi.InterfacedDate is null


GO
GRANT SELECT ON  [dbo].[PMJCJMFuturePMOI] TO [public]
GRANT INSERT ON  [dbo].[PMJCJMFuturePMOI] TO [public]
GRANT DELETE ON  [dbo].[PMJCJMFuturePMOI] TO [public]
GRANT UPDATE ON  [dbo].[PMJCJMFuturePMOI] TO [public]
GO
