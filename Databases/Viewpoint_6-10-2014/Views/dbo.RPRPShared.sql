SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RPRPShared] AS
/***********************************************
* Created:
* Modified: GG 10/27/06
*			GG 06/20/07 - #124814 - removed UniqueAttchID
*			GG 06/20/07 - #123500 - added DefaultType for active info
*
* Combines standard and custom Report Parameter information 
* from vRPRP and vRPRPc.
*
* Uses 'instead of triggers' to handle data modifications 
*
*******************************************/
SELECT	ISNULL(c.ReportID, p.ReportID) AS ReportID,
		ISNULL(c.ParameterName, p.ParameterName) AS ParameterName,
		ISNULL(c.DisplaySeq, p.DisplaySeq) AS DisplaySeq,
		ISNULL(c.ReportDatatype, p.ReportDatatype) AS ReportDatatype,
		ISNULL(c.Datatype, p.Datatype) AS Datatype,
		ISNULL(c.ActiveLookup, p.ActiveLookup) AS ActiveLookup,
		ISNULL(c.LookupParams, p.LookupParams) AS LookupParams, 
		ISNULL(c.LookupSeq, p.LookupSeq) AS LookupSeq, 
        ISNULL(c.Description, p.Description) AS Description,
		case when ISNULL(c.ParameterDefault, p.ParameterDefault) is null then null
			when substring(ISNULL(c.ParameterDefault, p.ParameterDefault),1,2) = '%D' then 1
			when substring(ISNULL(c.ParameterDefault, p.ParameterDefault),1,2) = '%M' then 2
			when substring(ISNULL(c.ParameterDefault, p.ParameterDefault),1,3) = '%RP' then 3
			when substring(ISNULL(c.ParameterDefault, p.ParameterDefault),1,3) = '%FI' then 4
			when ISNULL(c.ParameterDefault, p.ParameterDefault) = '%C' then 5
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%PROJECT' then 6
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%JOB' then 7
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%CONTRACT' then 8
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%PRGROUP' then 9
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%PRENDDATE' then 10
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%JBPROGMTH' then 11
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%JBPROGBILL' then 12
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%JBTMMTH' then 13
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%JBTMBILL' then 14
			when upper(ISNULL(c.ParameterDefault, p.ParameterDefault)) = '%RAC' then 15
			else 0 end as DefaultType,
		ISNULL(c.ParameterDefault, p.ParameterDefault) AS ParameterDefault,
		ISNULL(c.InputType, p.InputType) AS InputType,
		ISNULL(c.InputMask, p.InputMask) AS InputMask,
		ISNULL(c.InputLength, p.InputLength) AS InputLength,
		ISNULL(c.Prec, p.Prec) AS Prec,
		ISNULL(c.ParamRequired, p.ParamRequired) AS ParamRequired,
		CASE WHEN c.ReportID IS NULL THEN 0 ELSE 1 END AS Custom,
		CASE WHEN c.ReportID IS NULL and p.ReportID IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportID IS NOT NULL and p.ReportID IS NOT NULL THEN 'Override' 
				 WHEN c.ReportID IS NOT NULL and p.ReportID IS  NULL THEN 'Custom' 
				ELSE 'Unknown' END AS Status,
		ISNULL(c.PortalParameterDefault, p.PortalParameterDefault) AS PortalParameterDefault,
		ISNULL(c.PortalAccess, p.PortalAccess) AS PortalAccess
FROM dbo.vRPRPc AS c
FULL OUTER JOIN dbo.vRPRP AS p ON p.ReportID = c.ReportID AND p.ParameterName = c.ParameterName



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPRPShared] on [dbo].[RPRPShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 10/26/06		
-- Modified:
--
-- Processes deletions to RPRPShared, a view combining standard
-- and custom report parameters, into their respective tables.
--
-- Deleting any report parameter removes its overridden or custom entry from vPRRPc.
-- When logged in as 'viewpointcs', standard report parameters are deleted from vRPRP.
--
-- Delete triggers on vRPRP and vRPRPc perform cascading deletes to remove all
-- related data referencing the deleted standard or custom report parameters.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom report parameter entries regardless of login
delete dbo.vRPRPc
from deleted d
join dbo.vRPRPc p on p.ReportID = d.ReportID and p.ParameterName = d.ParameterName

-- if using 'viewpointcs' login remove standard report parameters as well
if suser_name() = 'viewpointcs'
	delete dbo.vRPRP
	from deleted d
	join dbo.vRPRP p on p.ReportID = d.ReportID and p.ParameterName = d.ParameterName

return

	







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPRPShared] on [dbo].[RPRPShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 10/26/06		
-- Modified: 
--
-- Processes inserts to RPRPShared, a view combining standard
-- and custom report parameters, into their respective tables.
--
-- Adding parameters to a standard report when logged in as 'viewpointcs' inserts vRPRP.
-- Parameters on a standard report can only be added from the 'viewpointcs' login.
-- Adding parameters to a custom report inserts vRPRPc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- insert standard report parameters for report id#s < 10000 when using 'viewpointcs' login
if suser_name() = 'viewpointcs'
	insert dbo.vRPRP(ReportID, ParameterName, DisplaySeq, ReportDatatype, Datatype, ActiveLookup,
		LookupParams, LookupSeq, Description, ParameterDefault, InputType, InputMask, InputLength, Prec, ParamRequired)
	select i.ReportID, i.ParameterName, i.DisplaySeq, i.ReportDatatype, i.Datatype, i.ActiveLookup,
		i.LookupParams, i.LookupSeq, i.Description, i.ParameterDefault, i.InputType, i.InputMask, i.InputLength, i.Prec, i.ParamRequired
	from inserted i
	left join dbo.vRPRP p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	where i.ReportID < 10000 and p.ReportID is null -- exclude existing entries

-- insert custom report parameters for report id#s > 9999, regardless of login
insert dbo.vRPRPc(ReportID, ParameterName, DisplaySeq, ReportDatatype, Datatype, ActiveLookup,
	LookupParams, LookupSeq, Description, ParameterDefault, InputType, InputMask, InputLength, Prec, ParamRequired)
select i.ReportID, i.ParameterName, i.DisplaySeq, i.ReportDatatype, i.Datatype, i.ActiveLookup,
	i.LookupParams, i.LookupSeq, i.Description, i.ParameterDefault, i.InputType, i.InputMask, i.InputLength, i.Prec, i.ParamRequired
from inserted i
left join dbo.vRPRPc p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
where i.ReportID > 9999 and p.ReportID is null	-- exclude existing entries

return
	







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtuRPRPShared] on [dbo].[RPRPShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: GG 10/26/06		
-- Modified: GG 04/10/07 - remove unecessary custom RPRPc entries
-- Modified: JVH 04/29/08 - corrected evaluation of integer fields
--
-- Processes updates to RPRPShared, a view combining standard
-- and custom report parameters into their respective tables.
--
-- Updating parameters on a standard report when logged in as 'viewpointcs' updates vRPRP.
-- Updating parameters on a standard report from other logins insert/updates an override entry in vRPRPc.
-- Updating parameters on a custom report updates vRPRPc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- handle parameters for standard reports (report id#s < 10000)
-- if using the 'viewpointcs' login update standard parameter info
if suser_name() = 'viewpointcs'
	update dbo.vRPRP set DisplaySeq = i.DisplaySeq, ReportDatatype = i.ReportDatatype, Datatype = i.Datatype,
		ActiveLookup = i.ActiveLookup, LookupParams = i.LookupParams, LookupSeq = i.LookupSeq,
		Description = i.Description, ParameterDefault = i.ParameterDefault, InputType = i.InputType,
		InputMask = i.InputMask, InputLength = i.InputLength, Prec = i.Prec, ParamRequired = i.ParamRequired,
		PortalParameterDefault = i.PortalParameterDefault, PortalAccess = i.PortalAccess
	from inserted i
	join dbo.vRPRP p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
	where i.ReportID < 10000 
else
	-- limited updates allowed to standard report parameters when using other logins
	if update(DisplaySeq) or update(ActiveLookup) or update(LookupSeq) or
		update(Description) or update(ParameterDefault) or update(PortalParameterDefault) or update(PortalAccess)
		begin
		-- add override records for standard parameters not already in vRPRPc
		insert dbo.vRPRPc(ReportID, ParameterName)
		select i.ReportID, i.ParameterName
		from inserted i
		left join dbo.vRPRPc p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
		where i.ReportID < 10000 and p.ReportID is null	-- exclude existing entries
		-- update override info
		update dbo.vRPRPc set DisplaySeq = i.DisplaySeq, ActiveLookup = i.ActiveLookup, LookupSeq = i.LookupSeq,
			Description = i.Description, ParameterDefault = i.ParameterDefault, ParamRequired = i.ParamRequired,
			PortalParameterDefault = i.PortalParameterDefault, PortalAccess = i.PortalAccess
		from inserted i
		join dbo.vRPRPc p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
		where i.ReportID < 10000
		-- remove any custom entries matching standard entries
		delete dbo.vRPRPc
		from dbo.vRPRPc c (nolock)
		join dbo.vRPRP p (nolock) on c.ReportID = p.ReportID and c.ParameterName = p.ParameterName
		where isnull(c.DisplaySeq,p.DisplaySeq) = p.DisplaySeq
			and isnull(c.ActiveLookup,isnull(p.ActiveLookup,'')) = isnull(p.ActiveLookup,'')
			and isnull(c.Description,isnull(p.Description,'')) = isnull(p.Description,'')
			and isnull(c.ParameterDefault,isnull(p.ParameterDefault,'')) = isnull(p.ParameterDefault,'')
			and isnull(c.ParamRequired,isnull(p.ParamRequired,'')) = isnull(p.ParamRequired,'')
			and isnull(c.PortalParameterDefault, isnull(p.PortalParameterDefault,'')) = isnull(p.PortalParameterDefault,'')
			-- This syntax does not work for integers because if the value for the custom column is 0 and the value for the standard column is null then this evaluates as true
			--and isnull(c.PortalAccess, isnull(p.PortalAccess,'')) = isnull(p.PortalAccess,'')
			-- The line below could be made into a function quite easily to simplify all checks like these.
			and (c.PortalAccess is null and p.PortalAccess is null or c.PortalAccess = p.PortalAccess)
			and c.ReportID < 10000
		end

-- handle parameters for custom reports (report id#s > 9999)
-- update custom parameters regardless of login, records should already exist in vRPRPc
update dbo.vRPRPc set DisplaySeq = i.DisplaySeq, ReportDatatype = i.ReportDatatype, Datatype = i.Datatype,
	ActiveLookup = i.ActiveLookup, LookupParams = i.LookupParams, LookupSeq = i.LookupSeq,
	Description = i.Description, ParameterDefault = i.ParameterDefault, InputType = i.InputType,
	InputMask = i.InputMask, InputLength = i.InputLength, Prec = i.Prec, ParamRequired = i.ParamRequired,
	PortalParameterDefault = i.PortalParameterDefault, PortalAccess = i.PortalAccess
from inserted i
join dbo.vRPRPc p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
where i.ReportID > 9999


return
GO
GRANT SELECT ON  [dbo].[RPRPShared] TO [public]
GRANT INSERT ON  [dbo].[RPRPShared] TO [public]
GRANT DELETE ON  [dbo].[RPRPShared] TO [public]
GRANT UPDATE ON  [dbo].[RPRPShared] TO [public]
GRANT SELECT ON  [dbo].[RPRPShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRPShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRPShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRPShared] TO [Viewpoint]
GO
