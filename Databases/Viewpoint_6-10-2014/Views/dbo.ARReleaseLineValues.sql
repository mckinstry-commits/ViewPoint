SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARReleaseLineValues]
/*************************************************************************
* Created: TJL  06/17/05: Issue #27717, 6x Rewrite ARRetDetail
* Modified: GG 04/10/08 - added top 100 percent and order by 
*		TJL 07/07/08 - Issue #128371, AR Release International Sales Tax
*		
*
* Provides a view for AR Retainage Detail entries (ARBL) that fills a grid on
* the ARRetDetail form.  Some special values are displayed in the grid
* as a result of this view.  Others would be bound directly to ARBL table
*
*
**************************************************************************/

as 

select top 100 percent 'vCo' = b.Co, 'vMth' = b.Mth, 'vBatchId' = b.BatchId,
	'vBatchSeq' = b.BatchSeq, 'vARLine' = b.ARLine,		--Link to DDFI
	'TransLine' = l.ApplyLine, 'LineOpenRetg' = IsNull(sum(l.Retainage),0),							--Special Col values
	'LineOpenRetgTax' = IsNull(sum(l.RetgTax),0)
from ARTL l (nolock)
join ARTH h (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans					--NA: For InUseBatchId of each ApplyTrans
join ARBL b (nolock) on b.Co = l.ARCo and b.ApplyMth = l.ApplyMth and b.ApplyTrans = l.ApplyTrans	--ARBL Apply Info link to all ARTL w/Same
	and b.ApplyLine = l.ApplyLine
where l.ARCo = b.Co and l.ApplyMth = b.ApplyMth and l.ApplyTrans = b.ApplyTrans				--Limit to specific ApplyMth and ApplyTrans
  	and (isnull(h.InUseBatchID,0) <> b.BatchId												--NA: Cannot currently add Rel Trans into batch
		or (isnull(h.InUseBatchID,0) = b.BatchId and h.Mth <> b.Mth))						--NA: See above (Exclude this BatchMth/BatchId)
group by l.ApplyLine,																		--Sum Retainage and group/Display by ApplyLine value
	b.Co, b.Mth, b.BatchId, b.BatchSeq, b.ARLine
order by l.ApplyLine, b.Co, b.Mth, b.BatchId, b.BatchSeq, b.ARLine

GO
GRANT SELECT ON  [dbo].[ARReleaseLineValues] TO [public]
GRANT INSERT ON  [dbo].[ARReleaseLineValues] TO [public]
GRANT DELETE ON  [dbo].[ARReleaseLineValues] TO [public]
GRANT UPDATE ON  [dbo].[ARReleaseLineValues] TO [public]
GRANT SELECT ON  [dbo].[ARReleaseLineValues] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARReleaseLineValues] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARReleaseLineValues] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARReleaseLineValues] TO [Viewpoint]
GO
