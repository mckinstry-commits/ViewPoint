SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************************
* Created: TJL  05/30/07: Issue #27720, 6x Rewrite ARCashReceipts
* 
*		
*
* Provides a view for CMDeposit Lookup in the ARCashReceipts form
* which combines posted CMRefs in CMDT with unposted CMDeposits still
* in ARCashReceipts batches.
*
*
**************************************************************************/

CREATE view [dbo].[CMRefByMthIncludeARBatch] as 

select CMDT.CMCo CMCo, CMDT.CMTransType CMTransType, 
	CMDT.CMRef CMRef, CMDT.CMAcct CMAcct, CMDT.Description Description, CMDT.Mth Mth, CMDT.ActDate ActDate, 
	(case CMDT.CMTransType when 0 then 'Adj' when 1 then 'Chk'when 2 then 'Dep' when 3 then 'Trns' when 4 then 'EFT' end) TransType
from CMDT
union
select ARBH.CMCo, 2,
	ARBH.CMDeposit, ARBH.CMAcct, 'Not Posted', ARBH.Mth, ARBH.TransDate, 
	'Dep'
from ARBH

GO
GRANT SELECT ON  [dbo].[CMRefByMthIncludeARBatch] TO [public]
GRANT INSERT ON  [dbo].[CMRefByMthIncludeARBatch] TO [public]
GRANT DELETE ON  [dbo].[CMRefByMthIncludeARBatch] TO [public]
GRANT UPDATE ON  [dbo].[CMRefByMthIncludeARBatch] TO [public]
GO
