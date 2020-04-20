CREATE TABLE [dbo].[bINPD]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ProdSeq] [int] NOT NULL,
[CompLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[CompMatl] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[PECM] [dbo].[bECM] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[INTrans] [dbo].[bTrans] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   CREATE   trigger [dbo].[btINPDd] on [dbo].[bINPD] for DELETE as
   

/*****************************************************
    *	Created:	GP 05/15/09
    *	Modified:	
    *
    *	Delete trigger on INPD
    *
    *****************************************************/
   
   declare @numrows int, @errmsg varchar(255)
     
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
      
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
    where d.UniqueAttchID is not null   
		
	return
   
	error:
   		select @errmsg = @errmsg + ' - cannot delete INPD record!'
		RAISERROR(@errmsg, 11, -1);


   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE   trigger [dbo].[btINPDi] on [dbo].[bINPD] for INSERT as
   

/*--------------------------------------------------------------
    * Created: GR 11/30/99
    * Modified: GG 10/17/02 - #16039 - cleanup
    *
    *  Insert trigger for IN Production Batch Detail
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate Production Batch Header
   select @validcnt = count(*)
   from inserted i
   join bINPB b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId and i.BatchSeq = b.BatchSeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Missing IN Production Batch Header'
   	goto error
   	end
   -- validate Location
   select @validcnt = count(*)
   from inserted i
   join bINLM m on i.CompLoc = m.Loc and i.Co = m.INCo
   where m.Active = 'Y'
   if @validcnt <> @numrows
   	begin
       select @errmsg = 'Invalid or inactive IN Location'
       goto error
       end
   -- validate Material
   select @validcnt = count(*)
   from inserted i
   join bINMT t on i.Co = t.INCo and i.MatlGroup = t.MatlGroup
   	and i.CompMatl = t.Material and i.CompLoc = t.Loc 
   where t.Active = 'Y'
   if @validcnt <> @numrows
   	begin
       select @errmsg = 'Invalid or inactive Material'
       goto error
       end
    
   -- Component Material can't be equal to finished good
   if exists(select 1 from inserted i
   			join bINPB b on b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq
     			and b.FinMatl = i.CompMatl and b.ProdLoc = i.CompLoc)
   	begin
       select @errmsg = 'Component material cannot be equal to finished good'
       goto error
       end
    
   --validate ECM, PECM
   if exists(select 1 from inserted where ECM not in ('E','C','M')
   			or PECM not in ('E','C','M'))
   	begin
    	select @errmsg = 'Invalid Unit Cost or Price ECM - must be E, C, or M '
    	goto error
       end
    
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert IN Production Detail [bINPD]'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINPDu] on [dbo].[bINPD] for UPDATE as
   

/*********************************************************************
    *	CREATED BY: GR 12/3/99
    *
    *	This trigger rejects update in bINPD
    *  if  the following error condition exists:
    *
    *  Check for change of location and material
    *	Invalid ECM or PECM
    *
    ********************************************************************/
   declare @errmsg varchar(255),
   	@numrows int,
   	@validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   --Check for changes
   if update(CompLoc)
   	begin
   	select @errmsg = 'Cannot change Component Location '
   	goto error
   	end
   
   if update(CompMatl)
       begin
   	select @errmsg = 'Cannot change Component Material'
   	goto error
   	end
   
   --validate ECM
   if update(ECM) or update(PECM)
   	begin
   	select @validcnt=count(*) from inserted i
       where i.ECM not in ('E', 'C', 'M') or i.PECM not in ('E', 'C', 'M')
   	if @validcnt <>0
   		begin
   		select @errmsg = 'Invalid ECM - must be E, C, or M '
   		goto error
   		end
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update IN Production Batch Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINPD] ON [dbo].[bINPD] ([Co], [Mth], [BatchId], [BatchSeq], [ProdSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINPD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINPD].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINPD].[PECM]'
GO
