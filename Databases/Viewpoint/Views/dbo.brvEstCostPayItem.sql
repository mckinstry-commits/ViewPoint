SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvEstCostPayItem] as Select JCCI.JCCo, JCCI.Contract, ContDesc=JCCM.Description, JCJP.Item,ItemDesc=JCCI.Description,
    ItemUM=JCCI.UM, JCCI.OrigContractUnits, JCCI.OrigContractAmt, JCCI.OrigUnitPrice, 
    CurrContUnits=JCID.ContractUnits, CurrContAmt=JCID.ContractAmt, CurrUnitPrice=JCID.UnitPrice,
    JCCD.CostTrans, JCCD.Mth, JCCD.JCTransType, JCCD.EstUnits, JCCD.EstHours, JCCD.EstCost, 
    JCCD.PostedDate,JCCD.ActualDate, JCCD.ActualUnits, JCCD.ActualHours, JCCD.ActualCost,
    JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag, JCCH.ActiveYN, JCCH.CostType
     
    
    FROM
        JCCI JCCI
        Left Join JCID on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
    
        Join JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract 
         Left Join JCJP on JCJP.JCCo=JCCI.JCCo and JCJP.Contract=JCCI.Contract and 
    JCJP.Item=JCCI.Item
    
        Left Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase
    
        Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
    and JCCH.CostType=JCCD.CostType

GO
GRANT SELECT ON  [dbo].[brvEstCostPayItem] TO [public]
GRANT INSERT ON  [dbo].[brvEstCostPayItem] TO [public]
GRANT DELETE ON  [dbo].[brvEstCostPayItem] TO [public]
GRANT UPDATE ON  [dbo].[brvEstCostPayItem] TO [public]
GO
