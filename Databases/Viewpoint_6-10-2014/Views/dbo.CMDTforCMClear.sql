SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMDTforCMClear] as 
		Select CMDT.CMCo, CMDT.CMAcct, CMDT.InUseBatchId, CMDT.Amount as [DBAmt], CMDT.ClearedAmt, 
		case when CMDT.StmtDate is not null then (case when CMDT.Void = 'Y' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt],
		CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
		CMDT.ClearDate, CMDT.Mth, 
		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
		CMDT.StmtDate, case when PRVP.PaidDate is null then 'N' else 'Y' end as [PRVoidChk]
		from CMDT (nolock)
		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
		and PRVP.CMAcct=CMDT.CMAcct



GO
GRANT SELECT ON  [dbo].[CMDTforCMClear] TO [public]
GRANT INSERT ON  [dbo].[CMDTforCMClear] TO [public]
GRANT DELETE ON  [dbo].[CMDTforCMClear] TO [public]
GRANT UPDATE ON  [dbo].[CMDTforCMClear] TO [public]
GRANT SELECT ON  [dbo].[CMDTforCMClear] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMDTforCMClear] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMDTforCMClear] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMDTforCMClear] TO [Viewpoint]
GO
