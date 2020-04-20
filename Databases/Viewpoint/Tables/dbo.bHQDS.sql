CREATE TABLE [dbo].[bHQDS]
(
[Seq] [int] NOT NULL,
[Status] [dbo].[bStatus] NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[YNBeginStatus] [dbo].[bYN] NOT NULL,
[YNComplete] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQDS_Status] ON [dbo].[bHQDS] ([Status]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biHQDS_Seq] ON [dbo].[bHQDS] ([Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btHQDSd] on [dbo].[bHQDS] for DELETE as
   

/****************************************************************
    * Created:  09/16/03 RBT - #21492 
    * Modified: 
    *
    * Delete trigger for HQ Document Routing Status table.
    *
    ****************************************************************/
   
   declare @errmsg varchar(255), @numrows int, @existingcount int, @newcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @existingcount = count(*) 
   from bHQDR a join deleted d
   on a.Status = d.Status
   
   select @existingcount = isnull(@existingcount,0)
   if @existingcount > 1
   	begin
   	select @errmsg = 'Status code in use'
   	goto error
   	end
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Document Review Status!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btHQDSi] on [dbo].[bHQDS] for INSERT as
   

/****************************************************************
    * Created:  09/16/03 RBT - #21492 
    * Modified: 
    *
    * Update trigger for HQ Document Routing Status table.
    *
    ****************************************************************/
   
   declare @errmsg varchar(255), @numrows int, @existingcount int, @newcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @existingcount = count(*) from bHQDS where YNBeginStatus = 'Y'
   select @newcount = count(*) from inserted where YNBeginStatus = 'Y'
   select @existingcount = isnull(@existingcount,0) + isnull(@newcount,0)
   if @existingcount > 2
   	begin
   	select @errmsg = 'Only one status may be set as beginning status'
   	goto error
   	end
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert HQ Document Review Status!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btHQDSu] on [dbo].[bHQDS] for UPDATE as
   

/****************************************************************
    * Created:  09/16/03 RBT - #21492 
    * Modified: 
    *
    * Update trigger for HQ Document Routing Status table.
    *
    ****************************************************************/
   
   declare @errmsg varchar(255), @numrows int, @existingcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @existingcount = count(*) from bHQDS where YNBeginStatus = 'Y'
   if @existingcount > 1
   	begin
   	select @errmsg = 'Only one status may be set as beginning status'
   	goto error
   	end
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HQ Document Review Status!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQDS].[YNBeginStatus]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQDS].[YNComplete]'
GO
