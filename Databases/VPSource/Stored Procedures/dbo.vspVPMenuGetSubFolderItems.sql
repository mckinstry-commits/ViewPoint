SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPMenuGetSubFolderItems]
/**************************************************
* Created: GG 07/11/03
* Modified: JRK 12/19/03 - RPRTShared no longer has an IconKey field so select null instead.
* Modified: JRK 11/14/04 - Retrieve the ReportType and CustomReport for the report items, or null for programs.
*			GG 02/09/04 - return Y/N indicating SQL Reporting Services report for all items 
* Modified: JRK 06/03/04 - Change field SQLRsReport to AppType.
*	JRK 01/26/06 - Select IconKey field for reports.
*	JRK 04/12/06 - FormType 9 is Setup.
*   RM 06/11/08 - Added error handling to tell which form is erroring.
*	RM 07/08/08 - Issue 128748: If there is an error getting form security, just mark it as inaccessible, rather than throwing an error
*	CC 07/09/09 - #129922 - Added link for form header to culture text
*	CC 07/15/09 - Issue #133695 - Hide forms that are not applicable to the current country
*
*
* Used by VPMenu to list all forms and reports assigned
* to a 'My Viewpoint' or module sub-folder.  Resultset includes 'Accessible' flag
* to indicate whether the user is allowed to run the form or report in the 
* given Company. 
*
* Inputs:
*	@co				Active Company # - needed for security
*	@mod			Module - empty for 'My Viewpoint'
*	@subfolder		Sub-Folder ID# - 0 used for module level items
*
* Output:
*	resultset of users' accessible items for the sub folder
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	( @co bCompany = NULL
	, @mod char(2) = NULL
	, @subfolder smallint = NULL
	, @culture INT = NULL
	, @country CHAR(2) = NULL
	, @errmsg varchar(512) OUTPUT
	)
as

set nocount on 

declare @rcode int, @user bVPUserName, @opencursor tinyint, @itemtype char(1), @menuitem varchar(30),
	@access tinyint, @reportid int

if @co is null or @mod is null or @subfolder is null
	begin
	select @errmsg = 'Missing required input parameters: Company #, Module, and/or Sub-Folder!', @rcode = 1
	goto vspexit
	end

select @rcode = 0, @user = suser_sname()

-- use a local table to hold all Forms and Reports for the Sub-Folder
declare @allitems table(ItemType char(1), MenuItem varchar(30), Title varchar(60), 
	IconKey varchar(20), FormOrReportType varchar(10), RptOwner varchar(128), CustomReport char(1),
	MenuSeq int, LastAccessed datetime, Accessible char(1), AssemblyName varchar(50), 
	FormClassName varchar(50), Custom tinyint, AppType varchar(30))

/* 
 		Load Forms  
 - Set CustomReport to null for all forms.
 - Set RptOwner to null for all forms, per Gail and Carol.
 - FormOrReportType has logic described below.
*/
insert @allitems (ItemType, MenuItem, Title, IconKey, FormOrReportType, CustomReport, MenuSeq, 
 LastAccessed, Accessible, AssemblyName, FormClassName, Custom, AppType)

select 'F', i.MenuItem, ISNULL(CultureText.CultureText, f.Title) AS Title, f.IconKey, 
  /* 
   FormOrReportType, when used for forms:
   - User Defined programs have Form names beginning with "UD".
     "User Defined" is more than 10 chars, out output "UserDefine".
   - If not UD, get the value from the FormType field.
     It stores tinyints (1, 2 or 3), so map to friendly strings.
 */
 CASE SUBSTRING(f.Form, 1, 2) WHEN 'UserDefine'
    THEN 'UD'
    ELSE 
      CASE f.FormType
         WHEN 1 THEN 'Setup'
         WHEN 2 THEN 'Posting'
         WHEN 3 THEN 'Processing'
         WHEN 4 THEN 'Post Dtl'
         WHEN 5 THEN 'Batch Proc'
         WHEN 6 THEN 'Detail'
         WHEN 7 THEN 'Batch Proc'
         WHEN 8 THEN 'Setup'
         WHEN 9 THEN 'Setup'
         ELSE ''
      END
 END,
 null, i.MenuSeq, u.LastAccessed, 'Y', f.AssemblyName, 
 f.FormClassName, 0, 'N'  -- Custom applies to reports so always set to zero (non-custom).
from vDDSI i
join DDFHShared f on f.Form = i.MenuItem
--join vDDMF m on m.Form = i.MenuItem
left join vDDFU u on u.VPUserName = i.VPUserName and u.Form = i.MenuItem
LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = f.TitleID
LEFT OUTER JOIN dbo.DDFormCountries ON dbo.DDFormCountries.Form = f.Form
where	i.VPUserName = @user 
		and i.Mod = @mod 
		and i.SubFolder = @subfolder 
		and i.ItemType = 'F'  -- Different WHERE than for Company folders.
		AND (dbo.DDFormCountries.Country = @country OR dbo.DDFormCountries.Country IS NULL)

/*
 		Load Reports
*/
insert @allitems (ItemType, MenuItem, Title, IconKey, FormOrReportType, RptOwner, MenuSeq,
 LastAccessed, Accessible, AssemblyName, FormClassName, Custom, AppType)
select 'R', i.MenuItem, r.Title, IconKey, r.ReportType,
 /*
 RptOwner:
 - RPRTShared now has a "Custom" field that indicates there is a custom report was
   set up, so there is a record in vRPRTc for it.
   If Custom = 1, then we return either "VP" or "User".  All custom reports
   with "viewpointcs" in the ReportOwner field of RPRTShared were modified
   by Viewpoint, so we'll display "VP".  Otherwise a user at the customer
   site created/modified the report and we'll display the text "User".
 */
 CASE r.Custom WHEN 1 THEN
   CASE r.ReportOwner
	WHEN 'viewpointcs' THEN 'VP'
	ELSE 'User'
   END
 ELSE null
 END,
ISNULL(i.MenuSeq, 0) MenuSeq, 
u.LastAccessed, 'Y', null, null, r.Custom, r.AppType
from vDDSI i
join RPRTShared r on r.ReportID = convert(int,i.MenuItem)
left join vRPUP u on u.VPUserName = i.VPUserName and u.ReportID = convert(int,i.MenuItem)
where	i.VPUserName = @user 
		and i.Mod = @mod 
		and i.SubFolder = @subfolder 
		and i.ItemType = 'R'  -- Different WHERE than for Company folders.
		AND (r.Country = @country OR r.Country IS NULL)

if @user = 'viewpointcs' goto return_results	-- Viewpoint system user has access to all forms 

-- create a cursor to process each Item
declare vcItems cursor for
select ItemType, MenuItem from @allitems

open vcItems
set @opencursor = 1

item_loop:	-- check Security for each Menu Item
	fetch next from vcItems into @itemtype, @menuitem
	if @@fetch_status <> 0 goto end_item_loop

	if @itemtype = 'F'
		begin
			exec @rcode = vspDDFormSecurity @co, @menuitem, @access output, 
			 @errmsg = @errmsg output
			if @rcode <> 0
			begin
				--select @errmsg = 'An error occured while getting security for the ''' + @menuitem + ''' form.' + CHAR(13) + CHAR(10) + isnull(@errmsg,'')
				--goto vspexit
				select @access = '255' --anything other than 0/1 is denied... so, 255 is error...yay!
			end
		end
	
	if @itemtype = 'R'
		begin
			set @reportid = convert(int,@menuitem)
			exec @rcode = vspRPReportSecurity @co, @reportid, @access output,
			 @errmsg = @errmsg output
			if @rcode <> 0
			begin 
				--select @errmsg = 'An error occured while getting security for the ''' + @menuitem + ''' report.' + CHAR(13) + CHAR(10) + isnull(@errmsg,'')
				--goto vspexit
				select @access = '255' --anything other than 0/1 is denied... so, 255 is error...yay!
			end
		end
	
	update @allitems
	set Accessible = case when @access in (0,1) then 'Y' else 'N' end
	where ItemType = @itemtype and MenuItem = @menuitem

	goto item_loop

end_item_loop:	--  all Items checked
	close vcItems
	deallocate vcItems
	select @opencursor = 0

return_results:	-- return resultset
	select ItemType, MenuItem, Title, IconKey, FormOrReportType, RptOwner, MenuSeq, 
	 LastAccessed, Accessible, AssemblyName, FormClassName, AppType
	from @allitems
	order by MenuSeq, Title
   
   
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuGetSubFolderItems]'
	return @rcode
	

GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetSubFolderItems] TO [public]
GO
