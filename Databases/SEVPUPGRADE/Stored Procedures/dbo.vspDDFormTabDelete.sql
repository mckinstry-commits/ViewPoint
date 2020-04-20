SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspDDFormTabDelete]
/********************************
* Created: mj 8/11/04 
* Modified:	
*
* Called from DD Form Properties form to delete a custom tab
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
(@form varchar(30), @tab tinyint,  @errmsg varchar(60) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0



begin
	delete from vDDFTc where Form = @form and Tab = @tab 
	end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormTabDelete] TO [public]
GO
