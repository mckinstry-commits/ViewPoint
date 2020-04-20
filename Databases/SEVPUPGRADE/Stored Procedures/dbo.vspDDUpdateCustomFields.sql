SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspDDUpdateCustomFields]
/********************************
* Created: kb 2/9/4
* Modified:	GG 04/22/04 - changed vDDUF to vDDFU, added SplitPosition
*
* Called from the VPForm Class to update the control position of a custom field 
*
* Input:
*	@form		Form 
*	@position	comma delimited string of top, left, width, height
*	
* Output:
*	@errmsg		error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @position varchar(20) = null, @seq smallint = null,
	@errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- update custom field control position
update vDDFIc
set ControlPosition = @position
where Form = @form and Seq = @seq
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Form and Sequence #, unable to update custom field control position.', @rcode = 1
	goto vspexit
	end

vspexit:
	if @rcode<>0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDUpdateCustomFields]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateCustomFields] TO [public]
GO
