SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     view [dbo].[brvCMOutEntryAudit] as 
   select Co, Mth, BatchId, BatchSeq, BatchTransType, CMTrans,CMTransType,
          CMAcct, OldCMAcct = 0, ActDate, Description, Amount,
          CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, GLAcct, OldGLAcct = '', Void,
          RecordType = 1
   From dbo.CMDB with(NoLock)
   
   union all 
   select	Co, Mth, BatchId, BatchSeq, BatchTransType, CMTrans,CMTransType,
   	0, OldCMAcct, OldActDate, OldDesc, OldAmount,
   	OldCMRef, OldCMRefSeq, OldPayee, OldGLCo, OldCMGLAcct, Null, OldGLAcct, OldVoid,
   	RecordType = 2
   from dbo.CMDB with(NoLock)

GO
GRANT SELECT ON  [dbo].[brvCMOutEntryAudit] TO [public]
GRANT INSERT ON  [dbo].[brvCMOutEntryAudit] TO [public]
GRANT DELETE ON  [dbo].[brvCMOutEntryAudit] TO [public]
GRANT UPDATE ON  [dbo].[brvCMOutEntryAudit] TO [public]
GRANT SELECT ON  [dbo].[brvCMOutEntryAudit] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvCMOutEntryAudit] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvCMOutEntryAudit] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvCMOutEntryAudit] TO [Viewpoint]
GO
