CREATE TABLE [dbo].[bHQCP]
(
[CompCode] [dbo].[bCompCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[CompType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Verify] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AllInvoiceYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQCP_AllInvoiceYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQCPd    Script Date: 8/28/99 9:37:33 AM ******/
   CREATE  trigger [dbo].[btHQCPd] on [dbo].[bHQCP] for DELETE as
   

/*----------------------------------------------------------
    * Modified by: kb 12/9/98
    *
    *	This trigger rejects delete in bHQCP (HQ Compliance Codes)
    *	if a deleted record is found in:
    *
    *		HQCX - Compliance Group Codes
    *
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check HQ Compliance Group Codes */
   if exists(select * from bHQCX g, deleted d where 
   	g.CompCode = d.CompCode)
   	begin
   	select @errmsg = 'Compliance Code exists as a member of a Compliance Group'
   	goto error
   	end
   
   if exists(select * from bAPVC g, deleted d where 
   	g.CompCode = d.CompCode)
   	begin
   	select @errmsg = 'Compliance Code is being used in AP Vendor Compliance'
   	goto error
   	end
   
   if exists(select * from bSLCT g, deleted d where 
   	g.CompCode = d.CompCode)
   	begin
   	select @errmsg = 'Compliance Code is being used in SL Compliance'
   	goto error
   	end
   	
   if exists(select * from bPOCT g, deleted d where 
   	g.CompCode = d.CompCode)
   	begin
   	select @errmsg = 'Compliance Code is being used in PO Compliance'
   	goto error
   	end
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Compliance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQCPu    Script Date: 8/28/99 9:37:33 AM ******/
   CREATE  trigger [dbo].[btHQCPu] on [dbo].[bHQCP] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQCP (HQ Compliance Codes) 
    *	if the following error condition exists:
    *
    *		Cannot change HQ Compliance Code
   
   	Modified: RM 06/14/01 Cannot change type if exists in AP Compliance, SL Compliance or PO Compliance
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   
   
   
   
   select @validcount = count(*) from deleted d, inserted i
   	where d.CompCode = i.CompCode
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Compliance Code'
   	goto error
   	end
   
   
   if update(CompType)
   begin
   	if exists(select * from bAPVC c join inserted i on c.CompCode = i.CompCode)
   	begin
   		select @errmsg = 'Compliance Code in use in AP Vendor Compliance'
   		goto error
   	end
   
   	if exists(select * from bSLCT t join inserted i on t.CompCode = i.CompCode)
   	begin
   		select @errmsg = 'Compliance Code in use in  SL Compliance'
   		goto error
   	end
   
   	if exists(select * from bPOCT t join inserted i on t.CompCode = i.CompCode)
   	begin
   		select @errmsg = 'Compliance Code in use in PO Compliance'
   		goto error
   	end
   end
   
   
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Compliance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHQCP] ON [dbo].[bHQCP] ([CompCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQCP] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQCP].[Verify]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQCP].[AllInvoiceYN]'
GO
