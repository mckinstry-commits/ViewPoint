SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE      view [dbo].[DDLHShared]
/****************************************
 * Created: GG 06/09/03 
 * Modified: GG 07/13/04 - added GroupByClause
 *			GG 08/16/04 - added Version
 *
 * Combines standard and custom Lookup Header information
 * from vDDLH and vDDLHc
 *
 ****************************************/
as

select isnull(c.Lookup,l.Lookup) as Lookup,
	isnull(c.Title,l.Title) as Title,
	isnull(c.FromClause, l.FromClause) as FromClause,
	isnull(c.WhereClause,l.WhereClause) as WhereClause,
	isnull(c.JoinClause,l.JoinClause) as JoinClause,
	isnull(c.OrderByColumn,l.OrderByColumn) as OrderByColumn,
	isnull(c.Memo,l.Memo) as Memo,
	isnull(c.GroupByClause,l.GroupByClause) as GroupByClause,
	isnull(c.Version,l.Version) as Version,
--Modifed by Terry Lis 06/21/05 to show what lookups in frmRPParameterLookups are std and custom
    case when c.Lookup is Null then 'Viewpoint' else 'Custom' end as  Source
from dbo.vDDLHc c
full outer join dbo.vDDLH l on  l.Lookup = c.Lookup








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdDDLHShared] on [dbo].[DDLHShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: TEP 07/10/2007		
-- Modified:
--
-- Processes deletions to DDLHShared, a view combining standard
-- and custom lookups, into their respective tables.
--
-- Deleting any lookup removes its overridden or custom entry from vDDLHc.
-- When logged in as 'viewpointcs', standard lookups are deleted from vDDLH.
--
-- Delete triggers on vDDLH and vDDLHc perform cascading deletes to remove all
-- related data referencing the deleted standard or custom report.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom Lookups entries regardless of login
delete dbo.vDDLHc
from deleted d
join dbo.vDDLHc l on l.Lookup = d.Lookup

-- if using 'viewpointcs' login remove standard Lookups as well
if suser_name() = 'viewpointcs'
	begin
	delete dbo.vDDLH
	from deleted d
	join dbo.vDDLH l on l.Lookup = d.Lookup
	end

return
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiDDLHShared] on [dbo].[DDLHShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: TEP 07/09/2007		
-- Modified:
--
-- Processes inserts to DDLHShared, a view combining standard
-- and custom lookups into their respective tables.
--
-- Adding a standard lookup when logged in as 'viewpointcs' inserts vDDLH.
-- Standard lookups can only be added from the 'viewpointcs' login.
-- Adding a custom report inserts vDDLHc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- insert custom Lookups where Lookup <> starts with 'ud' when using 'viewpointcs' login
if suser_name() = 'viewpointcs'
	begin
	insert dbo.vDDLH(Lookup, Title, FromClause, WhereClause, JoinClause, OrderByColumn,
				Memo, GroupByClause, Version)
	select Lookup, Title, FromClause, WhereClause, JoinClause, OrderByColumn,
			Memo, GroupByClause, Version
	from inserted
	where SUBSTRING(Lookup,1,2) <> 'ud' and Lookup not in (select Lookup from dbo.vDDLH)
	end
-- insert custom Lookups where Lookup starts with = 'ud'
insert dbo.vDDLHc(Lookup, Title, FromClause, WhereClause, JoinClause, OrderByColumn,
				Memo, GroupByClause, Version)
select Lookup, Title, FromClause, WhereClause, JoinClause, OrderByColumn,
			Memo, GroupByClause, Version
from inserted
where SUBSTRING(Lookup,1,2) = 'ud' and Lookup not in (select Lookup from dbo.vDDLHc)

return


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuDDLHShared] on [dbo].[DDLHShared] INSTEAD OF UPDATE AS
-- ============================================
-- Created: TEP 07/10/2007		
-- Modified:
--
-- Processes updates to DDLHShared, a view combining standard
-- and custom lookups into their respective tables.
--
-- Updating a standard lookup when logged in as 'viewpointcs' updates vDDLH.
-- Updating a custom lookup updates vDDLHc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- handle standard Lookups (Lookup not starting with 'ud')
-- if using the 'viewpointcs' login update standard Lookups 
if suser_name() = 'viewpointcs'
	begin
	update dbo.vDDLH set Title = i.Title, FromClause = i.FromClause, 
		WhereClause = i.WhereClause, JoinClause = i.JoinClause, OrderByColumn = i.OrderByColumn,
		Memo = i.Memo, GroupByClause = i.GroupByClause, Version = i.Version
	from inserted i
	join dbo.vDDLH l on l.Lookup = i.Lookup
	where SUBSTRING(i.Lookup,1,2) <> 'ud'
	end	
-- update custom Lookups info regardless of login, records should already exist in vDDLHc
update dbo.vDDLHc set Title = i.Title, FromClause = i.FromClause, 
	WhereClause = i.WhereClause, JoinClause = i.JoinClause, OrderByColumn = i.OrderByColumn,
	Memo = i.Memo, GroupByClause = i.GroupByClause, Version = i.Version
from inserted i
join dbo.vDDLHc l on l.Lookup = i.Lookup
where SUBSTRING(i.Lookup,1,2) = 'ud'

return



GO
GRANT SELECT ON  [dbo].[DDLHShared] TO [public]
GRANT INSERT ON  [dbo].[DDLHShared] TO [public]
GRANT DELETE ON  [dbo].[DDLHShared] TO [public]
GRANT UPDATE ON  [dbo].[DDLHShared] TO [public]
GO
