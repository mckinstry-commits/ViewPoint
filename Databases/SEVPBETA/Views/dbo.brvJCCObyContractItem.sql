SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
    
    
    
    CREATE     View [dbo].[brvJCCObyContractItem] as 
    Select JCOD.JCCo,JCOI.Contract,JCOI.Item,JCOD.Job,JCOD.ACO,JCOD.ACOItem ,JCOI.Description,ACOSequence = Null,Phase, JCOD.CostType,UM,JCOI.ApprovedMonth,EstUnits,EstHours,EstCost,ContractUnits = Null,ContUnitPrice = Null,ContractAmt = 0,ViewName = 'JCOD' From JCOD 
    	Inner Join JCOI on JCOD.JCCo = JCOI.JCCo and JCOD.Job = JCOI.Job and JCOD.ACO = JCOI.ACO and JCOD.ACOItem = JCOI.ACOItem
    
    Union all
    Select JCOI.JCCo,JCOI.Contract,JCOI.Item,JCOI.Job,JCOI.ACO,ACOItem,JCOI.Description,ACOSequence =  Null,Phase = Null,CostType = Null,UM = Null,ApprovedMonth,EstUnits = Null,EstHours = Null,EstCost = Null,ContractUnits,ContUnitPrice,ContractAmt,  ViewName = 'JCOI'From JCOI
    	Inner Join JCOH on JCOI.JCCo = JCOH.JCCo and JCOI.Job = JCOH.Job and JCOI.ACO = JCOH.ACO and JCOH.Contract = JCOI.Contract
    
    /*Union all
    Select JCOH.JCCo,JCOI.Contract,JCOI.Item,JCOH.Job,JCOH.ACO,ACOItem = Null, JCOH.Description,ACOSequence,Phase = Null,CostType = Null,UM = Null,ApprovedMonth = Null,EstUnits = Null,EstHours = Null,EstCost = Null,ContractUnits = Null,ContUnitPrice = Null,ContractAmt = 0, ViewName = 'JCOH' From JCOH
    	Inner Join JCOI on JCOH.JCCo = JCOI.JCCo and JCOH.Job = JCOI.Job and JCOH.ACO = JCOI.ACO and JCOH.Contract = JCOI.Contract
    
    Union all
    Select JCJM.JCCo,JCJM.Contract,JCOI.Item,JCOI.Job,ACO = Null ,ACOItem = Null,JCJM.Description,ACOSequence = Null,Phase = Null,CostType = Null,UM = Null,ApprovedMonth = Null,EstUnits = Null,EstHours = Null,EstCost = Null,ContractUnits = Null,ContUnitPrice = Null,ContractAmt = 0,  'JCJM' From JCJM
    	Inner Join JCOI on JCJM.JCCo = JCOI.JCCo and JCJM.Job = JCOI.Job and JCJM.Contract = JCOI.Contract
    
    Union all
    Select  JCCI.JCCo,JCCI.Contract,JCCI.Item,Job = Null  ,ACO = Null, ACOItem = Null, JCCI.Description,ACOSequence = Null,Phase = Null,CostType = Null,UM,ApprovedMonth = Null,EstUnits = Null,EstHours = Null,EstCost = Null, JCCI.ContractUnits,OrigContractAmt,JCCI.ContractAmt, ViewName = 'JCCI' From JCCI
    	Inner Join JCOI on JCCI.JCCo = JCOI.JCCo and JCCI.Contract = JCOI.Contract and JCCI.Item = JCOI.Item
    	
    Union all
    Select  JCCM.JCCo,JCOI.Contract, Item = Null,Job = Null,AC0 = Null, ACOItem = Null,JCCM.Description,ACOSequence = Null,Phase = Null, CostType = Null,UM = Null,ApprovedMonth = Null,EstUnits = Null,EstHours = Null,EstCost = Null,ContractUnits = Null,JCCM.OrigContractAmt,JCCM.ContractAmt,ViewName = 'JCCM' From JCCM
           Inner Join JCOI on JCCM.JCCo = JCOI.JCCo and JCCM.Contract = JCOI.Contract	*/
    
    
    
    
    
    
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCCObyContractItem] TO [public]
GRANT INSERT ON  [dbo].[brvJCCObyContractItem] TO [public]
GRANT DELETE ON  [dbo].[brvJCCObyContractItem] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCObyContractItem] TO [public]
GO
