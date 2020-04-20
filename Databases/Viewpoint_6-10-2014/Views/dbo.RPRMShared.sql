SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RPRMShared] AS
/***********************************************
 * Created:
 * Modified: GG 10/27/06
 *
 * Combines standard and custom Module Report assignments 
 * from vRPRM and vRPRMc.
 *
 * Uses 'instead of triggers' to handle data modifications 
 *
 *******************************************/
SELECT  ISNULL(c.Mod, r.Mod) AS Mod,
		ISNULL(c.ReportID, r.ReportID) AS ReportID,
		ISNULL(c.MenuSeq, r.MenuSeq) AS MenuSeq,
		ISNULL(c.Active, 'Y') AS Active,
		CASE WHEN c.ReportID IS NULL THEN 0 ELSE 1 END AS Custom,
		CASE WHEN c.ReportID IS NULL and r.ReportID IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportID IS NOT NULL and r.ReportID IS NOT NULL THEN 'Override' 
				 WHEN c.ReportID IS NOT NULL and r.ReportID IS  NULL THEN 'Custom' 
				ELSE 'Unknown' END AS Status
FROM dbo.vRPRMc AS c
FULL OUTER JOIN dbo.vRPRM AS r ON r.Mod = c.Mod AND r.ReportID = c.ReportID

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPRMShared] on [dbo].[RPRMShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: TRL 11/13/06		
-- Modified: GG 05/13/08 - #128007 - fix vRPRMc delete when viewpointcs
--
-- Processes deletions to RPRMShared, a view combining standard
-- and custom report links, into their respective tables.
--
-- When logged in as 'viewpointcs', standard form report assignments are deleted
-- from vRPRM, and custom assignments are removed from vRPRMc only if they have no 
-- corresponding standard entry.
--
-- All other logins delete custom form report assignments only.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will delete custom and standard form report assignments
if suser_name() = 'viewpointcs'
	begin
	-- remove custom form reports only if they have no corresponding standard entry
	delete dbo.vRPRMc
	from deleted d
	join dbo.vRPRMc c on c.Mod = d.Mod and c.ReportID = d.ReportID	-- #128007 added join to vRPRMc
	left join dbo.vRPRM f (nolock) on f.Mod = d.Mod and f.ReportID = d.ReportID 
	where f.Mod is null 
	-- remove any existing standard form reports
	delete dbo.vRPRM
	from deleted d
	join dbo.vRPRM f on f.Mod = d.Mod and f.ReportID = d.ReportID 
	end
else
	-- all other logins, remove existing custom form report assignments only
	delete dbo.vRPRMc
	from deleted d
	join dbo.vRPRMc f on f.Mod = d.Mod and f.ReportID = d.ReportID 
	
return

	









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPRMShared] on [dbo].[RPRMShared] INSTEAD OF INSERT AS
-- =============================================
-- Created:  TRL 11/13/06		
-- Modified:
--
-- Processes inserts to RPRMShared, a view combining standard
-- and custom module report assignments into their respective tables.
--
-- When using the 'viewpointcs' login, adding standard module report combinations will 
-- insert entries in vRPRM.  Module report combinations added for non-standard
-- reports will be inserted as custom entries in vRPRMc.
--
-- Adding form/report combinations for any other login inserts custom entries in vRPRMc.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will insert standard and custom module report combinations
if suser_name() = 'viewpointcs'
	begin
	-- insert standard module report combos for standard modules and reports
	insert dbo.vRPRM(Mod, ReportID, MenuSeq)
	select i.Mod, i.ReportID, i.MenuSeq
	from inserted i
	join dbo.vDDMO h (nolock) on h.Mod = i.Mod		-- must be a standard module
	join dbo.vRPRT t (nolock) on t.ReportID = i.ReportID	-- must be a standard report
	left join dbo.vRPRM r on r.Mod = i.Mod and r.ReportID = i.ReportID 
	where r.ReportID is null -- exclude existing entries
	-- insert custom module report combos for non-standard modules or reports
	insert dbo.vRPRMc(Mod, ReportID, MenuSeq, Active)
	select i.Mod, i.ReportID, i.MenuSeq, i.Active
	from inserted i
	left join dbo.vDDMO h (nolock) on h.Mod = i.Mod		
	left join dbo.vRPRT t (nolock) on t.ReportID = i.ReportID	
	left join dbo.vRPRMc r on r.Mod = i.Mod and r.ReportID = i.ReportID 
	where (h.Mod is null or t.ReportID is null) and r.ReportID is null -- exclude standard form/report combos and existing entries
	end
else
	-- insert custom form reports form all other logins
	insert dbo.vRPRMc(Mod, ReportID, MenuSeq, Active)
	select i.Mod, i.ReportID,i.MenuSeq, i.Active
	from inserted i
	left join dbo.vRPRMc r on r.Mod = i.Mod and r.ReportID = i.ReportID 
	where r.ReportID is null -- exclude existing entries
return

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuRPRMShared] on [dbo].[RPRMShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: TrL 11/13/06		
-- Modified: GG 04/10/07 - remove unecessary custom RPRMc entries
--
-- Processes updates to RPRMShared, a view combining standard
-- and custom report links into their respective tables.
--
-- When using the 'viewpointcs' login, no updates to standard form/report combinations in vRPRM.
-- Custom combinations will update vRPRMc only if they have no corresponding standard entry,
-- to prevent overwritting custom info.
--
-- Updating form/reports for any other login inserts/updates custom entries in vRPRMc.
--
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return	
   
set nocount on

-- 'viewpointcs' login will update custom form/report combinations only, nothing to update on standard entries
if suser_name() = 'viewpointcs'
	begin
	-- update existing standard module reports
	update dbo.vRPRM set MenuSeq = i.MenuSeq
	from inserted i
	join dbo.vRPRM r on r.Mod = i.Mod and r.ReportID = i.ReportID  
	-- update existing custom module report combos without standard entries
	update dbo.vRPRMc set MenuSeq = i.MenuSeq, Active = i.Active 
	from inserted i
	left join dbo.vRPRM r (nolock) on r.Mod = i.Mod and r.ReportID = i.ReportID 
	where r.Mod is null	and vRPRMc.ReportID = i.ReportID and vRPRMc.Mod = i.Mod-- exclude form/report combos with standard entries
	end
else
	-- insert/update custom form/report combinations from all other logins
	if update(Active) or update(MenuSeq)
		begin
		-- add override records for standard parameters not already in vRPRMc
		insert dbo.vRPRMc(Mod, ReportID, MenuSeq, Active)
		select i.Mod, i.ReportID, i.MenuSeq, i.Active
		from inserted i
		left join dbo.vRPRMc r on r.Mod = i.Mod and r.ReportID = i.ReportID 
		where r.Mod is null	-- exclude existing entries
		-- update override info
		update dbo.vRPRMc set MenuSeq = i.MenuSeq, Active = i.Active
		from inserted i
		join dbo.vRPRMc r on r.Mod = i.Mod and r.ReportID = i.ReportID 
		end

-- remove any custom entries matching standard entries
delete dbo.vRPRMc
from dbo.vRPRMc c (nolock)
join dbo.vRPRM r (nolock) on c.Mod = r.Mod and c.ReportID = r.ReportID
	and isnull(c.MenuSeq,-1) = isnull(r.MenuSeq,-1)
where c.Active = 'Y'	-- all standard module reports are active

return


GO
GRANT SELECT ON  [dbo].[RPRMShared] TO [public]
GRANT INSERT ON  [dbo].[RPRMShared] TO [public]
GRANT DELETE ON  [dbo].[RPRMShared] TO [public]
GRANT UPDATE ON  [dbo].[RPRMShared] TO [public]
GRANT SELECT ON  [dbo].[RPRMShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRMShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRMShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRMShared] TO [Viewpoint]
GO
