SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMDTGrid]
   as
        Select CMCo, CMAcct, StmtDate, CMTrans, CMTransType, CMRef,
             Amount = (case when CMTransType in (1,4) then Amount * -1 else Amount end) ,
             ActDate, Description, Void, 'Cleared' = (Case StmtDate when null then 0 else 1 end),
             ClearDate, Mth, ClearedAmt = (case when CMTransType in (1,4) then
             (case when ClearedAmt > 0 then ClearedAmt * -1 else ClearedAmt end) else ClearedAmt end),
             InUseBatchId
        from CMDT

GO
GRANT SELECT ON  [dbo].[CMDTGrid] TO [public]
GRANT INSERT ON  [dbo].[CMDTGrid] TO [public]
GRANT DELETE ON  [dbo].[CMDTGrid] TO [public]
GRANT UPDATE ON  [dbo].[CMDTGrid] TO [public]
GRANT SELECT ON  [dbo].[CMDTGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMDTGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMDTGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMDTGrid] TO [Viewpoint]
GO
