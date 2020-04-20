CREATE TABLE [dbo].[bHQIC]
(
[InsCode] [dbo].[bInsCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQICu    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE  trigger [dbo].[btHQICu] on [dbo].[bHQIC] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQIC (HQ Insurance Codes)
    *	if the following error condition exists:
    *
    *		Cannot change HQ Insurance Code
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.InsCode = i.InsCode
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Insurance Code'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Insurance Codes!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHQIC] ON [dbo].[bHQIC] ([InsCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQIC] ([KeyID]) ON [PRIMARY]
GO
