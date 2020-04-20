CREATE TABLE [dbo].[bHQWD]
(
[TemplateName] [dbo].[bReportTitle] NOT NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TemplateType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[FileName] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_Active] DEFAULT ('Y'),
[UsedLast] [smalldatetime] NULL,
[UsedBy] [dbo].[bVPUserName] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[WordTable] [tinyint] NOT NULL CONSTRAINT [DF_bHQWD_WordTable] DEFAULT ((0)),
[SuppressZeros] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_SuppressZeros] DEFAULT ('N'),
[SuppressNotes] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_SuppressNotes] DEFAULT ('Y'),
[StdObject] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_StdObject] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CreateFileType] [varchar] (4) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bHQWD_CreateFileType] DEFAULT ('doc'),
[AutoResponse] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_AutoResponse] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWDd] on [dbo].[bHQWD] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for HQWD
 * Created By:	GF 11/20/2001
 * Modified By:	DANF 09/14/2004 - Issue 19246 added new login
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- delete bHQWF merge fields for template
delete bHQWF from deleted d join bHQWF o on o.TemplateName=d.TemplateName
if exists(select d.TemplateName from deleted d join bHQWF o ON d.TemplateName = o.TemplateName)
	begin
	select @errmsg = 'Merge Fields exist in HQWF Template Merge Fields'
	goto error
	end


return


error:
	select @errmsg = @errmsg + ' - cannot delete Template from HQWD'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWDi] on [dbo].[bHQWD] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for HQWD
 * Created By:	GF 11/20/2001
 * Modified By:
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, 
		@validcnt1 int, @validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- validate Template Name
select @nullcnt = count(*) from inserted where isnull(TemplateName,'') = ''
if @nullcnt <> 0
	begin
	select @errmsg = 'A template name may not be empty'
	goto error
   	end

---- validate Template Location
select @validcnt = count(*) from inserted i join bHQWL r on i.Location=r.Location
select @validcnt1 = count(*) from inserted i where i.Location = 'PMStandard'
----select @validcnt2 = count(*) from inserted i where i.Location = 'PMCustom'
if @validcnt + @validcnt1 + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Invalid Location'
	goto error
   	end

------ validate Template Type
--select @validcnt = count(*) from inserted i join bPMCT r on i.TemplateType=r.DocCat
--if @validcnt <>@numrows
--	begin
--	select @errmsg = 'Invalid Template Type'
--	goto error
--   	end

---- validate FileName
select @validcnt = count(*) from inserted where UPPER(FileName) not like '%.DOT' and UPPER(FileName) not like '%.DOTX'
if @validcnt <> 0
   	begin
   	select @errmsg = 'All Document Template File names must end in .dot or dotx'
   	goto error
   	end



return



error:
	select @errmsg=@errmsg + ' - cannot insert Document Template into HQWD'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWDu] on [dbo].[bHQWD] for UPDATE as

/*--------------------------------------------------------------
 * Update trigger for HQWD
 * Created By:	GF 11/20/2001
 * Modified By:	DANF 09/14/2004 - Issue 19246 added new login
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int,
		@validcnt1 int, @validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- validate TemplateName - Key Value
if Update(TemplateName)
       begin
       select @errmsg = 'Cannot change Template Name'
       goto error
       end

---- validate Word Template Location
if update(Location)
	begin
   	select @validcnt = count(*) from inserted i join bHQWL r on i.Location=r.Location
	select @validcnt1 = count(*) from inserted i where i.Location = 'PMStandard'
----	select @validcnt2 = count(*) from inserted i where i.Location = 'PMCustom'
	if @validcnt + @validcnt1 + @validcnt2 <> @numrows
       	begin
       	select @errmsg = 'Invalid Location'
       	goto error
   		end
	end

---- validate TemplateType
if update(TemplateType)
	begin
   	--select @validcnt = count(*) from inserted i join bPMCT r on i.TemplateType=r.DocCat
   	--if @validcnt <>@numrows
    --   	begin
    --   	select @errmsg = 'Invalid Template Type'
    --   	goto error
   	--	end

	---- no change if merge fields exist
   	if exists(select f.Seq from bHQWF f join inserted i on f.TemplateName=i.TemplateName)
   		begin
   		select @errmsg = 'Cannot change Template Type when Template Merge Fields exist'
   		goto error
   		end
	end

---- validate FileName
if update(FileName)
	begin
   	select @nullcnt = count(*) from inserted where isnull(FileName,'') = ''
   	if @nullcnt <>0
   		begin
   		select @errmsg = 'Template File Name may not be empty'
   		goto error
   		end

	---- validate file name extension
   	select @validcnt = count(*) from inserted
   	where UPPER(FileName) not like '%.DOT' and UPPER(FileName) not like '%.DOTX'
   	if @validcnt <>0
   		begin
   		select @errmsg = 'All Templates must end in .dot or .dotx'
   		goto error
   		end
	end




return


error:
	select @errmsg=@errmsg + ' - cannot update Template - HQWD'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 








GO
ALTER TABLE [dbo].[bHQWD] ADD CONSTRAINT [CK_bHQWD_CreateFileType] CHECK (([CreateFileType]='pdf' OR [CreateFileType]='docx' OR [CreateFileType]='doc'))
GO
ALTER TABLE [dbo].[bHQWD] ADD CONSTRAINT [PK_bHQWD] PRIMARY KEY CLUSTERED  ([TemplateName]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQWD] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWD].[Active]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWD].[SuppressZeros]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWD].[SuppressNotes]'
GO
