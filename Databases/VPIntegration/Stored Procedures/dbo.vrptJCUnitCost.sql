SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================      
     


-- ============================================= 
CREATE PROCEDURE  [dbo].[vrptJCUnitCost]  

(@JCCo bCompany, 
@BeginContract bContract ='', 
@EndContract bContract= 'zzzzzzzzzz',  
@BeginDate bDate = '01/01/50', 
@EndDate bDate='12/31/2050', 
@DateActPost varchar(1) = 'P', 
@JobActivity char(1))  
          
with recompile  as  

declare 
@BeginPostedDate bDate,
@EndPostedDate bDate,
@BeginActualDate bDate,
@EndActualDate bDate  
      
if @JCCo is null 
begin 
	select @JCCo=0 
end  

select 
@BeginPostedDate=case when @DateActPost = 'P' then @BeginDate else '1/1/1950' end,  
@EndPostedDate=case when @DateActPost = 'P' then @EndDate else '12/31/2050' end,  
@BeginActualDate=case when @DateActPost <> 'P' then @BeginDate else '1/1/1950' end,  
@EndActualDate=case when @DateActPost <> 'P' then @EndDate else '12/31/2050' end  
  
Select 
JCCH.JCCo, 
JCCH.Job, 
JCCH.PhaseGroup, 
JCCH.Phase, 
PhaseDesc=JCJP.Description, 
JCCH.CostType,   
JCCH.UM,   
CTAbbrev=JCCT.Abbreviation, 
JCJP.Contract, 
ContDesc=JCCM.Description,   
JCJP.Item ,  
ItemDesc=JCCI.Description,  
Cost.OrigEstHours, 
Cost.OrigEstUnits, 
Cost.OrigEstItemUnits, 
Cost.OrigEstPhaseUnits, 
Cost.JCCHOrigEstCost, 
Cost.OrigEstCost,  
Cost.CurrEstHours, 
Cost.CurrEstUnits, 
Cost.CurrEstItemUnits, 
Cost.CurrEstPhaseUnits, 
Cost.CurrEstCost, 
Cost.ActualHours,   
Cost.ActualUnits, 
Cost.ActualItemUnits, 
Cost.ActualPhaseUnits, 
Cost.ActualCost, 
Cost.ProjHours, 
Cost.ProjUnits, 
Cost.ProjItemUnits,  
Cost.ProjPhaseUnits, 
Cost.ProjCost, 
Cost.PerActualHours, 
Cost.PerActualUnits, 
Cost.PerActualItemUnits, 
Cost.PerActualPhaseUnits,  
Cost.PerActualCost, 
Bill.ContractStatus, 
Cost.PhaseUM,   
ItemUM=JCCI.UM,  
Bill.OrigContractAmt, 
Bill.OrigContractUnits, 
Bill.OrigUnitPrice,  
Bill.CurrContractAmt, 
Bill.CurrContractUnits, 
Bill.CurrUnitPrice,   
Bill.BilledAmt, 
Bill.BilledUnits, 
Bill.ReceivedAmt,
CoName=HQCO.Name  
from JCCI  
Left Join JCJP with (Nolock) 
	on JCCI.JCCo=JCJP.JCCo 
	and JCCI.Contract = JCJP.Contract 
	and JCCI.Item=JCJP.Item  
Left join JCCH with (NOLOCK) 
	on JCJP.JCCo=JCCH.JCCo 
	and JCJP.Job=JCCH.Job 
	and JCJP.PhaseGroup=JCCH.PhaseGroup 
	and JCJP.Phase=JCCH.Phase  
left Join JCCT with (NOLOCK) 
	on JCCT.PhaseGroup=JCCH.PhaseGroup 
	and JCCT.CostType=JCCH.CostType  
Join HQCO with (NOLOCK) 
	on JCCI.JCCo=HQCO.HQCo  
join JCCM with (NOLOCK) 
	on JCCI.JCCo=JCCM.JCCo 
	and JCCI.Contract=JCCM.Contract  
       
Join(
			select 
			JCCD.JCCo, 
			JCCD.Job, 
			JCCD.PhaseGroup, 
			JCCD.Phase, 
			JCCD.CostType, 
			JCCD.UM,  
			PhaseUM=min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),  
			OrigEstHours=sum(case when (JCCD.JCTransType='OE') then JCCD.EstHours else 0 end),  
			OrigEstUnits=sum(case when JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE' then JCCD.EstUnits else 0 end),  
			OrigEstItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')  
									  then JCCD.EstUnits else 0 end),  
			OrigEstPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')  
									   then JCCD.EstUnits else 0 end),  
			JCCHOrigEstCost=sum(JCCH.OrigCost),  
			OrigEstCost=sum(case when (JCCD.JCTransType='OE') then JCCD.EstCost else 0 end),  
			CurrEstHours=sum(JCCD.EstHours),  
			CurrEstUnits=sum(case when JCCH.UM=JCCD.UM then JCCD.EstUnits else 0 end),  
			CurrEstItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.EstUnits else 0 end),  
			CurrEstPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.EstUnits else 0 end),  
			CurrEstCost=sum(JCCD.EstCost),  
			ActualHours=sum(JCCD.ActualHours),   
			ActualUnits=sum(case when JCCH.UM=JCCD.UM then JCCD.ActualUnits else 0 end),  
			ActualItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.ActualUnits else 0 end),  
			ActualPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.ActualUnits else 0 end),  
			ActualCost=sum(JCCD.ActualCost),  
			ProjHours=sum(JCCD.ProjHours),    
			ProjUnits=sum(case when JCCH.UM=JCCD.UM then JCCD.ProjUnits else 0 end),  
			ProjItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.ProjUnits else 0 end),  
			ProjPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.ProjUnits else 0 end),  
			ProjCost=sum(JCCD.ProjCost),  
			PerActualHours=sum(case when JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate  
							   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate  
							   then JCCD.ActualHours else 0 end),  
			PerActualUnits=sum(case when JCCH.UM=JCCD.UM and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate  
							   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate  
							   then JCCD.ActualUnits else 0 end),  
			PerActualItemUnits=sum(case when JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y'   
							   and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate  
							   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate  
							   then JCCD.ActualUnits else 0 end),  
			PerActualPhaseUnits=sum(case when JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y'  
							   and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate  
							   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate  
							   then JCCD.ActualUnits else 0 end),  
			PerActualCost=sum(case when JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate  
							   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate  
							   then JCCD.ActualCost else 0 end)     
			from JCCD  
			Join JCCH with (NOLOCK) 
				on JCCD.JCCo=JCCH.JCCo 
				and JCCD.Job=JCCH.Job 
				and JCCD.PhaseGroup=JCCH.PhaseGroup 
				and JCCD.Phase=JCCH.Phase 
				and JCCD.CostType=JCCH.CostType  
				and (case when @DateActPost = 'P' then JCCD.PostedDate  else JCCD.ActualDate end)<=@EndDate    
			group by JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType, JCCD.UM) 
as Cost  
	on Cost.JCCo=JCCH.JCCo 
	and Cost.Job=JCCH.Job 
	and Cost.PhaseGroup=JCCH.PhaseGroup 
	and Cost.Phase=JCCH.Phase   
	and Cost.CostType=JCCH.CostType  
Left join (
			select 
			JCCI.JCCo, 
			JCCI.Contract, 
			ContDesc=Min(JCCM.Description), 
			JCCI.Item, 
			ItemDesc=JCCI.Description,  
			ContractStatus=Min(JCCM.ContractStatus),   
			OrigContractAmt=JCCI.OrigContractAmt, 
			OrigContractUnits=JCCI.OrigContractUnits,   
			OrigUnitPrice=JCCI.OrigUnitPrice,  
			CurrContractAmt=sum(JCID.ContractAmt),CurrContractUnits=sum(JCID.ContractUnits), CurrUnitPrice=JCCI.UnitPrice,  
			BilledAmt=sum(JCID.BilledAmt), 
			BilledUnits=sum(JCID.BilledUnits), 
			ReceivedAmt=sum(JCID.ReceivedAmt),
			HQCO.Name  
			FROM  JCCI with (NOLOCK)   
			join HQCO with (nolock) 
				on JCCI.JCCo=HQCO.HQCo  
			Join JCID with (NOLOCK) 
				on JCID.JCCo=JCCI.JCCo 
				and JCID.Contract=JCCI.Contract 
				and JCID.Item=JCCI.Item  
			Join JCCM with (NOLOCK) 
				on JCCM.JCCo=JCCI.JCCo 
				and JCCM.Contract=JCCI.Contract  
			where JCCI.JCCo=@JCCo 
				and JCCI.Contract>=@BeginContract 
				and JCCI.Contract<=@EndContract 
				and case when (@DateActPost = 'P') then JCID.PostedDate  else JCID.ActualDate end <=@EndDate  
			group by   
			JCCI.JCCo, 
			JCCI.Contract, 
			JCCI.Item,
			JCCI.OrigContractAmt, 
			JCCI.OrigContractUnits,  
			JCCI.OrigUnitPrice, 
			JCCI.UnitPrice, 
			JCCI.Description, 
			HQCO.Name) 

as Bill  
	on Bill.JCCo=JCCI.JCCo 
	and Bill.Contract=JCCI.Contract 
	and Bill.Item=JCCI.Item   
where @JCCo=JCCI.JCCo 
and JCCI.Contract >= @BeginContract 
and JCCI.Contract<=@EndContract  

GO
GRANT EXECUTE ON  [dbo].[vrptJCUnitCost] TO [public]
GO
