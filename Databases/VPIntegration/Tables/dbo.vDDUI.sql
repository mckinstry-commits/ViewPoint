CREATE TABLE [dbo].[vDDUI]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[DefaultType] [tinyint] NULL,
[DefaultValue] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[InputSkip] [dbo].[bYN] NULL,
[InputReq] [dbo].[bYN] NULL,
[GridCol] [smallint] NULL,
[ColWidth] [smallint] NULL,
[ShowGrid] [dbo].[bYN] NULL,
[ShowForm] [dbo].[bYN] NULL,
[DescriptionColWidth] [smallint] NULL,
[ShowDesc] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtDDUIi] on [dbo].[vDDUI] for INSERT as


/*-----------------------------------------------------------------
 *	This trigger validates insertions into vDDUI (User Input) 
 *
 */----------------------------------------------------------------

declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate user
select @validcnt = count(*)
from dbo.vDDUP u with (nolock)
join inserted i on u.VPUserName = i.VPUserName
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid User'
  	goto error
  	end


---- bypass form sequence check if form like 'PMDocTrack'
select @validcnt = count(*) 
from dbo.DDFIShared f join inserted i on f.Form=i.Form and f.Seq=i.Seq and i.Form not like 'PMDocTrack%'
select @validcnt2 = count(*) from inserted i where i.Form like 'PMDocTrack%'
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Invalid Form and Sequence #'
	goto error
	end
---- validate Form and Sequence #
----select @validcnt = count(*)
----from dbo.DDFIShared f
----join inserted i on f.Form = i.Form and f.Seq = i.Seq
----if @validcnt <> @numrows
----	begin
----	select @errmsg = 'Invalid Form and Sequence #'
----	goto error
----	end


  
return
  
error:
	select @errmsg = @errmsg +  ' - cannot insert User Input overrides (vDDUI)!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
 
  
 





GO
CREATE UNIQUE CLUSTERED INDEX [viDDUI] ON [dbo].[vDDUI] ([VPUserName], [Form], [Seq]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDUI].[InputSkip]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDUI].[InputReq]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDUI].[ShowGrid]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDUI].[ShowForm]'
GO
