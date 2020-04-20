SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             PROCEDURE [dbo].[vspDDGetFormPosition]
/********************************
* Created: mj 2/20/06
* Modified: 
*
* Input:
*	@vpusername	VPUsername
*	@form		Form name
*
* Output:
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@form varchar(30) = null, @vpusername varchar(30) = null,  @errmsg varchar(5000) output)
as
set nocount on

declare @rcode int

select @rcode = 0

	begin
	SELECT FormPosition 
	from vDDFU 
	where Form = @form and VPUserName = @vpusername
	End

	if @@rowcount = 0
	begin
	select @errmsg = 'Missing required input parameters: Form!', @rcode = 1
	goto vspexit
	end


select @errmsg = 'Could not retrieve form position for ' + @form

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDGetFormPosition]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDGetFormPosition] TO [public]
GO
