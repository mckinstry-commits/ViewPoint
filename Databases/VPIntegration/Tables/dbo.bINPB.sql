CREATE TABLE [dbo].[bINPB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[ProdLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[FinMatl] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[INTrans] [dbo].[bTrans] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE   trigger [dbo].[btINPBd] on [dbo].[bINPB] for DELETE as
   

declare @errmsg varchar(255)
   
   /*-----------------------------------------------------------------
    *	This trigger deletes all related components in this batch on delete
    *  of finished material
    *
    * Modified By:	GP 05/15/09 - Issue 133436 Removed HQAT delete, added new insert
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   delete bINPD from bINPD b, deleted d
   where d.Co = b.Co and d.Mth = b.Mth and d.BatchId = b.BatchId and d.BatchSeq = b.BatchSeq
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
	where h.UniqueAttchID not in(select t.UniqueAttchID from bINPD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete Production Batch!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE trigger [dbo].[btINPBi] on [dbo].[bINPB] for INSERT as
/*--------------------------------------------------------------
*  Created:  GR 11/30/99
* Modified: GG 10/17/02 - #16039 - removed bINPD initalization
*			GG 09/15/06 - added bHQCC update
*
* Insert trigger for IN Production Batch Header
*
*--------------------------------------------------------------*/
   
declare @numrows int, @errmsg varchar(255), @validcnt int
 
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate IN Company
select @validcnt = count(*)
from inserted i
join bINCO c on i.Co = c.INCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid IN Company'
	goto error
	end
-- validate Location
select @validcnt = count(*)
from inserted i
join bINLM m on i.ProdLoc = m.Loc and i.Co = m.INCo
where m.Active = 'Y'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid or inactive IN Location'
	goto error
	end
-- validate Material
select @validcnt = count(*)
from inserted i
join bINMT t on i.Co = t.INCo and i.MatlGroup = t.MatlGroup and i.FinMatl = t.Material and i.ProdLoc = t.Loc 
where t.Active = 'Y'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid or inactive Material'
	goto error
	end

-- add HQ Close Control for IN GL Co#
insert bHQCC (Co, Mth, BatchId, GLCo)
select i.Co, i.Mth, i.BatchId, c.GLCo
from inserted i
join bINCO c on i.Co = c.INCo
where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
						and h.BatchId = i.BatchId)
    
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert into IN Production Batch [bINPB]'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
    
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btINPBu] on [dbo].[bINPB] for UPDATE as
   

/*********************************************************************
    *	CREATED BY: GR 12/3/99
    *
    *	This trigger rejects update in bINPB
    *  if  the following error condition exists:
    *
    *  Invalid Location
    *	Invalid Material
    *
    ********************************************************************/
   declare @errmsg varchar(255),
   	@numrows int,
   	@validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   --Check for changes
   if update(ProdLoc)
   	begin
   	select @errmsg = 'Cannot change Production Location '
   	goto error
   	end
   
   if update(FinMatl)
       begin
   	select @errmsg = 'Cannot change Finished Good'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update IN Production Batch Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINPB] ON [dbo].[bINPB] ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINPB] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINPB].[ECM]'
GO
