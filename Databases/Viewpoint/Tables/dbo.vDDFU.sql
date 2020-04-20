CREATE TABLE [dbo].[vDDFU]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DefaultTabPage] [tinyint] NULL,
[FormPosition] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LastAccessed] [datetime] NULL,
[GridRowHeight] [smallint] NULL,
[SplitPosition] [int] NULL,
[Options] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[FilterOption] [dbo].[bYN] NULL,
[DefaultAttachmentTypeID] [int] NULL,
[LimitRecords] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDFU_LimitRecords] DEFAULT ('N'),
[OpenAttachmentViewer] [dbo].[bYN] NULL CONSTRAINT [DF_vDDFU_OpenAttachmentViewer] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_viDDFU_VPUserNameForm] ON [dbo].[vDDFU] ([VPUserName], [Form]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[vtDDFUi] on [dbo].[vDDFU] for INSERT
/*****************************
* Created: GG 07/21/05
* Modified:
*
* Insert trigger on vDDFU (DD User Form Settings)
*
* Rejects insert if the following conditions exist:
*	Invalid User
*	Invalid Form 
*
*
*************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate User
select @validcnt = count(*)
from inserted i
join dbo.vDDUP u with (nolock) on i.VPUserName = u.VPUserName
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid User Name - must exist in vDDUP'
  	goto error
  	end
-- validate Form
select @validcnt = count(*)
from inserted i
join dbo.DDFHShared h with (nolock) on i.Form = h.Form
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Form - must exist in DDFHShared'
  	goto error
  	end
-- validate Default Tab Page
if exists(select top 1 1 from inserted where DefaultTabPage is not null and DefaultTabPage not in (0,1))
		begin
		select @errmsg = 'Invalid Default Tab Page - must be null, "0" or "1"'
		goto error
		end

  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert User Form Settings!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
    











GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE    trigger [dbo].[vtDDFUu] on [dbo].[vDDFU] for UPDATE
/************************************
* Created: kb 3/7/5
* Modified: GG 06/16/05 - fix primary key check
*
* Update trigger on vDDFU (DD Form Header)
*
* Rejects update if any of the following conditions exist:
*	Change Form name
*	Change VPUsername
*	DefaultTabPage must be 0 or 1
*
*
************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
-- check for key changes 
if update(VPUserName) or update(Form)
	begin
	select @validcnt = count(*) from inserted i join deleted d	on i.VPUserName = d.VPUserName and i.Form = d.Form
	if @validcnt <> @numrows
		begin
  		select @errmsg = 'Cannot change VP User Name or Form'
  		goto error
  		end
	end

if update(DefaultTabPage)
	begin
	if exists(select top 1 1 from inserted where DefaultTabPage is not null and DefaultTabPage not in (0,1))
		begin
		select @errmsg = 'Invalid Default Tab Page - must be null, "0" or "1"'
		goto error
		end
	end

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update User Form Settings!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 








GO
