SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDFTVal]
/***************************************
* Created: GG 09/13/07
* Modified: 
*
* Used to validate standard Form Tabs in vDDFT
*
* Inputs:
*	@form			Form
*	@tab			Tab		
*
* Outputs:
*	@msg			Tab title or error message
*
* Return code:
*	0 = success, 1 = error
*
**************************************/
(@form char(30) = null, @tab tinyint = null, @msg varchar(60) = null output)

as
set nocount on

declare @rcode int
select @rcode = 0

if @form is null or @tab is null
	begin
	select @msg = 'Missing Form and/or Tab#!', @rcode = 1
	goto vspexit
	end

select @msg = Title 
from dbo.vDDFT (nolock)
where Form = @form and Tab = @tab
if @@rowcount = 0
	begin
	select @msg = 'Invalid Tab, not setup in DDFT!', @rcode = 1
	end

vspexit:
	return @rcode


--grant EXECUTE on vspDDFTVal to public

GO
GRANT EXECUTE ON  [dbo].[vspDDFTVal] TO [public]
GO
