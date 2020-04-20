SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************/
CREATE proc [dbo].[vspEMCostTypeVal]
/***********************************************************
 * CREATED BY:
 * MODIFIED By:	GF 12/14/2007 - changed to allow for a new cost type
 *
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
(@EMGroup bGroup, @costtype varchar(10) = null, @costtypeout bEMCType = null output,
 @msg varchar(255) output)
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
if dbo.bfIsInteger(@costtype) = 1 and len(@costtype) < 4
	begin
	if convert(numeric(3,0),@costtype) < 0 or convert(numeric(3,0),@costtype) > 255
		begin
		select @msg = 'EM Cost Type must be between 0 and 255.', @rcode = 1
		goto bspexit
		end
	select @costtypeout = CostType, @msg = Description
	from EMCT
	where EMGroup = @EMGroup and CostType = convert(int,convert(float, @costtype))
	end

---- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
   	select @costtypeout = CostType, @msg = Description 
   	from EMCT with (nolock)
   	where EMGroup = @EMGroup and CostType=(select min(e.CostType) from bEMCT e where e.EMGroup=@EMGroup 
   			and e.Abbreviation like @costtype + '%')
	if @@rowcount = 0
	   	begin
		if dbo.bfIsInteger(@costtype) = 1 and len(@costtype) < 4
			select @costtypeout = @costtype
		else
			select @costtypeout = null
		end
	end


bspexit:
   	if @rcode <> 0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCostTypeVal] TO [public]
GO
