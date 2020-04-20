SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE view [dbo].[DDSLShared]
/****************************************
 * Created: GG 07/31/03 
 * Modified: GG 05/04/07 - added Status
 *			 JonathanP 021/16/09 - See issue #129835. I've added the InUseState and ViewIsOutOfSync columns.
 *
 * Combines standard and custom Security Links
 * from vDDSL and vDDSLc
 *
 ****************************************/
as


select a.*, 
	   case when s.TABLE_NAME is null then 'N' else 'Y' end as InUseState,
	   dbo.vfVAViewGenViewOutOfSync(substring(TableName, 2, len(TableName)), TableName) as ViewIsOutOfSync from
	(select isnull(c.TableName,l.TableName) as TableName,
			isnull(c.Datatype,l.Datatype) as Datatype,
			isnull(c.InstanceColumn,l.InstanceColumn) as InstanceColumn, 
			isnull(c.QualifierColumn,l.QualifierColumn) as QualifierColumn,
			isnull(c.InUse, l.InUse) as InUse,
			case when c.TableName is null and l.TableName is not null then 'Standard' 
				when c.TableName is not null and l.TableName is not null then 'Override' 
				when c.TableName is not null and l.TableName is null then 'Custom' end as Status		
		from dbo.vDDSLc c (nolock)
		full outer join dbo.vDDSL l (nolock) on  l.TableName = c.TableName and l.Datatype = c.Datatype
			and l.InstanceColumn = c.InstanceColumn) a
						
	left outer join INFORMATION_SCHEMA.VIEWS s with (nolock)
		on s.TABLE_NAME = substring(a.TableName, 2, len(a.TableName)) and
		   s.VIEW_DEFINITION like '%vDDDU %' 
		 --s.VIEW_DEFINITION like '%' + a.Datatype + '%' and s.VIEW_DEFINITION like '%' + a.InstanceColumn + '%'
		   
	left outer join INFORMATION_SCHEMA.VIEWS v with (nolock)
		on v.TABLE_NAME = s.TABLE_NAME and
		   v.VIEW_DEFINITION like '%' + a.Datatype + '%' and v.VIEW_DEFINITION like '%' + a.InstanceColumn + '%'	


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdDDSLShared] on [dbo].[DDSLShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 05/04/07		
-- Modified:
--
-- Processes deletions to DDSLShared, a view combining standard
-- and custom security links into their respective tables.
--
-- Deleting any security link removes its overridden or custom entry from vDDSLc.
-- When logged in as 'viewpointcs', standard security links are deleted from vDDSL.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom security links regardless of login
delete dbo.vDDSLc
from deleted d
join dbo.vDDSLc s on s.TableName = d.TableName and s.Datatype = d.Datatype and s.InstanceColumn = d.InstanceColumn 

-- if using 'viewpointcs' login remove standard standard security links as well
if suser_name() = 'viewpointcs'
	delete dbo.vDDSL
	from deleted d
	join dbo.vDDSL s on s.TableName = d.TableName and s.Datatype = d.Datatype and s.InstanceColumn = d.InstanceColumn 

return

	







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiDDSLShared] on [dbo].[DDSLShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 05/04/07		
-- Modified:
--
-- Processes inserts to DDSLShared, a view combining standard
-- and custom security links into their respective tables.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- if using the 'viewpointcs' login insert standard Security Links (vDDSL)
if suser_name() = 'viewpointcs'
	insert dbo.vDDSL(TableName, Datatype, InstanceColumn, QualifierColumn, InUse)
	select i.TableName, i.Datatype, i.InstanceColumn, i.QualifierColumn, i.InUse
	from inserted i
	left join dbo.vDDSL s on s.TableName = i.TableName and s.Datatype = i.Datatype and s.InstanceColumn = i.InstanceColumn 
	where s.TableName is null -- exclude existing 
else
	-- if logged in as anyone else insert custom Security Links (vDDSLc)	
	insert dbo.vDDSLc(TableName, Datatype, InstanceColumn, QualifierColumn, InUse)
	select i.TableName, i.Datatype, i.InstanceColumn, i.QualifierColumn, i.InUse
	from inserted i
	left join dbo.vDDSLc s on s.TableName = i.TableName and s.Datatype = i.Datatype and s.InstanceColumn = i.InstanceColumn 
	where s.TableName is null -- exclude existing 

return
	





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuDDSLShared] on [dbo].[DDSLShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: GG 05/04/07	
-- Modified: 
--
-- Processes updates to DDSLShared, a view combining standard
-- and custom security links into their respective tables.
--
-- Updating standard security links when logged in as 'viewpointcs' updates vDDSL.
-- Updating custom security links when logged in as 'viewpointcs' updates vDDSLc.
-- Updating custom or overridden security links from other logins insert/updates an override entry in vDDSLc.
-- Removes vDDSLc entries that match standard vDDSL to clenup unecessary entries
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- if using the 'viewpointcs' login update standard and custom security links
if suser_name() = 'viewpointcs'
	begin
	-- update standard security links
	update dbo.vDDSL set QualifierColumn = i.QualifierColumn, InUse = i.InUse
	from inserted i
	join dbo.vDDSL s on s.TableName = i.TableName and s.Datatype = i.Datatype and s.InstanceColumn = i.InstanceColumn 
	-- update custom security links
	update dbo.vDDSLc set QualifierColumn = i.QualifierColumn, InUse = i.InUse
	from inserted i
	join dbo.vDDSLc s on s.TableName = i.TableName and s.Datatype = i.Datatype and s.InstanceColumn = i.InstanceColumn 
	left join dbo.vDDSL l on l.TableName = i.TableName and l.Datatype = i.Datatype and l.InstanceColumn = i.InstanceColumn
	where l.TableName is null	-- exclude if link exists as a standard entry 
	end
else
	-- update overridden and custom security links when using other logins
	begin
	-- add override for standard security links not already in vDDSLc
	insert dbo.vDDSLc(TableName, Datatype, InstanceColumn, QualifierColumn, InUse)
	select i.TableName, i.Datatype, i.InstanceColumn, i.QualifierColumn, i.InUse
	from inserted i
	left join dbo.vDDSLc s on s.TableName = i.TableName and s.Datatype = i.Datatype and s.InstanceColumn = i.InstanceColumn 
	where s.TableName is null	-- exclude existing entries
	-- update override info
	update dbo.vDDSLc set QualifierColumn = i.QualifierColumn, InUse = i.InUse
	from inserted i
	join dbo.vDDSLc s on s.TableName = i.TableName and s.Datatype = i.Datatype and s.InstanceColumn = i.InstanceColumn
	end

-- remove any custom entries matching standard entries
delete dbo.vDDSLc
from dbo.vDDSLc c (nolock)
join dbo.vDDSL s (nolock) on s.TableName = c.TableName and s.Datatype = c.Datatype and s.InstanceColumn = c.InstanceColumn 
where isnull(c.QualifierColumn,isnull(s.QualifierColumn,'')) = isnull(s.QualifierColumn,'')
	and isnull(c.InUse,isnull(s.InUse,'')) = isnull(s.InUse,'')

return





GO
GRANT SELECT ON  [dbo].[DDSLShared] TO [public]
GRANT INSERT ON  [dbo].[DDSLShared] TO [public]
GRANT DELETE ON  [dbo].[DDSLShared] TO [public]
GRANT UPDATE ON  [dbo].[DDSLShared] TO [public]
GO
