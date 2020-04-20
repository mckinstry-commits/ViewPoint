SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDSetupFormVal]
/***********************************************************
* Created By: GG 06/02/04
* Modified By: 
*
* Used by Field Overrides to validate a Setup/Maintaince form
*
* Input Parameters
*   @form       Form 
*
* Output Paramseters
*   @msg		Form title or error message	
*
* Return Value
*	@rcode		0 = success, 1 = error
*
************************************************************************/
  	(@form varchar(30) = null, @msg varchar(255) output)
as
  
set nocount on
declare @rcode int, @formtype tinyint
select @rcode = 0
  
if @form is null
	begin
  	select @msg = 'Missing Form!', @rcode = 1
  	goto vspexit
  	end
  
select @msg = Title, @formtype = FormType
from DDFHShared
where Form = @form 
if @@rowcount = 0
  	begin
  	select @msg = 'Form not on file!', @rcode = 1
	goto vspexit
  	end
if @formtype <> 1
	begin
	select @msg = 'Must be a setup form!', @rcode = 1
	goto vspexit
	end
	
  
vspexit:
	if @rcode<>0 select @msg = @msg + char(13) + char(10) + '[vspDDSetupFormVal]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDSetupFormVal] TO [public]
GO
