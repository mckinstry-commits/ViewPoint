SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptJCIDtoJCIP]
   as 
   /* Issue 25919 add with (nolock) DW 11/05/04*/
   select JCCo, Mth, Contract, Item,
          JCIDOrigContractAmt=sum(case when JCTransType='OC' then
             ContractAmt else 0 end), 
          JCIDOrigContractUnits=sum(case when JCTransType='OC' then
             ContractUnits else 0 end), 
          JCIDOrigUnitPrice=sum(case when JCTransType='OC' then
             UnitPrice else 0 end),
          JCIDContractAmt=sum(ContractAmt),
          JCIDContractUnits=sum(ContractUnits),
          JCIDCurrentUnitPrice=sum(UnitPrice),
          JCIDBilledUnits=sum(BilledUnits), JCIDBilledAmt=sum(BilledAmt), 
          JCIDReceivedAmt=sum(ReceivedAmt), JCIDCurrentRetainAmt=sum(CurrentRetainAmt)
          
   into #brptJCIDtoJCIP
   from bJCID with(nolock)
   group by JCCo, Mth, Contract, Item
   
   select t.JCCo, p.JCCo, t.Mth, p.Mth, t.Contract, p.Contract, t.Item, p.Item,
          t.JCIDOrigContractAmt, JCIPOrigContractAmt=p.OrigContractAmt,
          t.JCIDOrigContractUnits, JCIPOrigContractUnits=p.OrigContractUnits,
          t.JCIDOrigUnitPrice, JCIPOrigUnitPrice=p.OrigUnitPrice,
          t.JCIDContractAmt, JCIPContractAmt=p.ContractAmt, 
          t.JCIDContractUnits, JCIPContractUnits=p.ContractUnits, 
          t.JCIDCurrentUnitPrice, JCIPCurrentUnitPrice=p.CurrentUnitPrice,
          t.JCIDBilledUnits, JCIPBilledUnits=p.BilledUnits,
          t.JCIDBilledAmt, JCIPBilledAmt=p.BilledAmt,
          t.JCIDReceivedAmt, JCIPReceivedAmt=p.ReceivedAmt,
          t.JCIDCurrentRetainAmt, JCIPCurrentRetainAmt=p.CurrentRetainAmt
          
   from bJCIP p with(nolock)
    left join #brptJCIDtoJCIP t with(nolock) on p.JCCo=t.JCCo and p.Mth=t.Mth and
              p.Contract=t.Contract and p.Item=t.Item
   where isnull(t.JCIDOrigContractAmt, 0)<>isnull(p.OrigContractAmt, 0) or
         isnull(t.JCIDOrigContractUnits, 0)<>isnull(p.OrigContractUnits, 0) or
        -- isnull(t.JCIDOrigUnitPrice, 0)<>isnull(p.OrigUnitPrice, 0) or
         isnull(t.JCIDContractAmt, 0)<>isnull(p.ContractAmt, 0) or
         isnull(t.JCIDContractUnits, 0)<>isnull(p.ContractUnits, 0) or
       --  isnull(t.JCIDCurrentUnitPrice, 0)<>isnull(p.CurrentUnitPrice, 0) or
         isnull(t.JCIDBilledUnits, 0)<>isnull(p.BilledUnits, 0) or
         isnull(t.JCIDBilledAmt, 0)<>isnull(p.BilledAmt, 0) or
         isnull(t.JCIDReceivedAmt, 0)<>isnull(p.ReceivedAmt, 0) or
         isnull(t.JCIDCurrentRetainAmt, 0)<>isnull(p.CurrentRetainAmt, 0)

GO
GRANT EXECUTE ON  [dbo].[brptJCIDtoJCIP] TO [public]
GO
