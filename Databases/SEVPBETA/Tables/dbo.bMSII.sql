CREATE TABLE [dbo].[bMSII]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[SoldToCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[InUseAPCo] [dbo].[bCompany] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPHBd    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE trigger [dbo].[btMSIId] on [dbo].[bMSII] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created :  GG 08/14/01
    *	Modified: 
    *
    *	Delete trigger for MS Intercompany Invoices 
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   --check for existing detail
   select @validcnt = count(*)
   from bMSIX x with (nolock)
   join deleted d on d.MSCo = x.MSCo and d.MSInv = x.MSInv
   if @validcnt > 0
   	begin
   	select @errmsg = 'Detail still exists'
   	goto error
   	end
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Intercompany Invoice Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSII] ON [dbo].[bMSII] ([MSCo], [MSInv]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
