CREATE TABLE [dbo].[vDDFHc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[FormType] [tinyint] NULL,
[ShowOnMenu] [dbo].[bYN] NULL,
[IconKey] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ViewName] [varchar] (257) COLLATE Latin1_General_BIN NULL,
[JoinClause] [varchar] (6000) COLLATE Latin1_General_BIN NULL,
[WhereClause] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[AssemblyName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FormClassName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ProgressClip] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[FormNumber] [smallint] NULL,
[NotesTab] [tinyint] NULL,
[LoadProc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LoadParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[PostedTable] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AllowAttachments] [dbo].[bYN] NULL,
[Version] [tinyint] NULL,
[Mod] [char] (2) COLLATE Latin1_General_BIN NULL,
[CoColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OrderByClause] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[DefaultTabPage] [tinyint] NULL,
[SecurityForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DetailFormSecurity] [dbo].[bYN] NULL,
[DefaultAttachmentTypeID] [int] NULL,
[ShowFormProperties] [dbo].[bYN] NULL,
[ShowFieldProperties] [dbo].[bYN] NULL,
[FormattedNotesTab] [tinyint] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDFHc] ADD
CONSTRAINT [CK_vDDFHc_AllowAttachments] CHECK (([AllowAttachments]='Y' OR [AllowAttachments]='N' OR [AllowAttachments] IS NULL))
ALTER TABLE [dbo].[vDDFHc] ADD
CONSTRAINT [CK_vDDFHc_ShowOnMenu] CHECK (([ShowOnMenu]='Y' OR [ShowOnMenu]='N' OR [ShowOnMenu] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtDDFHcu] on [dbo].[vDDFHc] for UPDATE
/************************************
* Created: AL 8/26/08
* *
* Update trigger on vDDFHc 
*
* Removes security records that exist
* when DetailFormSecurity is set to 'N' or Null from 'Y'
*
* 
*
************************************/

as


declare @numrows int, @detailformsecurity bYN 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
if update(DetailFormSecurity)
	Select @detailformsecurity = (select DetailFormSecurity from Deleted)
	
	if @detailformsecurity = 'Y'
	begin
		Delete from DDFS where Form = (select Form from Deleted)
	
	--Auditing
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDFHc', 'U', 'Form: ' + rtrim(i.Form), 'DetailFormSecurity',
		d.DetailFormSecurity, i.DetailFormSecurity, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form 
  	where isnull(i.DetailFormSecurity,'') <> isnull(d.DetailFormSecurity,'')
	
	end
	


  

GO
CREATE UNIQUE CLUSTERED INDEX [viDDFHc] ON [dbo].[vDDFHc] ([Form]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFHc].[ShowOnMenu]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFHc].[AllowAttachments]'
GO
