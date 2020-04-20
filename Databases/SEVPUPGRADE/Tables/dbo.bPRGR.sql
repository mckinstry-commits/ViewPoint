CREATE TABLE [dbo].[bPRGR]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PayFreq] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachGLLedgerRpts] [dbo].[bYN] NOT NULL CONSTRAINT [DF__bPRGR__AttachGLL__56D2742E] DEFAULT ('N'),
[AttachTypeID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   trigger [dbo].[btPRGRd] on [dbo].[bPRGR] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: GG 06/19/01
    *  Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Delete trigger on PR Groups (bPRGR)
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check for Group Leave Codes
   select @validcnt = count(*)
   from dbo.bPRGV v with (nolock)
   join deleted d on v.PRCo = d.PRCo and v.PRGroup = d.PRGroup
   if @validcnt <> 0
    	begin
   	select @errmsg = 'Group Leave codes exist'
   	goto error
   	end
   -- check for Group Benefits
   select @validcnt = count(*)
   from dbo.bPRGB b with (nolock)
   join deleted d on b.PRCo = d.PRCo and b.PRGroup = d.PRGroup
   if @validcnt <> 0
    	begin
   	select @errmsg = 'Group Benefits exist'
   	goto error
   	end
   -- check for Group Security
   select @validcnt = count(*)
   from dbo.bPRGS s with (nolock)
   join deleted d on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup
   if @validcnt <> 0
    	begin
   	select @errmsg = 'Group Security entries exist'
   	goto error
   	end
   -- check for Pay Period Control
   select @validcnt = count(*)
   from dbo.bPRPC p with (nolock)
   join deleted d on p.PRCo = d.PRCo and p.PRGroup = d.PRGroup
   if @validcnt <> 0
    	begin
   	select @errmsg = 'Pay Period Control entries exist'
   	goto error
   	end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Group!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE    trigger [dbo].[btPRGRi] on [dbo].[bPRGR] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: GG 06/19/01
    *  Modified:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Insert trigger for PR Groups (bPRGR)
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate PR Company
   select @validcnt = count(*) from dbo.bPRCO c with (nolock) join inserted i on c.PRCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid PR Company# '
   	goto error
   	end
   
   -- validate Pay Frequency
   select @validcnt = count(*) from inserted where PayFreq in ('W','B','S','M')
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid payment frequency.  Must be ''W'',''B'',''S'', or ''M'''
       goto error
       end
   
   -- validate GL Co# - must match GL Co# assigned in bPRCO
   select @validcnt = count(*)
   from inserted i join dbo.bPRCO c with (nolock) on i.PRCo = c.PRCo
   where i.GLCo = c.GLCo
   if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Co# must match one assigned in PR Company'
       goto error
       end
   select @validcnt = count(*)
   from inserted i join dbo.bGLCO c with (nolock) on i.GLCo = c.GLCo
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid GL Co#'
       goto error
       end
   
   -- validate GL Account
   select @validcnt = count(*)
   from inserted i
   join dbo.bGLAC c with (nolock) on i.GLCo = c.GLCo and i.GLAcct = c.GLAcct
   where c.AcctType not in ('H','M') and c.SubType is null and c.Active = 'Y'
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid GL Account'
       goto error
       end
   
   
   -- validate CM Co# - must match CM Co# assigned in bPRCO
   
   /*Issue 16037
   select @validcnt = count(*)
   from inserted i join bPRCO c on i.PRCo = c.PRCo
   where i.CMCo = c.CMCo
   if @validcnt <> @numrows
       begin
       select @errmsg = 'CM Co# must match one assigned in PR Company'
       goto error
       end
   */
   select @validcnt = count(*)
   from inserted i join dbo.bCMCO c with (nolock) on i.CMCo = c.CMCo
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid CM Co#'
       goto error
       end
   
   -- validate CM Account
   select @validcnt = count(*)
   from inserted i
   join dbo.bCMAC c with (nolock) on i.CMCo = c.CMCo and i.CMAcct = c.CMAcct
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid CM Account'
       goto error
       end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Group!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE      trigger [dbo].[btPRGRu] on [dbo].[bPRGR] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: GG 06/19/01
    * Modified:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *
    *	Update trigger on bPRGR (PR Groups)
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*) from deleted d join inserted i
   on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change PR Company or PR Group'
    	goto error
    	end
   
   if update(PayFreq)
       begin
       -- validate Pay Frequency
       select @validcnt = count(*) from inserted where PayFreq in ('W','B','S','M')
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid payment frequency.  Must be ''W'',''B'',''S'', or ''M'''
           goto error
           end
       end
   
   if update(GLCo)
       begin
       -- validate GL Co# - must match GL Co# assigned in bPRCO
       select @validcnt = count(*)
       from inserted i join dbo.bPRCO c with (nolock) on i.PRCo = c.PRCo
       where i.GLCo = c.GLCo
       if @validcnt <> @numrows
           begin
           select @errmsg = 'GL Co# must match one assigned in PR Company'
           goto error
           end
       select @validcnt = count(*)
       from inserted i join dbo.bGLCO c with (nolock) on i.GLCo = c.GLCo
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid GL Co#'
           goto error
           end
       end
   
   if update(GLCo) or update(GLAcct)
       begin
       -- validate GL Account
       select @validcnt = count(*)
       from inserted i
       join dbo.bGLAC c with (nolock) on i.GLCo = c.GLCo and i.GLAcct = c.GLAcct
       where c.AcctType not in ('H','M') and c.SubType is null and c.Active = 'Y'
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid GL Account'
           goto error
           end
       end
   
   if update(CMCo)
       begin
       -- validate CM Co# - must match CM Co# assigned in bPRCO
   /*Issue 16037
       select @validcnt = count(*)
       from inserted i join bPRCO c on i.PRCo = c.PRCo
       where i.CMCo = c.CMCo
       if @validcnt <> @numrows
           begin
           select @errmsg = 'CM Co# must match one assigned in PR Company'
           goto error
           end
   */
       select @validcnt = count(*)
       from inserted i join dbo.bCMCO c with (nolock) on i.CMCo = c.CMCo
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid CM Co#'
           goto error
           end
       end
   
   if update(CMCo) or update(CMAcct)
       begin
       -- validate CM Account
   /*Issue 16037 - comment: The CM Company is indirectly validated
   			when the CM Account is validated here.*/
       select @validcnt = count(*)
       from inserted i
       join dbo.bCMAC c with (nolock) on i.CMCo = c.CMCo and i.CMAcct = c.CMAcct
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid CM Account'
           goto error
           end
       end
   
   return
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Group!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRGR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRGR] ON [dbo].[bPRGR] ([PRCo], [PRGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bPRGR].[CMAcct]'
GO
