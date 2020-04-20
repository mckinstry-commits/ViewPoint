SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDFTRelatedVal]
/***************************************
* Created: RM 04-29-08
* Modified: 
*
* Used to validate standard Form Tabs in vDDFT, and verify that they have a related grid.
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

declare @relatedgrid varchar(30)

if @form is null or @tab is null
	begin
	select @msg = 'Missing Form and/or Tab#!', @rcode = 1
	goto vspexit
	end

select @msg = Title, @relatedgrid=GridForm 
from dbo.DDFTShared (nolock)
where Form = @form and Tab = @tab
if @@rowcount = 0
	begin
	select @msg = 'Invalid Tab, not setup in DDFT!', @rcode = 1
	goto vspexit
	end

if @relatedgrid is null
begin
	select @msg = 'Must select a tab with a related grid form!', @rcode = 1
	goto vspexit
end



vspexit:
	return @rcode

--go
--grant EXECUTE on [vspDDFTRelatedVal] to public

GO
GRANT EXECUTE ON  [dbo].[vspDDFTRelatedVal] TO [public]
GO
