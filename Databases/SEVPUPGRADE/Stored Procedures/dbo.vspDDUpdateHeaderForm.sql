SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[vspDDUpdateHeaderForm]
/********************************
* Created: mj 1/12/05
* Modified:	
*
* Input:
*	@form		Form 
*	@position	comma delimited string of top, left, width, height
*	@rowheight	grid row height
*	@splitpos	Split position value

* Output:
*	@errmsg		error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @position varchar(20) = null, @splitpos int = null, @errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- don't update if viewpoint
if suser_sname()= 'viewpointcs' goto vspexit

-- try to update existing user lookup entry
update vDDFU
set FormPosition = @position, SplitPosition = @splitpos
where VPUserName = suser_sname() and Form = @form 
if @@rowcount = 0
	begin
	-- add new entry
	insert vDDFU (VPUserName, Form,  FormPosition, SplitPosition)
	select suser_sname(), @form,  @position, @splitpos
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateHeaderForm] TO [public]
GO
