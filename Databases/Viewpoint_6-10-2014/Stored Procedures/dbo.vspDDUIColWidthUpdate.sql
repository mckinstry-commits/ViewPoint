SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[vspDDUIColWidthUpdate]
/********************************
* Created: GG 03/30/04
* Modified:	kb 6/8/4 - add column width update
		kb 8/27/5 - add description column width update
*
* Called from the VPForm Class to set an override column width on a specific
* form sequence or reset all of the column widths for the form back to standard.
*
* Input:
*	@form			Form name
*	@seq			Field sequence # - required if reset is 'N'
*	@columnwidth	Column width for updating
*	@resetYN		Y = reset grid column width for all sequences on the form
*
* Output:
*	@errmsg			Error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30), @seq smallint = NULL, @colwidth as smallint = null, @resetYN bYN = null,
@desccolwidth as smallint = null, @errmsg varchar(255) output)

as
set nocount on

declare @rcode int
select @rcode = 0

-- skip update if user is viewpoint
if suser_sname() = 'viewpointcs' goto vspexit

-- reset Grid Column Widths to standard values
if @resetYN = 'Y'
	begin
	-- remove column width overrides
	update vDDUI set ColWidth = null, DescriptionColWidth = null
	where Form = @form and VPUserName = suser_sname()
	-- delete entries with no overridden values

	delete vDDUI
	where Form = @form and VPUserName = suser_sname()
		and DefaultType is null and DefaultValue is null and InputSkip is null
		and InputReq is null and GridCol is null and ColWidth is null
		and	ShowGrid is null and ShowForm is null and DescriptionColWidth is null
	end
	
-- update the user's custom column width
if @resetYN = 'N' 
	begin
	-- update existing user entry
	update vDDUI set ColWidth = isnull(@colwidth,ColWidth), 
	  DescriptionColWidth = isnull(@desccolwidth,DescriptionColWidth)
	where Form = @form and Seq = @seq and VPUserName = suser_sname()
	if @@rowcount = 0
		begin
		-- add a user override entry
		insert vDDUI (VPUserName,Form,Seq, ColWidth, DescriptionColWidth)
		select suser_sname(), @form, @seq, @colwidth, @desccolwidth
		end
	-- remove the entry if not override values exist
	delete vDDUI
	where Form = @form and Seq = @seq and VPUserName = suser_sname()
		and DefaultType is null and DefaultValue is null and InputSkip is null
		and InputReq is null and GridCol is null and ColWidth is null
		and	ShowGrid is null and ShowForm is null and DescriptionColWidth is null
	end

	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUIColWidthUpdate] TO [public]
GO
