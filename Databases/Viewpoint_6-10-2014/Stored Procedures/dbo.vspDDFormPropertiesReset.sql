SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDFormPropertiesReset]
/********************************
* Created: GG 11/18/06
* Modified: George Clingerman 04/08/2008 #127561 Need to reset the SetupForm and SetupParam overrides
*
* Purpose: Removes user and/or system-wide overrides for a form.
*	Called from the Form Properties form. 
*
* Input:
*	@form	Form name
*	@userall		Y = remove all of the user's overrides
*	@userdefault	Y = remove user's field default and input skip overides
*	@userdisplay	Y = remove user's form and grid display overrides
*	@userreq		Y = remove user required input overrides
*	@siteall		Y = remove all site overrides (standard fields only)
*	@sitedefault	Y = remove site default and input skip overrides (standard fields only)
*	@sitedisplay	Y = remove site form, grid display, and label overrides (standard fields only)
*	@siteval		Y = remove site overrides for required input and validation (standard fields only)
*	@inputorder		Y = remove input order overrides (standard fields only)
*	@groupbox		Y = remove custom group boxes
*	@lookups		Y = remove lookup overrides (standard fields only)
*	@tabpages		Y = remove tab page order overrides (standard forms only)
*	@images			Y = remove form image overrides (standard forms only)
*	@reports		Y = remove form reports
*
* Output:
*	@errmsg			Error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@form varchar(30) = null, @userall bYN = 'N', @userdefault bYN = 'N', @userdisplay bYN = 'N',
	@userreq bYN = 'N', @siteall bYN = 'N', @sitedefault bYN = 'N', @sitedisplay bYN = 'N',
	@siteval bYN = 'N', @inputorder bYN = 'N', @groupbox bYN = 'N', @lookups bYN = 'N',
	@tabpages bYN = 'N', @images bYN = 'N', @reports bYN = 'N', @headerform varchar(30) = null, @errmsg varchar(500) output)
as
set nocount on

declare @rcode int, @customform bYN, @stdfield bYN

select @rcode = 0, @stdfield = 'N'

-- determine if Form is custom
select @customform = Custom
from DDFHShared (nolock)
where Form = @form
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Form: ' + isnull(@form,'') + ' - unable to reset form properties.', @rcode = 1
	goto vspexit
	end

/**** User Resets - applies to both standard and custom fields ***/
-- remove user field defaults and input skips
if @userall = 'Y' or @userdefault = 'Y' 
	begin
	update dbo.vDDUI set DefaultType = null, DefaultValue = null, InputSkip = null 
	where Form = @form and VPUserName = suser_sname() 
	end
-- remove user form and display overrides
if @userall = 'Y' or @userdisplay = 'Y' 
	begin
	update dbo.vDDUI set GridCol = null, ColWidth = null, ShowGrid = null, ShowForm = null,
		ShowDesc = null, DescriptionColWidth = null
	where Form = @form and VPUserName = suser_sname()
	end
-- remove user required input overrides
if @userall = 'Y' or @userreq = 'Y' 
	begin
	update dbo.vDDUI set InputReq = null
	where Form = @form and VPUserName = suser_sname() 
	end
-- remove all form level overrides for the user
if @userall = 'Y'
	begin
	update dbo.vDDFU set DefaultTabPage = null, FormPosition = null, GridRowHeight = null,
		SplitPosition = null, Options = null
	where Form = @form and VPUserName = suser_sname() 
	
		if not @headerform is null --if this is a detai form we need to reset some of the header level stuff at the same time.
			begin
			update dbo.vDDFU set FormPosition = null, SplitPosition = null
			where Form = @headerform and VPUserName = suser_sname() 
			end
	end

-- remove user field entries if no overrides exist
delete vDDUI
where DefaultType is null and DefaultValue is null and InputSkip is null and InputReq is null
	and GridCol is null and ColWidth is null and ShowGrid is null and ShowForm is null
	and DescriptionColWidth is null and ShowDesc is null 
	and Form = @form and VPUserName = suser_sname()
 
/*** System Wide Resets  ***/
-- remove system wide defaults and input skips
if @customform = 'N' and (@siteall = 'Y' or @sitedefault = 'Y')
	begin
	update dbo.vDDFIc set DefaultType = null, DefaultValue = null, InputSkip = null
	where Form = @form  and (ColumnName is null or ColumnName not like 'ud%') -- standard fields only
	end
-- remove system wide form and display overrides
if @customform = 'N' and (@siteall = 'Y' or @sitedisplay = 'Y')
	begin
	update dbo.vDDFIc set Label = null, ShowGrid = null, ShowForm = null,
		ShowDesc = null, IsFormFilter = null
	where Form = @form  and (ColumnName is null or ColumnName not like 'ud%')
	end 
-- remove system wide validation and required input overrides
if @customform = 'N' and (@siteall = 'Y' or @siteval = 'Y')
	begin
	update dbo.vDDFIc set Req = null, ValProc = null, ValParams = null,
		ValLevel = null, MinValue = null, MaxValue = null, ValExpression = null,
		ValExpError = null
	where Form = @form  and (ColumnName is null or ColumnName not like 'ud%')
	end
-- remove input order overrides
if @customform = 'N' and (@siteall = 'Y' or @inputorder = 'Y')
	begin
	update dbo.vDDFIc set TabIndex = null
	where Form = @form  and (ColumnName is null or ColumnName not like 'ud%')
	end

-- #127561 remove Custom Setup Forms and Parameters
if @customform = 'N' and @siteall = 'Y'
	begin
	update dbo.vDDFIc set SetupForm = null, SetupParams = null
	where Form = @form  and (ColumnName is null or ColumnName not like 'ud%')
	end

-- remove system field entries for standard inputs if no overrides exist
if @customform = 'N'
	begin
	delete dbo.vDDFIc
	where Form = @form and ActiveLookup is null and LookupParams is null and LookupLoadSeq is null
		and TabIndex is null and Req is null and ValProc is null and ValParams is null
		and ValLevel is null and DefaultType is null and DefaultValue is null and InputSkip is null
		and Label is null and ShowGrid is null and ShowForm is null and MinValue is null
		and MaxValue is null and ValExpression is null and ValExpError is null and ShowDesc is null
		and IsFormFilter is null and (ColumnName is null or ColumnName not like 'ud%')
	end

-- remove field lookup overrides
if @customform = 'N' and (@siteall = 'Y' or @lookups = 'Y') 
	begin
	delete dbo.vDDFLc where Form = @form 
	end
-- remove custom group boxes - applies to both standard and custom forms
if @siteall = 'Y' or @groupbox = 'Y'
	begin
	delete dbo.vDDGBc where Form = @form
	end

/*** Reset Tab Page Order ***/
if @customform = 'N' and @tabpages = 'Y'
	begin
	-- remove overrides for standard tabs
	delete dbo.vDDFTc 
	where Form = @form and Tab < 100
	-- remove custom tabs without fields
	delete dbo.vDDFTc 
	from dbo.vDDFTc t
	where not exists(select 1 from dbo.DDFIShared s where s.Form = t.Form and s.Tab = t.Tab)
	and t.Form = @form and t.Tab > 99
	-- reassign load sequence to custom tabs based on tab #
   	update dbo.vDDFTc set LoadSeq = Tab
	where Form = @form and Tab > 99
	end 

/*** Reset Form Images ***/
if @customform = 'N' and @images = 'Y' 
	begin
	update dbo.vDDFHc set ProgressClip = null, IconKey = null
	where Form = @form 
	end

/*** Reset Form Reports ***/
if @reports = 'Y'
	begin
	-- remove Form Report Parameter overrides
	delete dbo.vRPFDc where Form = @form
	-- remove Form Report Overrides
	delete dbo.vRPFRc where Form = @form
	end
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormPropertiesReset] TO [public]
GO
