use Viewpoint
go

declare @FormName	varchar(50)
set @FormName = 'PMSLHeader'

select 
	Form
, Seq
, Custom
, Status
, ShowGrid
, GridCol
,GridColHeading
,CustomGridColHeading
, ViewName
, ColumnName
, ColWidth
,  Description
, DescriptionColumn
, DescriptionColWidth 
from 
	DDFIShared 
where 
	Form = @FormName 
order by 
	ShowGrid DESC
,	coalesce(GridCol, Seq)

select * from DDUI where Form=@FormName and upper(VPUserName)='MCKINSTRY\BILLO'

set @FormName = 'PMSubcontractCO'

select 
	Form
, Seq
, Custom
, Status
, ShowGrid
, GridCol
,GridColHeading
,CustomGridColHeading
, ViewName
, ColumnName
, ColWidth
,  Description
, DescriptionColumn
, DescriptionColWidth 
from 
	DDFIShared 
where 
	Form = @FormName 
order by 
	ShowGrid DESC
,	coalesce(GridCol, Seq)

select * from DDUI where Form=@FormName and upper(VPUserName)='MCKINSTRY\BILLO'

set @FormName = 'udMSA'

select 
	Form
, Seq
, Custom
, Status
, ShowGrid
, GridCol
,GridColHeading
,CustomGridColHeading
, ViewName
, ColumnName
, ColWidth
,  Description
, DescriptionColumn
, DescriptionColWidth 
from 
	DDFIShared 
where 
	Form = @FormName 
order by 
	ShowGrid DESC
,	coalesce(GridCol, Seq)


select * from DDUI where Form=@FormName and upper(VPUserName)='MCKINSTRY\BILLO'
