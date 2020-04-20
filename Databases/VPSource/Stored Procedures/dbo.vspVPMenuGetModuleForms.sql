SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVPMenuGetModuleForms]
/**************************************************
* Created: GG 07/11/03
* Modified: JK 01/13/2004 - Return the form type.
*			GG 04/10/06 - mods for LicLevel
*			JK 04/12/06 - mods for FormType = 9 (grid only)
*			CC 07/09/09 - Issue #129922 - Add culture based override for form title.
*			CC 07/15/09 - Issue #133695 - Hide forms that are not applicable to the current country
*
* Used by VPMenu to list all Forms assigned to a 
* Viewpoint Module.  Resultset includes 'Accessible' flag to
* indicate whether the user is allowed to run the form in the 
* given Company. 
*
* Inputs:
*	@co			Company
*	@mod		Module
*
* Output:
*	resultset	Forms with access info
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@co bCompany = null, @mod char(2) = null, @culture int = NULL, @country CHAR(2) = NULL, @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int, @opencursor tinyint, @user bVPUserName, @form varchar(30),
	@access tinyint, @formaccess tinyint
	
if @co is null or @mod is null
	begin
	select @errmsg = 'Missing required input parameter(s): Company # and/or Module!', @rcode = 1
	goto vspexit
	end

select @rcode = 0, @user = suser_sname()

-- use a local table to hold all Forms for the Module
declare @allforms table(Form varchar(30), Title varchar(30), IconKey varchar(20),
	FormType varchar(10), LastAccessed datetime, Accessible char(1),
	AssemblyName varchar(50), FormClassName varchar(50))

insert @allforms (Form, Title, IconKey, FormType, LastAccessed, Accessible, AssemblyName, FormClassName)
select m.Form, ISNULL(CultureText.CultureText, h.Title) AS Title, h.IconKey,
/* 
   FormType:
   - User Defined programs have Form names beginning with "UD".
     "User Defined" is more than 10 chars, out output "UserDefine".
   - If not UD, get the value from the FormType field.
     It stores tinyints (1, 2 or 3), so map to friendly strings.
 */
 CASE lower(SUBSTRING(h.Form, 1, 2)) WHEN 'ud'
    THEN 'UserDefine'
    ELSE 
      CASE h.FormType
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
 --ISNULL(si.MenuSeq, h.FormNumber) FormNumber,
 u.LastAccessed, 'Y', h.AssemblyName, h.FormClassName	
from DDMFShared m (nolock)
join DDFHShared h (nolock) on h.Form = m.Form
join vDDMO o (nolock) on h.Mod = o.Mod	-- join on form's primary module
left outer join vDDFU u on u.Form = m.Form and u.VPUserName = @user
LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = h.TitleID
LEFT OUTER JOIN DDFormCountries ON DDFormCountries.Form = h.Form
where m.Mod = @mod and m.Active = 'Y' and h.ShowOnMenu = 'Y' 
	and (o.LicLevel > 0 and o.LicLevel >= h.LicLevel)
	AND (dbo.DDFormCountries.Country = @country OR dbo.DDFormCountries.Country IS NULL)

if @user = 'viewpointcs' goto return_results	-- Viewpoint system user has access to all forms 

-- create a cursor to process each Form
declare vcForms cursor for
select Form from @allforms

open vcForms
set @opencursor = 1

form_loop:	-- check Security for each Form
	fetch next from vcForms into @form
	if @@fetch_status <> 0 goto end_form_loop

	exec @rcode = vspDDFormSecurity @co, @form, @access = @formaccess output, @errmsg = @errmsg output
	if @rcode <> 0 goto vspexit
	
	update @allforms
	set Accessible = case when @formaccess in (0,1) then 'Y' else 'N' end
	where Form = @form

	goto form_loop

end_form_loop:	--  all Forms checked
	close vcForms
	deallocate vcForms
	select @opencursor = 0

return_results:	-- return resultset
	select Form, Title, IconKey,
	 -- FormNumber,
	 FormType, LastAccessed, Accessible, AssemblyName, FormClassName
	from @allforms
	order by Form
   
vspexit:
	if @opencursor = 1
		begin
		close vcForms
		deallocate vcForms
		end

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetModuleForms]'
	return @rcode
	

GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetModuleForms] TO [public]
GO
