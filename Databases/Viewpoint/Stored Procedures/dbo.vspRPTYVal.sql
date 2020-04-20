SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspRPTYVal]
/***************************************
* Created: ??
* Modified: GG 1/18/07 - cleanup
*
* Validates Report Type
*
* Inputs:
*	@reporttype		Report Type to validate
*
* Output:
*	@msg			Report Type desription or error message
*
* Return code:
*	0 = success, 1 = error
*
*************************************/
 
	(@reporttype varchar(10) = null, @msg varchar(60) output)
as
set nocount on
declare @rcode int, @cnt int, @active bYN
select @rcode = 0

if @reporttype is null
	begin
	select @msg = 'Missing Report Type.', @rcode = 1
	goto vspexit
	end

select @active = Active, @msg = Description
from dbo.RPTYShared (nolock)
where ReportType = @reporttype
if @@rowcount<>1
	begin
  	select @msg = 'Invalid Report Type', @rcode = 1
  	goto vspexit
	end
if @active <> 'Y'
	begin
	select @msg = 'Inactive Report Type', @rcode = 1
	goto vspexit
	end
  
vspexit:
  	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspRPTYVal] TO [public]
GO
