CREATE TABLE [dbo].[vRPRTc]
(
[ReportID] [int] NOT NULL,
[Title] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[FileName] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Location] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ReportOwner] [dbo].[bVPUserName] NULL,
[ReportType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ShowOnMenu] [dbo].[bYN] NULL,
[ReportMemo] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ReportDesc] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[UserNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AppType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Version] [tinyint] NULL,
[IconKey] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AvailableToPortal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vRPRTc_AvailableToPortal] DEFAULT ('N'),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtRPRTcd] on [dbo].[vRPRTc] for DELETE as
/************************************************************
 * Created: TL 6/13/05
 * Modified: GG 10/25/06 
 *
 * Delete trigger for custom Report Titles (vRPRTc)
 *
 * Removes data from all tables referencing the custom Report ID#
 *
 * Adds HQ Audit entry 
 *
 *********************************************************/

declare @numrows int, @errmsg varchar(255)
 
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- remove custom form/report defaults 
delete dbo.vRPFDc
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove custom form/report links
delete dbo.vRPFRc
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove custom parameter lookups
delete dbo.vRPPLc
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove custom report parameters 
delete dbo.vRPRPc
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove custom module/report links
delete dbo.vRPRMc
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove report security
delete dbo.vRPRS
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove report tables
delete dbo.vRPRF
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove report tables
delete dbo.vRPTP
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove user/report preferences
delete dbo.vRPUP
where ReportID > 9999 and ReportID in (select ReportID from deleted)

-- remove custom report title overrides
delete dbo.vRPRTc
where ReportID > 9999 and ReportID in (select ReportID from deleted)


/* Audit deletes */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRTc','ReportID: ' + convert(varchar,ReportID), null, 'D',
 		NULL, NULL, NULL, getdate(), suser_name()
from deleted 
 
return
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete custom Report Title.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 


















GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtRPRTci] on [dbo].[vRPRTc] for INSERT as
/************************************************************
* Created: TL 6/13/05
* Modified: GG 10/25/06
*			GG 06/20/07 - #124717 add custom menu link to RP module for custom reports
*			CC 03/16/2009 - Issue # 132222 - Add OLAP report application type
*			DC 04/13/2009 - #132321 - Add validation ensuring Custom Report title not the same as Stand Report Title
*			KE 06/06/2012 - Removed PartReport form the report application list
*
* Insert trigger for custom Report Titles (vRPRTc)
*
* Rejects insert if the following conditions exist:
*	Invalid Report ID (if < 10000 must have standard entry in vRPRT)
*	Invalid Filename
*	Invalid Location
*	Invalid Report Type
*	Invalid Application Type 
*
* Adds HQMA audit
*
********************************************************/

declare @numrows int, @validcnt int, @validcnt2 int, @nullcnt int, @errmsg varchar(255)
 	
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- validate ReportID
select @validcnt = count(*) 
from inserted i
join dbo.vRPRT t (nolock) on t.ReportID = i.ReportID
where i.ReportID < 10000
select @validcnt2 = count(*) from inserted
where ReportID < 10000
if @validcnt <> @validcnt2
	begin
	select @errmsg = 'Report override is missing standard entry'
  	goto error
  	end

-- validate FileName  
if exists(select top 1 1 from inserted where ReportID > 9999 and upper(FileName) not like '%.RPT' and AppType = 'Crystal')
	begin
	select @errmsg = 'Filename for Crystal reports must have an .rpt extension'
  	goto error
  	end

--Location/ReportType/Application  not need on Standard Reports in RPRTc
select @validcnt2 = count(*) from inserted where ReportID > 9999

-- validate Location - standard report must use standard location
select @validcnt = count(*)
from inserted i
join dbo.vRPRL r (nolock) on i.Location = r.Location
where i.ReportID > 9999
if @validcnt <> @validcnt2
	begin
  		select @errmsg = 'Invalid Report Location'
		goto error
	end
-- validate Report Type 
select @validcnt = count(*)
from inserted i
join dbo.RPTYShared r with (nolock) on i.ReportType = r.ReportType
where i.ReportID > 9999
if @validcnt <> @validcnt2
begin
	select @errmsg = 'Invalid Report Type'
	goto error
end
-- validate Application Type
if exists(select top 1 1 from inserted where ReportID > 9999 and AppType not in ('Crystal','SQL Reporting Services','Other', 'OLAPReport'))
begin
	select @errmsg = 'Application Type must be Crystal, SQL Reporting Services, or Other'
	goto error
end
-- validate that the Custom Report title does not match an existing report title	
if exists(select top 1 1 from vRPRT a inner join inserted i on a.Title = i.Title where i.ReportID >= 10000)
	begin
	select @errmsg = 'Duplicate Custom Report name -- Report names must be unique'
	goto error
	end



--add custom menu link to RP module for all custom reports
insert dbo.vRPRMc(Mod, ReportID, MenuSeq,Active)
select 'RP',ReportID,null,'Y'
from inserted where ReportID >=10000


/* Audit inserts */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRTc','Report ID: ' + convert(varchar, ReportID), null, 'A', NULL, NULL, NULL, getdate(), SUSER_NAME()
from inserted

return
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert custom Report Title.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtRPRTcu] on [dbo].[vRPRTc] for UPDATE as
/*****************************************
 * Created: TL 6/13/05
 * Modified: GG 10/25/06
 *			 CC 09/04/2008 - Added PartReport to report application list
 *			 CC 03/16/2009 - Issue # 132222 - Add OLAP report application type
 *			 DC 04/13/2009 - #132321 - Add validation ensuring Custom Report title not the same as Standard Report Title
 *			 CC 04/22/2009 - Issue # 133330 - Substring audit of UserNotes field to 255 characters to match HQMA
 *		    CJG 03/18/2010 - Issue #137342 - No need to truncate ReportDesc as HQMA Old/New fields are varchar(max)
 *			 KE 06/06/2012 - Removed PartReport from the report application list
 *
 * Update trigger on custom Report Titles (vRPRTc)
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
 
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255)
  	
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
 
-- prevent primary key changes
if update(ReportID)
	begin
	select @errmsg = 'Not allowed to change Report ID#'
	goto error
	end 
-- validate Report Location
if update(Location)
	begin
	select @nullcnt = count(*) from inserted where Location is null
	select @validcnt = count(*) from inserted i
	join dbo.vRPRL r (nolock) on i.Location = r.Location
	where i.ReportID > 9999		-- required with custom reports
	if @validcnt + @nullcnt <> @numrows
		begin
  		select @errmsg = 'Invalid Location'
  		goto error
  		end
	end
 -- validate Report Type
if update(ReportType)
	begin
	if exists(select top 1 1 from inserted where ReportType is null and ReportID > 9999)
		begin
		select @errmsg = 'Report Type required on all custom reports'
		goto error
		end
	select @nullcnt = count(*) from inserted  where ReportType is null 
	select @validcnt = count(*) from inserted i
	join dbo.RPTYShared r  (nolock) on i.ReportType = r.ReportType
	if @validcnt + @nullcnt <> @numrows
  		begin
  		select @errmsg = 'Invalid Report Type'
  		goto error
  		end
	end
-- validate Application Type
if update(AppType)
	begin
	select @nullcnt = count(*) from inserted where AppType is null
	select @validcnt = count(*) from inserted
		where ReportID > 9999 and AppType in ('Crystal','SQL Reporting Services','Other', 'OLAPReport') -- required with custom reports
 	if @validcnt + @nullcnt <> @numrows
	 	begin
 		select @errmsg = 'Invalid Application, must be Crystal, SQL Reporting Services, or Other'
 		goto error
 		end
	end
-- validate that the Custom Report title does not match an existing report title	
if update(Title)
	begin
	if exists(select top 1 1 from vRPRT a inner join inserted i on a.Title = i.Title where i.ReportID >= 10000)
		begin
		select @errmsg = 'Duplicate Custom Report name -- Report names must be unique'
		goto error
		end
	end

/* Audit updates */
if update(Title)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C',	'Title',
		d.Title, i.Title, getdate(), SUSER_NAME() 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.Title,'') <> isnull(d.Title,'')
if update(FileName)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C',	'FileName',
		d.FileName, i.FileName, getdate(), SUSER_NAME() 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.FileName,'') <> isnull(d.FileName,'')
if update(Location)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C','Location',
		d.Location, i.Location, getdate(), SUSER_NAME() 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.Location,'') <> isnull(d.Location,'')
if update(ReportOwner)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C','ReportOwner',
		d.ReportOwner, i.ReportOwner, getdate(), SUSER_NAME() 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.ReportOwner,'') <> isnull(d.ReportOwner,'')
if update(ReportType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ReportType',
		d.ReportType, i.ReportType, getdate(), SUSER_NAME() 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.ReportType,'') <> isnull(d.ReportType,'')
if update(ShowOnMenu)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ShowOnMenu',
		d.ShowOnMenu, i.ShowOnMenu, getdate(), SUSER_NAME() 
 	from inserted i
	join deleted d on i.ReportID = d.ReportID
 	where isnull(i.ShowOnMenu,'') <> isnull(d.ShowOnMenu,'')
if update(ReportMemo)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ReportMemo',
		d.ReportMemo, i.ReportMemo, getdate(), SUSER_NAME()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.ReportMemo,'') <> isnull(d.ReportMemo,'')
 	
if update(ReportDesc)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'ReportDesc',
		d.ReportDesc, i.ReportDesc, getdate(), SUSER_NAME()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.ReportDesc,'') <> isnull(d.ReportDesc,'')

if update(UserNotes)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'UserNotes',
		substring(d.UserNotes,1,255), substring(i.UserNotes,1,255), getdate(), SUSER_NAME()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.UserNotes,'') <> isnull(d.UserNotes,'')
if update(AppType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C',	'AppType',
		d.AppType, i.AppType, getdate(), SUSER_NAME()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
	where isnull(i.AppType,'') <> isnull(d.AppType,'')
if update(IconKey)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRTc', 'ReportID: ' + convert(varchar,i.ReportID), null, 'C', 'IconKey',
		d.IconKey, i.IconKey, getdate(), SUSER_NAME()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID 
 	where isnull(i.IconKey,'') <> isnull(d.IconKey,'')
 
  return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update custom Report Title.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction



GO
ALTER TABLE [dbo].[vRPRTc] WITH NOCHECK ADD CONSTRAINT [CK_vRPRTc_ShowOnMenu] CHECK (([ShowOnMenu]='Y' OR [ShowOnMenu]='N' OR [ShowOnMenu] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vRPRTc_ReportID] ON [dbo].[vRPRTc] ([ReportID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
