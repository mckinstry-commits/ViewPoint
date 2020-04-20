CREATE TABLE [dbo].[bGLBR]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[FYEMO] [dbo].[bMonth] NOT NULL,
[BudgetCode] [dbo].[bBudgetCode] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[BeginBalance] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bGLBR_BeginBalance] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   
   /****** Object:  Trigger dbo.btGLBRi    Script Date: 8/28/99 9:37:28 AM ******/
 CREATE TRIGGER [dbo].[btGLBRi] on [dbo].[bGLBR] FOR INSERT AS
   
DECLARE @errmsg varchar(255)
   /*-----------------------------------------------------------------
    *   Created:  ??
    *   ReCreated:  JayR TK-16020.  The FK needed to be replaced with Triggers because the
    *                     logic needed to be more complex.  This trigger needed to be created to match.
    *               JayR 07/16/2012 Tk-16020 Change to use more closely match newer coding standards.
    *  
    *	This trigger rejects insertion in bGLBR (Budget Revisions) if  
    *	any of the following error conditions exist:
    *		
    *		Replaced with FK  -- Invalid Fiscal Year - bGLFY
    *		Replaced with FK -- Invalid Budget Code - bGLBC
    *		Invalid GL Account  - bGLAC
    *		
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* validate GL Account */
   IF EXISTS
		(
		SELECT 1
		FROM inserted i
		WHERE NOT EXISTS
			(
			SELECT 1
			FROM bGLAC a
			WHERE i.GLCo = a.GLCo 
			AND i.GLAcct = a.GLAcct
			)
		)
	BEGIN 
   		SELECT @errmsg = 'GL Account code invalid - cannot insert Budget Revision!'
		RAISERROR(@errmsg, 11, -1);
		ROLLBACK TRANSACTION
    END
    	
	RETURN  

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLBRu    Script Date: 8/28/99 9:37:29 AM ******/
   CREATE  trigger [dbo].[btGLBRu] on [dbo].[bGLBR] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bGLBR (Budget Revisions) if
    *	any of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change Fiscal Year Ending Month
    *		Cannot change Budget Code
    *		Cannot change GL Account
    *
    */----------------------------------------------------------------
   
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.FYEMO = i.FYEMO and
   	d.BudgetCode = i.BudgetCode and d.GLAcct = i.GLAcct
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change GL Company, Fiscal Year	Ending Month, Budget Code, or GL Account'
   	goto error
   	end
   		
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Budget Revision!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bGLBR] ADD CONSTRAINT [PK_bGLBR] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLBR] ON [dbo].[bGLBR] ([GLCo], [FYEMO], [BudgetCode], [GLAcct]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLBR] WITH NOCHECK ADD CONSTRAINT [FK_bGLBR_bGLBC_GLCoBudgetCode] FOREIGN KEY ([GLCo], [BudgetCode]) REFERENCES [dbo].[bGLBC] ([GLCo], [BudgetCode])
GO
ALTER TABLE [dbo].[bGLBR] WITH NOCHECK ADD CONSTRAINT [FK_bGLBR_bGLFY_GLCoFYEMO] FOREIGN KEY ([GLCo], [FYEMO]) REFERENCES [dbo].[bGLFY] ([GLCo], [FYEMO])
GO
