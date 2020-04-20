CREATE TABLE [dbo].[vRPRT]
(
[ReportID] [int] NOT NULL,
[Title] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[FileName] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[Location] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ReportType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ShowOnMenu] [dbo].[bYN] NOT NULL,
[ReportMemo] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ReportDesc] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[AppType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Version] [tinyint] NOT NULL,
[IconKey] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AvailableToPortal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vRPRT_AvailableToPortal] DEFAULT ('N'),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[MenuCategoryID] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtRPRTd] on [dbo].[vRPRT] for DELETE as
/************************************************************
 * Created: TL 6/13/05
 * Modified: GG 10/25/06 
 *
 * Delete trigger on standard Report Titles (vRPRT)
 *
 * Performs cascade delete on all tables referencing deleted Report ID#
 *
 * Adds HQ Audit entry 
 *
 *********************************************************/

declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end 
 
-- remove custom form/report defaults 
delete dbo.vRPFDc
where ReportID in (select ReportID from deleted)
-- remove standard form/report defaults
delete dbo.vRPFD
where ReportID in (select ReportID from deleted)

-- remove custom form/report links
delete dbo.vRPFRc
where ReportID in (select ReportID from deleted)
-- remove standard form/report links
delete dbo.vRPFR
where ReportID in (select ReportID from deleted)

-- remove custom parameter lookups
delete dbo.vRPPLc
where ReportID in (select ReportID from deleted)
-- remove standard parameter lookups
delete dbo.vRPPL
where ReportID in (select ReportID from deleted)

-- remove report fields
delete dbo.vRPRF
where ReportID in (select ReportID from deleted)

-- remove custom module/report links
delete dbo.vRPRMc
where ReportID in (select ReportID from deleted)
-- remove standard module/report links
delete dbo.vRPRM
where ReportID in (select ReportID from deleted)

-- remove custom report parameters 
delete dbo.vRPRPc
where ReportID in (select ReportID from deleted)
-- remove standard report parameters
delete dbo.vRPRP
where ReportID in (select ReportID from deleted)

-- remove report security
delete dbo.vRPRS
where ReportID in (select ReportID from deleted)

-- remove report tables
delete dbo.vRPTP
where ReportID in (select ReportID from deleted)

-- remove user/report preferences
delete dbo.vRPUP
where ReportID in (select ReportID from deleted)

-- remove menu item references
delete dbo.vDDSI
where ItemType = 'R' and convert(int,MenuItem) in (select ReportID from deleted) 

-- remove menu template item references
delete dbo.vDDTD
where ItemType = 'R' and convert(int,MenuItem) in (select ReportID from deleted) 

-- remove custom report title overrides
delete dbo.vRPRTc
where ReportID in (select ReportID from deleted)

/* Audit deletes */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRT','ReportID: ' + convert(varchar,ReportID), null, 'D',
 		NULL, NULL, NULL, getdate(),
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
from deleted 
 
return
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete standard Report Title.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtRPRTi] on [dbo].[vRPRT] for INSERT  as
/***************************************************
* Created: TL 06/13/05
* Modified: GG 10/25/06
*			GG 06/20/07 - #124717 add menu link to RP module
*	        CC 09/04/2008 - Added PartReport to report application list
*			 CC 03/16/2009 - Issue # 132222 - Add OLAP report application type
*	        KE 06/06/2012 - Removed PartReport from the report application list
*
* Insert trigger on standard Report Titles (vRPRT)
*
* Rejects insert if the following conditions exist:
*	Invalid Report ID (1 - 9999)
*	Invalid Filename
*	Invalid Location
*	Invalid Report Type
*	Invalid Application Type
*
* Adds HQ Audit entry
*
*********************************************************/

declare @numrows int, @validcnt int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end 
-- validate ReportID - standard Report ID#s are < 10000, custom are > 9999
if exists(select top 1 1 from inserted where ReportID < 1 or ReportID > 9999)
	begin
	select @errmsg = 'Report ID#s must be between 1 and 9999'
  	goto error
  	end
-- validate FileName  
if exists(select top 1 1 from inserted where upper(FileName) not like '%.RPT' and AppType = 'Crystal')
	begin
	select @errmsg = 'Filename for Crystal reports must have an .rpt extension'
  	goto error
  	end
-- validate Location - standard report must use standard location
select @validcnt = count(*)
from inserted i
join dbo.vRPRL r with (nolock) on i.Location = r.Location
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Report Location'
  	goto error
  	end
-- validate Report Type 
select @validcnt = count(*)
from inserted i
join dbo.vRPTY r with (nolock) on i.ReportType = r.ReportType
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid Report Type'
  	goto error
  	end
-- validate Application Type
if exists(select top 1 1 from inserted where AppType not in ('Crystal','SQL Reporting Services','Other', 'OLAPReport'))
	begin
	select @errmsg = 'Application Type must be Crystal, SQL Reporting Services, or Other'
	goto error
	end
--add menu link to RP module
insert dbo.vRPRM(Mod, ReportID, MenuSeq)
select 'RP',ReportID,null
from inserted

/* Audit inserts */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRT','Report ID: ' + convert(varchar,ReportID), null, 'A', 
 		NULL, NULL, NULL, getdate(),
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
from inserted 

return
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert standard Report Title'
 	RAISERROR(@errmsg, 11, -1);
  	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtRPRTu] on [dbo].[vRPRT] for UPDATE as
/*****************************************
 * Created: TL 6/13/05
 * Modified: GG 10/25/06
 *			 CC 11/04/2008 - Added PartReport to report application list
 *			 CC 03/16/2009 - Issue # 132222 - Add OLAP report application type
 *		    CJG 03/18/2010 - Issue #137342 - No need to truncate ReportDesc as HQMA Old/New fields are varchar(max)
 *			 KE 06/06/2012 - Remove PartReport from the report application list
 *
 * Update trigger on standard Report Titles (vRPRT)
 *
 * Rejects update if the following conditions exist:
 *	Update Report ID#
 *	Invalid Location
 *	Invalid Report Type
 *	Invalid Application Type 
 *
 * Audits changes in bHQMA
 *
 ***************************************/

declare @numrows int, @validcnt int, @errmsg varchar(255)
  	
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end 
-- prevent primary key changes
if update(ReportID)
	begin
	select @errmsg = 'Not allowed to change Report ID#'
	goto error
	end
-- validate Report Location
if update(Location)
	begin
	select @validcnt = count(*) from inserted i
	join dbo.vRPRL r (nolock) on i.Location = r.Location
	if @validcnt <> @numrows
		begin
  		select @errmsg = 'Invalid Location'
  		goto error
  		end
	end
-- validate Report Type
if update(ReportType)
	begin 
	select @validcnt = count(*) from inserted i
	join dbo.vRPTY r  (nolock) on i.ReportType = r.ReportType
	if @validcnt <>@numrows
  		begin
  		select @errmsg = 'Invalid Report Type'
  		goto error
  		end
	end
  -- validate Application Type
if update(AppType)
	begin
	if exists(select 1 from inserted where AppType not in ('Crystal','SQL Reporting Services','Other', 'OLAPReport'))
 		begin
 		select @errmsg = 'Invalid Application, must be Crystal, SQL Reporting Services, or Other'
 		goto error
 		end
	end
 

/* Audit updates */
if update(Title)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C',	'Title',
		d.Title, i.Title, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where i.Title <> d.Title
if update(FileName)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C',	'FileName',
		d.FileName, i.FileName, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where i.FileName <> d.FileName
if update(Location)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C','Location',
		d.Location, i.Location, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where i.Location <> d.Location
if update(ReportType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ReportType',
		d.ReportType, i.ReportType, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where i.ReportType <> d.ReportType
if update(ShowOnMenu)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ShowOnMenu',
		d.ShowOnMenu, i.ShowOnMenu, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID
 	where i.ShowOnMenu <> d.ShowOnMenu 
if update(ReportMemo)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ReportMemo',
		d.ReportMemo, i.ReportMemo, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.ReportMemo,'') <> isnull(d.ReportMemo,'')
if update(ReportDesc)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ReportDesc',
		d.ReportDesc, i.ReportDesc, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.ReportDesc,'') <> isnull(d.ReportDesc,'')

if update(AppType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C',	'AppType',
		d.AppType, i.AppType, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
	where i.AppType <> d.AppType
if update(IconKey)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRT', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'IconKey',
		d.IconKey, i.IconKey, getdate(), 
		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.IconKey,'') <> isnull(d.IconKey,'')

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update standard Report Titles'
	RAISERROR(@errmsg, 11, -1);
    rollback transaction
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vRPRT_ReportID] ON [dbo].[vRPRT] ([ReportID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vRPRT_Title] ON [dbo].[vRPRT] ([Title]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vRPRT].[ShowOnMenu]'
GO
