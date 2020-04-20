SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspDDColumnOrderUpdate]
/********************************
* Created: mj 8/11/04 
* Modified:	
*
* Called from DD Form Properties form to update the title of a custom tab
*
* GG - should pass form and tab #, not title
*
* Input:
*	@form		Form
*
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30), @seq int, @gridcol int, @errmsg varchar(60) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0



begin 
	update vDDUI
	set GridCol = @gridcol  
	from vDDUI 
	where Form = @form and Seq = @seq and VPUserName = suser_sname()
	if @@rowcount = 0
		begin
		-- add a user override entry
		insert vDDUI (VPUserName,Form,Seq, GridCol)
		select suser_sname(), @form, @seq, @gridcol
		end
	-- remove the entry if not override values exist
	delete vDDUI
	where Form = @form and Seq = @seq and VPUserName = suser_sname()
		and DefaultType is null and DefaultValue is null and InputSkip is null
		and InputReq is null and GridCol is null and ColWidth is null
		and	ShowGrid is null and ShowForm is null and DescriptionColWidth is null

	/*if @@rowcount = 0
		begin
		insert vDDFIc (Form, Seq, ViewName, ColumnName, [Description], Datatype, 
				InputType, InputMask, InputLength, Prec, ActiveLookup, LookupParams, 
				LookupLoadSeq, SetupForm, SetupParams, StatusText, Tab, TabIndex, Req, 
				ValProc, ValParams, ValLevel, UpdateGroup, ControlType, ControlPosition, 
				FieldType, DefaultType, DefaultValue, InputSkip, Label, ShowGrid, ShowForm, 
				GridCol, AutoSeqType, MinValue, MaxValue, ValExpression, ValExpError, ComboType, 
				GridColHeading)
		select @form, @seq, null,null,null,null,null,null,null,null,null,null,null,null,null,null,
				null,null,null,null,null,null,null,null,null,null,null,null,null,null,
				null,null,@gridcol,null,null,null,null,null, null, null
		end*/
	


end






vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDColumnOrderUpdate] TO [public]
GO
