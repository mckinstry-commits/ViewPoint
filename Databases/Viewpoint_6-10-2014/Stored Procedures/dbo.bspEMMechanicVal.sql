SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMMechanicVal]
/*************************************************************************************
* Created By:  JM 6/9/00
* Modified By: DANF 08/17/00 Changed to use view PREHName
*		TV 02/11/04 - 23061 added isnulls
*		TJL  06/14/07 - Issue #27974, 6x Rewrite.  Return FullName in same format as PREHFullName.FullName
* Usage: Validates Mechanic by either Sort Name or number.
*
* Input params:
*	   @prco       PRCo
*	   @mech	      Mech SortName or Number
*
* Output params:
*	   @mechout	   Mech number
*	   @msg		   Mech Name or error message
*
* Return code:
*	   0 = success, 1 = failure
**********************************************************************************/
(@prco bCompany = null,
	@mech varchar(15) = null,
	@mechout bEmployee = null output,
	@msg varchar(255) output)
   
as

set nocount on

declare @rcode int

select @rcode = 0
   
if @prco is null
	begin
	select @msg = 'Missing PR Company', @rcode = 1
	goto bspexit
	end

if @mech is null
	begin
	select @msg = 'Missing Mechanic', @rcode = 1
	goto bspexit
	end
   
-- If @mech is numeric then try to find Mech number
if isnumeric(@mech) = 1
select @mechout=Employee, @msg=isnull(LastName, '') + ', ' + isnull(FirstName, '') + ' ' + isnull(MidName, '')
from PREHName where PRCo=@prco and Employee=convert(int,convert(float, @mech))
-- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @mechout=Employee, @msg=isnull(LastName, '') + ', ' + isnull(FirstName, '') + ' ' + isnull(MidName, '')
	from PREHName where PRCo=@prco and SortName=@mech
	-- if not found, try to find closest
	if @@rowcount = 0
  		begin
		set rowcount 1
		select @mechout=Employee, @msg=isnull(LastName, '') + ', ' + isnull(FirstName, '') + ' ' + isnull(MidName, '')
		from PREHName
		where PRCo=@prco and SortName like @mech + '%'
		if @@rowcount = 0
  			begin
			select @msg = 'Not a valid Mechanic', @rcode = 1
			goto bspexit
			end
		end
	end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')		--+ char(13) + char(10) + '[bspEMMechanicVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMMechanicVal] TO [public]
GO
