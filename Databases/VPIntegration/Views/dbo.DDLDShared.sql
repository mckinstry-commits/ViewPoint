SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  view [dbo].[DDLDShared]
/****************************************
 * Created: 06/10/03 GG
 * Modified:
 *
 * Combines standard and custom Lookup Detail information
 * from vDDLD and vDDLDc
 *
 ****************************************/
as

select isnull(c.Lookup,l.Lookup) as Lookup,
	isnull(c.Seq,l.Seq) as Seq,
	isnull(c.ColumnName,l.ColumnName) as ColumnName,
	isnull(c.ColumnHeading, l.ColumnHeading) as ColumnHeading,
	isnull(c.Hidden,l.Hidden) as Hidden,
	isnull(c.Datatype,l.Datatype) as Datatype,
	isnull(c.InputType,l.InputType) as InputType,
	isnull(c.InputLength,l.InputLength) as InputLength,
	isnull(c.InputMask,l.InputMask) as InputMask,
	isnull(c.Prec,l.Prec) as Prec
from dbo.vDDLDc c
full outer join dbo.vDDLD l on  l.Lookup = c.Lookup and l.Seq = c.Seq








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdDDLDShared] on [dbo].[DDLDShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: TEP 07/11/2007		
-- Modified:
--
-- Processes deletions to DDLDShared, a view combining standard
-- and custom lookups details, into their respective tables.
--
-- Deleting any lookup details removes the overridden or custom entry from vDDLDc.
-- When logged in as 'viewpointcs', standard lookups detail are deleted from vDDLD.
--
-- Delete triggers on vDDLD and vDDLDc perform cascading deletes to remove all
-- related data referencing the deleted standard or custom report.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom Lookups detail entries regardless of login
delete vDDLDc
from deleted d
join vDDLDc l on l.Lookup = d.Lookup AND l.Seq = d.Seq

-- if using 'viewpointcs' login remove standard Lookups as well
if suser_name() = 'viewpointcs'
	delete vDDLD
	from deleted d
	join vDDLD l on l.Lookup = d.Lookup AND l.Seq = d.Seq

return



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiDDLDShared] on [dbo].[DDLDShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: TEP 07/11/2007		
-- Modified:
--
-- Processes inserts to DDLDShared, a view combining standard
-- and custom lookups details, into their respective tables.
--
-- Adding a standard lookup details when logged in as 'viewpointcs' inserts vDDLD.
-- Standard lookups details can only be added from the 'viewpointcs' login.
-- Adding a custom report inserts vDDLDc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- insert custom Lookups detail where Lookup <> starts with 'ud' when using 'viewpointcs' login
if suser_name() = 'viewpointcs'
begin
	insert vDDLD(Lookup, Seq, ColumnName, ColumnHeading,Hidden,
					Datatype, InputType, InputLength, InputMask, Prec)
	select Lookup, Seq, ColumnName, ColumnHeading,Hidden,
			Datatype, InputType, InputLength, InputMask, Prec
	from inserted
	where SUBSTRING(Lookup,1,2) <> 'ud'
end
-- insert custom Lookups detail where Lookup starts with = 'ud'
insert vDDLDc(Lookup, Seq, ColumnName, ColumnHeading,Hidden,
					Datatype, InputType, InputLength, InputMask, Prec)
	select Lookup, Seq, ColumnName, ColumnHeading,Hidden,
			Datatype, InputType, InputLength, InputMask, Prec
from inserted
where SUBSTRING(Lookup,1,2) = 'ud'

return



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuDDLDShared] on [dbo].[DDLDShared] INSTEAD OF UPDATE AS
-- ============================================
-- Created: TEP 07/11/2007		
-- Modified: TEP 11/08/2007 - Issue #125950 - Added 'AND l.Seq = i.Seq' to both updates
--
-- Processes updates to DDLDShared, a view combining standard
-- and custom lookups details into their respective tables.
--
-- Updating a standard lookup details when logged in as 'viewpointcs' updates vDDLD.
-- Updating a custom lookup details updates vDDLDc regardless of login.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- handle standard Lookups detail(Lookup not starting with 'ud')
-- if using the 'viewpointcs' login update standard Lookups details
if suser_name() = 'viewpointcs'
	begin
		update vDDLD set ColumnName = i.ColumnName, 
				ColumnHeading = i.ColumnHeading, Hidden = i.Hidden, Datatype = i.Datatype,
				InputType = i.InputType, InputLength = i.InputLength, InputMask = i.InputMask, 
				Prec = i.Prec
		from inserted i
		join vDDLD l on l.Lookup = i.Lookup AND l.Seq = i.Seq
		where SUBSTRING(i.Lookup,1,2) <> 'ud'
	end	
-- handle custom Lookups details(Lookup not starting with 'ud')
-- update custom Lookups details info regardless of login, records should already exist in vDDLHc
update vDDLDc set ColumnName = i.ColumnName, 
			ColumnHeading = i.ColumnHeading, Hidden = i.Hidden, Datatype = i.Datatype,
			InputType = i.InputType, InputLength = i.InputLength, InputMask = i.InputMask, 
			Prec = i.Prec
from inserted i
join vDDLDc l on l.Lookup = i.Lookup AND l.Seq = i.Seq
where SUBSTRING(i.Lookup,1,2) = 'ud'

return




GO
GRANT SELECT ON  [dbo].[DDLDShared] TO [public]
GRANT INSERT ON  [dbo].[DDLDShared] TO [public]
GRANT DELETE ON  [dbo].[DDLDShared] TO [public]
GRANT UPDATE ON  [dbo].[DDLDShared] TO [public]
GO
