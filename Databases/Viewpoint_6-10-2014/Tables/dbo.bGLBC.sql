CREATE TABLE [dbo].[bGLBC]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[BudgetCode] [dbo].[bBudgetCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLBCu    Script Date: 8/28/99 9:37:28 AM ******/
   CREATE  trigger [dbo].[btGLBCu] on [dbo].[bGLBC] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bGLBC (Budget Codes) if any
    *	of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change Budget Code
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.BudgetCode = i.BudgetCode
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change GL Company or Budget Code'
   	goto error
   	end
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update Budget Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bGLBC] ADD CONSTRAINT [PK_bGLBC] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLBC] ON [dbo].[bGLBC] ([GLCo], [BudgetCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLBC] WITH NOCHECK ADD CONSTRAINT [FK_bGLBC_bGLCO_GLCo] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bGLCO] ([GLCo])
GO
ALTER TABLE [dbo].[bGLBC] NOCHECK CONSTRAINT [FK_bGLBC_bGLCO_GLCo]
GO
