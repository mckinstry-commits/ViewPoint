SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE  proc [dbo].[bspEMCostTypeVal]
/***********************************************************
 * CREATED BY: bc  3/31/98
 * MODIFIED By : bc 12/9/98
 *                   RM 02/28/01 - Changed cost type to varchar(10)
 *				TV 02/11/04 - 23061 added isnulls
 *
 * USAGE:
 * validates EM Cost Type
 * an error is returned if any of the following occurs
 * not Cost Type passed, no Cost Type found.
 *
 * INPUT PARAMETERS
 *   EMGroup
 *   CostType
 *
 * OUTPUT PARAMETERS
 *   @desc     Description for grid
 *   @msg      error message if error occurs otherwise Description returned
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@EMGroup bGroup, @costtype varchar(10) = null, @costtypeout bEMCType = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @EMGroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end

if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end

---- If @costtype is numeric then try to find
if isnumeric(@costtype) = 1
   	begin
   	select @costtypeout = CostType, @msg = Description
   	from EMCT with (nolock)
   	where EMGroup = @EMGroup and CostType = convert(int,convert(float, @costtype))
   	if @@rowcount <> 0 goto bspexit
   	end
   
---- if not numeric or not found try to find as Sort Name
select @costtypeout = CostType, @msg = Description 
from EMCT with (nolock)
where EMGroup = @EMGroup and CostType=(select min(e.CostType) from bEMCT e where e.EMGroup=@EMGroup 
   											and e.Abbreviation like @costtype + '%')
if @@rowcount = 0
   	begin
   	select @msg = 'EM Cost Type not on file!', @rcode = 1
   	goto bspexit
	end


bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostTypeVal] TO [public]
GO
