SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
* Created By: DANF 03/14/2005
* Modfied By:	GF 04/13/2010 - issue #139060 added approved month to select
*
*
* Provides a view of Future JC Change Orders for Revenue Projections.
*
*****************************************/
  
  CREATE          view [dbo].[JCFutureJCCO] 
  as 
  
  	select 
  		i.JCCo as 'Co',
  		i.Contract as 'Cnt',
  		h.ApprovalDate as 'ApprovalDate',
  		i.Item as 'Item',
  		----#139060
  		i.ApprovedMonth as 'ApprovedMonth',
  		----#139060
  		isnull(i.ContractAmt,0) as 'Amt',
   		isnull(i.ContractUnits,0) as 'Units'
  		from dbo.JCOI i with (nolock)
  		join dbo.JCOH h with (nolock)
  		on  i.JCCo=h.JCCo and i.Job=h.Job and i.ACO = h.ACO and i.Contract = h.Contract





GO
GRANT SELECT ON  [dbo].[JCFutureJCCO] TO [public]
GRANT INSERT ON  [dbo].[JCFutureJCCO] TO [public]
GRANT DELETE ON  [dbo].[JCFutureJCCO] TO [public]
GRANT UPDATE ON  [dbo].[JCFutureJCCO] TO [public]
GO
