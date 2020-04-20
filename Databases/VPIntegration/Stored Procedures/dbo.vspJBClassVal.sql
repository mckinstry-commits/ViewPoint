SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBClassVal    Script Date:  ******/
CREATE proc [dbo].[vspJBClassVal]
/***********************************************************
* CREATED BY: 		12/09/05  TJL
* MODIFIED By :
*
* USAGE:
* Validates Class to see if it exists in ANY PRCo.  Very loose validation for
* for JB T&M purposes only.  (very similar to bspJBCraftVal)
*
* INPUT PARAMETERS
*   Class  PR Class to validate against
*
* OUTPUT PARAMETERS
*   @msg      error message 
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/ 
  
(@class bClass = null, @msg varchar(90) output)
as
  
set nocount on
  
declare @rcode int
  
select @rcode = 0
  
if @class is null
	begin
	select @msg = 'Missing PR Class!', @rcode = 1
	goto vspexit
	end
  
select @msg=Description from PRCC where Class = @class
if @@rowcount = 0
	begin
	select @msg = 'Class not on file!', @rcode = 1
	goto vspexit
	end
  
vspexit:
  	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBClassVal] TO [public]
GO
