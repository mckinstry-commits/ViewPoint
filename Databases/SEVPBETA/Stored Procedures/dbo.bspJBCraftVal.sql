SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBCraftVal    Script Date: 8/28/99 9:33:15 AM ******/
CREATE proc [dbo].[bspJBCraftVal]
/***********************************************************
* CREATED BY: 	08/16/00 bc
* MODIFIED By :	TJL 07/13/06 - Issue #28183, 6x Recode JBLaborCategories.  Check for RestrictByCraftYN = Y
*
* USAGE:
* validates Craft to see if it exists in any PRCo
*
* INPUT PARAMETERS
*   Craft  PR Craft to validate against
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/ 
   
(@craft bCraft = null, @restrictbycraftyn bYN = 'N', @msg varchar(90) output)
as
   
set nocount on
   
declare @rcode int
   
select @rcode = 0
   
if isnull(@restrictbycraftyn, '') <> 'Y'
   	begin
   	select @msg = 'Restrict By Craft input must be selected/checked if a Craft value is entered.', @rcode = 1
   	goto bspexit
   	end

if @craft is null
	begin
	select @msg = 'Missing PR Craft.', @rcode = 1
	goto bspexit
	end
   
select @msg=Description 
from PRCM with (nolock)
where Craft = @craft
if @@rowcount = 0
   	begin
   	select @msg = 'Craft not on file.', @rcode = 1
   	goto bspexit
   	end
   
bspexit:
   	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBCraftVal] TO [public]
GO
