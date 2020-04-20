SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCACCostTypeVal   *****/
CREATE     proc [dbo].[vspJCACCostTypeVal]
/*************************************
 * Created By:	DANF 05/26/2005
 * Modified By:
 *
 *
 * USAGE:
 * Called from JCAC to validate the cost type.
 *
 *
 * INPUT PARAMETERS
 * @phasegroup
 * @phase
 * @costtype
 * @costtypeout
 * @desc
 * @msg
 *
 * Success returns:
 * 0, cost type and description
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@phasegroup bGroup, @phase bPhase, @costtype varchar(10) = null, @costtypeOut bJCCType output, @Desc bDesc output, @msg varchar(255) output)
as
set nocount on

declare @rc int, @rcode int, @errortext varchar(255)

select @rc = 0, @rcode = 0, @msg = ''

if isnull(@phasegroup,'') = ''
	begin
   	select @msg = 'Phase group is missing.', @rc = 1
   	goto bspexit
	end

if isnull(@costtype,'') = ''
	begin
   	select @msg = 'Cost Type is missing.', @rc = 1
   	goto bspexit
	end


if isnull(@phase,'') = '' 
	begin
		exec @rcode = dbo.bspJCCostTypeVal @phasegroup, @costtype, @costtypeOut  output, @Desc output, @msg = @msg output
	end
else
	begin
		exec @rcode = dbo.bspJCVCOSTTYPEForAlloc @phasegroup, @phase, @costtype, @costtypeout = @costtypeOut output, @desc = @Desc output, @msg = @msg output
	end

select @rc = @rcode

bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rc

GO
GRANT EXECUTE ON  [dbo].[vspJCACCostTypeVal] TO [public]
GO
