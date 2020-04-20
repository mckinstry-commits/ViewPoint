SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDSecurityFormVal]
/***********************************************************
* Created: GG 09/05/07
* Modified: 
*
* Usage:
*	Validates Security Form value.  Must be a standard form or equal to the current form.
*
* Inputs:
*   @form			Form 
*	@securityform	Security Form
*
* Outputs:
*   @msg			Form Title or error message 
*
* Return code:
*   0 = success, 1 = error
* 
************************************************************************/
	(@form varchar(30) = null, @securityform varchar(30) = null,  @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0
  
if @form is null or @securityform is null
	begin
  	select @msg = 'Missing Form or Security Form - cannot validate!', @rcode = 1
  	goto vspexit
  	end

-- validate Security Form
select @msg = Title
from dbo.vDDFH (nolock) where Form = @securityform
if @@rowcount = 0
  	begin
	if @securityform = @form goto vspexit	-- allow self reference, may be adding a new form
	select @msg = 'Form not on file!', @rcode = 1
	end
  
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDSecurityFormVal] TO [public]
GO
