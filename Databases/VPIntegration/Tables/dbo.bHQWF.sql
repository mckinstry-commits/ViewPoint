CREATE TABLE [dbo].[bHQWF]
(
[TemplateName] [dbo].[bReportTitle] NOT NULL,
[Seq] [int] NOT NULL,
[DocObject] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[MergeFieldName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[MergeOrder] [smallint] NOT NULL,
[WordTableYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWF_WordTableYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[Format] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btHQWFi] on [dbo].[bHQWF] for INSERT as
/*--------------------------------------------------------------
 * Created By:	GF 03/01/2002
 * Modified By:	GF 01/26/2004 - issue #18841 allow multiple columns in @columnname check for '+'
 *
 *
 *
 *--------------------------------------------------------------*/
declare @rcode int, @opencursor tinyint, @errmsg varchar(255), @validcnt int, @numrows int,
   		@templatename bReportTitle, @docobject varchar(30), @columnname varchar(80),
   		@templatetype varchar(10), @objecttable varchar(30), @msg varchar(255),
   		@wordtableyn bYN, @hqwo_wordtable bYN, @mergefieldtype varchar(1),
   		@xusertype_name varchar(50)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @opencursor = 0

---- validate inserted HQWF records
if @numrows = 1
	begin
	---- if only one row inserted, no cursor is needed
   	select @templatename=TemplateName, @docobject=DocObject, @columnname=ColumnName, @wordtableyn=WordTableYN
	from inserted
	end
else
	begin
	---- use a cursor to process all inserted rows
	declare bHQWF_insert cursor for select TemplateName, DocObject, ColumnName, WordTableYN
	from inserted

	open bHQWF_insert
	select @opencursor = 1

	---- get 1st row inserted
	fetch next from bHQWF_insert into @templatename, @docobject, @columnname, @wordtableyn
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error '
		goto error
		end
	end


Validate_Process:
---- validate template name
select @templatetype=TemplateType from bHQWD where TemplateName=@templatename
if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid Template Name.'
   	goto error
   	end

---- validate document object
select @objecttable=ObjectTable, @hqwo_wordtable=WordTable
from bHQWO 
where TemplateType=@templatetype and DocObject=@docobject
if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid document object: ' + ISNULL(@docobject,'') + ' for template type: ' + isnull(@templatetype,'') + '.'
   	goto error
   	end

---- make sure that word table flags match up between HQWF and HQWO
if @wordtableyn <> @hqwo_wordtable
   	begin
   	select @errmsg = 'Invalid merge field. Word table flags must be the same between merge field and document object.'
   	goto error
   	end

select @mergefieldtype = 'R'
if @hqwo_wordtable = 'Y'
	begin
   	select @mergefieldtype = 'T'
	end

---- run stored proc to validate column name
exec @rcode = dbo.bspHQWFColumnNameVal @objecttable, @columnname, @mergefieldtype, null, null, @msg output
if @rcode <> 0 
   	begin
   	select @errmsg = @msg
   	goto error
   	end


---- get next row
if @numrows > 1
	begin
	fetch next from bHQWF_insert into @templatename, @docobject, @columnname, @wordtableyn
	if @@fetch_status = 0 
		begin
		goto Validate_Process
		end
   
	close bHQWF_insert
	deallocate bHQWF_insert
	select @opencursor = 0
	end


return


error:
   	if @opencursor = 1
   		begin
   		close bHQWF_insert
   		deallocate bHQWF_insert
   		end
   
       select @errmsg=@errmsg + ' - cannot insert into HQWF'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   trigger [dbo].[btHQWFu] on [dbo].[bHQWF] for UPDATE as
/*--------------------------------------------------------------
 * Created By:	GF 03/01/2002
 * Modified By:	GF 01/26/2004 - issue #18841 allow multiple columns in @columnname check for '+'
 *				DANF 09/14/2004 - Issue 19246 added new login
 *
 *
 *--------------------------------------------------------------*/
declare @dbname varchar(128), @rcode int, @opencursor tinyint, @errmsg varchar(255), 
   		@validcnt int, @numrows int, @templatename bReportTitle, @docobject varchar(30), 
   		@columnname varchar(80), @templatetype varchar(10), @objecttable varchar(30), 
   		@msg varchar(255), @wordtableyn bYN, @hqwo_wordtable bYN, @mergefieldtype varchar(1),
   		@xusertype_name varchar(50)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @opencursor = 0

---- validate inserted HQWF records
if @numrows = 1
	begin
	---- if only one row inserted, no cursor is needed
   	select @templatename=TemplateName, @docobject=DocObject, @columnname=ColumnName, @wordtableyn=WordTableYN
	from inserted
	end
else
	begin
	---- use a cursor to process all inserted rows
	declare bHQWF_insert cursor for select TemplateName, DocObject, ColumnName, WordTableYN
	from inserted

	open bHQWF_insert
	select @opencursor = 1

	---- get 1st row inserted
	fetch next from bHQWF_insert into @templatename, @docobject, @columnname, @wordtableyn
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error '
		goto error
		end
	end


Validate_Process:
---- validate template name
select @templatetype=TemplateType from bHQWD where TemplateName=@templatename
if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid Template Name.'
   	goto error
   	end

---- validate document object
select @objecttable=ObjectTable, @hqwo_wordtable=WordTable from bHQWO 
where TemplateType=@templatetype and DocObject=@docobject
if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid document object for template type: ' + isnull(@templatetype,'') + '.'
   	goto error
   	end

---- make sure that word table flags match up between HQWF and HQWO
if @wordtableyn <> @hqwo_wordtable
   	begin
   	select @errmsg = 'Invalid merge field. Word table flags must be the same between merge field and document object.'
   	goto error
   	end

select @mergefieldtype = 'R'
if @hqwo_wordtable = 'Y'
	begin
   	select @mergefieldtype = 'T'
	end

---- run stored proc to validate column name
exec @rcode = dbo.bspHQWFColumnNameVal @objecttable, @columnname, @mergefieldtype, null, null, @msg output
if @rcode <> 0 
   	begin
   	select @errmsg = @msg
   	goto error
   	end


if @numrows > 1
	begin
	fetch next from bHQWF_insert into @templatename, @docobject, @columnname, @wordtableyn
	if @@fetch_status = 0
		begin
		goto Validate_Process
		end

	close bHQWF_insert
	deallocate bHQWF_insert
	select @opencursor = 0
	end


return


error:
	if @opencursor = 1
		begin
   		close bHQWF_insert
   		deallocate bHQWF_insert
   		end
   
	select @errmsg=@errmsg + ' - cannot update HQWF.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
  
 






GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQWF] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQWF] ON [dbo].[bHQWF] ([TemplateName], [Seq]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWF].[WordTableYN]'
GO
