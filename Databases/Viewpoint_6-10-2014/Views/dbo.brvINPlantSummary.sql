SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        view [dbo].[brvINPlantSummary]
      as
      /* created 5/15/02 JRE - used in Crystal Reports IN Plant Revenue and Cost report */
      /* mod 3/25/03 JRE Issue 19588 */
      SELECT
          Type=case when INDT.TransType like '___Sale%' then '1-Sales'
                    else '2-Cost of Sales' end,
          INDT.INCo, INDT.Loc, INDT.Mth, IMonth=datepart(mm,INDT.Mth), Year=datepart(yyyy,INDT.Mth),
          LocDescription=INLM.Description, LocActive=INLM.Active,
          HQMT.Category, CatDescription=HQMC.Description, 
          INDT.Material, MatDescription=HQMT.Description,
          Units=sum(INDT.StkUnits),
          Tons=sum(case when INDT.TransType like '___Sale%' and Left(UPPER(INDT.StkUM),3)='TON'
                        then -INDT.StkUnits 
                        else 0 end),
          PrintTons=sum(case 
                        when INDT.TransType like '___Sale%' and Left(UPPER(INDT.StkUM),3)='TON'
                        then -INDT.StkUnits
                        else 0 end),
          Price=sum(case when INDT.TransType like '___Sale%' then -INDT.TotalPrice
                         Else INDT.StkTotalCost end),
          ReversePrice=sum(case 
                         when INDT.TransType like '___Sale%' then -INDT.TotalPrice
                         Else -INDT.StkTotalCost end),
      	INDT.StkUM
      FROM INDT 
      join INLM on INDT.INCo=INLM.INCo and INDT.Loc=INLM.Loc
      join HQMT on INDT.MatlGroup = HQMT.MatlGroup  and INDT.Material = HQMT.Material
      left join HQMC on HQMC.MatlGroup = HQMT.MatlGroup  and HQMC.Category = HQMT.Category
      
      WHERE INDT.TransType not in ('Usage','Prod')
      
      group by case when INDT.TransType like '___Sale%' then '1-Sales'
                    else '2-Cost of Sales' end,
          INDT.INCo, INDT.Loc, INDT.Mth,datepart(mm,INDT.Mth), datepart(yyyy,INDT.Mth),
          INLM.Description, INLM.Active,
          HQMT.Category,HQMC.Description, 
          INDT.Material, HQMT.Description, INDT.StkUM
      
      union all
      
      SELECT 
      	Type='3-Production Costs', INLM.INCo, INLM.Loc,JCCP.Mth, datepart(mm,JCCP.Mth), datepart(yyyy,JCCP.Mth),
       INLM.Description, INLM.Active, '','',JCCP.Phase,
          JCJP.Description, Units=0, Tons=0, PrintTons=0, Price=sum(ActualCost),
          ReversePrice=sum(-ActualCost),''
      from INLM 
      join JCCP on INLM.JCCo=JCCP.JCCo and INLM.Job=JCCP.Job
      join JCJP on JCCP.JCCo=JCJP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup and JCJP.Phase=JCCP.Phase
      where ActualCost<>0
      group by INLM.INCo, INLM.Loc,INLM.Description, INLM.Active, JCCP.Phase,JCJP.Description,
       JCCP.Mth, datepart(mm,JCCP.Mth), datepart(yyyy,JCCP.Mth) 
      Having sum(ActualCost)<>0
    
      
    Union all
    
    select Type='3-Production Costs', INLM.INCo, INLM.Loc, EMCD.Mth, datepart(mm,EMCD.Mth), datepart(yyyy,EMCD.Mth),
          INLM.Description, INLM.Active, '','',convert(varchar(16),EMCD.CostCode),
          EMCC.Description, Units=0,Tons=0,PrintTons=0,Price=sum(EMCD.Dollars),
          ReversePrice=sum(-EMCD.Dollars),EMCD.INStkUM
    from INLM 
    join EMCD on INLM.EMCo=EMCD.EMCo and INLM.Equipment=EMCD.Equipment
    left join EMCC on EMCD.EMGroup=EMCC.EMGroup and EMCD.CostCode=EMCC.CostCode
    where EMCD.Dollars<>0
    Group by INLM.INCo, INLM.Loc,INLM.Description,INLM.Active, EMCC.Description, EMCD.CostCode,  EMCD.INStkUM,
    EMCD.Mth, datepart(mm,EMCD.Mth), datepart(yyyy,EMCD.Mth)
    having sum(EMCD.Dollars)<>0

GO
GRANT SELECT ON  [dbo].[brvINPlantSummary] TO [public]
GRANT INSERT ON  [dbo].[brvINPlantSummary] TO [public]
GRANT DELETE ON  [dbo].[brvINPlantSummary] TO [public]
GRANT UPDATE ON  [dbo].[brvINPlantSummary] TO [public]
GRANT SELECT ON  [dbo].[brvINPlantSummary] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvINPlantSummary] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvINPlantSummary] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvINPlantSummary] TO [Viewpoint]
GO
