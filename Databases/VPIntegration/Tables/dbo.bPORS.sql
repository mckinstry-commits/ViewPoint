CREATE TABLE [dbo].[bPORS]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[RecvdUnits] [dbo].[bUnits] NOT NULL,
[RecvdCost] [dbo].[bDollar] NOT NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPORSd    Script Date: 8/28/99 9:38:07 AM ******/
CREATE  trigger [dbo].[btPORSd] on [dbo].[bPORS] for DELETE as
/*--------------------------------------------------------------
*
*  Update trigger for PORS
*  Created By: DANF
*  Date: 05/24/01
*  Modified: DANF 02/22/02 corrected update query on POIT
*			 GF 08/23/2011 TK-07879 PO ITEM LINE
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- clean up batches when deleting Initalization Batch

----TK-07879
UPDATE dbo.vPOItemLine
	SET InUseBatchId = NULL,
		InUseMth = NULL
FROM DELETED d JOIN dbo.vPOItemLine l ON l.POCo=d.Co AND l.PO=d.PO and l.POItem=d.POItem AND l.POItemLine=d.POItemLine
	
	
UPDATE dbo.bPOIT
	SET InUseBatchId = NULL,
		InUseMth = NULL
FROM DELETED d JOIN dbo.bPOIT t ON d.Co=t.POCo and d.PO=t.PO and d.POItem=t.POItem

UPDATE dbo.bPOHD
	SET InUseMth = NULL,
		InUseBatchId = NULL
FROM DELETED d
JOIN dbo.bPOHD h ON d.Co=h.POCo AND d.PO=h.PO
JOIN dbo.bHQBC b ON b.BatchId = d.BatchId AND b.Mth = d.Mth
--from bPOHD h, deleted d, bHQBC b
--where d.Co=h.POCo and d.PO=h.PO and b.BatchId = d.BatchId and b.Mth = d.Mth

delete bPORG from bPORG g
inner join deleted d
on d.Co = g.POCo and d.Mth = g.Mth and d.BatchId = g.BatchId and d.BatchSeq = g.BatchSeq

delete bPORJ from bPORJ g
inner join deleted d
on d.Co = g.POCo and d.Mth = g.Mth and d.BatchId = g.BatchId and d.BatchSeq = g.BatchSeq

delete bPORN from bPORN g
inner join deleted d
on d.Co = g.POCo and d.Mth = g.Mth and d.BatchId = g.BatchId and d.BatchSeq = g.BatchSeq

delete bPORE from bPORE g
inner join deleted d
on d.Co = g.POCo and d.Mth = g.Mth and d.BatchId = g.BatchId and d.BatchSeq = g.BatchSeq



return


error:
	select @errmsg = @errmsg + ' - cannot remove PORS'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biPORS] ON [dbo].[bPORS] ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
