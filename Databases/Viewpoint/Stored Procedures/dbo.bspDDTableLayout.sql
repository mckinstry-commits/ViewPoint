SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDTableLayout    Script Date: 8/28/99 9:32:39 AM ******/
   CREATE  proc [dbo].[bspDDTableLayout] (@modtable varchar(30)=null)

/* written by jim emery										*
* Modified by:	TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*
* used to retrieve all information about a table(s)		*
* pass in either a module or a table name					*/

as
set nocount on
declare @length tinyint
select @length=datalength(@modtable)


if @length=0
return
   
SELECT
'TableName'=sysobjects.name,
'Colid'=syscolumns.colid, 'ColName'=syscolumns.name, 'TypeName'=systypes.name,
'ColLen'=syscolumns.length,
'ColDefault'=case isnull(syscolumns.cdefault, 0) when 0 then ''
	else (select sysobjects3.name
		from sysobjects sysobjects3
		where syscolumns.cdefault+syscolumns.domain=sysobjects3.id) End,
'VarLen'= case isnull(systypes.variable, 0) when 0 then 'N'	else 'Y' end,
'Domain'= case isnull(syscolumns.domain, 0) when 0 then ''
	else (select sysobjects2.name
	from sysobjects sysobjects2
	where syscolumns.cdefault+syscolumns.domain=sysobjects2.id) End,
'NullOpt'=case syscolumns.scale when 0 then 'Not Null' else 'Null' end
into #Layout
FROM syscolumns syscolumns, sysobjects sysobjects, systypes systypes
WHERE syscolumns.usertype = systypes.usertype
AND syscolumns.type = systypes.type
AND sysobjects.id = syscolumns.id
AND SubString(sysobjects.name,1,@length)=@modtable
order by sysobjects.name, syscolumns.colid
select * from #Layout


GO
GRANT EXECUTE ON  [dbo].[bspDDTableLayout] TO [public]
GO
