SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCostTypeVal    Script Date: 3/27/2002 9:32:13 AM ******/
CREATE proc [dbo].[bspJCCostTypeVal]
/***********************************************************
* CREATED BY:	JM   10/21/96
* MODIFIED By:	LM 9/16/97
*				RM 02/28/01 - Changed Cost type to varchar(10)
*				TV - 23061 added isnulls
*
* USAGE:
* validates JC Cost Type
* an error is returned if any of the following occurs
* not Cost Type passed, no Cost Type found.
*
* INPUT PARAMETERS
*   PhaseGroup
*   CostType
*
* OUTPUT PARAMETERS
*   @desc     Description for grid
*   @msg      error message if error occurs otherwise Description returned
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@phasegroup tinyint = null, @costtype varchar(10) = null, @costtypeout bJCCType = null output,
 @desc varchar(60) output, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
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
	select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
	from JCCT with (nolock)
	where PhaseGroup = @phasegroup and CostType = convert(int,convert(float, @costtype))
	end

---- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
	from JCCT with (nolock)
	where PhaseGroup = @phasegroup and CostType=(select min(j.CostType)
	from bJCCT j with (nolock) where j.PhaseGroup=@phasegroup
	and j.Abbreviation like @costtype + '%')
	if @@rowcount = 0
		begin
		select @msg = 'JC Cost Type not on file!', @rcode = 1
		goto bspexit
		end
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCostTypeVal] TO [public]
GO
