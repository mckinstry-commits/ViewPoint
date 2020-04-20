SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMLocVal]
/*************************************
* validates Location
*
*	TV 02/11/04 - 23061 added isnulls
*	TV 10/18/05 moved to 6X
* Pass:
*	EMCO, Location
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
	(@emco bCompany = null, @loc bLoc = null, @msg varchar(60) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0

if @loc is null
	begin
	select @msg = 'Missing location', @rcode = 1
	goto bspexit
	end

select @msg = Description from bEMLM where EMCo = @emco and EMLoc = @loc
	if @@rowcount = 0
		begin
		select @msg = 'Not a valid Location', @rcode = 1
		end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMLocVal] TO [public]
GO
