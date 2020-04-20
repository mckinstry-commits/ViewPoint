CREATE TABLE [dbo].[bPRCH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Holiday] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRCHi]
   ON [dbo].[bPRCH]
   FOR INSERT AS
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for PRCH
    *  Created By:  MV 04/29/01
    *  Modified by: EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* Validate PRCo and Craft */
   select @validcnt = count(*) from dbo.bPRCM m with (nolock) JOIN inserted i ON i.PRCo = m.PRCo and
   		i.Craft = m.Craft
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PRCompany or Craft is Invalid '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PRCH'
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRCHu]
   ON [dbo].[bPRCH]
   FOR UPDATE AS
   

/*--------------------------------------------------------------
    *
    *  Update trigger for PRCH
    *  Created By:  MV 04/29/01
    *  Modified by: EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* Validate PRCo and Craft */
   select @validcnt = count(*) from dbo.bPRCM m with (nolock) JOIN inserted i ON i.PRCo = m.PRCo and
   		i.Craft = m.Craft
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PRCompany or Craft is Invalid '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update PRCH'
      rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCH] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCH] ON [dbo].[bPRCH] ([PRCo], [Craft], [Holiday]) ON [PRIMARY]
GO
