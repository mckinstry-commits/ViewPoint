SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptJCIDtoARTL]
   as 
   /* Issue 25918 add with (nolock) DW 11/05/04*/
   select JCCo, Contract, Item, Mth, 
          JCIDBilledUnits=sum(isnull(BilledUnits,0)), 
          JCIDBilledAmt=sum(isnull(BilledAmt,0)), 
          JCIDReceivedAmt=sum(isnull(ReceivedAmt,0)),
          JCIDCurrRetainAmt=sum(isnull(CurrentRetainAmt,0))
          
   into #brptJCIDtoARTL1
   from bJCID with(nolock)
   where JCTransType='AR'
   group by JCCo,Contract, Item, Mth
   
   select l.JCCo, l.Contract, l.Item, l.Mth, 
          ARTLContractUnits=sum(case when h.ARTransType <> 'P' then isnull(l.ContractUnits, 0) else 0 end), 
          ARTLAmount=sum(case when h.ARTransType <> 'P' then
              (l.Amount-l.Retainage) else 0 end),
          ARTLReceivedAmt=sum(case when h.ARTransType = 'P' then
              -(l.Amount-l.Retainage) else 0 end),
          ARTLRetainage=sum(case when h.ARTransType <> 'P' then isnull(l.Retainage, 0) else 0 end)
          
   into #brptJCIDtoARTL2
   from bARTL l with(nolock)
     join bARTH h with(nolock) on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
   where l.Contract is not null
   group by l.JCCo,l.Contract, l.Item, l.Mth
   
   select a.JCCo, b.JCCo, a.Contract, b.Contract, a.Item, b.Item,
          a.JCIDBilledUnits, b.ARTLContractUnits,
          a.JCIDBilledAmt, b.ARTLAmount,
          a.JCIDReceivedAmt, b.ARTLReceivedAmt,
          a.JCIDCurrRetainAmt, b.ARTLRetainage
   
   from #brptJCIDtoARTL1 a with(nolock)
     full outer join #brptJCIDtoARTL2 b with(nolock) on a.JCCo=b.JCCo and a.Contract=b.Contract and
              a.Item=b.Item and a.Mth=b.Mth  
   where isnull(a.JCIDBilledUnits, 0)<>isnull(b.ARTLContractUnits, 0) or
         isnull(a.JCIDBilledAmt, 0)<>isnull(b.ARTLAmount, 0) or
         isnull(a.JCIDReceivedAmt, 0)<>isnull(b.ARTLReceivedAmt, 0) or
         isnull(a.JCIDCurrRetainAmt,0)<>isnull(b.ARTLRetainage,0)

GO
GRANT EXECUTE ON  [dbo].[brptJCIDtoARTL] TO [public]
GO
