SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[SLEntryTotal] as
/***************************************
* Created: DC 02/22/2007 6.x only
* Modified: GG 04/10/08 - added top 100 percent and order by
*			DC 12/23/2009 - #130175 - SLIT needs to match POIT
*			DC 02/05/10 - #129892 - Handle Max Retainage
*
* Used by SL Entry to provide Subcontract Original Cost totals
*
*****************************/

SELECT sum(TotalCost) as [TotalCost], sum(Tax) as [Tax],
		SLCo, Mth, BatchId, BatchSeq
FROM (SELECT top 100 percent sum(isnull(b.OrigCost,0)) as [TotalCost],
		sum(isnull(b.OrigTax,0)) AS [Tax],
		h.Co as SLCo,
		h.Mth,
		h.BatchId,
		h.BatchSeq
	FROM dbo.bSLHB h with (nolock)
		-- SL Entry batch entries for Regular Items flagged as 'Add' or 'Change', exclude 'Delete'
		LEFT JOIN dbo.bSLIB b with (nolock) on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq and b.ItemType = 1 and b.BatchTransType in ('A','C')
	GROUP BY h.Co, h.Mth, h.BatchId, h.BatchSeq
	UNION
	SELECT top 100 percent sum(isnull(t.CurCost, 0)) as [TotalCost],
			sum(isnull(t.CurTax, 0)) as [Tax],
		h.Co as SLCo,
		h.Mth,
		h.BatchId,
		h.BatchSeq
	FROM dbo.bSLHB h with (nolock)
		-- existing Regular Items not in any batch
		LEFT JOIN dbo.bSLIT t with (nolock) on h.Co = t.SLCo and h.SL = t.SL and t.InUseMth is null and t.InUseBatchId is null and t.ItemType = 1
	GROUP BY h.Co, h.Mth, h.BatchId, h.BatchSeq)
as MyTable
Group by SLCo, Mth, BatchId, BatchSeq


GO
GRANT SELECT ON  [dbo].[SLEntryTotal] TO [public]
GRANT INSERT ON  [dbo].[SLEntryTotal] TO [public]
GRANT DELETE ON  [dbo].[SLEntryTotal] TO [public]
GRANT UPDATE ON  [dbo].[SLEntryTotal] TO [public]
GO
