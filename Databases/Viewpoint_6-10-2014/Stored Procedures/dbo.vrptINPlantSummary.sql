SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc  [dbo].[vrptINPlantSummary] 
       /* created 9/25/06 NF Used for the IN Plant Summary Report
       Issue 121195 Use Cost from the Sales records for COGS */
       
       /*********************************************************
       * Issue: 140947 
       * Changed By: DanK
       * Date: 11/11/10
       *
       * Change: Previous revision only performed summation where 
       *  the UM was TON and did not account for other common 
       *  abbreviations as well as international measures. 
       *  New summation formula: Tons=sum(case when  Left(UPPER(INDT.StkUM),3)IN ('TON','TN','T','KG') then -INDT.StkUnits else 0 end),
       **********************************************************/
       
-- exec	[dbo].[vrptINPlantSummary_dank] 10,'','zzzzzzzzzz','
     (@Company bCompany, 
      @BegLoc bLoc ='', 
      @EndLoc bLoc= 'zzzzzzzzzz',
      @ThroughMth datetime )

with recompile as
SELECT
        Type= '1-Sales',
        INDT.INCo, CoName=HQCO.Name, INDT.Loc, INDT.Mth, 
        IMonth=datepart(mm,INDT.Mth), 
        Year=datepart(yyyy,INDT.Mth),
        LocDescription=INLM.Description, LocActive=INLM.Active,
        HQMT.Category, CatDescription=HQMC.Description, 
        INDT.Material, MatDescription=HQMT.Description,
        Units=sum(INDT.StkUnits),
        Tons=sum(case when  Left(UPPER(INDT.StkUM),3)IN ('TON','TN','T','KG') then -INDT.StkUnits else 0 end),
        Amount=sum(-INDT.TotalPrice),
        INDT.StkUM
FROM INDT 
    join HQCO on INDT.INCo=HQCO.HQCo
    join INLM on INDT.INCo=INLM.INCo and INDT.Loc=INLM.Loc
    join HQMT on INDT.MatlGroup = HQMT.MatlGroup  and INDT.Material = HQMT.Material
    left join HQMC on HQMC.MatlGroup = HQMT.MatlGroup  and HQMC.Category = HQMT.Category
    
WHERE INDT.TransType like '___Sale%' 
      and INDT.INCo = @Company 
      and INDT.Loc >= @BegLoc and INDT.Loc <= @EndLoc 
      and ((Year(Mth)=Year(@ThroughMth) and Mth <= @ThroughMth) or 
            (DateDiff("mm", Mth,@ThroughMth) >= 12  and DateDiff("yy", Mth,@ThroughMth) = 1))
    
group by Type,
        INDT.INCo, HQCO.Name, INDT.Loc, INDT.Mth,datepart(mm,INDT.Mth), datepart(yyyy,INDT.Mth),
        INLM.Description, INLM.Active,
        HQMT.Category,HQMC.Description, 
        INDT.Material, HQMT.Description, INDT.StkUM

UNION ALL  

SELECT
        Type= '2-Cost of Sales',
        INDT.INCo, CoName=HQCO.Name, INDT.Loc, INDT.Mth, 
        IMonth=datepart(mm,INDT.Mth), Year=datepart(yyyy,INDT.Mth),
        LocDescription=INLM.Description, LocActive=INLM.Active,
        HQMT.Category, CatDescription=HQMC.Description, 
        INDT.Material, MatDescription=HQMT.Description,
        Units=sum(INDT.StkUnits),
        Tons=sum(case when Left(UPPER(INDT.StkUM),3)IN ('TON','TN','T','KG') then -INDT.StkUnits else 0 end),
        Amount=sum(-INDT.StkTotalCost),
        INDT.StkUM
FROM INDT 
    join HQCO on INDT.INCo=HQCO.HQCo
    join INLM on INDT.INCo=INLM.INCo and INDT.Loc=INLM.Loc
    join HQMT on INDT.MatlGroup = HQMT.MatlGroup  and INDT.Material = HQMT.Material
    left join HQMC on HQMC.MatlGroup = HQMT.MatlGroup  and HQMC.Category = HQMT.Category
    
WHERE INDT.TransType like '___Sale%' 
      and INDT.INCo = @Company 
      and INDT.Loc >= @BegLoc and INDT.Loc <= @EndLoc 
      and ((Year(Mth)=Year(@ThroughMth) and Mth <= @ThroughMth) or 
            (DateDiff("mm", Mth,@ThroughMth) >= 12  and DateDiff("yy", Mth,@ThroughMth) = 1))
    
group by Type,
        INDT.INCo, HQCO.Name, INDT.Loc, INDT.Mth,datepart(mm,INDT.Mth), datepart(yyyy,INDT.Mth),
        INLM.Description, INLM.Active,
        HQMT.Category,HQMC.Description, 
        INDT.Material, HQMT.Description, INDT.StkUM

union all
    
SELECT Type='3-Production Costs', 
       INLM.INCo, CoName=HQCO.Name, INLM.Loc,JCCP.Mth, 
       datepart(mm,JCCP.Mth), datepart(yyyy,JCCP.Mth),
       INLM.Description, INLM.Active, 
       '','',
       JCCP.Phase, JCJP.Description, 
       Units=0, Tons=0, 
       Amount=sum(ActualCost),
       ''
from INLM 
    join HQCO on INLM.INCo=HQCO.HQCo
    join JCCP on INLM.JCCo=JCCP.JCCo and INLM.Job=JCCP.Job
    join JCJP on JCCP.JCCo=JCJP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup and            JCJP.Phase=JCCP.Phase
where ActualCost<>0 
      and INLM.INCo = @Company 
      and INLM.Loc >= @BegLoc and INLM.Loc <= @EndLoc 
      and ((Year(Mth)=Year(@ThroughMth) and Mth <= @ThroughMth) or 
            (DateDiff("mm", Mth,@ThroughMth) >= 12  and DateDiff("yy", Mth,@ThroughMth) = 1))

group by INLM.INCo, HQCO.Name, INLM.Loc,INLM.Description, INLM.Active, JCCP.Phase,JCJP.Description,
         JCCP.Mth, datepart(mm,JCCP.Mth), datepart(yyyy,JCCP.Mth) 
Having sum(ActualCost)<>0
    
Union all
  
select Type='3-Production Costs', 
       INLM.INCo, CoName=HQCO.Name, INLM.Loc, EMCD.Mth, 
       datepart(mm,EMCD.Mth), datepart(yyyy,EMCD.Mth),
       INLM.Description, INLM.Active, 
       '','',
       convert(varchar(16),EMCD.CostCode), EMCC.Description, 
       Units=0,Tons=0,
       Amount=sum(EMCD.Dollars),
       EMCD.INStkUM
from INLM 
  join HQCO on INLM.INCo=HQCO.HQCo
  join EMCD on INLM.EMCo=EMCD.EMCo and INLM.Equipment=EMCD.Equipment
  left join EMCC on EMCD.EMGroup=EMCC.EMGroup and EMCD.CostCode=EMCC.CostCode
where EMCD.Dollars<>0
      and INLM.INCo = @Company 
      and INLM.Loc >= @BegLoc and INLM.Loc <= @EndLoc 
      and ((Year(Mth)=Year(@ThroughMth) and Mth <= @ThroughMth) or 
            (DateDiff("mm", Mth,@ThroughMth) >= 12  and DateDiff("yy", Mth,@ThroughMth) = 1))

Group by INLM.INCo, HQCO.Name, INLM.Loc,INLM.Description,INLM.Active, EMCC.Description, 
         EMCD.CostCode,  EMCD.INStkUM, EMCD.Mth, datepart(mm,EMCD.Mth), datepart(yyyy,EMCD.Mth)
having sum(EMCD.Dollars)<>0


GO
GRANT EXECUTE ON  [dbo].[vrptINPlantSummary] TO [public]
GO
