SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMPFListViewFill]
/****************************************************************************
 * Created By:	GF 01/11/2006
 * Modified By:	GF 07/29/2008 - issue #129182 added PMPM.SortName to resultset.
 *				GP 08/26/2008 - Issue 128425 added ExcludeYN = 'N' to where clause.
 *				GP 05/20/2009 - Issue 24641 rewrite to handle dynamically built select
 *									based on setup values in PMLS.
 *
 *
 *
 * USAGE:
 * Returns a resultset with information from the PM Project Firms for specified
 * PMCo and Project. Used in the PMPFListView form to populate list view.
 *
 * INPUT PARAMETERS:
 * PM Company, Project
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@pmco bCompany = null, @project bJob = null, @DocCat varchar(10) = null)
as
set nocount on

declare @rcode int

select @rcode = 0

declare @SQLString nvarchar(max), @SQLSelect nvarchar(max), @SQLFrom nvarchar(max),
	@Count int, @i int, @Column varchar(50), @ColumnAlias varchar(50), @Table varchar(50),
	@AliasChar char(2)

declare @PMLSTemp table ( 
	Seq int identity(1,1), 
	TableName varchar(50) not null,
	ColumnName varchar(50) not null,
	ColumnAlias varchar(max) null,
	KeyID bigint null)

--Setup select clause
set @SQLSelect = 'select a.FirmNumber as [Firm], b.FirmName as [Firm Name], a.ContactCode as [Contact], ' + 
	'isnull(c.SortName,' + char(39) + char(39) + ') as [Sort Name], ' +
	'isnull(c.FirstName,' + char(39) + char(39) + ') + ' + char(39) + ' ' + char(39) +  ' + isnull(c.MiddleInit,' + 
	char(39) + char(39) + ') + ' + char(39) + ' ' + char(39) +  ' + isnull(c.LastName,' + char(39) + char(39) + ') as [Contact Name]'

--Setup from clause
set @SQLFrom = ' FROM dbo.PMPF a ' +
'LEFT JOIN dbo.PMFM b with (nolock) ON b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber ' +
'LEFT JOIN dbo.PMPM c with (nolock) ON c.VendorGroup=a.VendorGroup and c.FirmNumber=a.FirmNumber and ' +
'c.ContactCode=a.ContactCode ' +
'where a.PMCo=' + cast(@pmco as varchar(5)) + ' and a.Project=' + char(39) + @project + char(39) + 
' and b.ExcludeYN = ' + char(39) + 'N' + char(39) + ' ' +
'order by a.PMCo, a.Project, a.VendorGroup, b.FirmName, c.LastName'

--Get info from PMLS
insert into @PMLSTemp(TableName, ColumnName, ColumnAlias, KeyID)
select TableName, ColumnName, ColumnAlias, KeyID
from PMLS with (nolock)
where DocCat = @DocCat and ColumnType <> 'Standard'
order by KeyID

--Add PMLS fields to select clause
select @Count = count(*) from @PMLSTemp
set @i = 1

while @Count >= @i
begin
	select @Column = ColumnName, @ColumnAlias = ColumnAlias, @Table = TableName from @PMLSTemp where Seq = @i
	select @AliasChar = case @Table when 'PMPF' then 'a.' when 'PMFM' then 'b.' when 'PMPM' then 'c.' end
	set @SQLSelect = @SQLSelect + ', ' + @AliasChar + @Column + ' as [' + isnull(@ColumnAlias, @Column) + ']'
	set @i = @i + 1
end

--Combine clauses
set @SQLString = @SQLSelect + @SQLFrom

--Execute select statement
execute sp_executesql @SQLString


--OLD CODE:
------ return resultset of PMPF firms and contacts to PMPFListView
--select  'Firm' = a.FirmNumber, 'Firm Name' = b.FirmName, 
--		'Contact' = a.ContactCode, 'Sort Name' = isnull(c.SortName,''),
--		'Contact Name'=isnull(c.FirstName,'') + ' ' + isnull(c.MiddleInit,'') + ' ' + isnull(c.LastName,'')
--FROM dbo.PMPF a
--LEFT JOIN dbo.PMFM b with (nolock) ON b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber
--LEFT JOIN dbo.PMPM c with (nolock) ON c.VendorGroup=a.VendorGroup and c.FirmNumber=a.FirmNumber and c.ContactCode=a.ContactCode
--where a.PMCo=@pmco and a.Project=@project and b.ExcludeYN = 'N'
--order by a.PMCo, a.Project, a.VendorGroup, b.FirmName, c.LastName


bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPFListViewFill] TO [public]
GO
