SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE  [dbo].[brptJCContItemCostEstiReca]
as 


select 
LTRIM(RTRIM(U.JCCo)) as 'JCCo',
LTRIM(RTRIM(U.[Contract])) as 'Contract',
CM.Description,
CM.ContractStatus,
case CM.ContractStatus
when 1 then 'Open' 
when 2 then  'Soft Closed'
when 3 then 'Closed' end as 'ContractStatusTxt',
LTRIM(RTRIM(U.Item)) as 'Item',
LTRIM(RTRIM(U.ItemDescription)) as 'ItemDescription',
LTRIM(RTRIM(U.ACO)) as 'ACO',
LTRIM(RTRIM(U.ACOItem)) as 'ACOItem',
--(select top 1 ContractStatus from JCCM where Contract = U.[Contract] and JCCo = U.JCCo) as 'ContractStatus',
--(select  top 1 [Description] from JCCM where Contract = U.[Contract] and JCCo = U.JCCo) as 'Discription',
isnull(Sum(OriginalContract),0) as 'OriginalContract',
isnull(Sum(ChangeOrders),0) as 'ChangeOrders',
isnull(Sum(CurrentContract),0) as 'CurrentContract',
isnull(Sum([OriginalEstimate(Cost)]),0) as 'OriginalEstimate(Cost)',
isnull(Sum([ChangeOrders(Cost)]),0) as 'ChangeOrders(Cost)',
isnull(Sum(Profit),0) as 'Profit'
from (
select
CI.JCCo, 
CI.[Contract] as 'Contract', 
CI.Item as 'Item', 
CI.Description as 'ItemDescription',
Null as 'ACO', 
Null  as 'ACOItem',
CI.OrigContractAmt as 'OriginalContract', 
0 as 'ChangeOrders',
CI.OrigContractAmt + 0 as 'CurrentContract',
CH.OrigCost as 'OriginalEstimate(Cost)',
0 as 'ChangeOrders(Cost)',
(CI.OrigContractAmt + 0)-(CH.OrigCost + 0) as 'Profit'
from JCCH CH
join JCJP JP
	on CH.JCCo = JP.JCCo 
	and CH.Job = JP.Job
	and CH.PhaseGroup = JP.PhaseGroup 
	and CH.Phase = JP.Phase
right join JCCI CI
	on JP.JCCo = CI.JCCo
	and JP.Contract = CI.Contract
	and JP.Item = CI.Item

Union All

select 
CI.JCCo,
CI.Contract,
CI.Item,
CI.Description as 'ItemDescription',
OI.ACO,
OI.ACOItem as 'ACOItem',
0 as 'OriginalContract',
OI.ContractAmt as 'ChangeOrders',
OI.ContractAmt as 'CurrentContract',
0 as 'OriginalEstimate(Cost)',
OD.EstCost as 'ChangeOrders(Cost)',
OI.ContractAmt - (OI.ContractAmt +(OD.EstCost)) as 'Profit' 
from JCCH CH
join JCOD OD
	on CH.JCCo = OD.JCCo
	and CH.Job = OD.Job
	and CH.PhaseGroup = OD.PhaseGroup
	and CH.Phase = OD.Phase
join JCOI OI
	on OD.JCCo = OI.JCCo	
	and OD.Job = OI.Job
	and OD.ACO = OI.ACO
	and OD.ACOItem = OI.ACOItem
join JCJP JP
	on CH.JCCo = JP.JCCo 
	and CH.Job = JP.Job
	and CH.PhaseGroup = JP.PhaseGroup 
	and CH.Phase = JP.Phase
right join JCCI CI
	on JP.JCCo = CI.JCCo
	and JP.Contract = CI.Contract
	and JP.Item = CI.Item
) as U
left join JCCM CM  
on U.JCCo = CM.JCCo
and U.Contract = CM.Contract
where U.JCCo = 1
--and U.ACOItem is not Null
Group by 
U.JCCo,
U.[Contract],
CM.ContractStatus,
CM.Description,
U.Item,
U.ItemDescription,
U.ACO,
U.ACOItem
order by 1,2,3,4,5


GO
GRANT EXECUTE ON  [dbo].[brptJCContItemCostEstiReca] TO [public]
GO
