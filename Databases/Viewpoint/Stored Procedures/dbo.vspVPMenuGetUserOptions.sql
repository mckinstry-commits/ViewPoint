SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPMenuGetUserOptions]
/******************************************************************************
* Created: JK 07/14/03
* Last Modified: Francine Taylor 2011-03-15
*
* Used by ClientHelper to populate properties that all forms can access.
*
* Inputs:
*	<none>	Altered
*
* Output:
*	resultset	Oodles of fields from DDUP.
*	@errmsg		Error message
*
*******************************************************************************
* Modified:
* 2008-06-09 - RM - Explicitly return columns, added Recording Framework columns
* 2010-12-17 - Chris Crewdson - Added LabelBackgroundColor and LabelTextColor columns - Issue #141940
* 2011-01-11 - Chris Crewdson - Added LabelBorderStyle column
* 2011-03-15 - Francine Taylor - Added ShowLogoPanel column
* 2011-03-25 - Francine Taylor - Added ShowMainToolbar
* 2011-12-19 - Nitor - Adding ShowSSRSViewer, SaveLastUsedParameters
* 2012-01-17 - Chris C - Adding ShowSSRSInBrowser
* 2012-05-29 - Gabe P - Fixed Project column by adding removed comma back into select statement
* 2012-09-06 - Dan Wehn - Added checking for existence of user in result set and set @errmsg accordingly if not #147060
* 2012-09-21 - Paul Wiegardt - Removed Recording Framwork columns
*******************************************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @user bVPUserName

select @user = suser_sname()

if exists(select p.VPUserName from dbo.vDDUP p (nolock) join vDDVS s on 1=1 where p.VPUserName = @user)
    begin
		return_results:		-- return resultset
			select VPUserName,ShowRates,HotKeyForm,RestrictedBatches,FullName,Phone,EMail,ConfirmUpdate,
					DefaultCompany,EnterAsTab,ExtendControls,SavePrinterSettings,SmartCursor,
					SaveLastUsedParameters,ToolTipHelp,ReportViewerOptions,
					Project,PRGroup,PREndDate,JBBillMth,JBBillNumber,MenuColWidth,LastNode,LastSubFolder,
					MinimizeUse,AccessibleOnly,ViewOptions,ReportOptions,SmartCursorColor,AccentColor1,
					UseColorGrad,FormColor1,FormColor2,GradDirection,UniqueAttchID,MenuAdmin,AccentColor2,
					ReqFieldColor,IconSize,FontSize,FormAdmin,MultiFormInstance,PayCategory,HideModFolders,
					FolderSize,Job,Contract,MenuInfo,LastReportID,ColorSchemeID,MappingID,ImportId,
					ImportTemplate,JBTMBillMth,JBTMBillNumber,PMTemplate,MergeGridKeys,p.MaxLookupRows,
					p.MaxFilterRows,PMViewName,DefaultColorSchemeID,AltGridRowColors,KeyID,HRCo,HRRef,
					DefaultDestType,WindowsUserName,SelectedTemplate,RQEntyHeaderID,PRCo,Employee,RQQuoteEditHeaderID,
					MyTimesheetRole, ShowLogoPanel, ShowMainToolbar,
					AttachmentGrouping,
					LabelBackgroundColor, LabelTextColor,
					LabelBorderStyle,
					ThumbnailMaxCount
			from dbo.vDDUP p (nolock) join vDDVS s on 1=1
			where p.VPUserName = @user
    goto vspexit
	end	

select @errmsg = 'Can not resolve ' + @user + '. Possibly a conflict with case-sensitivity between Active Directory and sql server.' 

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetUserOptions] TO [public]
GO
