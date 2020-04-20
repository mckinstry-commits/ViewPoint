SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RPTYShared] AS
/***********************************************
* Created:
* Modified: GG 10/27/06
*			GG 06/20/07 - #124814 - remove UniqueAttchID
*
* Combines standard and custom Report Type information 
* from vRPTY and vRPTYc.
*
* Uses 'instead of triggers' to handle data modifications 
*
*******************************************/
SELECT ISNULL(c.ReportType, r.ReportType) AS ReportType,
		ISNULL(c.Description, r.Description) AS Description,
		ISNULL(c.Active, 'Y') AS Active, 
        CASE WHEN c.ReportType IS NULL and r.ReportType IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportType IS NOT NULL and r.ReportType IS NOT NULL THEN 'Override' 
				 WHEN c.ReportType IS NOT NULL and r.ReportType IS  NULL THEN 'Custom' 
				ELSE 'Unknown' END AS Status,
		CASE WHEN c.ReportType IS NULL THEN 'Y' ELSE 'N' END AS VPType,
  CASE WHEN c.ReportType IS NULL THEN 0 ELSE 1 END AS Custom
FROM dbo.vRPTYc AS c
FULL OUTER JOIN dbo.vRPTY AS r ON r.ReportType = c.ReportType


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPTYShared] on [dbo].[RPTYShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 10/24/06		
-- Modified:
--
-- Processes deletions to RPTYShared, a view combining standard
-- and custom report types, into their respective tables.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom Report Type entries regardless of login
delete dbo.vRPTYc
from deleted d
join vRPTYc t on t.ReportType = d.ReportType

-- if using 'viewpointcs' login remove standard Report Types as well
if suser_name() = 'viewpointcs'
	delete dbo.vRPTY
	from deleted d
	join dbo.vRPTY t on t.ReportType = d.ReportType

return

	




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPTYShared] on [dbo].[RPTYShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 10/24/06		
-- Modified:
--
-- Processes inserts to RPTYShared, a view combining standard
-- and custom report types, into their respective tables.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- if using the 'viewpointcs' login insert standard Report Types (vRPTY)
if suser_name() = 'viewpointcs'
	insert dbo.vRPTY(ReportType, Description)
	select ReportType, Description
	from inserted 
	where ReportType not in (select ReportType from dbo.vRPTY)	-- exclude existing Report Types 
else
	-- if logged in as anyone else insert custom Report Types (vRPTYc)	
	insert dbo.vRPTYc(ReportType, Description, Active)
	select ReportType, Description, Active
	from inserted 
	where ReportType not in (select ReportType from dbo.vRPTYc)	-- exclude existing Report Types 

return
	





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuRPTYShared] on [dbo].[RPTYShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: GG 10/24/06		
-- Modified: GG 04/10/07 - remove unecessary custom RPTYc entries
--
-- Processes updates to RPTYShared, a view combining standard
-- and custom report types into their respective tables.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- if using the 'viewpointcs' login update standard Report Types (vRPTY)
if suser_name() = 'viewpointcs'
	begin
	if update(Description)
		update dbo.vRPTY set Description = i.Description
		from inserted i
		join dbo.vRPTY t on t.ReportType = i.ReportType
	end
else
	-- if logged in as anyone else update custom Report Types (vRPTYc)
	begin
	if update(Description) or update(Active)
		begin
		-- add custom entries for those that don't exist 
		insert dbo.vRPTYc(ReportType)
		select ReportType
		from inserted 
		where ReportType not in (select ReportType from dbo.vRPTYc)	-- exclude existing Report Types 
		-- update custom info
		update dbo.vRPTYc set Description = i.Description, Active = i.Active
		from inserted i
		join dbo.vRPTYc t on t.ReportType = i.ReportType
		end
	end

-- remove any custom entries matching standard entries
delete dbo.vRPTYc
from dbo.vRPTYc c (nolock)
join dbo.vRPTY t (nolock) on c.ReportType = t.ReportType
	and isnull(c.Description,'') = isnull(t.Description,'')
where c.Active = 'Y'	-- all standard report types are active


return

	






GO
GRANT SELECT ON  [dbo].[RPTYShared] TO [public]
GRANT INSERT ON  [dbo].[RPTYShared] TO [public]
GRANT DELETE ON  [dbo].[RPTYShared] TO [public]
GRANT UPDATE ON  [dbo].[RPTYShared] TO [public]
GRANT SELECT ON  [dbo].[RPTYShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPTYShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPTYShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPTYShared] TO [Viewpoint]
GO
