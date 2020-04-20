CREATE TABLE [dbo].[bINXB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MO] [dbo].[bMO] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[OrderDate] [dbo].[bDate] NULL,
[OrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RemainCost] [dbo].[bDollar] NOT NULL,
[CloseDate] [dbo].[bDate] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btINXBd] on [dbo].[bINXB] for DELETE as
   

/*--------------------------------------------------------------
    *  Created: GG 04/29/02
    *  Modified: 
    *
    *	Delete trigger on IN Material Order Close Batch
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- unlock MO Header when Close Batch entry is deleted
   update bINMO
   set InUseBatchId = null, InUseMth = null
   from bINMO h
   join deleted d on d.Co = h.INCo and d.MO = h.MO
   if @@rowcount <> @numrows
       begin
       select @errmsg = 'Unable to unlock MAterial Order Header'
       goto error
       end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete MO Close Batch (bINXB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btINXBi] on [dbo].[bINXB] for INSERT as
   

/************************************************************
    *	Created: GG 04/29/02
    *  Modified: 
    *
    *	Insert trigger for IN Material Order Close Batch
    *
    ***********************************************************/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate batch
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   where r.Status = 0
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Batch or incorrect status, must be ''open'''
    	goto error
    	end
   
   -- add HQ Close Control for IN GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bINCO c on i.Co = c.INCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
    
   -- lock MO Header when added to Close Batch
   update bINMO
   set InUseBatchId = i.BatchId, InUseMth = i.Mth
   from bINMO h
   join inserted i on i.MO = h.MO and i.Co = h.INCo
   where h.InUseMth is null and h.InUseBatchId is null
   if @@rowcount <> @numrows
   	begin
   	select @errmsg = 'Unable to lock Material Order Header'
   	goto error
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert MO Close Batch entry (bINXB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE trigger [dbo].[btINXBu] on [dbo].[bINXB] for UPDATE as
   

/*--------------------------------------------------------------
    *	Created: GG 04/29/02
    *	Modified: 
    *
    *  Update trigger on IN Material Order Close Batch
    *  
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	and i.MO = d.MO	
   if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID, Batch Sequence, or Material Order'
    	goto error
    	end
   
   -- MO Header locked on Close Batch insert, cannot change MO
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update MO Close Batch (bINXB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINXB] ON [dbo].[bINXB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
