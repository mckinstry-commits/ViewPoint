CREATE TABLE [dbo].[bHQLT]
(
[LiabType] [dbo].[bLiabilityType] NOT NULL,
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
 
  
   
   
   CREATE  trigger [dbo].[btHQLTd] on [dbo].[bHQLT] for DELETE as
   

declare @errmsg varchar(255),@sep char(2)
   
   /*-----------------------------------------------------------------
    *	CREATED: 05/15/02 RM
    *
    *	This trigger rejects delete in bHQLT (HQ Liability Types)
    *	if the following error condition exists:
    *
    *		LiabType in use in EMPB,JCTL,  and PRDL
    *
    */----------------------------------------------------------------
   
   select @sep  = char(13) + char(10)
   
   if exists(select * from EMPB e join deleted d on e.LiabType = d.LiabType)
   begin
   	select @errmsg = isnull(@errmsg,'') + 'Liablity Type in use in EM Company Parameters' + @sep
   end
   
   if exists(select * from JCTL j join deleted d on j.LiabType = d.LiabType)
   begin
   	select @errmsg = isnull(@errmsg,'') + 'Liablity Type in use in JC Liability Template' + @sep
   end
   
   if exists(select * from PRDL p join deleted d on p.LiabType = d.LiabType)
   begin
   	select @errmsg = isnull(@errmsg,'') + 'Liablity Type in use in PR Deductions/Liablities' + @sep
   end
   
   
   if @errmsg is not null  goto error
   
   
   
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + 'Cannot delete HQ Liability Types!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQLTu    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE  trigger [dbo].[btHQLTu] on [dbo].[bHQLT] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQLT (HQ Liability Types)
    *	if the following error condition exists:
    *
    *		Cannot change HQ LiabType
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.LiabType = i.LiabType
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Liability Type'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Liability Types!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQLT] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQLT] ON [dbo].[bHQLT] ([LiabType]) ON [PRIMARY]
GO
