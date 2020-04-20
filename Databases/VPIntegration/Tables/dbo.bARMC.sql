CREATE TABLE [dbo].[bARMC]
(
[CustGroup] [dbo].[bGroup] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Rate] [dbo].[bRate] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARMCd    Script Date: 8/28/99 9:37:02 AM ******/
   CREATE trigger [dbo].[btARMCd] on [dbo].[bARMC] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects delete in bARMC (AR Misc Dist Codes) if any of
    *	the following error condition exists:
    *
    *		ARBM entry exists
    *		ARMD entry exists
    *		ARCM entry exists 
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255) 
   
   if @@rowcount = 0 return 
   set nocount on
   
   /* check for corresponding entries in ARBM */
   if exists (select * from deleted d, bARBM g
   	where g.CustGroup = d.CustGroup and g.MiscDistCode = d.MiscDistCode)
   	begin
   	select @errmsg = 'Entries exist in AR Misc Distributions Batch'
   	goto error
   	end
   
   /* check for corresponding entries in ARMD */
   if exists (select * from deleted d, bARMD g
   	where g.CustGroup = d.CustGroup and g.MiscDistCode = d.MiscDistCode)
   	begin
   	select @errmsg = 'Entries exist in Misc Distributions'
   	goto error
   	end
   
   /* check for corresponding entries in ARCM */
   if exists (select * from deleted d, bARCM g
   	where g.CustGroup = d.CustGroup and g.MiscDistCode = d.MiscDistCode)
   	begin
   	select @errmsg = 'Entries exist in AR Customer Master'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg +  ' - unable to delete AR Misc Distribution Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARMCi    Script Date: 8/28/99 9:37:02 AM ******/
   CREATE trigger [dbo].[btARMCi] on [dbo].[bARMC] for INSERT as
   

/*-----------------------------------------------------------------
    *	This trigger rejects insertion in bARMC (AR Misc Dist Codes)
    *	if any of the following error conditions exist:
    *
    *		CustGroup doesn't exist in HQGP
    *
    */----------------------------------------------------------------
   
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* validate CustGroup */
   select @validcnt = count(*) from bHQGP g, inserted i
   	where g.Grp = i.CustGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Customer Group'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert AR Misc Distribution Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARMCu    Script Date: 8/28/99 9:37:02 AM ******/
   CREATE trigger [dbo].[btARMCu] on [dbo].[bARMC] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bARMC (AR Misc Distribution Codes) if the 
    *	following error condition exists:
    *
    *		Cannot change CustGroup
    *		Cannot change MiscDistCode
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* reject key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.CustGroup = i.CustGroup and d.MiscDistCode = i.MiscDistCode
   if @numrows <> @validcnt
   	begin
   
   	select @errmsg = 'Cannot change Customer Group or Misc Distribution Code'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update AR Misc Distribution Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biARMC] ON [dbo].[bARMC] ([CustGroup], [MiscDistCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARMC] ([KeyID]) ON [PRIMARY]
GO
