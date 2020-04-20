SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPMenuGetSearchItems]
/**************************************************
* Created: 2013-02-18 Chris Crewdson - 
* Modified: DW 3/14/2013 - 43296 Added full set of parameters on calls to vspVPMenuGetModuleForms
                           and vspVPMenuGetModuleReports. Also added SELECT DISTINCT for loading 
						   temp table for both reports and forms to avoid duplicates.
*
* Used by VPMenu to list all forms and reports so they can be searched. 
* Resultset includes 'Accessible' flag to indicate whether the user is 
* allowed to run the form or report in the given Company. 
*
* Inputs:
*	@co			Active Company # - needed for security
*
* Output:
*	resultset of users' accessible items
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
(
	  @co bCompany = NULL
	, @culture INT = NULL
	, @country CHAR(2) = NULL
	, @errmsg varchar(512) OUTPUT
)
as

set nocount on 

declare 
	@rcode int, @user bVPUserName, @opencursor tinyint, 
	@itemtype char(1), @menuitem varchar(30), @access tinyint, @reportid int

if @co is null
begin
	select @errmsg = 'Missing required input parameters: Company #', @rcode = 1
	goto vspexit
end

select @rcode = 0, @user = suser_sname()

-- use a local table to hold all Forms and Reports for the Sub-Folder
declare @allitems table
(
	ItemType char(1), 
	MenuItem varchar(30), 
	Title varchar(60), 
	IconKey varchar(20), 
	FormOrReportType varchar(10), 
	RptOwner varchar(128), 
	MenuSeq int,
	LastAccessed datetime, 
	Accessible char(1), 
	AssemblyName varchar(50), 
	FormClassName varchar(50), 
	AppType varchar(30)
)

/* Load Forms */
--Temp table to hold ModuleForm results
declare @formitems table
(
	Form varchar(30), 
	Title varchar(30), 
	IconKey varchar(20),
	FormType varchar(10), 
	LastAccessed datetime, 
	Accessible char(1),
	AssemblyName varchar(50), 
	FormClassName varchar(50)
)

INSERT @formitems
EXEC @rcode = vspVPMenuGetModuleForms @co, null, @culture, @country, @errmsg = @errmsg OUTPUT

IF @rcode <> 0 
    GOTO vspexit

INSERT @allitems 
(
	ItemType, 
	MenuItem, 
	Title, 
	IconKey, 
	FormOrReportType, 
	RptOwner, 
	LastAccessed, 
	Accessible, 
	AssemblyName, 
	FormClassName, 
	AppType
)
select distinct
	'F',			--ItemType: select 'F'
	Form,			--MenuItem: Returned from vspVPMenuGetModuleForms as Form
	Title,			--Title: Returned from vspVPMenuGetModuleForms as Title
	IconKey,		--IconKey: Returned from vspVPMenuGetModuleForms as IconKey
	FormType,		--FormType: Returned from vspVPMenuGetModuleForms as FormType
	NULL,			--RptOwner: N/A for forms, select null
	LastAccessed,	--LastAccessed: Returned from vspVPMenuGetModuleForms as LastAccessed
	Accessible,		--Accessible: Returned from vspVPMenuGetModuleForms as Accessible
	AssemblyName,	--AssemblyName: Returned from vspVPMenuGetModuleForms as AssemblyName
	FormClassName,	--FormClassName: Returned from vspVPMenuGetModuleForms as FormClassName
	'N'				--AppType: N/A for forms, select 'N'
FROM @formitems

/* Load Reports */
declare @reportitems table
(
	ReportID INT ,
	Title VARCHAR(60) ,
	ReportType VARCHAR(10) ,
	RptOwner VARCHAR(128) ,
	LastAccessed DATETIME ,
	Accessible CHAR(1) ,
	Status CHAR(8) ,
	AppType VARCHAR(30) ,
	IconKey VARCHAR(20)
)

INSERT @reportitems
EXEC @rcode = vspVPMenuGetModuleReports @co, null, @country, @errmsg = @errmsg OUTPUT

IF @rcode <> 0 
    GOTO vspexit

insert @allitems 
(
	ItemType, 
	MenuItem, 
	Title, 
	IconKey, 
	FormOrReportType, 
	RptOwner, 
	LastAccessed, 
	Accessible, 
	AssemblyName, 
	FormClassName, 
	AppType
)
select distinct
	'R',				--ItemType: select 'R'
	ReportID,			--MenuItem: Returned from vspVPMenuGetModuleReports as ReportID
	Title,				--Title: Returned from vspVPMenuGetModuleReports as Title
	IconKey,			--IconKey: Returned from vspVPMenuGetModuleReports as IconKey
	ReportType,			--FormOrReportType: Returned from vspVPMenuGetModuleReports as ReportType
	RptOwner,			--RptOwner: Returned from vspVPMenuGetModuleReports as RptOwner
	LastAccessed,		--LastAccessed: Returned from vspVPMenuGetModuleReports as LastAccessed
	Accessible,			--Accessible: Returned from vspVPMenuGetModuleReports as Accessible
	NULL,				--AssemblyName: N/A for reports, select NULL
	NULL,				--FormClassName: N/A for reports, select NULL
	AppType			--AppType: Returned from vspVPMenuGetModuleReports as AppType
FROM @reportitems

--Select the result set
select ItemType, MenuItem, Title, IconKey, FormOrReportType, RptOwner, MenuSeq,
 LastAccessed, Accessible, AssemblyName, FormClassName, AppType
from @allitems
order by Title

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuGetSearchItems]'
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetSearchItems] TO [public]
GO
