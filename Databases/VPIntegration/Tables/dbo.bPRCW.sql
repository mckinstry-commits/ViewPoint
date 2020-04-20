CREATE TABLE [dbo].[bPRCW]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[Employee] [dbo].[bEmployee] NULL,
[UseStdHrs] [dbo].[bYN] NOT NULL,
[AddOnHrs] [dbo].[bHrs] NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[UsagePct] [dbo].[bPct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCWi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE   trigger [dbo].[btPRCWi] on [dbo].[bPRCW] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 4/28/03
    *		Modified:	EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Validates PR Company, Crew, and Sequence #.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate PR Company */
   select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
   
   /* validate Crew */
   select @validcnt = count(*) from dbo.bPRCR c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Crew = i.Crew
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Crew '
   	goto error
   	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Crew Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRCWu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE    trigger [dbo].[btPRCWu] on [dbo].[bPRCW] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/28/03
    *	Modified:	EN 02/11/03 - issue 23061  added isnull check
    *
    * Cannot change primary key.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change PR Company '
        	goto error
        	end
       end
   if update(Crew)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Crew '
        	goto error
        	end
       end
   if update(Seq)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.Seq = i.Seq
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Sequence # '
        	goto error
        	end
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Crew Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCW] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCW] ON [dbo].[bPRCW] ([PRCo], [Crew], [Seq]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCW].[UseStdHrs]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCW].[AddOnHrs]'
GO
