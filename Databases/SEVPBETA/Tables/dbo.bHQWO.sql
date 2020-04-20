CREATE TABLE [dbo].[bHQWO]
(
[TemplateType] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[DocObject] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LinkedDocObject] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ObjectTable] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Required] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWO_Required] DEFAULT ('N'),
[JoinOrder] [tinyint] NOT NULL,
[Alias] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[JoinClause] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[WordTable] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWO_WordTable] DEFAULT ('N'),
[StdObject] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWO_StdObject] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btHQWOd] on [dbo].[bHQWO] for DELETE as
/*--------------------------------------------------------------
 *  Delete trigger for HQWO
 *  Created By:     GF 12/20/2001
 *  Modified By:	DANF 09/14/2004 - Issue 19246 added new login
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-------- check if Document object is a linked document object
----if exists(select * from deleted d join bHQWO o ON d.TemplateType=o.TemplateType and d.DocObject = o.LinkedDocObject)
----   	begin
----   	select @errmsg = 'Template Object is linked to another Document Object'
----   	goto error
----   	end

-------- check if document object is referenced HQWF - template merge fields
----if exists(select * from deleted d join bHQWF f ON d.TemplateType=o.TemplateType and d.DocObject = f.DocObject)
----   	begin
----   	select @errmsg = 'Template Object is used in Template Merge Fields'
----   	goto error
----   	end


return


error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete Template Object from HQWO'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWOi] on [dbo].[bHQWO] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for HQWO
 *  Created By:		GF 11/20/2001
 *  Modified By:	GF 01/20/2004 - issue #18841 - added WordTable flag to table
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- verify document object, object table, and alias are not empty
select @validcnt2 = count(*) from inserted where isnull(DocObject,'') = ''
if @validcnt2 <> 0
	begin
	select @errmsg = 'Document object may not be empty'
	goto error
   	end
select @validcnt2 = count(*) from inserted where isnull(ObjectTable,'') = ''
if @validcnt2 <> 0
	begin
	select @errmsg = 'Object Table Name may not be empty'
	goto error
   	end
select @validcnt2 = count(*) from inserted where isnull(Alias,'') = ''
if @validcnt2 <> 0
	begin
	select @errmsg = 'Alias may not be empty'
	goto error
   	end
select @validcnt2 = count(*) from inserted i where JoinOrder is null
if @validcnt2 <> 0
	begin
	select @errmsg = 'Join order may not be empty'
	goto error
   	end

---- validate TemplateType
--select @validcnt = count(*) from inserted i join bPMCT r on i.TemplateType=r.DocCat
--if @validcnt <>@numrows
--	begin
--	select @errmsg = 'Invalid Template Type'
--	goto error
--   	end

---- validate linked document object
select @validcnt = count(*) from inserted i join bHQWO r on i.TemplateType=r.TemplateType and i.LinkedDocObject=r.DocObject
select @validcnt2 = count(*) from inserted where isnull(LinkedDocObject,'') = ''
if @validcnt + @validcnt2 <> @numrows
	begin
   	select @errmsg = 'Invalid linked document object'
   	goto error
   	end

---- validate object table
select @validcnt = count(*) from inserted i join INFORMATION_SCHEMA.TABLES t on i.ObjectTable = t.TABLE_NAME
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid object table name'
   	goto error
   	end

---- validate alias
select @validcnt = count(*) from inserted i where not exists(select a.DocObject
				from bHQWO a where a.TemplateType=i.TemplateType and a.Alias=i.Alias 
				and a.WordTable=i.WordTable and a.DocObject<>i.DocObject)
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid alias, used in another Document Object'
   	goto error
   	end

---- validate join order
select @validcnt = count(*) from inserted i where not exists(select a.JoinOrder
				from bHQWO a where a.TemplateType=i.TemplateType and a.JoinOrder=i.JoinOrder 
				and a.WordTable=i.WordTable and a.DocObject<>i.DocObject)
if @validcnt <> @numrows
	begin
   	select @errmsg = 'Invalid join order, used in another Document Object'
   	goto error
   	end



return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Template Object into HQWO'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btHQWOu] on [dbo].[bHQWO] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for HQW0
 * Created By:	GF 12/20/2001
 * Modified By:	GF 01/20/2004 - issue #18841 - added WordTable flag to table
 * Modified By:	DANF 09/14/2004 - Issue 19246 added new login
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- validate key columns
if Update(TemplateType)
	begin
	select @errmsg = 'Cannot change Template Type'
	goto error
	end

if update(DocObject)
   	begin
   	select @errmsg = 'Cannot change Document Object'
   	goto error
   	end

---- validate linked document object
if update(LinkedDocObject)
	begin
   	select @validcnt = count(*) from inserted i join bHQWO r on i.TemplateType=r.TemplateType and i.LinkedDocObject=r.DocObject
   	select @validcnt2 = count(*) from inserted where isnull(LinkedDocObject,'') = ''
   	if @validcnt + @validcnt2 <> @numrows
		begin
   		select @errmsg = 'Invalid linked document object'
   		goto error
   		end
	end

---- validate object table
if update(ObjectTable)
	begin
   	select @validcnt2 = count(*) from inserted where isnull(ObjectTable,'') = ''
   	if @validcnt2 <> 0
		begin
		select @errmsg = 'Object Table Name may not be empty'
		goto error
   		end

	select @validcnt = count(*) from inserted i join INFORMATION_SCHEMA.TABLES t on i.ObjectTable = t.TABLE_NAME
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid object table name'
		goto error
		end
	end

---- validate alias
if update(Alias)
	begin
   	select @validcnt2 = count(*) from inserted where isnull(Alias,'') = ''
   	if @validcnt2 <> 0
       	begin
       	select @errmsg = 'Alias may not be empty'
       	goto error
   		end

	select @validcnt = count(*) from inserted i where not exists(select a.DocObject
					from bHQWO a where a.TemplateType=i.TemplateType and a.Alias=i.Alias
					and a.WordTable=i.WordTable and a.DocObject<>i.DocObject)
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid alias, used in another Document Object'
   		goto error
   		end
	end

---- validate join order
if update(JoinOrder)
	begin
   	select @validcnt2 = count(*) from inserted i where JoinOrder is null
   	if @validcnt2 <>0
       	begin
       	select @errmsg = 'Join order may not be empty'
       	goto error
   		end
   
   	select @validcnt = count(*) from inserted i where not exists(select a.JoinOrder
					from bHQWO a where a.TemplateType=i.TemplateType and a.JoinOrder=i.JoinOrder
					and a.WordTable=i.WordTable and a.DocObject<>i.DocObject)
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid join order, used in another Document Object'
   		goto error
   		end
	end



return


error:
       select @errmsg=@errmsg + ' - cannot update Template Object - HQWO.'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 






GO
ALTER TABLE [dbo].[bHQWO] ADD CONSTRAINT [PK_bHQWO] PRIMARY KEY CLUSTERED  ([TemplateType], [DocObject]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQWO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWO].[Required]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWO].[WordTable]'
GO
