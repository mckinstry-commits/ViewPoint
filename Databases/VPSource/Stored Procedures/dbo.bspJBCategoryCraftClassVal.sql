SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBCategoryCraftClassVal]
/***********************************************************
* CREATED BY:     kb 8/7/00
* MODIFIED By :    bc 8/16/00 - make sure the class is valid in and of itself
*		TJL 07/13/06 - Issue #28183, 6x Recode JBLaborCategories.  Check for RestrictByClassYN = Y
*		TJL 05/31/07 - Issue #28183, Remove Duplicate JBLX check.  Done before Saving record in form.
*
* USAGE:
*
* INPUT PARAMETERS
*   JBCo      JB Co to validate against
*
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
@jbco bCompany, @laborcat varchar(10), @craft bCraft, @class bClass,
	@restrictbyclassyn bYN = 'N', @msg varchar(255) output
   
as
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@restrictbyclassyn, '') <> 'Y'
   	begin
   	select @msg = 'Restrict By Class input must be selected/checked if a Class value is entered.', @rcode = 1
   	goto bspexit
   	end

if @jbco is null
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto bspexit
	end
   
select 1 
from PRCC with (nolock)
where Class = @class
if @@rowcount = 0
	begin
	select @msg = 'Invalid class.', @rcode = 1
	goto bspexit
	end
   
/*check if this craft/class combination exists on anyother
labor category for this company, if so then this one can't be added here*/
-- Removed 05/31/07:  
--if exists(select * from bJBLX where JBCo = @jbco and LaborCategory <> @laborcat
--	and (Craft = @craft or (Craft is null and @craft is null))
--	and (Class = @class or (Class is null and @class is null)))
--	begin
--	select @msg = 'Craft/Class combination exists for another labor category', @rcode = 1
--	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBCategoryCraftClassVal] TO [public]
GO
