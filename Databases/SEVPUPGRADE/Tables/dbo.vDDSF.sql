CREATE TABLE [dbo].[vDDSF]
(
[Co] [dbo].[bCompany] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[SubFolder] [smallint] NOT NULL,
[Title] [dbo].[bDesc] NOT NULL,
[ViewOptions] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






create trigger [dbo].[vtDDSFd] on [dbo].[vDDSF] for delete 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified: GG 12/08/03 - added Co column
 *
 *	This trigger rejects delete in vDDSF (User Sub-Folders) if any of the
 *	following error conditions exist:
 *
 *		Menu items assigned to Sub-Folder
 *
 */----------------------------------------------------------------
 
as



declare @errmsg varchar(255)
if @@rowcount = 0 return

set nocount on
 
-- check User SubFolder Menu Items 
if exists (select top 1 1 from deleted d
			join vDDSI s on s.Co = d.Co and s.VPUserName = d.VPUserName
				and s.Mod = d.Mod and s.SubFolder = d.SubFolder)
 	begin
 	select @errmsg = 'Menu items assigned'
 	goto error
 	end

return
 
error:
	select @errmsg = @errmsg + ' - cannot delete Sub-Folder!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE     trigger [dbo].[vtDDSFi] on [dbo].[vDDSF] for INSERT 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified: GG 12/08/03 - added Co column and validation
 *
 *	This trigger rejects insertion in vDDSF (User Subfolders) if
 *	any of the following error conditions exist:
 *
 *		Invalid Company
 *		Invalid User
 *		Invalid Module
 *
 *	Company 0 is used to indicate this is a user-defined subfolder.
 */----------------------------------------------------------------

as
 


declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- check Company level subfolders.
if exists(select top 1 1 from inserted where Co > 0 and (VPUserName <> '' or Mod <> ''))
	begin
	select @errmsg = 'Company level Subfolders must not specify a User Name or Module'
	goto error
	end
-- check User level subfolders
if exists(select top 1 1 from inserted where Co = 0 and VPUserName = '')
	begin
	select @errmsg = 'User level Subfolders must specify a User Name'
	goto error
	end
 
-- check Company #s
select @nullcnt = count(*) from inserted where Co = 0 -- user entries
select @validcnt = count(*)
from inserted i
join bHQCO c on c.HQCo = i.Co
if @validcnt + @nullcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Company #'
 	goto error
 	end

-- check Users
select @nullcnt = count(*) from inserted where Co > 0 	-- company level entries.
select @validcnt = count(*)
from inserted i
join vDDUP u on u.VPUserName = i.VPUserName
if @validcnt + @nullcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid User'
 	goto error
 	end

-- check Modules
select @nullcnt = count(*) from inserted where Mod = ''	-- Company and My Viewpoint entries
select @validcnt = count(*)
from inserted i
join vDDMO m on m.Mod = i.Mod
if @validcnt + @nullcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Module'
 	goto error
 	end
 
return
 
error:
    select @errmsg = @errmsg + ' - cannot insert Menu Subfolder!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 












GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  trigger [dbo].[vtDDSFu] on [dbo].[vDDSF] for UPDATE 
/*-----------------------------------------------------------------
 * 	Created: GG 08/01/03
 *	Modified: GG 12/08/03 - added Co column and validation
 *
 *	This trigger rejects update in vDDSF (Menu Sub-Folders) if the
 *	following error condition exists:
 *
 *		Cannot change Company, User, Mod, or Sub-Folder
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int
 	 
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
/* check for key change */
select @validcnt = count(*) from inserted i
	join deleted d on i.Co = d.Co and i.VPUserName = d.VPUserName and i.Mod = d.Mod 
		and d.SubFolder = i.SubFolder
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Cannot change Company, User, Module, or Sub-Folder'
 	goto error
 	end

-- check Company level subfolders
if exists(select top 1 1 from inserted where Co > 0 and (VPUserName <> '' or Mod <> ''))
	begin
	select @errmsg = 'Company level Subfolders must not specify a User Name or Module'
	goto error
	end
-- check User level subfolders
if exists(select top 1 1 from inserted where Co = 0 and VPUserName = '')
	begin
	select @errmsg = 'User level Subfolders must specify a User Name'
	goto error
	end
 
return
 
error:
    select @errmsg = @errmsg + ' - cannot update Menu Sub-Folder!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 







GO
CREATE UNIQUE CLUSTERED INDEX [viDDSF] ON [dbo].[vDDSF] ([Co], [VPUserName], [Mod], [SubFolder]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
