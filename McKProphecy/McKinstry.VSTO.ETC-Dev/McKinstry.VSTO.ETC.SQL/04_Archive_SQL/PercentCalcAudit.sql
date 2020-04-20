--Contract Item Percent of Contract
select
	JCCo
,	Contract
,	sum(udPercentOfContract) as Pct
from 
	JCCI
group by
	JCCo
,	Contract
having
	sum(udPercentOfContract) <> 1

--Job Phase Percent of Job
select
	JCCo
,	Job
,	sum(udPercentOfJob) as Pct
from 
	JCJP
group by
	JCCo
,	Job
having
	sum(udPercentOfJob) <> 1

--Job Phase Percent of Contract Item
select
	JCCo
,	Contract
,	Item
,	sum(udPercentOfContractItem) as Pct
from 
	JCJP
group by
	JCCo
,	Contract
,	Item
having
	sum(udPercentOfContractItem) <> 1


--Job Phase Percent of Contract Item Group
select
	jcjp.JCCo
,	jcjp.Contract
,	coalesce(jcci.udItemGroup, jcci.Item) as ItemGroup
,	sum(jcjp.udPercentOfContractItemGroup) as Pct
from 
	JCJP jcjp join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item
group by
	jcjp.JCCo
,	jcjp.Contract
,	coalesce(jcci.udItemGroup, jcci.Item)
having
	sum(udPercentOfContractItemGroup) <> 1

