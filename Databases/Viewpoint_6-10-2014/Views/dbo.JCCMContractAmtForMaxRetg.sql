SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[JCCMContractAmtForMaxRetg]
/*************************************************************************
* Created:  TJL 12/30/09 - Issue #129894, Maximum Retainage Enhancement
* Modified: 
*		
* Provides a view for JC/PM Contract Master forms that returns the calculated
* maximum retainage amount based upon:
*
*	JCCM Percent of Contract setup value.
*	JCCM exclude Variations from Max Retainage by % value.
*	JCCI Non-Zero Retainage Percent items
*
*
**************************************************************************/ 
   
as
select top 100 percent m.JCCo, m.Contract,
	'MaxRetgByPct' = case when m.InclACOinMaxYN = 'Y' then (m.MaxRetgPct * isnull(sum(i.ContractAmt), 0)) 
				else (m.MaxRetgPct * isnull(sum(i.OrigContractAmt), 0)) end
from bJCCI i with (nolock)
join bJCCM m with (nolock) on m.JCCo = i.JCCo and m.Contract = i.Contract
where i.RetainPCT <> 0
group by m.JCCo, m.Contract, m.InclACOinMaxYN, m.MaxRetgPct


GO
GRANT SELECT ON  [dbo].[JCCMContractAmtForMaxRetg] TO [public]
GRANT INSERT ON  [dbo].[JCCMContractAmtForMaxRetg] TO [public]
GRANT DELETE ON  [dbo].[JCCMContractAmtForMaxRetg] TO [public]
GRANT UPDATE ON  [dbo].[JCCMContractAmtForMaxRetg] TO [public]
GRANT SELECT ON  [dbo].[JCCMContractAmtForMaxRetg] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCMContractAmtForMaxRetg] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCMContractAmtForMaxRetg] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCMContractAmtForMaxRetg] TO [Viewpoint]
GO
