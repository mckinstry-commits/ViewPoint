CREATE TABLE [dbo].[bGLIA]
(
[ARGLCo] [dbo].[bCompany] NOT NULL,
[APGLCo] [dbo].[bCompany] NOT NULL,
[ARGLAcct] [dbo].[bGLAcct] NOT NULL,
[APGLAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLIAu    Script Date: 8/28/99 9:37:30 AM ******/
   CREATE  trigger [dbo].[btGLIAu] on [dbo].[bGLIA] for UPDATE as
/************************************************************************
* CREATED:	
* MODIFIED: AR -#142311 - replacing trigger code with a check constraints
*
* Purpose:	  This trigger rejects update in bGLIA (Intercompany Accts) if
*				any of the following error conditions exist:
*
*	Cannot change AR/GL Company
*	Cannot change AP/GL Company

* returns 1 and error msg if failed
*
*************************************************************************/   

declare @apglco bCompany, @arglco bCompany, @errmsg varchar(255),
   	@errno int, @newapglacct bGLAcct, @newapglco bCompany,
   	@newarglacct bGLAcct, @newarglco bCompany, @numrows int,
   	@oldapglacct bGLAcct, @oldarglacct bGLAcct, @oldapglco bCompany,
   	@oldarglco bCompany, @opencursor tinyint, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bGLIA (Intercompany Accts) if
    *	any of the following error conditions exist:
    *
    *		Cannot change AR/GL Company
    *		Cannot change AP/GL Company
    *		Invalid AR GL Account
    *		Invalid AP GL Account
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @opencursor = 0	/* initialize open cursor flag */
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.ARGLCo = i.ARGLCo and d.APGLCo = i.APGLCo
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change AR/GL Company or AP/GL Company'
   	goto error
   	end
      --#142311 - replacing with a check constraints
    /*
   if @numrows = 1
   	select @arglco = i.ARGLCo, @apglco = i.APGLCo, @oldarglacct = d.ARGLAcct,
   		@newarglacct = i.ARGLAcct, @oldapglacct = d.APGLAcct, @newapglacct = i.APGLAcct
   		from deleted d, inserted i
   		where d.ARGLCo = i.ARGLCo and d.APGLCo = i.APGLCo
   else
   	begin
   	/* use a cursor to process each update row */
   	declare bGLIA_update cursor for select i.ARGLCo, i.APGLCo, OldARGLAcct = d.ARGLAcct, 
   		NewARGLAcct = i.ARGLAcct, OldAPGLAcct = d.APGLAcct, NewAPGLAcct = i.APGLAcct
   		from deleted d, inserted i
   		where d.ARGLCo = i.ARGLCo and d.APGLCo = i.APGLCo
   	open bGLIA_update
   	select @opencursor = 1	/* set open cursor flag */
   	fetch next from bGLIA_update into @arglco, @apglco, @oldarglacct, @newarglacct, @oldapglacct,@newapglacct
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   update_check:
 
   	/* validate AR GL Account */
   	if @oldarglacct <> @newarglacct
   		begin
   		exec @errno = bspGLAcctVal @arglco, @newarglacct, @errmsg output
   		if @errno <> 0 goto error
   		end
   		
   	/* validate AP GL Account */
   	if @oldapglacct <> @newapglacct
   		begin
   		exec @errno = bspGLAcctVal @apglco, @newapglacct, @errmsg output
   		if @errno <> 0 goto error
   		end
	 
   	if @numrows > 1
   		begin
   		fetch next from bGLIA_update into @arglco, @apglco, @oldarglacct, @newarglacct, @oldapglacct, @newapglacct
   		if @@fetch_status = 0
   			goto update_check
   		else
   			begin
   			close bGLIA_update
   			deallocate bGLIA_update
   			end
   		end
	   */
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bGLIA_update
   		deallocate bGLIA_update
   		end
   
   	select @errmsg = @errmsg + ' - cannot update InterCo GL Accounts!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bGLIA] ADD CONSTRAINT [CK_bGLIA_APGLCoNot0] CHECK (([APGLCo]>(0)))
GO
ALTER TABLE [dbo].[bGLIA] ADD CONSTRAINT [CK_bGLIA_ARGLCoNEQAPGLCo] CHECK (([ARGLCo]<>[APGLCo]))
GO
ALTER TABLE [dbo].[bGLIA] ADD CONSTRAINT [CK_bGLIA_ARGLCoNot0] CHECK (([ARGLCo]>(0)))
GO
ALTER TABLE [dbo].[bGLIA] ADD CONSTRAINT [PK_bGLIA] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLIA] ON [dbo].[bGLIA] ([ARGLCo], [APGLCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLIA] WITH NOCHECK ADD CONSTRAINT [FK_bGLIA_bGLAC_APGLCo] FOREIGN KEY ([APGLCo], [APGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
ALTER TABLE [dbo].[bGLIA] WITH NOCHECK ADD CONSTRAINT [FK_bGLIA_bGLAC_ARGLCo] FOREIGN KEY ([ARGLCo], [ARGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
