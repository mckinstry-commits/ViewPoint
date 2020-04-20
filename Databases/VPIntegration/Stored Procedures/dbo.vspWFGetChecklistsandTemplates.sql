SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:  CC 12/31/2007
* MODIFIED By : CC 3/10/2008 -- Changed to use WFStatusCodes view instead of table
*	JVH 6/23/09 -- Increased the item size to accomodate the template name being varchar(60)
* USAGE:
* 	This procedure returns a collection of checklists and templates
*
* INPUT PARAMETERS
*	@company		Company to return checklists from
*	@defaultCo		Default company for templates to return
*	@UserName		Username to limit the private checklists
*	@Item			A particluar checklist or template to return
*	@Where			Additional where clause to further limit the return
*   
* OUTPUT PARAMETERS
*   @msg      Error message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFGetChecklistsandTemplates] 
	-- Add the parameters for the stored procedure here
	@company bCompany = null,
	@defaultCo bCompany = null,
	@UserName bVPUserName = null,
	@Item varchar(60) = null,
	@Where varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @sql varchar(max)
if @company is null
	if @Item is null
		raiserror('No company or item specified.',16, 1)
		--select Template as [Name], 'Template' as [Type], 'N' as [Init.], '' as [NewName], 'N' as MakePrivate, 'N' as SendNotification, UseEmail as UseEmail, EnforceOrder as EnforceOrder, '' as InitialStatus, '' as AssignTo, '' as DestCompany from WFTemplates where IsActive = 'Y'
	else
		set @sql = 'select Template as [Name], ''Template'' as [Type], ''N'' as [Init.], '''' as [NewName], ''N'' as MakePrivate, ''N'' as SendNotification, UseEmail as UseEmail, EnforceOrder as EnforceOrder, isnull((select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y''),(select min(StatusID) from WFStatusCodes where StatusType = 0)) as InitialStatus, '''' as AssignTo, ''' + cast(@defaultCo as varchar(3)) + ''' as DestCompany, isnull((select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y'')),
(select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0))) as StatusDesc, '''' as UserName from WFTemplates where Template = ''' + @Item + ''''
else
	if @Item is null
		set @sql = 'select Checklist as [Name], ''Checklist'' as [Type], ''N'' as [Init.], '''' as [NewName], IsPrivate as MakePrivate, ''N'' as SendNotification, UseEmail as UseEmail, EnforceOrder as EnforceOrder, isnull((select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y''),(select min(StatusID) from WFStatusCodes where StatusType = 0)) as InitialStatus, '''' as AssignTo, Company as DestCompany, 
			isnull((select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y'')),(select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0))) as StatusDesc, '''' as UserName from WFChecklists where Company = ''' + cast(@company as varchar(3))+ '''and (IsPrivate = ''N'' or (IsPrivate = ''Y'' and AddedBy = ''' + @UserName + '''))' + isnull(@Where,'') +
		'union all
		select Template as [Name], ''Template'' as [Type], ''N'' as [Init.], '''' as [NewName], ''N'' as MakePrivate, ''N'' as SendNotification, UseEmail as UseEmail, EnforceOrder as EnforceOrder, isnull((select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y''),(select min(StatusID) from WFStatusCodes where StatusType = 0)) as InitialStatus, '''' as AssignTo, ''' + cast(@defaultCo as varchar(3)) + ''' as DestCompany, isnull((select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y'')),
(select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0))) as StatusDesc, '''' as UserName from WFTemplates where IsActive = ''Y''' 
	else
		set @sql = 'select Checklist as [Name], ''Checklist'' as [Type], ''N'' as [Init.], '''' as [NewName], IsPrivate as MakePrivate, ''N'' as SendNotification, UseEmail as UseEmail, EnforceOrder as EnforceOrder, isnull((select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y''),(select min(StatusID) from WFStatusCodes where StatusType = 0)) as InitialStatus, '''' as AssignTo, Company as DestCompany, isnull((select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0 and IsDefaultStatus = ''Y'')),
(select [Description] from WFStatusCodes where StatusID = (select min(StatusID) from WFStatusCodes where StatusType = 0))) as StatusDesc, '''' as UserName from WFChecklists where Company = ''' + cast(@company as varchar(3)) + ''' and Checklist = ''' + @Item  + ''' and (IsPrivate = ''N'' or (IsPrivate = ''Y'' and AddedBy = ''' + @UserName + '''))' + isnull(@Where,'') 
--select @sql
exec(@sql)
END

GO
GRANT EXECUTE ON  [dbo].[vspWFGetChecklistsandTemplates] TO [public]
GO
