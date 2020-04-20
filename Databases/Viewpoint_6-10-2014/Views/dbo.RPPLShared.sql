SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RPPLShared] AS
/***********************************************
 * Created:
 * Modified: GG 10/27/06
 *
 * Combines standard and custom Report Parameter Lookups 
 * from vRPPL and vRPPLc.
 *
 * Uses 'instead of triggers' to handle data modifications 
 *
 *******************************************/
SELECT	ISNULL(c.ReportID, p.ReportID) AS ReportID,
		ISNULL(c.ParameterName, p.ParameterName) AS ParameterName,
		ISNULL(c.Lookup, p.Lookup) AS Lookup,
		ISNULL(c.LookupParams, p.LookupParams) AS LookupParams,
		ISNULL(c.LoadSeq, p.LoadSeq) AS LoadSeq,
		ISNULL(c.Active, 'Y') AS Active,
        CASE WHEN c.ReportID IS NOT NULL THEN 1 ELSE 0 END AS Custom,
				CASE WHEN c.ReportID IS NULL and p.ReportID IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportID IS NOT NULL and p.ReportID IS NOT NULL THEN 'Override' 
				 WHEN c.ReportID IS NOT NULL and p.ReportID IS  NULL THEN 'Custom' 
				ELSE 'Unknown' END AS Status
FROM dbo.vRPPLc AS c
FULL OUTER JOIN dbo.vRPPL AS p ON p.ReportID = c.ReportID AND p.ParameterName = c.ParameterName AND p.Lookup = c.Lookup

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPPLShared] on [dbo].[RPPLShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 10/30/06		
-- Modified: JPD 10/15/09 to fix issue 135906 (all custom lookups for report parameters being deleted
--                                             when user is 'viewpointcs')
--
-- Processes deletions to RPPLShared, a view combining standard
-- and custom report parameter lookups, into their respective tables (vRPPL and vRPPLc)
--
-- NOTE: Custom report parameter lookups are only in the vRPPLc table
--       Standard report parameter lookups are only in the vRPPL table
--       Override report parameter lookups have records in both tables but share a single view row 
--                    (normally setting the active column (which is solely from vRPPLc) to 0)
--                    NOTE: There is currently a form code prohibition to deleting 'Override' view rows,
--                          although this trigger should handle that too.
--
-- Normal Behavior (when the user is NOT 'viewpointcs'):
--       only matching vRPPLc table entries are deleted (custom or override lookups)
--       (but not the base lookup covered by an override)
--
-- Special Behavior (when the use IS 'viewpointcs')
--       matching entries in Both () tables are deleted 
--          (includes the standard lookup and override (if any), or custom lookup)
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on


-- only the 'viewpointcs' login will delete from the standard table (special behavior)
if suser_name() = 'viewpointcs'
	delete dbo.vRPPL
		from deleted d
		join dbo.vRPPL l on l.ReportID = d.ReportID and l.ParameterName = d.ParameterName and l.Lookup = d.Lookup
		
-- all logins (including 'viewpointcs') will delete from the custom table (normal behavior)
delete dbo.vRPPLc
	from deleted d
	join dbo.vRPPLc l on l.ReportID = d.ReportID and l.ParameterName = d.ParameterName and l.Lookup = d.Lookup

return

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPPLShared] on [dbo].[RPPLShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 10/31/06		
-- Modified:
--
-- Processes inserts to RPPLShared, a view combining standard
-- and custom report parameter lookups, into their respective tables.
--
-- When using the 'viewpointcs' login, adding lookups to standard report parameters
-- will insert entries in vRPPL.  Lookups added to non-standard report parameters will
-- be inserted as custom entries in vRPPLc.
--
-- Adding parameter lookups for any other login inserts custom entries in vRPPLc.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will insert custom and standard report parameter lookups
if suser_name() = 'viewpointcs'
	begin
	-- insert standard parameter lookups for standard report parameters
	insert dbo.vRPPL(ReportID, ParameterName, Lookup, LookupParams, LoadSeq)
	select i.ReportID, i.ParameterName, i.Lookup, i.LookupParams, i.LoadSeq
	from inserted i
	join dbo.vRPRP p (nolock) on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	left join dbo.vRPPL l on l.ReportID = i.ReportID and l.ParameterName = i.ParameterName and l.Lookup = i.Lookup
	where l.ReportID is null -- exclude existing entries
	-- insert custom report parameter lookups for non-standard report parameters
	insert dbo.vRPPLc(ReportID, ParameterName, Lookup, LookupParams, LoadSeq, Active)
	select i.ReportID, i.ParameterName, i.Lookup, i.LookupParams, i.LoadSeq, i.Active
	from inserted i
	left join dbo.vRPRP p (nolock) on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	left join dbo.vRPPLc l on l.ReportID = i.ReportID and l.ParameterName = i.ParameterName and l.Lookup = i.Lookup
	where p.ReportID is null and l.ReportID is null -- exclude existing entries
	end
else
	-- insert custom report parameter lookups for all other logins
	insert dbo.vRPPLc(ReportID, ParameterName, Lookup, LookupParams, LoadSeq, Active)
	select i.ReportID, i.ParameterName, i.Lookup, i.LookupParams, i.LoadSeq, i.Active
	from inserted i
	left join dbo.vRPPLc p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName and p.Lookup = i.Lookup
	where p.ReportID is null -- exclude existing entries


return
	








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtuRPPLShared] on [dbo].[RPPLShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: GG 10/30/06		
-- Modified:	GG 04/06/07 - remove unecessary custom RPPLc entries
--				CC 09/29/10 - added inner join between RPPLc & inserted for update of viewpointcs to only update the records in the inserted table
--
-- Processes updates to RPPLShared, a view combining standard
-- and custom report parameter lookups, into their respective tables.
--
-- When using the 'viewpointcs' login, updating parameter lookups with standard entries
-- will update vRPPL.  Custom lookup entries will update vRPPLc only if they have no corresponding
-- standard entry, to prevent overwritting custom info.
--
-- Updating parameter lookups for any other login inserts/updates custom entries in vRPPLc.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- 'viewpointcs' login will update standard and custom report parameter lookups
if suser_name() = 'viewpointcs'
	begin
	-- update existing standard parameter lookups
		UPDATE dbo.vRPPL 
			SET LookupParams = i.LookupParams, 
				LoadSeq = i.LoadSeq
		FROM inserted i
		INNER JOIN dbo.vRPPL l on l.ReportID = i.ReportID AND l.ParameterName = i.ParameterName and l.Lookup = i.Lookup;
		
		-- update existing custom lookups without standard entries
		UPDATE dbo.vRPPLc 
			SET LookupParams = i.LookupParams, 
				LoadSeq = i.LoadSeq, 
				Active = i.Active
		FROM dbo.vRPPLc c
		INNER JOIN inserted i ON c.ReportID = i.ReportID AND c.ParameterName = i.ParameterName AND c.Lookup = i.Lookup
		LEFT OUTER JOIN dbo.vRPPL l WITH (NOLOCK) ON l.ReportID = i.ReportID AND l.ParameterName = i.ParameterName AND l.Lookup = i.Lookup
		WHERE l.ReportID IS NULL;	-- exclude parameter lookups with standard entries
	end
else
	-- insert/update custom report parameter lookups from all other logins
	if update(LookupParams) or update(LoadSeq) or update(Active)
		begin
		-- add override records for standard parameters not already in vRPPLc
		insert dbo.vRPPLc(ReportID, ParameterName, Lookup, LookupParams, LoadSeq, Active)
		select i.ReportID, i.ParameterName, i.Lookup, i.LookupParams, i.LoadSeq, i.Active
		from inserted i
		left join dbo.vRPPLc l on l.ReportID = i.ReportID and l.ParameterName = i.ParameterName and l.Lookup = i.Lookup
		where l.ReportID is null	-- exclude existing entries
		-- update override info
		update dbo.vRPPLc set LookupParams = i.LookupParams, LoadSeq = i.LoadSeq, Active = i.Active
		from inserted i
		join dbo.vRPPLc l on l.ReportID = i.ReportID and l.ParameterName = i.ParameterName and l.Lookup = i.Lookup
		end

-- remove any custom entries matching standard entries
delete dbo.vRPPLc
from dbo.vRPPLc c (nolock)
join dbo.vRPPL p (nolock) on c.ReportID = p.ReportID and c.ParameterName = p.ParameterName
	and c.Lookup = p.Lookup and isnull(c.LookupParams,isnull(p.LookupParams,'')) = isnull(p.LookupParams,'')
	and isnull(c.LoadSeq,p.LoadSeq) = p.LoadSeq
where c.Active = 'Y'	-- all standard parameter lookups are active
	
return
GO
GRANT SELECT ON  [dbo].[RPPLShared] TO [public]
GRANT INSERT ON  [dbo].[RPPLShared] TO [public]
GRANT DELETE ON  [dbo].[RPPLShared] TO [public]
GRANT UPDATE ON  [dbo].[RPPLShared] TO [public]
GRANT SELECT ON  [dbo].[RPPLShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPPLShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPPLShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPPLShared] TO [Viewpoint]
GO
