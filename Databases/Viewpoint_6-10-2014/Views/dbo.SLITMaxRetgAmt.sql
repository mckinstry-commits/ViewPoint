SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE view [dbo].[SLITMaxRetgAmt]
/*************************************************************************
* Created:  DC 02/02/10 - Issue #129892, Maximum Retainage Enhancement
* Modified: 
*				GF 05/15/2012 TK-14929 issue #146439 item type in (1,2)
*		
* Provides a view for SL Subcontract Entry form that returns the calculated
* maximum retainage amount based upon:
*
*	SLHD Percent of Contract setup value.
*	SLHD exclude Variations from Max Retainage by % value.
*	SLIT Non-Zero Retainage Percent items
*
*
**************************************************************************/ 
as

Select sum(MaxRetgByPct) as [MaxRetgByPct], SLCo, Mth, BatchId, BatchSeq
from
(SELECT top 100 percent --Sum of all SL Items not included in the batch
	'MaxRetgByPct' = case when h.InclACOinMaxYN = 'Y' then (h.MaxRetgPct * sum(isnull(t.CurCost, 0))) 
		else (h.MaxRetgPct * sum(isnull(t.OrigCost, 0))) end,
		h.Co as SLCo, 
		h.Mth, 
		h.BatchId, 
		h.BatchSeq
FROM dbo.bSLHB h with (nolock)
	LEFT JOIN dbo.bSLIT t with (nolock) on h.Co = t.SLCo and h.SL = t.SL 
	and t.InUseMth is null and t.InUseBatchId is null and WCRetPct <> 0
	----TK-14929
	AND t.ItemType IN (1,2) 
group by h.Co, h.Mth, h.BatchId, h.BatchSeq, h.InclACOinMaxYN, h.MaxRetgPct
UNION ALL
SELECT top 100 percent --The sum of ALL SL Item in the batch
	'MaxRetgByPct' = case when h.InclACOinMaxYN = 'Y' then h.MaxRetgPct * ((sum(isnull(t.CurCost, 0)) - sum(isnull(b.OldOrigCost, 0))) + sum(isnull(b.OrigCost,0))) 
		else (h.MaxRetgPct * sum(isnull(b.OrigCost, 0))) end,
		h.Co as SLCo, 
		h.Mth, 
		h.BatchId, 
		h.BatchSeq					
FROM dbo.bSLHB h with (nolock)
	LEFT JOIN dbo.bSLIB b with (nolock) on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId 
	AND h.BatchSeq = b.BatchSeq and b.BatchTransType in ('A','C') and b.WCRetPct <> 0 
	----TK-14929
	AND b.ItemType IN (1,2)
	LEFT JOIN dbo.bSLIT t with (nolock) on h.Co = t.SLCo and h.SL = t.SL and b.SLItem = t.SLItem
	AND t.InUseMth is not null and t.InUseBatchId is not null and t.WCRetPct <> 0
	AND t.ItemType IN (1,2) 
group by h.Co, h.Mth, h.BatchId, h.BatchSeq, h.InclACOinMaxYN, h.MaxRetgPct)
as MyTable
Group by SLCo, Mth, BatchId, BatchSeq






GO
GRANT SELECT ON  [dbo].[SLITMaxRetgAmt] TO [public]
GRANT INSERT ON  [dbo].[SLITMaxRetgAmt] TO [public]
GRANT DELETE ON  [dbo].[SLITMaxRetgAmt] TO [public]
GRANT UPDATE ON  [dbo].[SLITMaxRetgAmt] TO [public]
GRANT SELECT ON  [dbo].[SLITMaxRetgAmt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLITMaxRetgAmt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLITMaxRetgAmt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLITMaxRetgAmt] TO [Viewpoint]
GO
