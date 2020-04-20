CREATE TABLE [dbo].[bPRGG]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[GarnGroup] [dbo].[bGroup] NOT NULL,
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
 
  
   
   
   
   
/****** Object:  Trigger [dbo].[btPRGGd]    Script Date: 12/14/2007 11:23:18 ******/
    CREATE     trigger [dbo].[btPRGGd] on [dbo].[bPRGG] for DELETE as
     

/*-----------------------------------------------------------------
      *	Created by: EN 12/14/07
      *	Modified:	
      *
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int
     declare @prco integer, @employee integer
   
     select @numrows = @@rowcount
   
     if @numrows = 0 return
   
     if exists(select * from dbo.bPRDL e with (nolock) join deleted d on e.PRCo=d.PRCo and e.GarnGroup=d.GarnGroup)
     	begin
     	select @errmsg='Deduction(s) exist using this Garnishment Group'
     	goto error
     	end
     if exists(select * from dbo.bPREH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.CSGarnGroup=d.GarnGroup)
     	begin
     	select @errmsg='Employee(s) exist using this Garnishment Group for Garnishment Allocations'
     	goto error
     	end
   
   
     return
     error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Garnishment Group!'
         	RAISERROR(@errmsg, 11, -1);
         	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRGG] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRGG] ON [dbo].[bPRGG] ([PRCo], [GarnGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
