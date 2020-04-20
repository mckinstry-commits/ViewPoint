SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[RPRTShared] AS
/***********************************************
* Created:
* Modified: GG 10/27/06
*			GG 06/20/07 - #124814 - add KeyID for attachments
*
* Combines standard and custom Report Title information 
* from vRPRT and vRPRTc.
*
* Uses 'instead of triggers' to handle data modifications 
*
*******************************************/
SELECT ISNULL(c.ReportID, t.ReportID) AS ReportID,
		ISNULL(c.Title, t.Title) AS Title,
		ISNULL(c.FileName, t.FileName) AS FileName,
		ISNULL(c.Location, t.Location) AS Location,
		ISNULL(c.ReportOwner, 'viewpointcs') AS ReportOwner,
		ISNULL(c.ReportType, t.ReportType) AS ReportType, 
        ISNULL(c.ShowOnMenu, ISNULL(t.ShowOnMenu, 'N')) AS ShowOnMenu, 
		ISNULL(c.ReportMemo, t.ReportMemo) AS ReportMemo,
		ISNULL(c.ReportDesc, t.ReportDesc) AS ReportDesc,
		c.UserNotes,
		c.UniqueAttchID,
		ISNULL(c.AppType, t.AppType) AS AppType,
		ISNULL(c.Version, t.Version) AS Version, 
		CASE WHEN c.ReportID IS NULL and t.ReportID IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportID IS NOT NULL and t.ReportID IS NOT NULL THEN 'Override' 
				 WHEN c.ReportID IS NOT NULL and t.ReportID IS  NULL THEN 'Custom' 
				ELSE 'Unknown' END AS Status,
		CASE WHEN c.ReportID IS NULL THEN 0 ELSE 1 END AS Custom, 
        ISNULL(c.IconKey, t.IconKey) AS IconKey,
        ISNULL(c.Country, t.Country) AS Country,
		ISNULL(c.AvailableToPortal, t.AvailableToPortal) As AvailableToPortal,
		isnull(c.ReportID, t.ReportID) AS KeyID	-- used for attachments
FROM dbo.vRPRTc AS c
FULL OUTER JOIN dbo.vRPRT AS t ON t.ReportID = c.ReportID


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPRTShared] on [dbo].[RPRTShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 10/25/06		
-- Modified:
--
-- Processes deletions to RPRTShared, a view combining standard
-- and custom report titles, into their respective tables.
--
-- Deleting any report removes its overridden or custom entry from vPRRTc.
-- When logged in as 'viewpointcs', standard reports are deleted from vRPRT.
--
-- Delete triggers on vPRRT and vRPRTc perform cascading deletes to remove all
-- related data referencing the deleted standard or custom report.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom Report Titles entries regardless of login
delete vRPRTc
from deleted d
join vRPRTc t on t.ReportID = d.ReportID

-- if using 'viewpointcs' login remove standard Report Titles as well
if suser_name() = 'viewpointcs'
	delete vRPRT
	from deleted d
	join vRPRT t on t.ReportID = d.ReportID

return

	





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPRTShared] on [dbo].[RPRTShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 10/25/06		
-- Modified:
--				JB 4/13/09 #129822 - To handle Country field.
--
-- Processes inserts to RPRTShared, a view combining standard
-- and custom report titles, into their respective tables.
--
-- Adding a standard report when logged in as 'viewpointcs' inserts vRPRT.
-- Standard reports can only be added from the 'viewpointcs' login.
-- Adding a custom report inserts vRPRTc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- insert standard report titles for report id#s < 10000 when using 'viewpointcs' login
if suser_name() = 'viewpointcs'
	insert vRPRT(ReportID, Title, FileName, Location, ReportType, ShowOnMenu, ReportMemo,
				ReportDesc, AppType, Version, IconKey, Country)
	select ReportID, Title, FileName, Location, ReportType, ShowOnMenu, ReportMemo,
				ReportDesc, AppType, Version, IconKey, Country
	from inserted
	where ReportID < 10000 and ReportID not in (select ReportID from vRPRT)

-- insert custom report titles for report id#s > 9999, regardless of login
insert vRPRTc(ReportID, Title, FileName, Location, ReportOwner, ReportType, ShowOnMenu, ReportMemo,
			ReportDesc, UserNotes, UniqueAttchID, AppType, Version, IconKey, Country)
select ReportID, Title, FileName, Location, ReportOwner, ReportType, ShowOnMenu, ReportMemo,
			ReportDesc, UserNotes, UniqueAttchID, AppType, Version, IconKey, Country
from inserted
where ReportID > 9999 and ReportID not in (select ReportID from vRPRTc)

return
	







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtuRPRTShared] on [dbo].[RPRTShared] INSTEAD OF UPDATE AS
-- ============================================
-- Created: GG 10/25/06		
-- Modified: GG 04/10/07 - remove unecessary custom RPRTc entries
--			GG 06/20/07 - #124814 - handle UniqueAttchID updates for attachments
--          GC 07/23/07 - #125129 - handle AvailableToPortal column for Reports in the Portal
--			JB	4/13/09 - #129822 - handle the Country column
--			JVH	4/29/09 - #133164 - updated to handle attachements correctly
--
-- Processes updates to RPRTShared, a view combining standard
-- and custom report titles into their respective tables.
--
-- Updating a standard report when logged in as 'viewpointcs' updates vRPRT.
-- Updating a standard report from other logins insert/updates an override entry in vRPRTc.
-- Updating a custom report updates vRPRTc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- handle standard reports (report id#s < 10000)
-- if using the 'viewpointcs' login update standard Report Titles 
if suser_name() = 'viewpointcs' and not update(UniqueAttchID) -- we need to add a custom record in this case since that is where the UniqueAttchID comes from
	update vRPRT set Title = i.Title, FileName = i.FileName, Location = i.Location, ReportType = i.ReportType,
		ShowOnMenu = i.ShowOnMenu, ReportMemo = i.ReportMemo, ReportDesc = i.ReportDesc, AppType = i.AppType,
		Version = i.Version, IconKey = i.IconKey, AvailableToPortal = i.AvailableToPortal, Country = i.Country
	from inserted i
	join vRPRT t on t.ReportID = i.ReportID
	where i.ReportID < 10000
else
	-- limited updates allowed to standard reports when using other logins
	if update(ShowOnMenu) or update(IconKey) or update(ReportType) or update(UniqueAttchID) or update(AvailableToPortal) or update(UserNotes)
		begin
		-- add custom report title for standard reports not already in vRPRTc
		insert vRPRTc(ReportID)
		select ReportID
		from inserted 
		where ReportID not in (select ReportID from vRPRTc) and ReportID < 10000
		-- update custom info
		update vRPRTc set ReportType = i.ReportType, ShowOnMenu = i.ShowOnMenu,
			IconKey = i.IconKey, UniqueAttchID = i.UniqueAttchID, AvailableToPortal = i.AvailableToPortal,
			UserNotes = i.UserNotes
		from inserted i
		join vRPRTc t on t.ReportID = i.ReportID
		where i.ReportID < 10000
		-- remove any custom entries matching standard entries
		delete dbo.vRPRTc
		from dbo.vRPRTc c (nolock)
		join dbo.vRPRT r (nolock) on c.ReportID = r.ReportID 
		where isnull(c.ReportType,r.ReportType) = r.ReportType
			and isnull(c.ShowOnMenu,r.ShowOnMenu) = r.ShowOnMenu
			and isnull(c.IconKey,isnull(r.IconKey,'')) = isnull(r.IconKey,'')
			and isnull(c.AvailableToPortal, r.AvailableToPortal) = r.AvailableToPortal
			and c.UniqueAttchID is null and c.ReportID < 10000
			and c.UserNotes is null
		end
	
-- handle custom reports (report id#s > 9999)
-- update custom report title info regardless of login, records should already exist in vRPRTc
update vRPRTc set Title = i.Title, FileName = i.FileName, Location = i.Location,
	ReportOwner = i.ReportOwner, ReportType = i.ReportType, ShowOnMenu = i.ShowOnMenu, 
	ReportMemo = i.ReportMemo, ReportDesc = i.ReportDesc, UserNotes = i.UserNotes, 
	UniqueAttchID = i.UniqueAttchID, AppType = i.AppType , Version = i.Version, IconKey = i.IconKey,
	AvailableToPortal = i.AvailableToPortal, Country = i.Country
from inserted i
join vRPRTc t on t.ReportID = i.ReportID
where i.ReportID > 9999


return
GO
GRANT SELECT ON  [dbo].[RPRTShared] TO [public]
GRANT INSERT ON  [dbo].[RPRTShared] TO [public]
GRANT DELETE ON  [dbo].[RPRTShared] TO [public]
GRANT UPDATE ON  [dbo].[RPRTShared] TO [public]
GO
