SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[POTotals]
AS
-- Current Cost of Items not in a Batch
select i.POCo, i.PO, i.POItem, i.CurCost as [Amount]
from dbo.bPOIT i (nolock) 
join dbo.bPOHD h (nolock) on h.POCo = i.POCo and h.PO = i.PO 
where h.InUseMth is null and h.InUseBatchId is null
union
-- Original Cost of Items in a Batch
select i.Co, h.PO, i.POItem, i.OrigCost as [Amount]
from dbo.bPOIB i (nolock)
join dbo.bPOHB h (nolock) on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq 
where i.BatchTransType in ('A','C')

GO
GRANT SELECT ON  [dbo].[POTotals] TO [public]
GRANT INSERT ON  [dbo].[POTotals] TO [public]
GRANT DELETE ON  [dbo].[POTotals] TO [public]
GRANT UPDATE ON  [dbo].[POTotals] TO [public]
GRANT SELECT ON  [dbo].[POTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POTotals] TO [Viewpoint]
GO
