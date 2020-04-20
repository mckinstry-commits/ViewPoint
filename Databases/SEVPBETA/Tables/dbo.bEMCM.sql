CREATE TABLE [dbo].[bEMCM]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[JobFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PRClass] [dbo].[bClass] NULL,
[PRCo] [dbo].[bCompany] NULL,
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
   
CREATE   trigger [dbo].[btEMCMd] on [dbo].[bEMCM] for DELETE as

/***  basic declares for SQL Triggers ****/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
	@errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
/*--------------------------------------------------------------------------
 *
 *  Delete trigger for EMCM
 *  Created By: bc 04/06/99
 *  Modified by: TV 02/11/04 - 23061 added isnulls
 *		TJL 10/05/07 - Issue #123060, Prevent delete of Category if used in related tables
 *
 *
 *
 *--------------------------------------------------------------------------*/
   
/*** declare local variables ***/
   
declare @cnt int
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @cnt = count(*)
from EMEM e, deleted d
where e.EMCo = d.EMCo and e.Category = d.Category
if @cnt <> 0
	begin
	select @errmsg = 'Category exists on piece(s) of equipment in equipment master.'
	goto error
	end

if exists(select top 1 1 from deleted d join EMRR r on r.EMCo = d.EMCo and r.Category = d.Category)
	begin
	select @errmsg = 'Revenue Rate(s) exist for this category.'
	goto error
	end

if exists(select top 1 1 from deleted d join EMTC t on t.EMCo = d.EMCo and t.Category = d.Category)
	begin
	select @errmsg = 'Revenue Template(s) exist for this category.'
	goto error
	end

if exists(select top 1 1 from deleted d join EMUC c on c.EMCo = d.EMCo and c.Category = d.Category)
	begin
	select @errmsg = 'Auto use template(s) exist for this category.'
	goto error
	end

if exists(select top 1 1 from deleted d join EMRD rd on rd.EMCo = d.EMCo and rd.Category = d.Category)
	begin
	select @errmsg = 'Revenue detail transaction(s) exist for this category.'
	goto error
	end

return

error:
   select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMCM'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMCMi    Script Date: 8/28/99 9:37:15 AM ******/
   
    CREATE   trigger [dbo].[btEMCMi] on [dbo].[bEMCM] for insert as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  insert trigger for EMCM
     *  Created By: bc 04/06/99
     *  Modified by: TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
    declare @cnt int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   /* Validate EMCo */
   select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.EMCo = r.EMCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Company is Invalid '
      goto error
      end
   
   /* Job Flag */
   select @validcnt = count(*) from inserted i where i.JobFlag in ('Y','N')
    if @validcnt <> @numrows
      begin
      select @errmsg = 'Job flag is Invalid '
      goto error
      end
   
   /* Validate PRCo */
   select @validcnt = count(*) from bPRCO r JOIN inserted i ON i.PRCo = r.PRCo
   select @nullcnt = count(*) from inserted i where i.PRCo is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'PR Company from the EM Company table is Invalid '
      goto error
      end
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMCM'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMCMu    Script Date: 8/28/99 9:37:15 AM ******/
   
    CREATE  trigger [dbo].[btEMCMu] on [dbo].[bEMCM] for update as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  udpate trigger for EMCM
     *  Created By: bc 04/06/99
     *  Modified by: TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
    declare @cnt int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   if update(EMCo) or update(Category)
     begin
     select @errmsg = 'Key fields may not be changed '
     goto error
     end
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot udpate EMCM'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMCM] ON [dbo].[bEMCM] ([EMCo], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMCM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
