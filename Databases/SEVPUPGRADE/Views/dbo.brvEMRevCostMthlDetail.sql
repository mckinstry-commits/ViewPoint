SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvEMRevCostMthlDetail] as select EMCo, EMGroup,Equipment,CostCode,CostType,RevCode=Null,Month, ActCost= sum(ActCost), ActRevAmt=null,RecType = 2
    From EMMC
    group by EMCo, EMGroup,Equipment,CostCode,CostType,Month
    
    union all
    
    --Select Revenue information
    
    select EMCo, EMGroup,Equipment, Null,Null,RevCode,Month,  0, sum(ActualAmt) ,RecType = 1
    From EMAR
    group by EMCo, EMGroup,Equipment, RevCode,Month

GO
GRANT SELECT ON  [dbo].[brvEMRevCostMthlDetail] TO [public]
GRANT INSERT ON  [dbo].[brvEMRevCostMthlDetail] TO [public]
GRANT DELETE ON  [dbo].[brvEMRevCostMthlDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvEMRevCostMthlDetail] TO [public]
GO
