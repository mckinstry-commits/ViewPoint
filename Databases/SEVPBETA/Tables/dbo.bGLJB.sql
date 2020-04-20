CREATE TABLE [dbo].[bGLJB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[EntryId] [smallint] NOT NULL,
[Seq] [tinyint] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[InterCo] [dbo].[bCompany] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btGLJBu    Script Date: 8/28/99 9:37:30 AM ******/
   CREATE  trigger [dbo].[btGLJBd] on [dbo].[bGLJB] for Delete as
   

declare @numrows int, @errmsg varchar(255)
   /*-----------------------------------------------------------------
    *	This trigger Deletes HQAT entries
    *	if a trans record in GLDT does not exist
    *  
    * Created: TV 02/21/02
    * Modified By:	GP 05/14/09 - Issue 133435 Removed HQAT delete, added insert
    *----------------------------------------------------------------*/
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
    where h.UniqueAttchID not in(select t.UniqueAttchID from bGLDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null  
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Auto Journal Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE  trigger [dbo].[btGLJBi] on [dbo].[bGLJB] for INSERT as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 08/18/06 - VP6.0 recode - eliminated cursor and unnecessary validation
*
*	This trigger rejects insertion in bGLJB (Auto Journal Batch)  
*	if any of the following error conditions exist:
*
*	Invalid Batch ID#
*
*	Adds entry to HQ Close Control as needed.
*/----------------------------------------------------------------
  
declare @numrows int, @validcnt int, @errmsg varchar(255) 
   
select @numrows = @@rowcount
if @numrows = 0 return 
set nocount on

-- validate Batch Control 
select @validcnt = count(*) from bHQBC b (nolock) 
join inserted i on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
where b.Source = 'GL Auto' and b.TableName = 'GLJB' and b.InUseBy is not null
	and b.Status = 0 and b.Adjust = 'N'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Not a valid GL Auto Journal Entry batch.'
	goto error
	end
   
-- add entry to HQ Close Control as needed 
insert bHQCC (Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, Co
from inserted i
where not exists(select top 1 1 from bHQCC c (nolock) where c.Co=i.Co and c.Mth = i.Mth and c.BatchId = i.BatchId and c.GLCo = i.Co)
	
return

error:
	select @errmsg = @errmsg + ' - cannot insert Auto Journal Batch entry!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLJBu    Script Date: 8/28/99 9:37:30 AM ******/
   CREATE  trigger [dbo].[btGLJBu] on [dbo].[bGLJB] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bGLJB (Auto Journal Batch) if
    *	any of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change Month
    *		Cannot change Batch ID#
    *		Cannot change Batch Sequence#
    *
    *----------------------------------------------------------------*/
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */ 
   select @validcount = count(*) from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @validcount <> @numrows
   	begin
   	select @errmsg = 'Cannot change GL Company, Month, Batch ID Number, or Batch Sequence Number'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Auto Journal Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bGLJB] ADD CONSTRAINT [PK_bGLJB] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLJB] ON [dbo].[bGLJB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
