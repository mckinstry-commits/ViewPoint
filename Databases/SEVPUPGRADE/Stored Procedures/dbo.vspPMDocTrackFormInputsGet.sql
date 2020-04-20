SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE PROCEDURE [dbo].[vspPMDocTrackFormInputsGet]
/********************************
* Created By:	GF 01/26/2007 - 6.x
* Modified By:	GF 09/02/2008 - issue #129641 changed to use GridCol for combo box inputs
*
*
* Called from the PM Document Tracking Form to get non-key field grid column inputs
* to load into the form collection. These columns are defined in PMVC for each grid
* form.
*
* Input:
* @co		Current active company #
* @form		Form name
* @pmvm_view	PM Document Tracking View Name
*
* Output:
* resultset - Form Inputs 
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@co bCompany = null, @form varchar(30) = null, @pmvm_view varchar(10) = null, 
 @errmsg varchar(512) output)
as
set nocount on

declare @rcode int, @lastcolseq int

select @rcode = 0, @lastcolseq = 0

---- if @pmvm_view does not exist use 'Viewpoint' view
if not exists(select * from PMVM where ViewName=@pmvm_view)
	begin
	select @pmvm_view = 'Viewpoint'
	end

---- get last key sequence from DDFI for form
select @lastcolseq = max(Seq) from dbo.DDFI with (nolock) where Form=@form
if @@rowcount = 0 select @lastcolseq = 50

---- declare Form Inputs table to return current, standard, custom, and user input properties
declare @forminputs table (AutoSeq tinyint, ColumnName varchar(500), ControlType tinyint, ControlPosition varchar(20),
	CustDefaultType tinyint, CustDefaultValue varchar(256), CustGridCol smallint, CustInputSkip char(1),
	CustSetupForm varchar(30), CustSetupParams varchar(256), CustShowOnForm char(1), CustShowOnGrid char(1),
	CustValLevel tinyint, CustValParams varchar(256), CustValProc varchar(60), CustReq char(1), CustTab tinyint,
	CustTabIndex smallint, Datatype varchar(30), DatatypeLabel varchar(30), Description varchar(60), DescriptionCol varchar(120),
	FieldType tinyint, FormLabel varchar(30), HelpKeyword varchar(60), InputLength smallint,
	InputMask varchar(30), InputType tinyint, IsCustom char(1), LabelDescColumnName varchar(120), Prec tinyint,
	Secure char(1), Seq smallint, StatusText varchar(256), StdGridCol smallint, StdReq char(1), StdSetupForm varchar(30),
	StdSetupParams varchar(256), StdTab tinyint, StdValLevel tinyint, StdValParams varchar(256),
	StdValProc varchar(60), UpdateGroup varchar(20), UserColWidth smallint, UserDefaultType tinyint, UserDefaultValue varchar(256),
	UserGridCol smallint, UserShowOnForm char(1), UserShowOnGrid char(1), UserInputSkip char(1), UserReq char(1), ViewName varchar(30),
	StdSetupAssemblyName varchar(50), StdSetupFormClassName varchar(60),
	CustSetupAssemblyName varchar(50), CustSetupFormClassName varchar(60),
	CustMinValue varchar(20), CustMaxValue varchar(20), CustValExpression varchar(256), CustValExpError varchar(256),
	StdMinValue varchar(20), StdMaxValue varchar(20), StdValExpression varchar(256), StdValExpError varchar(256),
	StdShowOnForm char(1), StdShowOnGrid char(1), GridColHeading varchar(30), UserShowDesc tinyint, HeaderLinkSeq smallint,
	CustControlSize varchar(20), DescriptionColWidth smallint, Computed char(1), StdShowDesc tinyint, CustShowDesc tinyint,
	StdColWidth smallint, StdDescriptionColWidth smallint, StdIsFormFilter char(1), CustomIsFormFilter char(1))

---- insert values from PMVG by viewname and formname order by colseq
-- insert current and user override values
insert @forminputs (AutoSeq, ColumnName, ControlType, ControlPosition, CustDefaultType,
	CustDefaultValue, CustGridCol, CustInputSkip, CustSetupForm, CustSetupParams,
	CustShowOnForm, CustShowOnGrid,	CustValLevel, CustValParams, CustValProc, CustReq,
	CustTab, CustTabIndex, Datatype, DatatypeLabel, Description, DescriptionCol,
	FieldType, FormLabel, HelpKeyword, InputLength, InputMask, InputType,
	IsCustom, LabelDescColumnName, Prec, Secure, Seq, StatusText, StdGridCol, StdReq,
	StdSetupForm, StdSetupParams, StdTab, StdValLevel, StdValParams,
	StdValProc, UpdateGroup, UserColWidth, UserDefaultType, UserDefaultValue,
	UserGridCol, UserShowOnForm, UserShowOnGrid, UserInputSkip, UserReq, ViewName, 
	StdSetupAssemblyName,StdSetupFormClassName, CustSetupAssemblyName, CustSetupFormClassName, 
	StdShowOnForm, StdShowOnGrid, GridColHeading, 
	UserShowDesc, HeaderLinkSeq, CustControlSize, DescriptionColWidth, Computed,
	StdShowDesc, CustShowDesc, StdColWidth, StdDescriptionColWidth, StdIsFormFilter, CustomIsFormFilter)
select 0, isnull(g.ColumnName,''), 4, '', null,
		null, null,	null, null, null,
		null, null, null, null,	null, null, null, null,
    	'Datatype' = (select case when c.DOMAIN_NAME like 'b%' then c.DOMAIN_NAME 
							when c.DATA_TYPE = 'numeric' AND c.DOMAIN_NAME is null then 'bDollar'
							when c.DATA_TYPE = 'char' AND c.CHARACTER_MAXIMUM_LENGTH > 100 then 'bNotes'
							when c.DATA_TYPE = 'varchar' AND c.CHARACTER_MAXIMUM_LENGTH = -1 then 'bNotes'
							when c.DATA_TYPE = 'varchar' AND c.CHARACTER_MAXIMUM_LENGTH > 100 then 'bNotes'
							when c.DATA_TYPE = 'smalldatetime' and g.ColumnName like '%Time%' then 'bTime'
							else '' end
					from INFORMATION_SCHEMA.COLUMNS c where c.COLUMN_NAME = g.ColumnName and c.TABLE_NAME = g.TableView),
		'', '', '',
		'FieldType' = (select case when c.DOMAIN_NAME = 'bNotes' then 1
							when c.DATA_TYPE = 'char' AND c.CHARACTER_MAXIMUM_LENGTH > 100 then 1
							when c.DATA_TYPE = 'varchar' AND c.CHARACTER_MAXIMUM_LENGTH = -1 then 1
							when c.DATA_TYPE = 'varchar' AND c.CHARACTER_MAXIMUM_LENGTH > 100 then 1
							else 0 end
					from INFORMATION_SCHEMA.COLUMNS c where c.COLUMN_NAME = g.ColumnName and c.TABLE_NAME = g.TableView),
		null, '',

		'InputLength' = (select case when c.DOMAIN_NAME like 'b%' then 0
							when c.CHARACTER_MAXIMUM_LENGTH is not null then c.CHARACTER_MAXIMUM_LENGTH
							else 0 end
						from INFORMATION_SCHEMA.COLUMNS c where c.COLUMN_NAME=g.ColumnName and c.TABLE_NAME=g.TableView),
		'InputMask' = '', 'InputType' = 0,
		case when g.ColumnName like 'ud%' then 'Y' else 'N' end, '',
		'Prec' = 0,
		'N', g.GridCol, '', g.GridCol, 'N', null, null, 0, 0, null,
		null, null, null, null, null,
		null, null, null, null, null, isnull(g.TableView,''),
		null, null, null, null, isnull(g.Visible,'Y'), isnull(g.Visible,'Y'), isnull(g.ColTitle,''),
		null, null, null, null, 'N',
		null, null, null, null, null, null

from dbo.bPMVC g
where g.ViewName=@pmvm_view and g.Form=@form
order by g.ViewName, g.Form, g.GridCol

---- update datatype length, mask, type, and precision
update @forminputs set InputLength = isnull(d.InputLength,f.InputLength),
					   InputMask = isnull(d.InputMask,f.InputMask),
					   InputType = isnull(d.InputType,f.InputType),
					   Prec = isnull(d.Prec,f.Prec)
from @forminputs f left join dbo.DDDTShared d on d.Datatype=f.Datatype
where f.Datatype like 'b%'

---- if revisions column exists for drawing logs, set as a bYN so check box will appear in grid.
if @form='PMDocTrackPMDG'
	begin
	update @forminputs set Datatype='bYN'
	from @forminputs f where f.ColumnName='Revisions'
	end

---- check grid form for UniqueAttchID column, if found set as a bYN so check box will appear in grid
update @forminputs set Datatype='bYN', Computed='Y',
		ColumnName='Case when ' + f.ViewName + '.' + f.ColumnName + ' is not null then ' + char(39) + 'Y' + char(39) + ' else ' + char(39) + 'N' + char(39) + ' end'
from @forminputs f where f.ColumnName='UniqueAttchID'

---- update user input overrides from vDDUI
update @forminputs set UserColWidth=u.ColWidth, UserGridCol=u.GridCol, UserShowOnForm=u.ShowForm,
					   UserShowOnGrid=u.ShowGrid, UserInputSkip=u.InputSkip, UserReq=u.InputReq,
					   UserShowDesc=u.ShowDesc, DescriptionColWidth=u.DescriptionColWidth
from @forminputs f 
join dbo.vDDUI u with (nolock) on u.VPUserName = suser_sname() and u.Form=@form and u.Seq=f.Seq

---- return Form Inputs as 1st resultset
select Seq, ViewName, ColumnName, AutoSeq, ControlType, ControlPosition, CustDefaultType,
	CustDefaultValue, CustGridCol, CustInputSkip, CustSetupForm, CustSetupParams,
	CustSetupAssemblyName, CustSetupFormClassName,
	CustShowOnForm, CustShowOnGrid,	CustValLevel, CustValParams, CustValProc, CustReq,
	CustTab, CustTabIndex, Datatype, DatatypeLabel, Description, DescriptionCol,
	FieldType, FormLabel, HelpKeyword, InputLength, InputMask, InputType,
	IsCustom, LabelDescColumnName, Prec, Secure, StatusText, StdGridCol, StdReq,
	StdSetupForm, StdSetupParams, StdSetupAssemblyName, StdSetupFormClassName,
	StdTab, StdValLevel, StdValParams,
	StdValProc, UpdateGroup, UserColWidth, UserDefaultType, UserDefaultValue,
	UserGridCol, UserShowOnForm, UserShowOnGrid, UserInputSkip, UserReq,
	CustMinValue, CustMaxValue, CustValExpression, CustValExpError,
	StdMinValue, StdMaxValue, StdValExpression, StdValExpError, StdShowOnForm, StdShowOnGrid,
	GridColHeading, UserShowDesc, HeaderLinkSeq, CustControlSize, DescriptionColWidth, Computed,
	StdShowDesc, CustShowDesc, StdColWidth, StdDescriptionColWidth, StdIsFormFilter, CustomIsFormFilter
from @forminputs
order by isnull(StdGridCol,CustGridCol), Seq


---- ComboBox Types as 2nd resultset - issue #129641
select g.GridCol as Seq, c.Seq as ComboTypeSeq, c.DisplayValue, c.DatabaseValue
from dbo.bPMVC g
join dbo.DDFIShared s (nolock) on s.ViewName=g.TableView and s.ColumnName=g.ColumnName and s.Form like 'PM%'
join dbo.DDCIShared c (nolock) on c.ComboType = s.ComboType
where g.ViewName=@pmvm_view and g.Form=@form
group by g.GridCol, c.Seq, c.DisplayValue, c.DatabaseValue
order by g.GridCol, c.Seq, c.DisplayValue, c.DatabaseValue







vspexit:
	if @rcode <> 0 --select @errmsg = @errmsg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTrackFormInputsGet] TO [public]
GO
