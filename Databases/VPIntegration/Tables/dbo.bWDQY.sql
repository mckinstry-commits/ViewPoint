CREATE TABLE [dbo].[bWDQY]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Title] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SelectClause] [varchar] (8000) COLLATE Latin1_General_BIN NOT NULL,
[FromWhereClause] [varchar] (8000) COLLATE Latin1_General_BIN NOT NULL,
[Standard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bWDQY_Standard] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[IsEventQuery] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bWDQY_IsEventQuery] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE      trigger [dbo].[btWDQYd] on [dbo].[bWDQY] for delete as
   

/*--------------------------------------------------------------
   *
   *  Delete trigger for bWFQY - Notifier Queries - Cascade deletes records in bWDQP (Notifier Query Params) 
   *	and bWDQF (Notirier Query EMail Fields)
   *
   *  Created By:  JM 08/22/02
   *  Modified by: TV - 23061 added isnulls
   *			   CC - issue 125070 11/9/07, added check for query use in jobs
   *--------------------------------------------------------------*/
   /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255)--, @rcode int 
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
/* Check for use in WDJB */
--Begin code for 125070

if exists (select top 1 1 from deleted d join dbo.bWDJB w with (nolock) on w.QueryName = d.QueryName)
	begin
	select @errmsg = 'Query is being used on one or more jobs and cannot be deleted.'
	goto error
	end

   delete bWDQP from bWDQP p JOIN deleted d ON p.QueryName = d.QueryName where p.QueryName = d.QueryName
   delete bWDQF from bWDQF f JOIN deleted d ON f.QueryName = d.QueryName where f.QueryName = d.QueryName

--End code for 125070   

   /* Note that Job Params in bWDJP are cascade deleted in bWDJB delete trigger */
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bWFQY', 'QueryName: ' + d.QueryName, null, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d
   return
   error:
   select @errmsg = isnull(@errmsg,'')
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 
 
 
 
 
 
 
 
 CREATE                  trigger [dbo].[btWDQYi] on [dbo].[bWDQY] for insert as
  

/*--------------------------------------------------------------
  *
  *  Insert trigger for bWDQY - Notifier Queries
  *  Created By:    JM 08/22/02
  *  Modified by:   TV 10/25/05 30156 - Insert Trigger error saving queries with insert or delete column names
  *					TV 10/26/05 30157 - Selectclause Param too small
  *					DANF 10/27/2008 - Issue 129859 Correct psuode cursor to include next from and select clauses from WDQY
  *--------------------------------------------------------------*/
  
  /*  Basic declares for SQL Triggers */
  declare @numrows int, @errmsg varchar(255), @rcode int, @queryname varchar(150), 
  	@selectclause varchar(8000), @fromwhereclause varchar(8000)
  
  select @numrows = @@rowcount
  if @numrows = 0 return
  
  set nocount on
  
  /* Insert records in WDQF (EMailFields) from Select statement and WDQP (Query Params) from FromWhere clause*/
  /* Get the first record being inserted */
  select @queryname = min(QueryName) from inserted
  select @selectclause = SelectClause, @fromwhereclause = FromWhereClause from inserted where QueryName = @queryname
  	while @queryname is not null
  	begin
      if (charindex('update b',lower(@selectclause))<> 0 or charindex('delete b',lower(@selectclause))<> 0)
          begin 
          select @rcode = 1, @errmsg = 'Update or Delete statments are not allowed in Select clause- ' + @errmsg
  		goto error
          end
  	exec @rcode = bspVAWDNotifierInsertWDQF @queryname, @selectclause, @errmsg=@errmsg output
  	if @rcode <> 0
  		begin
  		select @rcode = 1, @errmsg = 'Error intializing Notifier Query EMail fields - ' + @errmsg
  		goto error
  		end
  	
  	/* Get the next record being updated */
  	select @queryname = min(QueryName) from inserted where QueryName > @queryname
	select @selectclause = SelectClause, @fromwhereclause = FromWhereClause from inserted where QueryName = @queryname
  	end
  
  /* Audit inserts */
  insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bWDQY','QueryName: ' + i.QueryName, null, 'A', null, null, null, getdate(), SUSER_SNAME()
  	from inserted i
  
  return
  error:
  select @errmsg = isnull(@errmsg,'') + ' - cannot insert into Notifier Queries - bWDQY'
  RAISERROR(@errmsg, 11, -1);
  rollback transaction
  
  
  
  
  
 
 
 
 
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 
 
 
 
 
 
 
 
 
 CREATE               trigger [dbo].[btWDQYu] on [dbo].[bWDQY] for update as
  

/*--------------------------------------------------------------
  * Created:  JM 08/22/02
  * Modified:  JM 09/17/02 - Removed auditing of selectclause because it produces SQL error
  *	that 'some data will be truncated' and terminates; due to the selectclause being longer than
  *	the OldValue or NewValue columns in HQMA
  *			TV - 23061 added isnulls
  * 		TV 10/25/05 30156 - Insert Trigger error saving queries with insert or delete column names
  *			TV 10/26/05 30157 - Selectclause Param too small
  *  Insert trigger for Notifier Queries
  *
  *--------------------------------------------------------------*/
  
  declare @numrows int, @errmsg varchar(255), @validcnt int, @rcode int, @queryname varchar(50), 
  	@selectclause varchar(8000), @fromwhereclause varchar(8000)
  
  select @numrows = @@rowcount
  if @numrows = 0 return
  
  set nocount on
  
  /* Prohibit changing key fields */
  if update(QueryName) 
  	begin
  	select @validcnt = count(*) from inserted i join deleted d ON d.QueryName = i.QueryName
  	if @validcnt <> @numrows
  		begin
  		select @errmsg = 'Primary key fields may not be changed'
  		goto error
  		end
  	end
  
  /* If necessary, regenerate Param values in bWDTF */
  if update(SelectClause)
  	begin
  	/* Get the first record being updated */
     	select @queryname = min(QueryName) from inserted
  	select @selectclause = SelectClause from inserted where QueryName = @queryname
     	while @queryname is not null
  		begin
          if (charindex('update b',lower(@selectclause))<> 0 or charindex('delete b',lower(@selectclause))<> 0)
              begin 
              select @rcode = 1, @errmsg = 'Update or Delete statments are not allowed in Select clause- ' + @errmsg
      		goto error
              end
  		exec @rcode = bspVAWDNotifierInsertWDQF @queryname, @selectclause, @errmsg=@errmsg output
  		if @rcode <> 0
  			begin
  			select @rcode = 1, @errmsg = 'Error intializing Notifier Query EMail fields - ' + @errmsg
  			goto error
  			end
  		/* Get the next record being updated */
  		select @queryname = min(QueryName) from inserted where QueryName > @queryname
  		end
  	end
  
  
  
  /* Audit inserts */
  if update(Description)
  	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bWDQY', 'QueryName: ' + i.QueryName, null, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
  	from inserted i, deleted d
  	where i.QueryName = d.QueryName and isnull(i.Description,0) <> isnull(d.Description,0)
  
  if update(Title)
  	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bWDQY', 'QueryName: ' + i.QueryName, null, 'C', 'Title', d.Title, i.Title, getdate(), SUSER_SNAME()
  	from inserted i, deleted d
  	where i.QueryName = d.QueryName and isnull(i.Title,0) <> isnull(d.Title,0)
  
  
  return
  
  error:
  	select @errmsg = isnull(@errmsg,'') + ' - cannot update Notifier Queries - bWDQY!'
      RAISERROR(@errmsg, 11, -1);
      if @rcode <> 0 
          begin
          rollback transaction
          end
  
  
  
  
  
 
 
 
 
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bWDQY] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biWDQY] ON [dbo].[bWDQY] ([QueryName]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDQY].[Standard]'
GO
