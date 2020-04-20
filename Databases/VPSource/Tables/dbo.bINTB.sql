CREATE TABLE [dbo].[bINTB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[ToLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[INTrans] [dbo].[bTrans] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bINTB] ADD
CONSTRAINT [CK_bINTB_ECM] CHECK (([ECM]='M' OR [ECM]='C' OR [ECM]='E'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE trigger [dbo].[btINTBi] on [dbo].[bINTB] for INSERT as
/*--------------------------------------------------------------
*  Created:  GG 09/15/06
* Modified: 
*
* Insert trigger for IN Transfer Batch 
*
*--------------------------------------------------------------*/
   
declare @numrows int, @errmsg varchar(255), @validcnt int
 
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- add HQ Close Control for IN GL Co#
insert bHQCC (Co, Mth, BatchId, GLCo)
select i.Co, i.Mth, i.BatchId, c.GLCo
from inserted i
join bINCO c on i.Co = c.INCo
where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
						and h.BatchId = i.BatchId)
    
return
   
error:
	select @errmsg = @errmsg + ' - cannot insert into IN Transfer Batch [bINTB]'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
    
    
   
   
   
  
 





GO
CREATE UNIQUE CLUSTERED INDEX [biINTB] ON [dbo].[bINTB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINTB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINTB].[ECM]'
GO
