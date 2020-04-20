CREATE TABLE [dbo].[bINMB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MO] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[OrderDate] [dbo].[bDate] NULL,
[OrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Status] [tinyint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldOrderDate] [dbo].[bDate] NULL,
[OldOrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldStatus] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE  trigger [dbo].[btINMBd] on [dbo].[bINMB] for DELETE as 
   

/***************************************************
    * Created: GG 04/29/02
    * Modified:	GP 05/15/09 - Issue 133436 Removed HQAT delete, added new insert
    *
    * Delete trigger for IN Material Order Header Batch
    *
    ****************************************************/
   
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount 
   if @numrows = 0 return
   
   set nocount on
   
   -- do not allow removal if Items exist
   if exists(select 1 from deleted d join bINIB b on d.Co = b.Co and d.Mth = b.Mth
   			and d.BatchId = b.BatchId and d.BatchSeq = b.BatchSeq)
   	begin
       select @errmsg = 'Material Order Items exist in Batch'
       goto error
       end
   
   --unlock MO Headers
   update bINMO
   set InUseMth = null, InUseBatchId = null 
   from bINMO h
   join deleted d on d.Co = h.INCo and d.MO = h.MO
   where h.InUseMth = d.Mth and h.InUseBatchId = d.BatchId
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
	where h.UniqueAttchID not in(select t.UniqueAttchID from bINMO t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot remove IN Material Order Batch Header (bINMB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE    trigger [dbo].[btINMBi] on [dbo].[bINMB] for INSERT as
   

/*****************************************************
    * Created: GG 04/18/02
    * Modified: DAN SO - 02/02/09 - Issue #132099 - "nolock" hints and If Exists
    *
    *  Update trigger for IN Material Order Batch Header
    *
    *******************************************************/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate batch
   select @validcnt = count(*)
   from bHQBC r WITH (NOLOCK)
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   where r.Status = 0
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid or ''closed'' Batch'
    	goto error
    	end
    
   -- add HQ Close Control for IN GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bINCO c WITH (NOLOCK) on i.Co = c.INCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   -- add HQ Close Control for JC GL Co#s referenced by MO 
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bJCCO c WITH (NOLOCK) on i.JCCo = c.JCCo 
   where c.GLCo not in (select h.GLCo from bHQCC h WITH (NOLOCK) join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   
   --lock existing MO Headers
	--Issue #132099
	IF EXISTS(SELECT TOP 1 1 FROM inserted WHERE BatchTransType in ('C','D'))
   	begin
   		update bINMO
   		set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   		from bINMO h
   		join inserted i on i.Co = h.INCo and i.MO = h.MO
   		where h.InUseMth is null and h.InUseBatchId is null and i.BatchTransType in ('C','D')

		if @@ERROR <> 0
   	 		begin
   	 			select @errmsg = 'Unable to lock Material Order Header'
   	 			goto error
   	 		end
   	end
    
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Material Order Batch Header (bINMB)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btINMBu] on [dbo].[bINMB] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created: GG 04/29/02
    *  Modified:
    *
    *	Update trigger on IN Material Order Header Batch
    *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Seq#'
   	goto error
   	end
   
   /* check for change in BatchTransType */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   where (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   	or (d.BatchTransType in ('C','D') and i.BatchTransType = 'A')
   if @validcnt > 0
   	begin
   	select @errmsg = 'Cannot change from ''add'' to ''change'' or ''delete'' or vice-versa'
   	goto error
   	end
   
   /* if change or delete, cannot change MO */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   where i.BatchTransType in ('C','D') and d.MO <> i.MO
   if @validcnt > 0
   	begin
   	select @errmsg = 'Cannot change Material Order# on ''change'' or ''delete'''
   	goto error
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update IN Material Order Header Batch (bINMB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINMB] ON [dbo].[bINMB] ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINMB] ([KeyID]) ON [PRIMARY]
GO
