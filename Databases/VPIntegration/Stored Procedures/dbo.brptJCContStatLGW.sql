SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[brptJCContStatLGW]
/***************************
* Created 04/28/97 
* Modified: JRE 07/20/00 multipl records if more than 1 job per contract
*			GG 10/07/08 - #129574 - replaced obsolete outer join syntax for SQL2008
*
* Usage: ??
*
***************************/       
        
	(@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract='zzzzzzzzz',
		@ThroughMth bDate, @EndDate bDate)

as
create table #ContractStatus
(
JCCo				tinyint         NULL,
Contract			char(10)        NULL,
RevMo				smalldatetime   Null,
Job					char(10)        NULL,
CostMo				smalldatetime   Null,
bondcna				char(1)			null,  
PhaseGroup			tinyint         NULL,
CostType			tinyint         NULL,
CTAbbrev			char(10)        NULL,
Customer			int				NULL,
CustName			varchar(30)		NULL,
ProjCloseDate		smalldatetime	NULL,
ContractDays		smallint		NULL,
OrigContractAmt		decimal(12,2)   NULL,
CurrContractAmt		decimal(12,2)   NULL,
ContractUnits		decimal(16,3)   NULL,
BilledAmt           decimal(12,2)   NULL,
BilledUnits         decimal(16,3)   NULL,
ProjDollars         decimal(12,2)   NULL,
ProjUnits           decimal(16,3)   NULL,
CurrRetainAmt		decimal (12,2)  Null,
BilledTax			decimal (12,2)  Null,
ReceivedAmt			decimal(12,2)	NULL,
OrigEstCost         decimal(12,2)   NULL,
CurrEstCost         decimal(12,2)   NULL,
ActualCost			decimal(12,2)   NULL,
ProjCost			decimal(12,2)   NULL,
APAmount			decimal (12,2)	NULL,
SourceAPAmt			decimal (12,2)  NULL
)

/* insert Contract info */
insert into #ContractStatus (JCCo, Contract, bondcna, OrigContractAmt, CurrContractAmt,
	BilledAmt, CurrRetainAmt, BilledTax,  ReceivedAmt, RevMo,ContractUnits,BilledUnits,ProjDollars,ProjUnits)
Select JCCM.JCCo, JCCM.Contract, 0, 
	sum(case when JCID.JCTransType = 'OC'then(JCID.ContractAmt) else 0 end),
	sum(JCID.ContractAmt), sum(JCID.BilledAmt), sum(JCID.CurrentRetainAmt), 
	sum(JCID.BilledTax), sum(JCID.ReceivedAmt), JCID.Mth,
    sum(JCID.ContractUnits),sum(JCID.BilledUnits),
    sum(case when JCID.JCTransType = 'RP'then(JCID.ProjDollars) else 0 end),
    sum(case when JCID.JCTransType = 'RP'then(JCID.ProjUnits) else 0 end)
FROM JCCM
JOIN JCID on JCCM.JCCo=JCID.JCCo and JCCM.Contract=JCID.Contract 
where JCID.Mth<=@ThroughMth   and JCID.ActualDate<=@EndDate and
	JCCM.JCCo=@JCCo and JCCM.Contract>=@BeginContract and JCCM.Contract<=@EndContract
group by JCCM.JCCo, JCCM.Contract, JCID.Mth
  
/* insert jtd Cost info */
insert into #ContractStatus (JCCo, Contract, Job, PhaseGroup,CostType, CTAbbrev, 
	OrigEstCost, CurrEstCost, ActualCost, ProjCost, CostMo)
Select JCJM.JCCo, JCJM.Contract, JCJM.Job, JCCD.PhaseGroup, JCCD.CostType, JCCT.Abbreviation, 
	sum(case when JCCD.JCTransType='OE' then JCCD.EstCost else 0 end),
    sum(JCCD.EstCost),sum(JCCD.ActualCost),sum(JCCD.ProjCost), JCCD.Mth
FROM JCJM
JOIN JCCD on JCJM.JCCo=JCCD.JCCo and JCJM.Job=JCCD.Job
JOIN JCCT on JCCD.PhaseGroup=JCCT.PhaseGroup and JCCD.CostType=JCCT.CostType
Where JCCD.Mth<=@ThroughMth and JCCD.ActualDate<=@EndDate
     and JCJM.JCCo=@JCCo and JCJM.Contract>=@BeginContract and JCJM.Contract<=@EndContract
GROUP by JCJM.JCCo, JCJM.Contract,  JCJM.Job, JCCD.PhaseGroup, JCCD.CostType, JCCT.Abbreviation, JCCD.Mth
  
  
/* Get source AP */
insert into #ContractStatus (JCCo, Contract, Job, PhaseGroup,CostType, CTAbbrev,SourceAPAmt)
select JCJM.JCCo, JCJM.Contract, JCJM.Job, JCCD.PhaseGroup, JCCD.CostType, JCCT.Abbreviation, sum(JCCD.ActualCost)
from JCJM    
JOIN JCCD on JCJM.JCCo=JCCD.JCCo and JCJM.Job=JCCD.Job
JOIN JCCT on JCCD.PhaseGroup=JCCT.PhaseGroup and JCCD.CostType=JCCT.CostType
where  JCCD.JCTransType='AP' and JCJM.JCCo=@JCCo and JCJM.Contract>=@BeginContract
	and JCJM.Contract<=@EndContract and JCCD.JCTransType='AP' and JCCD.Mth <= @ThroughMth 
GROUP by JCJM.JCCo, JCJM.Contract,  JCJM.Job, JCCD.PhaseGroup, JCCD.CostType, JCCT.Abbreviation
  
/*insert AP Amount */
insert into #ContractStatus (JCCo, Contract, Job, PhaseGroup,CostType,CTAbbrev,APAmount)
select JCJM.JCCo, JCJM.Contract, JCJM.Job, bAPTL.PhaseGroup, bAPTL.JCCType,
	bJCCT.Abbreviation, sum(bAPTD.Amount)
from JCJM
join bAPTL on bAPTL.JCCo=JCJM.JCCo and bAPTL.Job=JCJM.Job
join bAPTD on bAPTD.APCo=bAPTL.APCo and bAPTD.Mth=bAPTL.Mth 
	and bAPTD.APTrans=bAPTL.APTrans and bAPTL.APLine=bAPTD.APLine
join bJCCT on bAPTL.JCCType=bJCCT.CostType and bAPTL.PhaseGroup=bJCCT.PhaseGroup 
where JCJM.JCCo=@JCCo and JCJM.Contract>=@BeginContract and JCJM.Contract<=@EndContract
	--and (bAPTD.PaidMth>@EndDate or bAPTD.Status<3)
	and ((bAPTD.Mth <=@ThroughMth and  bAPTD.PaidMth>@ThroughMth) or (bAPTD.Mth <= @ThroughMth and bAPTD.PaidMth is null ))
GROUP by JCJM.JCCo, JCJM.Contract, JCJM.Job, bAPTL.PhaseGroup, bAPTL.JCCType, bJCCT.Abbreviation
  
/* select the results */  

select bJCCM.JCCo, bJCCM.Contract, ContDesc=bJCCM.Description, a.Job, 
	ProjectMgr=(select top 1 bJCMP.name
				from bJCMP
				join bJCJM on bJCJM.JCCo=a.JCCo and bJCJM.Job=a.Job and bJCMP.JCCo=bJCJM.JCCo and bJCMP.ProjectMgr=bJCJM.ProjectMgr),
	a.PhaseGroup,
	CostType=a.CostType,
	CTAbbrev=a.CTAbbrev,
	Customer=bJCCM.Customer,
	CustName=bARCM.Name,
	ProjCloseDate=bJCCM.ProjCloseDate,
	ContractDays=bJCCM.CurrentDays,
	OrigContractAmt=(a.OrigContractAmt),
	CurrContractAmt=(a.CurrContractAmt),
	ContractUnits=(a.ContractUnits),
	BilledAmt=(a.BilledAmt),
	BilledUnits=(a.BilledUnits),
	ProjDollars=(a.ProjDollars),
	ProjUnits=(a.ProjUnits),
	CurrRetainAmt=(a.CurrRetainAmt),
	BilledTax=(a.BilledTax),
	ReceivedAmt=(a.ReceivedAmt),
	OrigEstCost=(a.OrigEstCost),
	CurrEstCost=(a.CurrEstCost),
	ActualCost=(a.ActualCost),
	ProjCost=(a.ProjCost),
	--PaidToDate=IsNull(a.SourceAPAmt,0)-(IsNull(a.APAmount,0)),
	UnPaid = a.APAmount,
	a.SourceAPAmt,
	bJCCM.Notes,
	CoName=bHQCO.Name,
	ThroughMth=@ThroughMth,
	EndDate=@EndDate,
	RevMo,
	CostMo,
	 bondcna, 
	BeginContract=@BeginContract,
	EndContract=@EndContract,
	ContractStatus=bJCCM.ContractStatus
from #ContractStatus a
JOIN bJCCM on bJCCM.JCCo=a.JCCo and bJCCM.Contract=a.Contract
Left Join bARCM on bARCM.CustGroup=bJCCM.CustGroup and bARCM.Customer=bJCCM.Customer
Join bHQCO on bHQCO.HQCo=bJCCM.JCCo
where bJCCM.JCCo=@JCCo and bJCCM.Contract>=@BeginContract and bJCCM.Contract<=@EndContract
	and a.JCCo=@JCCo and a.Contract>=@BeginContract and a.Contract<=@EndContract and bHQCO.HQCo=@JCCo

GO
GRANT EXECUTE ON  [dbo].[brptJCContStatLGW] TO [public]
GO
