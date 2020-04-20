CREATE TABLE [dbo].[vDDSI]
(
[Co] [dbo].[bCompany] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[SubFolder] [smallint] NOT NULL,
[ItemType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MenuItem] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[MenuSeq] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE    trigger [dbo].[vtDDSIi] on [dbo].[vDDSI] for INSERT 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified: GG 12/08/03 - added Co column
 *
 *	This trigger rejects insertion in vDDSI (User Sub-Folders) if
 *	any of the following error conditions exist:
 *
 *		Invalid User Sub-Folder
 *		Invalid Item Type (must be F = Form or R = Report)
 *		Invalid Menu Item  (must be valid Form or Report)
 *
 */----------------------------------------------------------------

as
 


declare @errmsg varchar(255), @numrows int, @validcnt int, @formcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
-- check User Sub-Folders

select @validcnt = count(*)
from inserted i
join vDDSF f on f.Co = i.Co and f.VPUserName = i.VPUserName and f.Mod = i.Mod
	and f.SubFolder = i.SubFolder
if @validcnt <> @numrows
 	begin
 	--select @errmsg = 'Invalid Menu Sub-Folder'
declare @co bCompany, @user bVPUserName, @mod char(2), @subfolder tinyint
select @co = i.Co, @user = i.VPUserName, @mod = i.Mod, @subfolder = i.SubFolder from inserted i
 	select @errmsg = 'Invalid Insert into vDDSI.  Co=' + cast(@co as char(3)) + '; VPUserName=' + @user + '; Mod=' + @mod + '; SubFolder=' + cast(@subfolder as char(3))
	--
 	goto error
 	end

-- check Item Type
if exists(select top 1 1 from inserted where ItemType not in ('F','R'))
	begin
	select @errmsg = 'Invalid Item Type, must be ''F'' or ''R'''
	goto error
	end


-- check Program Menu Items 
select @formcnt = count(*)
from inserted i
join DDFHShared f on f.Form = i.MenuItem
where i.ItemType = 'F'

/*
-- DEBUG *************************************************************
select @errmsg = ' @formcnt=' + cast(@formcnt as varchar(3))
 + ', @validcnt=' + cast(@validcnt as varchar(3))
-- DEBUG *************************************************************
*/

-- check Report Menu Items
select @validcnt = count(*)
from inserted i
join RPRTShared r on convert(varchar,r.ReportID) = i.MenuItem
where i.ItemType = 'R'
if @formcnt + @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Program and/or Report'
 	goto error
 	end
 
return
 
error:
    select @errmsg = @errmsg + ' - cannot insert Menu Sub-Folder Item!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 











GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create trigger [dbo].[vtDDSIu] on [dbo].[vDDSI] for UPDATE 
/*-----------------------------------------------------------------
 * 	Created: GG 08/01/03
 *	Modified: GG 12/08/03 - added Co column
 *
 *	This trigger rejects update in vDDSI (Menu Sub-Folder Items) if the
 *	following error condition exists:
 *
 *		Cannot change Company, User, Mod, Sub-Folder, Item Type, or Menu Item
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
		and d.SubFolder = i.SubFolder and d.ItemType = i.ItemType and d.MenuItem = i.MenuItem
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Cannot change Company, User, Module, Sub-Folder, Item Type, or Menu Item'
 	goto error
 	end
 
return
 
error:
    select @errmsg = @errmsg + ' - cannot update Menu Sub-Folder Item!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 







GO
CREATE UNIQUE CLUSTERED INDEX [viDDSI] ON [dbo].[vDDSI] ([Co], [VPUserName], [Mod], [SubFolder], [ItemType], [MenuItem]) ON [PRIMARY]
GO
