SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDResetFormReports]
/********************************
* Created: GG 09/19/06  
* Modified:	
*
* Called from Form Properties to remove all custom linked Report
* info from a specific form.
*
* Input:
*	@form		current form name
*
* Output:
*	@errmsg		error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null, @errmsg varchar(255) output)
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

if @form is null  
	begin
	select @errmsg = 'Missing parameter values!', @rcode = 1
	goto vspexit
	end

-- remove any linked Report info for the Form
delete dbo.vRPFDc where Form = @form	-- custom parameter defaults

delete dbo.vRPFRc where Form = @form	-- custom report links


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDResetFormReports] TO [public]
GO
