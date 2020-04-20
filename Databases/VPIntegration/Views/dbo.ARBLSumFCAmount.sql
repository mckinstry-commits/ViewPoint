SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBLSumFCAmount]
/*************************************************************************
* Created: TJL  07/28/05: Issue #27704, 6x Rewrite ARFinChg
* Modified: GG 04/10/08 - added top 100 percent and order by
*		TJL 04/29/08:  Issue #128067, Keep FC Amount Total updated correctly
* 
* Provides a Total Finance Charge Amount value to be displayed in the form Header 
* based upon the sum of ARBL detail records for each FinanceChg header.
*
*
**************************************************************************/

as
select top 100 percent 'vCo' = Co, 'vMth' = Mth,
	'vBatchId' = BatchId, 
	'vBatchSeq' = BatchSeq, 
	'FCTotalAmount' = isnull(Sum(FinanceChg), 0)
from ARBL (nolock)
group by Co, Mth, BatchId, BatchSeq
order by Co, Mth, BatchId, BatchSeq

GO
GRANT SELECT ON  [dbo].[ARBLSumFCAmount] TO [public]
GRANT INSERT ON  [dbo].[ARBLSumFCAmount] TO [public]
GRANT DELETE ON  [dbo].[ARBLSumFCAmount] TO [public]
GRANT UPDATE ON  [dbo].[ARBLSumFCAmount] TO [public]
GO
