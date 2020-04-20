SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RPFDShared] AS
/***********************************************
* Created:
* Modified: GG 10/27/06
*			GG 06/20/07 - #123500 - added DefaultType for active info
*
* Combines standard and custom Form Report Parameter Defaults 
* from vRPFD and vRPFDc.
*
* Uses 'instead of triggers' to handle data modifications 
*
*******************************************/
SELECT	ISNULL(c.Form, d.Form) AS Form,
		ISNULL(c.ReportID, d.ReportID) AS ReportID,
		ISNULL(c.ParameterName, d.ParameterName) AS ParameterName,
		case when ISNULL(c.ParameterDefault, d.ParameterDefault) is null then null
			when substring(ISNULL(c.ParameterDefault, d.ParameterDefault),1,2) = '%D' then 1
			when substring(ISNULL(c.ParameterDefault, d.ParameterDefault),1,2) = '%M' then 2
			when substring(ISNULL(c.ParameterDefault, d.ParameterDefault),1,3) = '%RP' then 3
			when substring(ISNULL(c.ParameterDefault, d.ParameterDefault),1,3) = '%FI' then 4
			when ISNULL(c.ParameterDefault, d.ParameterDefault) = '%C' then 5
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%PROJECT' then 6
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%JOB' then 7
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%CONTRACT' then 8
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%PRGROUP' then 9
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%PRENDDATE' then 10
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%JBPROGMTH' then 11
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%JBPROGBILL' then 12
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%JBTMMTH' then 13
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%JBTMBILL' then 14
			when upper(ISNULL(c.ParameterDefault, d.ParameterDefault)) = '%RAC' then 15
			else 0 end as DefaultType,
        ISNULL(c.ParameterDefault, d.ParameterDefault) AS ParameterDefault,
		CASE WHEN c.ReportID IS NOT NULL THEN 1 ELSE 0 END AS Custom, 
       		CASE WHEN c.ReportID IS NULL and d.ReportID IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportID IS NOT NULL and d.ReportID IS NOT NULL THEN 'Override' 
				 WHEN c.ReportID IS NOT NULL and d.ReportID IS  NULL THEN 'Custom' 
				ELSE null END AS Status
FROM dbo.vRPFDc AS c
FULL OUTER JOIN dbo.vRPFD AS d ON d.Form = c.Form AND d.ReportID = c.ReportID
	and d.ParameterName = c.ParameterName

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPFDShared] on [dbo].[RPFDShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 10/30/06		
-- Modified:
--
-- Processes deletions to RPFDShared, a view combining standard
-- and custom report parameter defaults, into their respective tables.
--
-- When logged in as 'viewpointcs', standard report parameter defaults are deleted
-- from vRPFD, and custom defaults are removed from vRPFDc only if they have no 
-- corresponding standard entry.
--
-- All other logins delete custom report parameter defaults only.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will delete custom and standard report parameter defaults
if suser_name() = 'viewpointcs'
	begin
	-- remove custom parameter defaults only if they have no corresponding standard entry
	delete dbo.vRPFDc
	from deleted d
	left join dbo.vRPFD f on f.Form = d.Form and f.ReportID = d.ReportID and f.ParameterName = d.ParameterName
	where f.Form is null 
	-- remove any existing standard defaults
	delete dbo.vRPFD
	from deleted d
	join dbo.vRPFD f on f.Form = d.Form and f.ReportID = d.ReportID and f.ParameterName = d.ParameterName
	end
else
	-- all other logins, remove existing custom parameter defaults only
	delete dbo.vRPFDc
	from deleted d
	join dbo.vRPFDc f on f.Form = d.Form and f.ReportID = d.ReportID and f.ParameterName = d.ParameterName
	

return

	








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPFDShared] on [dbo].[RPFDShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 10/30/06		
-- Modified:
--
-- Processes inserts to RPFDShared, a view combining standard
-- and custom form based report parameter defaults, into their respective tables.
--
-- When using the 'viewpointcs' login, adding parameter defaults to standard form/reports
-- will insert entries in vRPFD.  Parameter defaults added to non-standard form/reports will
-- be inserted as custom entries in vRPFDc.
--
-- Adding parameter defaults for any other login inserts custom entries in vRPFDc.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will insert custom and standard report parameter defaults
if suser_name() = 'viewpointcs'
	begin
	-- insert standard parameter defaults for standard form/reports
	insert dbo.vRPFD(Form, ReportID, ParameterName, ParameterDefault)
	select i.Form, i.ReportID, i.ParameterName, i.ParameterDefault
	from inserted i
	join dbo.vRPFR r (nolock) on r.Form = i.Form and r.ReportID = i.ReportID	-- holds standard form/report combinations
	left join dbo.vRPFD p on p.Form = i.Form and p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	where p.ReportID is null -- exclude existing entries
	-- insert custom parameter defaults for non-standard form/reports
	insert dbo.vRPFDc(Form, ReportID, ParameterName, ParameterDefault)
	select i.Form, i.ReportID, i.ParameterName, i.ParameterDefault
	from inserted i
	left join dbo.vRPFR r (nolock) on r.Form = i.Form and r.ReportID = i.ReportID
	left join dbo.vRPFDc p on p.Form = i.Form and p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	where r.ReportID is null and p.ReportID is null -- exclude standard form/reports and existing entries
	end
else
	-- insert custom report parameter defaults for all other logins
	insert dbo.vRPFDc(Form, ReportID, ParameterName, ParameterDefault)
	select i.Form, i.ReportID, i.ParameterName, i.ParameterDefault
	from inserted i
	left join dbo.vRPFDc p on p.Form = i.Form and p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	where p.ReportID is null -- exclude existing entries

return
	










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuRPFDShared] on [dbo].[RPFDShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: GG 10/30/06		
-- Modified: GG 04/06/07 - remove unecessary custom RPFDc entries
--			 CC 02/09/10 - #137286 - corrected viewpointcs update statement for vRPFDc, join custom table 
--								with inserted table before joining standard table to eliminate unrelated entries.
--
-- Processes updates to RPFDShared, a view combining standard
-- and custom report parameter defaults, into their respective tables.
--
-- When using the 'viewpointcs' login, updating parameter defaults with standard entries
-- will update vRPFD.  Custom defaults will update vRPFDc only if they have no corresponding
-- standard entry, to prevent overwritting custom info.
--
-- Updating parameter defaults for any other login inserts/updates custom entries in vRPFDc.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- 'viewpointcs' login will update standard and custom report parameter defaults
if suser_name() = 'viewpointcs'
	begin
		-- update existing standard defaults
		update dbo.vRPFD set ParameterDefault = i.ParameterDefault
		from inserted i
		join dbo.vRPFD d on d.Form = i.Form and d.ReportID = i.ReportID and d.ParameterName = i.ParameterName;
		
		-- update existing custom defaults without standard entries
		update dbo.vRPFDc set ParameterDefault = i.ParameterDefault
		from dbo.vRPFDc
		INNER JOIN inserted i ON i.Form = vRPFDc.Form AND i.ReportID = vRPFDc.ReportID AND i.ParameterName = vRPFDc.ParameterName
		left join dbo.vRPFD d (nolock) on d.Form = i.Form and d.ReportID = i.ReportID and d.ParameterName = i.ParameterName
		where d.ReportID is NULL;	-- exclude parameter defaults with standard entries
	end
else
	-- insert/update custom report parameter defaults from all other logins
	if update(ParameterDefault)
		begin
			-- add override records for standard parameters not already in vRPFDc
			insert dbo.vRPFDc(Form, ReportID, ParameterName, ParameterDefault)
			select i.Form, i.ReportID, i.ParameterName, i.ParameterDefault
			from inserted i
			left join dbo.vRPFDc d on d.Form = i.Form and d.ReportID = i.ReportID and d.ParameterName = i.ParameterName
			where d.ReportID is NULL;	-- exclude existing entries
			
			-- update override info
			update dbo.vRPFDc set ParameterDefault = i.ParameterDefault
			from inserted i
			join dbo.vRPFDc d on d.Form = i.Form and d.ReportID = i.ReportID and d.ParameterName = i.ParameterName;
		end

-- remove any custom entries matching standard entries
delete dbo.vRPFDc
from dbo.vRPFDc c (nolock)
join dbo.vRPFD f (nolock) on c.Form = f.Form and c.ReportID = f.ReportID 
	and c.ParameterName = f.ParameterName and c.ParameterDefault = f.ParameterDefault;

return







GO
GRANT SELECT ON  [dbo].[RPFDShared] TO [public]
GRANT INSERT ON  [dbo].[RPFDShared] TO [public]
GRANT DELETE ON  [dbo].[RPFDShared] TO [public]
GRANT UPDATE ON  [dbo].[RPFDShared] TO [public]
GO
