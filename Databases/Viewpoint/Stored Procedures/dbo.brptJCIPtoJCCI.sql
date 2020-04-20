SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptJCIPtoJCCI]
   as 
   /* Issue 25920 add with (nolock) DW 11/05/04*/
   select JCCo, Contract, Item, 
          JCIPOrigContractAmt=sum(OrigContractAmt), JCIPOrigContractUnits=sum(OrigContractUnits), 
          JCIPOrigUnitPrice=sum(OrigUnitPrice), 
          JCIPContractAmt=sum(ContractAmt),
          JCIPContractUnits=sum(ContractUnits), 
          JCIPCurrentUnitPrice=sum(CurrentUnitPrice),
          JCIPBilledUnits=sum(BilledUnits), JCIPBilledAmt=sum(BilledAmt),
          JCIPReceivedAmt=sum(ReceivedAmt), JCIPCurrentRetainAmt=sum(CurrentRetainAmt)
          
   into #brptJCIPtoJCCI
   from bJCIP with(nolock)
   group by JCCo,Contract, Item
   
   select t.JCCo, i.JCCo, t.Contract, i.Contract, t.Item, i.Item,
          t.JCIPOrigContractAmt, JCCIOrigContractAmt=i.OrigContractAmt,
          t.JCIPOrigContractUnits, JCCIOrigContractUnits=i.OrigContractUnits,
          t.JCIPOrigUnitPrice, JCCIOrigUnitPrice=i.OrigUnitPrice,
          t.JCIPContractAmt, JCCIContractAmt=i.ContractAmt,
          t.JCIPContractUnits, JCCIContractUnits=i.ContractUnits, 
          t.JCIPCurrentUnitPrice, JCCIUnitPrice=i.UnitPrice,
          t.JCIPBilledUnits, JCCIBilledUnits=i.BilledUnits,
          t.JCIPBilledAmt, JCCIBilledAmt=i.BilledAmt,
          t.JCIPReceivedAmt, JCCIReceivedAmt=i.ReceivedAmt,
          t.JCIPCurrentRetainAmt, JCCICurrentRetainAmt=i.CurrentRetainAmt
          
   from bJCCI i with(nolock)
    left join #brptJCIPtoJCCI t with(nolock) on i.JCCo=t.JCCo and i.Contract=t.Contract and
              i.Item=t.Item 
   where isnull(t.JCIPOrigContractAmt, 0)<>isnull(i.OrigContractAmt, 0) or
         isnull(t.JCIPOrigContractUnits, 0)<>isnull(i.OrigContractUnits, 0) or
         --isnull(t.JCIPOrigUnitPrice, 0)<>isnull(i.OrigUnitPrice, 0) or
         isnull(t.JCIPContractAmt, 0)<>isnull(i.ContractAmt, 0) or
         isnull(t.JCIPContractUnits, 0)<>isnull(i.ContractUnits, 0) or
         --isnull(t.JCIPCurrentUnitPrice, 0)<>isnull(i.UnitPrice, 0) or
         isnull(t.JCIPBilledUnits, 0)<>isnull(i.BilledUnits, 0) or
         isnull(t.JCIPBilledAmt, 0)<>isnull(i.BilledAmt, 0) or
         isnull(t.JCIPReceivedAmt, 0)<>isnull(i.ReceivedAmt, 0) or
         isnull(t.JCIPCurrentRetainAmt, 0)<>isnull(i.CurrentRetainAmt, 0)

GO
GRANT EXECUTE ON  [dbo].[brptJCIPtoJCCI] TO [public]
GO
