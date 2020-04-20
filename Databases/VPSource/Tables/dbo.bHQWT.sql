CREATE TABLE [dbo].[bHQWT]
(
[TemplateType] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[WordTable] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWT_WordTable] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHQWT] ADD
CONSTRAINT [CK_bHQWT_WordTable] CHECK (([WordTable]='Y' OR [WordTable]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWTd] on [dbo].[bHQWT] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for HQWT
 * Created By:	GF 11/20/2001
 * Modified By:
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check HQWD for templates
if exists(select * from deleted d join bHQWD o ON d.TemplateType = o.TemplateType)
      begin
      select @errmsg = 'Document Templates exist that use this Template Type'
      goto error
      end


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Template Type from HQWT'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWTu] on [dbo].[bHQWT] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for HQWT
 * Created By:	GF 11/20/2001
 * Modified By:
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check HQWD for word document templates
if update(TemplateType)
	begin
   	if exists(select * from deleted d join bHQWD o ON d.TemplateType = o.TemplateType)
		begin
   		select @errmsg = 'Document Templates exist that use this Template Type'
   		goto error
   		end
	end



return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Template Type in HQWT'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
  
 





GO
CREATE UNIQUE CLUSTERED INDEX [biHQWT] ON [dbo].[bHQWT] ([TemplateType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQWT].[WordTable]'
GO
