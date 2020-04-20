SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspDDUIUpdateAnyForm]
/********************************
* Created: TJL 10/31/08 - Issue #129895, Add JCCI.BillGroup to JBProgressBillItems grid for display only 
* Modified:	
*
* Updates field propertys override by user vDDUI.  Can be called from Any Application Form if desired.
*
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
update vDDUI 
set DefaultType = case when @defaulttype is null then DefaultType else @defaulttype end, 
	DefaultValue = case when @defaultvalue is null then DefaultValue else @defaultvalue end, 
  	InputSkip = case when @inputskip is null then InputSkip else @inputskip end, 
	InputReq = case when @req is null then InputReq else @req end,  
	ShowGrid = case when @showgrid is null then ShowGrid else @showgrid end, 
	ShowForm = case when @showform is null then ShowForm else @showform end,
	ShowDesc = case when @showdesc is null then ShowDesc else @showdesc end
where Form = @form and Seq = @seq and VPUserName = suser_sname()
if @@rowcount = 0
	begin
	-- add an entry only if user has overrides
	if @defaulttype is not null or @defaultvalue is not null or
		@inputskip is not null or @req is not null or @showform is not null or
		@showgrid is not null or @showdesc is not null
	insert vDDUI (VPUserName, Form, Seq, DefaultType, DefaultValue,
		InputSkip, InputReq, ShowGrid, ShowForm, ShowDesc)
	select suser_sname(), @form, @seq, @defaulttype, @defaultvalue, 
	 	  @inputskip, @req, @showgrid, @showform, @showdesc
	end

-- remove user entry if no overrides exist
--delete vDDUI
--where DefaultType is null and DefaultValue is null and InputSkip is null and InputReq is null
--	and GridCol is null and ColWidth is null and ShowGrid is null and ShowForm is null
--	and DescriptionColWidth is null and ShowDesc is null 
--	and Form = @form and Seq = @seq and VPUserName = suser_sname()

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUIUpdateAnyForm] TO [public]
GO
