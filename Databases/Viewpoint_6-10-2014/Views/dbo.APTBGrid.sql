SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[APTBGrid] 
/*****************************************************
* Created:	??
* Modified:	MV 02/23/05 - #26761 top 100 percent, order by
*
* Used by Form APPayEdit
******************************************************/
as
select top 100 percent a.Co, a.Mth, a.BatchId, a.BatchSeq, a.ExpMth,
	a.APTrans, a.APRef, a.Description, a.InvDate, a.Gross, a.Retainage, a.PrevPaid,
  	a.PrevDisc, a.Balance, 'DiscAmt' = sum(d.DiscTaken), 'CurrentAmt' = sum(Amount),
  	'NetAmt' = sum(Amount) - sum(d.DiscTaken)
from APTB a (nolock)
join APDB d (nolock) on d.Co = a.Co and d.Mth = a.Mth and d.BatchId = a.BatchId
  	and d.BatchSeq = a.BatchSeq and d.APTrans = a.APTrans and d.ExpMth = a.ExpMth
group by a.Co, a.Mth, a.BatchId, a.BatchSeq, a.ExpMth, a.APTrans, a.APRef,
  		a.Description, a.InvDate, a.Gross, a.Retainage, a.PrevPaid, a.PrevDisc,
  		a.Balance, a.DiscTaken
order by a.Co, a.Mth, a.BatchId, a.BatchSeq

GO
GRANT SELECT ON  [dbo].[APTBGrid] TO [public]
GRANT INSERT ON  [dbo].[APTBGrid] TO [public]
GRANT DELETE ON  [dbo].[APTBGrid] TO [public]
GRANT UPDATE ON  [dbo].[APTBGrid] TO [public]
GRANT SELECT ON  [dbo].[APTBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APTBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APTBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APTBGrid] TO [Viewpoint]
GO
