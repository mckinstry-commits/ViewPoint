CREATE TABLE [dbo].[bGLJR]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Rev] [dbo].[bYN] NOT NULL,
[RevJrnl] [dbo].[bJrnl] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biGLJR] ON [dbo].[bGLJR] ([GLCo], [Jrnl]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bGLJR] ADD CONSTRAINT [PK_bGLJR] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]

ALTER TABLE [dbo].[bGLJR] WITH NOCHECK ADD
CONSTRAINT [FK_bGLJR_bGLCO_GLCo] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bGLCO] ([GLCo])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLJRi    Script Date: 8/28/99 9:37:31 AM ******/
   CREATE  trigger [dbo].[btGLJRi] on [dbo].[bGLJR] for INSERT as
   
/************************************************************************
* CREATED:	
* MODIFIED:	AR 2/7/2011  - #143291 - adding foreign keys and check constraints, removing trigger look ups
*
* Purpose:	This trigger rejects insertion in bGLJR (Journal) if any 
*			of the following error conditions exist:
*   		
*		Invalid GL Company
*		Invalid Reversal Journal 
*		Reversal Journal must be null
*
*
* returns 1 and error msg if failed
*
*************************************************************************/
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt1 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* validate GL Company */
   --#143291 - replacing with a FK
   
   /* validate Reversal Journal */
   select @validcnt = count(*) from inserted i, bGLJR j where i.GLCo = j.GLCo and
   		i.RevJrnl = j.Jrnl and i.Rev = 'Y' and i.Jrnl <> i.RevJrnl
   select @validcnt1 = count(*) from inserted where (Rev = 'Y' and Jrnl = RevJrnl)
   		or (Rev = 'N' and RevJrnl is null)
   
   if @validcnt + @validcnt1 <> @numrows
   	begin
   	select @errmsg = 'Invalid Reversal Journal setup'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert Journal!'
      	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLJRu    Script Date: 8/28/99 9:38:22 AM ******/
   CREATE  trigger [dbo].[btGLJRu] on [dbo].[bGLJR] for UPDATE as
   

declare @errmsg varchar(255), @errno int, @glco bCompany, 
   	@jrnl bJrnl, @numrows int, @opencursor tinyint,
   	@rev bYN, @revjrnl bJrnl, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bGLJR (Journals) if any
    *	of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change Journal
    *		Must specify a Reversing Journal
    *		Reversal Journal must be null
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @opencursor = 0	/* initialize open cursor flag */
   
   /* check for key changes */ 
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.Jrnl = i.Jrnl
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change GL Company or Journal'
   	goto error
   	end
   
   if @numrows = 1
   	select @glco = i.GLCo, @jrnl = i.Jrnl, @rev = i.Rev, @revjrnl = i.RevJrnl
   		from inserted i
   else
   	begin
   	/* use a cursor to process each updated row */
   	declare bGLJR_update cursor for select GLCo, Jrnl, Rev, RevJrnl 
   		from inserted
   	open bGLJR_update
   	select @opencursor = 1	/* set open cursor flag */
   	fetch next from bGLJR_update into @glco, @jrnl, @rev, @revjrnl
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   update_check:
   	/* validate Reversal Journal */
   	if @rev = 'Y' and @revjrnl is null
   		begin 
   		select @errmsg = 'Must specify a Reversing Journal'
   		goto error
   		end
   	if @rev = 'Y' and @jrnl <> @revjrnl
   		begin
   		exec @errno = bspGLJrnlVal @glco, @revjrnl, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @rev = 'N' and @revjrnl is not null
   		begin
   		select @errmsg = 'Reversal Journal must be null'
   		goto error
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bGLJR_update into @glco, @jrnl, @rev, @revjrnl
   		if @@fetch_status = 0
   
   			goto update_check
   		else
   			begin
   			close bGLJR_update
   			deallocate bGLJR_update
   			end
   		end
   
   
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bGLJR_update
   		deallocate bGLJR_update
   		end
   
   	select @errmsg = @errmsg + ' - cannot update Journal!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLJR].[Rev]'
GO
