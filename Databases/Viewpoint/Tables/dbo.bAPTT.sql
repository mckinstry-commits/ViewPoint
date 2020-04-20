CREATE TABLE [dbo].[bAPTT]
(
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPTT] ON [dbo].[bAPTT] ([V1099Type]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPTT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPTTd    Script Date: 8/28/99 9:36:58 AM ******/
   CREATE  trigger [dbo].[btAPTTd] on [dbo].[bAPTT] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created : EN 11/2/98
    *	Modified : EN 11/2/98
    *			 MV 10/18/02 - 18878 quoted identifier cleanup
    *
    *	This trigger restricts deletion of any APTT records if 
    *	used in APFT.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   if exists(select * from bAPFT a, deleted d where a.V1099Type=d.V1099Type)
   	begin
   	select @errmsg='1099 total(s) exist for this type.'
   	goto error
   	end
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP 1099 type!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPTTu    Script Date: 8/28/99 9:36:58 AM ******/
   CREATE  trigger [dbo].[btAPTTu] on [dbo].[bAPTT] for UPDATE as
   

/*-----------------------------------------------------------------
    *	Created : 10/30/98 EN
    *	Modified : 10/30/98 EN
    *			MV 10/18/02 - 18878 quoted identifier
    *
    *	This trigger rejects primary key changes.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.V1099Type = i.V1099Type
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   
   			
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update AP 1099 type!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
