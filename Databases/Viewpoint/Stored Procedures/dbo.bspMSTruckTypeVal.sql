SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************/
CREATE  proc [dbo].[bspMSTruckTypeVal]
/*************************************
* Created By:   GF 02/29/2000
* Modified By:
*
* validates MS Truck Type
*
* Pass:
*	MS Company and MS Truck Type to be validated
*
* Success returns:
*	0 and Description from bMSTT
*
* Error returns:
*	1 and error message
**************************************/
(@msco bCompany = null, @trucktype varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end

if @trucktype is null
   	begin
   	select @msg = 'Missing MS Truck Type', @rcode = 1
   	goto bspexit
   	end

select @msg = Description from MSTT with (nolock) where MSCo=@msco and TruckType = @trucktype
if @@rowcount = 0
	begin
	select @msg = 'Not a valid MS Truck Type', @rcode = 1
	goto bspexit
	end



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTruckTypeVal] TO [public]
GO
