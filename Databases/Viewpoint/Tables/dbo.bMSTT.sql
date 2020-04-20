CREATE TABLE [dbo].[bMSTT]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSTT] ON [dbo].[bMSTT] ([MSCo], [TruckType]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSTT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSTTd] on [dbo].[bMSTT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/18/2000
    *  Modified By:
    *
    *	This trigger rejects delete in bMSTT (MS Truck Types) if
    *	the following error condition exists:
    *
    *	used in MSPR - MS Pay Rates
    *	used in MSHR - MS Haul Rates
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check MSPR
   if exists(select * from deleted d, bMSPR b where d.MSCo=b.MSCo and d.TruckType=b.TruckType)
      begin
      select @errmsg = 'Truck Type is used in MS Pay Code Rates'
      goto error
      end
   
   -- check MSHR
   if exists(select * from deleted d, bMSHR c where d.MSCo=c.MSCo and d.TruckType=c.TruckType)
   	begin
   	select @errmsg = 'Truck Type is used in MS Haul Code Rates'
   	goto error
   	end
   
   return
   
   
   error:
       select @errmsg = @errmsg + ' - cannot delete MS Truck Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSTTi] on [dbo].[bMSTT] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/18/2000
    *  Modified By:
    *
    *	This trigger rejects insertion in bMSTT (MS Truck Types)
    *	if the following error condition exists:
    *
    *		Invalid MS Company
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate MS Company
   select @validcnt = count(*) from inserted i join bMSCO c on c.MSCo = i.MSCo
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS company!'
      goto error
      end
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert MS Truck Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSTTu] on [dbo].[bMSTT] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/18/2000
    *  Modified By:
    *
    *	This trigger rejects update in bMSTT (MS Truck Types) if any
    *	of the following error conditions exist:
    *
    *      Cannot change MS Company
    *		Cannot change Truck Type
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for changes to MS Company
   if update(MSCo)
   	begin
   	select @errmsg = 'Cannot change MS Company'
   	goto error
   	end
   
   -- check for changes to Truck Type
   if update(TruckType)
   	begin
   	select @errmsg = 'Cannot change Truck Type'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update Truck Types!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
