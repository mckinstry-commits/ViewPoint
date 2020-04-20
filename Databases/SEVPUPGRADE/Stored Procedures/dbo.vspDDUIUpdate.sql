SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspDDUIUpdate]
/********************************
* Created: GG 03/30/04
* Modified:	GG 06/17/05 - added vDDUI.ShowDesc, remove entry if no overrides
*
* Updates field property overrides by user vDDUI.  Called from
* Form Property form as field overrides are modified.
*
* Grid column sequence and width are saved into vDDUI when form is closed.
*
* Input:
*	@form			Form name
*	@seq			Field sequence #
*	@defaulttype	Default type
*	@defaultvalue	Default value
*	@inputskip		Input skip
*	@req			Input required
*	@showgrid		Show on grid
*	@showform		Show on form
*	@showdesc		Show description, 0=grid,1=panel,2=neither
*
* Output:
*	@errmsg			Error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30), @seq smallint, @defaulttype tinyint = null, @defaultvalue varchar(256) = null,
	@inputskip bYN = null, @req bYN = null,  @showgrid bYN = null, @showform bYN = null, @showdesc tinyint = null,
	@errmsg varchar(255) output)

as
set nocount on
declare @rcode int
select @rcode = 0

-- update existing user entry
update vDDUI set DefaultType = @defaulttype, DefaultValue = @defaultvalue, 
  	InputSkip = @inputskip, InputReq = @req,  ShowGrid = @showgrid, ShowForm = @showform,
	ShowDesc = @showdesc
where Form = @form and Seq = @seq and VPUserName = suser_sname()
if @@rowcount = 0
	begin
	-- add an entry only if user has overrides
	if @defaulttype is not null or @defaultvalue is not null or
	  @inputskip is not null or @req is not null or @showform is not null or
		@showgrid is not null or @showdesc is not null
		insert vDDUI (VPUserName,Form,Seq, DefaultType,DefaultValue,
		  InputSkip, InputReq, ShowGrid, ShowForm, ShowDesc)
		select suser_sname(), @form, @seq, @defaulttype, @defaultvalue, 
		  @inputskip, @req, @showgrid, @showform, @showdesc
	end

-- remove user entry if no overrides exist
delete vDDUI
where DefaultType is null and DefaultValue is null and InputSkip is null and InputReq is null
	and GridCol is null and ColWidth is null and ShowGrid is null and ShowForm is null
	and DescriptionColWidth is null and ShowDesc is null 
	and Form = @form and Seq = @seq and VPUserName = suser_sname()

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUIUpdate] TO [public]
GO
