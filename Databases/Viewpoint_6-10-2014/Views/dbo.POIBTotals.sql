SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[POIBTotals] as
/***************************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by
*			DC 9/28/2009 #122288 - Store tax rate in PO Item, display tax in header
*
* Returns the PO's total current cost for each entry in a PO Entry batch
*
*****************************/

/*SELECT     SUM(ISNULL(b.OrigCost, 0)) +	SUM(ISNULL(t.CurCost, 0)) AS CurrentCost,b.Co, b.Mth, b.BatchId, b.BatchSeq
FROM         dbo.bPOIB AS b WITH (NOLOCK)
left outer join dbo.bPOHB AS h with (nolock) on b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
left outer join dbo.bPOIT as t with (nolock) on t.POCo = h.Co and t.PO = h.PO
WHERE     (b.BatchTransType <> 'D')
		and ((t.InUseMth IS NULL) AND (t.InUseBatchId IS NULL))
GROUP BY b.Co, b.Mth, b.BatchId, b.BatchSeq*/

SELECT top 100 percent sum(isnull(t.CurCost, 0)) + sum(isnull(b.OrigCost,0)) AS [Cost],
	sum(isnull(t.CurTax, 0)) + sum(isnull(b.OrigTax,0)) AS [Tax],  --DC #122288
	h.Co, h.Mth, h.BatchId, h.BatchSeq
FROM dbo.bPOHB h (nolock)
	left join dbo.bPOIT t (nolock) ON t.POCo = h.Co AND t.PO = h.PO and t.InUseMth is null AND t.InUseBatchId is null
	left join dbo.bPOIB b (nolock) ON b.BatchSeq = h.BatchSeq and b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchTransType in ('A','C')
group by h.Co, h.Mth, h.BatchId, h.BatchSeq
order by h.Co, h.Mth, h.BatchId


GO
GRANT SELECT ON  [dbo].[POIBTotals] TO [public]
GRANT INSERT ON  [dbo].[POIBTotals] TO [public]
GRANT DELETE ON  [dbo].[POIBTotals] TO [public]
GRANT UPDATE ON  [dbo].[POIBTotals] TO [public]
GRANT SELECT ON  [dbo].[POIBTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POIBTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POIBTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POIBTotals] TO [Viewpoint]
GO
