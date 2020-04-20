SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Drop proc brptJCDailyRptByPayItem
  /****** Object:  Stored Procedure dbo.brptJCRevCostDate    Script Date: 8/28/99 9:33:52 AM ******/
 CREATE            proc [dbo].[brptJCDailyRptByPayItem]

/**********************************************************************
 * Created: 06/08/05 NF 
 * Modified:	
 * 
 *	TMS 03/17/2009 - #133502 - Updated ContDesc from varChar(30) to 
 *		varChar(60) to facilitate change in desc lengths
 *	CR	01/16/2006 - #119784 - removed the ItemDesc from the temp 
 *		table, it is not necessary, now getting ItemDesc from 
 *		JCCI in the stored proc coding 
 *	NF	06/14/2005 - #28792 - This replaces brptJCRevCostDate 
 * 		and is used by JC Daily Report By Pay Item
 *
 **********************************************************************/

	( @JCCo			bCompany				, @BeginContract	bContract	= ''		
	, @EndContract	bContract = 'zzzzzzzzz'	, @BeginDate		bDate		= '01/01/50'
	, @EndDate		bDate					, @DateActPost		char(2)
	, @JobActivity	char(2))

  as
  
  create table #JobActivity
  	(JCCo tinyint NULL,
  	 Contract varchar (10) NULL,
          COName varchar(60),
          ContDesc varchar(60) NULL)--,
          --ItemDesc varchar(60) NULL
 	 --)
  
  insert into #JobActivity
  	select JCJP.JCCo, JCJP.Contract,max(HQCO.Name), ContDesc=max(JCCM.Description)--, ItemDesc=max(JCCI.Description)
         From JCJP with(nolock) 
         join JCCD with(nolock) on JCCD.JCCo = JCJP.JCCo and JCCD.Job = JCJP.Job
 	--join JCCI with(nolock) on JCJP.JCCo=JCCI.JCCo and JCJP.Contract=JCCI.Contract and JCJP.Item = JCCI.Item
 	Join JCCM with(nolock) on JCCM.JCCo=JCJP.JCCo and JCCM.Contract=JCJP.Contract
     	Join HQCO with(nolock) on HQCO.HQCo=JCJP.JCCo
 	Where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
        	Group By JCJP.JCCo, JCJP.Contract 
         having Max(case when @JobActivity<>'Y' then JCCD.ActualCost else 1 end)<>0
         
  
  /* select the results */
 
 select 			--Insert the Contract Information  JCCI
     JCCo=JCCI.JCCo, 
     COName=#JobActivity.COName,
     Contract=JCCI.Contract, 
     ContDesc=#JobActivity.ContDesc,
     Item=JCCI.Item, 
     ItemDesc= JCCI.Description,--#JobActivity.ItemDesc,
     ItemUM=JCCI.UM, 
     BilledUnits=JCRev.BilledUnits, 
     BilledAmt=JCRev.BilledAmt,
  
     OrigContractUnits=JCCI.OrigContractUnits,
     OrigContractAmt=JCCI.OrigContractAmt, 
     OrigUnitPrice=JCCI.OrigUnitPrice, 
  
     CurrContractAmt=JCRev.CurrContractAmt,
     CurrContractUnits=JCRev.CurrContractUnits,
     CurrUnitPrice=JCRev.CurrUnitPrice,
  
     ActualHours=JCCost.ActualHours,
     ActualUnits=JCCost.ActualUnits,
     ActualCost=JCCost.ActualCost,
  
     CurrEstHours=JCCost.CurrEstHours,
     CurrEstUnits=JCCost.CurrEstUnits, 
     CurrEstCost=JCCost.CurrEstCost,
  
     PerActualHours=JCCost.PerActualHours,
     PerActualUnits=JCCost.PerActualUnits,
     PerActualCost=JCCost.PerActualCost,
  
     OrigEstHours=JCCost.OrigEstHours, 
     OrigEstUnits=JCCost.OrigEstUnits,
     OrigEstCost=JCCost.OrigEstCost,
  
     DayActualHours=JCCost.DayActualHours,
     DayActualUnits=JCCost.DayActualUnits,
     DayActualCost=JCCost.DayActualCost,
     DayEstHours=JCCost.DayEstHours,
     DayEstUnits=JCCost.DayEstUnits,
     DayEstCost=JCCost.DayEstCost,
  
     ProjHours=JCCost.ProjHours,
     ProjUnits=JCCost.ProjUnits,
     ProjCost=JCCost.ProjCost 
  
 from JCCI with(nolock) 
     Join #JobActivity on #JobActivity.JCCo=JCCI.JCCo and #JobActivity.Contract=JCCI.Contract
 
     left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item,
 	sum(CD.ActualHours) as ActualHours,
     	sum(case JCCH.ItemUnitFlag when 'Y' then CD.ActualUnits else 0 end) as ActualUnits,
     	sum(CD.ActualCost) as ActualCost,
    	sum(CD.EstHours) as CurrEstHours,
    	sum(case JCCH.ItemUnitFlag when 'Y' then CD.EstUnits else 0 end) as CurrEstUnits, 
    	sum(CD.EstCost) as CurrEstCost,
     	sum(case when(case when @DateActPost = 'P' then CD.PostedDate else CD.ActualDate end)>=@BeginDate then CD.ActualHours else 0 end) as PerActualHours,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate else CD.ActualDate end)>=@BeginDate then (case JCCH.ItemUnitFlag when 'Y' then CD.ActualUnits else 0 end)end) as PerActualUnits,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate else CD.ActualDate end)>=@BeginDate then CD.ActualCost else 0 end) as PerActualCost,
     	sum(case when CD.JCTransType = 'OE' then CD.EstHours else 0 end) as OrigEstHours, 
  	sum(case when JCCH.ItemUnitFlag = 'Y' and CD.JCTransType = 'OE' then CD.EstUnits else 0 end) as OrigEstUnits,
  	sum(case when CD.JCTransType = 'OE' then CD.EstCost else 0 end) as OrigEstCost,
      	sum(case when(case when @DateActPost = 'P' then CD.PostedDate  else CD.ActualDate end)=@EndDate then CD.ActualHours else 0 end) as DayActualHours,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate  else CD.ActualDate end)=@EndDate then (case JCCH.ItemUnitFlag when 'Y' then CD.ActualUnits else 0 end)end) as DayActualUnits,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate  else CD.ActualDate end)=@EndDate then CD.ActualCost else 0 end) as DayActualCost,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate  else CD.ActualDate end)=@EndDate then CD.EstHours else 0 end) as DayEstHours,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate  else CD.ActualDate end)=@EndDate then (case JCCH.ItemUnitFlag when 'Y' then CD.EstUnits else 0 end)end) as DayEstUnits,
  	sum(case when(case when @DateActPost = 'P' then CD.PostedDate  else CD.ActualDate end)=@EndDate then  CD.EstCost else 0 end) as DayEstCost,
  	sum(CD.ProjHours) as ProjHours,
     	sum(case JCCH.ItemUnitFlag when 'Y' then CD.ProjUnits else 0 end) as ProjUnits,
     	sum(CD.ProjCost) as ProjCost
     FROM JCCD CD with(nolock)
 	Left Outer JOIN JCJP with(nolock) on CD.JCCo=JCJP.JCCo and CD.Job=JCJP.Job and CD.Phase=JCJP.Phase
 	JOIN JCCH with(nolock) on JCCH.JCCo=CD.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase and JCCH.CostType=CD.CostType
 	group by JCJP.JCCo, JCJP.Contract, JCJP.Item )
 	as JCCost on JCCost.JCCo=JCCI.JCCo and JCCost.Contract = JCCI.Contract and JCCost.Item = JCCI.Item
 
     left join (select CI.JCCo, CI.Contract, CI.Item, ItemUM=max(CI.UM),
 	sum(CID.BilledUnits) as BilledUnits,
 	sum(CID.BilledAmt) as BilledAmt,
 	sum(CID.ContractAmt) as CurrContractAmt,
     	sum(CID.ContractUnits) as CurrContractUnits,
     	sum(CID.UnitPrice) as CurrUnitPrice
  
     from JCCI CI with (nolock) 
 	left outer join JCID CID on CI.JCCo=CID.JCCo and CI.Contract=CID.Contract and CI.Item=CID.Item
 	Where CI.JCCo=@JCCo and CI.Contract>=@BeginContract and CI.Contract<=@EndContract
 	group by CI.JCCo, CI.Contract, CI.Item)
 	as JCRev on JCRev.JCCo=JCCI.JCCo and JCRev.Contract = JCCI.Contract and JCRev.Item = JCCI.Item
 
 Where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract
 --Group by JCCI.JCCo, JCCI.Contract, JCCI.Item

GO
GRANT EXECUTE ON  [dbo].[brptJCDailyRptByPayItem] TO [public]
GO
