CREATE TABLE [dbo].[bPOXB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[Remaining] [dbo].[bDollar] NOT NULL,
[CloseDate] [dbo].[bDate] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOXB] ON [dbo].[bPOXB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOXBd    Script Date: 8/28/99 9:38:08 AM ******/
   CREATE    trigger [dbo].[btPOXBd] on [dbo].[bPOXB] for DELETE as
   

/*--------------------------------------------------------------
    *  Created: 5/14/97 kf
    *  Modified: 04/22/99 GG    (SQL 7.0)
    *              GG 11/05/99 - Cleanup
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- unlock PO Header when Close Batch entry is deleted
   update bPOHD
   set InUseBatchId = null, InUseMth = null
   from bPOHD h
   join deleted d on d.Co = h.POCo and d.PO = h.PO
   if @@rowcount <> @numrows
       begin
       select @errmsg = 'Unable to unlock PO Header'
       goto error
       end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete PO Close Batch (bPOXB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOXBi    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE    trigger [dbo].[btPOXBi] on [dbo].[bPOXB] for INSERT as
   

/************************************************************
    *	Created: kf   5/14/97
    *  Modified: GG 11/05/99
    *			GG 04/18/02 - #17051 cleanup
    *
    *	Insert trigger for PO Close Batch
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
    	select @errmsg = 'Invalid Batch or incorrect status, must be (open)'
    	goto error
    	end
   
   -- add HQ Close Control for AP/PO GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bAPCO c on i.Co = c.APCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
    
   
   -- lock PO Header when added to Close Batch
   update bPOHD
   set InUseBatchId = i.BatchId, InUseMth = i.Mth
   from bPOHD h
   join inserted i on i.PO = h.PO and i.Co = h.POCo
   where h.InUseMth is null and h.InUseBatchId is null
   if @@rowcount <> @numrows
   	begin
   	select @errmsg = 'Unable to lock Purchase Order Header'
   	goto error
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert PO Close Batch entry (bPOXB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btPOXBu] on [dbo].[bPOXB] for UPDATE as
   

/*--------------------------------------------------------------
    *	Created: EN 12/28/99
    *	Modified: GG 04/29/02 - #17051 - cleanup
    *
    *  Update trigger on PO Close Batch
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
   	and i.PO = d.PO	
   if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID, Batch Sequence, or PO#'
    	goto error
    	end
   
   -- PO Header locked on Close Batch insert, cannot change PO
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update PO Close Batch (bPOXB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
