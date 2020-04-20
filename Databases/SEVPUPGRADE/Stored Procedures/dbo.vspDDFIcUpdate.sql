SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspDDFIcUpdate]
/********************************
* Created: GG 03/30/04
* Modified:	GG 09/30/04 - added MinValue, MaxValue, ValExp, and ValExpError
*			GG 09/20/06 - added IsFormFilter
*			JVH 10/29/09 - added customgridcolheading
*
* Updates custom field property override to vDDFIc.  Called from
* Form Property form as field overrides are modified.
*
* Input:
*	@form			Form name
*	@seq			Field sequence #
*	@setupform		Setup form
*	@setupparams	Setup form parameters
*	@tab			Tab page - custom fields only
*	@tabindex		Tab index - custom fields only
*	@req			Input required
*	@valproc		Validation procedure
*	@valparams		Validation proc parameters
*	@vallevel		Validation level
*	@defaulttype	Default type
*	@defaultvalue	Default value
*	@formlabel		Form label text
*	@showgrid		Show on grid
*	@showform		Show on form
*	@inputskip		Input skip
*	@minvalue		Minimum value
*	@maxvalue		Maximum value
*	@valexp			Validation expression
*	@valexperror	Validation expression error
*	@statustext		Status text
*	@showdesc		Show Description
*	@isformfilter	Form Filter flag
*	@customgridcolheading	Grid Column Heading
*
* Output:
*	@errmsg			Error message, if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @seq smallint = null, @setupform varchar(30) = null,
	@setupparams varchar(256) = null, @tab tinyint = null, @tabindex smallint = null,
 	@req bYN = null, @valproc varchar(60) = null, @valparams varchar(256) = null, 
	@vallevel tinyint = null, @defaulttype tinyint = null, @defaultvalue varchar(256) = null, 
	@formlabel varchar(30) = null, @showgrid bYN = null, @showform bYN = null, @inputskip bYN = null,
	@minvalue varchar(20) = null, @maxvalue varchar(20) = null, @valexp varchar(256) = null,
	@valexperror varchar(256) = null, @statustext varchar(256) = null, @showdesc tinyint = null,
	@isformfilter bYN = null, @customgridcolheading varchar(30) = null, @errmsg varchar(255) output)
as

set nocount on
declare @rcode int
select @rcode = 0

-- update existing custom entry
update dbo.vDDFIc
set SetupForm = @setupform, SetupParams = @setupparams, Tab = @tab, TabIndex = @tabindex,
	Req = @req, ValProc = @valproc, ValParams = @valparams, ValLevel = @vallevel,
	DefaultType = @defaulttype, DefaultValue = @defaultvalue, Label = @formlabel,
	ShowGrid = @showgrid, ShowForm = @showform, InputSkip = @inputskip, MinValue = @minvalue,
	MaxValue = @maxvalue, ValExpression = @valexp, ValExpError = @valexperror, StatusText = @statustext,
	ShowDesc = @showdesc, IsFormFilter = @isformfilter, GridColHeading = @customgridcolheading
where Form = @form and Seq = @seq
if @@rowcount = 0
	begin
	-- add an entry only if user has overrides
	if @setupform is not null or @setupparams is not null or 
		@tab is not null or @tabindex  is not null or @req  is not null or 
		@valproc is not null or @valparams is not null or @vallevel  is not null or
		@defaulttype is not null or @defaultvalue is not null or
		@inputskip is not null or @formlabel is not null or @showform is not null or
		@showgrid is not null or @minvalue is not null or @maxvalue is not null or
		@valexp is not null or @valexperror is not null or @statustext is not null or
		@showdesc is not null or @isformfilter is not null or @customgridcolheading is not null
		insert dbo.vDDFIc (Form, Seq, SetupForm, SetupParams, 
		  	Tab, TabIndex, Req, ValProc, ValParams, ValLevel, 
		  	DefaultType, DefaultValue, InputSkip, Label, ShowForm, ShowGrid,
			MinValue, MaxValue, ValExpression, ValExpError, StatusText, ShowDesc, IsFormFilter, GridColHeading)
		values (@form, @seq, @setupform, @setupparams, 
		  	@tab, @tabindex, @req, @valproc, @valparams, @vallevel, 
		  	@defaulttype, @defaultvalue, @inputskip, @formlabel, @showform, @showgrid,
			@minvalue, @maxvalue, @valexp, @valexperror, @statustext, @showdesc, @isformfilter, @customgridcolheading)
					
	end
declare @tablename varchar(30)
		select top 1 @tablename = ViewName from vDDFIc where Form = @form and Seq = @seq
		EXEC vspUDVersionUpdate @tablename	
-- remove null entries
if exists(select top 1 1 from dbo.vDDFIc c join dbo.vDDFI i on i.Form = c.Form and i.Seq = c.Seq
		where c.ViewName is null and c.ColumnName is null and c.Description is null and c.Datatype is null
			and c.InputType is null and c.InputMask is null and c.InputLength is null and c.Prec is null
			and c.ActiveLookup is null and c.LookupParams is null and c.LookupLoadSeq is null 
			and c.SetupForm is null and c.SetupParams is null and c.StatusText is null and c.Tab is null
			and c.TabIndex is null and c.Req is null and c.ValProc is null and c.ValParams is null
			and c.ValLevel is null and c.UpdateGroup is null and c.ControlType is null
			and c.ControlPosition is null and c.FieldType is null and c.DefaultType is null
			and c.DefaultValue is null and c.InputSkip is null and c.Label is null and c.ShowGrid is null
			and c.ShowForm is null and c.GridCol is null and c.AutoSeqType is null and c.MinValue is null
			and c.MaxValue is null and c.ValExpression is null and c.ValExpError is null and c.ComboType is null
			and c.GridColHeading is null and c.HeaderLinkSeq is null and c.CustomControlSize is null
			and c.Computed is null and c.ShowDesc is null and c.ColWidth is null and c.DescriptionColWidth is null
			and c.IsFormFilter is null and c.Form = @form and c.Seq = @seq)
	begin
	delete dbo.vDDFIc where Form = @form and Seq = @seq
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFIcUpdate] TO [public]
GO
