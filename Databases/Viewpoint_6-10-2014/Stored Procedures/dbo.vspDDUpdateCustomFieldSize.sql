SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspDDUpdateCustomFieldSize]
/********************************
* Created: 	mj 8/17/05
* Modified:	CC 03/24/08 - Issue #125611 - allow viewpointcs to re-size custom controls
*
* Called from the VPForm Class to update the control size (label and textbox) of a custom field 
*
* Input:
*	@form		Form 
*	@position	comma delimited string of label width, textbox width
*	
* Output:
*	@errmsg		error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @size varchar(20) = null, @seq smallint = null,
	@errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- don't update if viewpoint (remarked out following line for Issue #125611)
--if suser_sname()= 'viewpointcs' goto vspexit

-- try to update existing custom field entry
update vDDFIc
set CustomControlSize = @size
where Form = @form and Seq = @seq
if @@rowcount = 0
	begin
	-- add new entry
	insert vDDFIc (Form, Seq, CustomControlSize)
	select @form, @seq, @size
	from vDDFTc
	where Form = @form	
	End


vspexit:
	if @rcode<>0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDUpdateCustomFieldSIze]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateCustomFieldSize] TO [public]
GO
