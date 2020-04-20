SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspMSTicFromLocVal]
/*************************************
 * Created By:   GF 07/11/2000
 * Modified By: GG 01/24/01 - initialized output parameters to null
 *
 * USAGE:   Validate From Location entered in MSTicEntry
 *
 * INPUT PARAMETERS
 *  @inco			IN/MS Company
 *  @loc			Location to be validated
 *  @activeopt		if 'Y', Location must be active
 *
 * OUTPUT PARAMETERS
 *  @locgroup		IN Location Group
 *  @wghtopt		Weight Option (0 = N/A, 1 = lbs, 2 = tons, 3 = kilos)
 *  @taxcode		Tax Code
 *  @haultaxopt	    Haul Tax Option (0 = not taxable, 1 = tax w/haul vendor, 2 = taxable)
 *  @msg      		Location description or error message
 *
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 **************************************/
(@inco bCompany = null, @loc bLoc = null, @activeopt bYN = null, @locgroup bGroup = null output,
 @wghtopt tinyint = null output, @taxcode bTaxCode = null output, @haultaxopt tinyint = null output,
 @msg varchar(100) = null output)
as
set nocount on

declare @rcode int, @active bYN

select @rcode = 0

if @inco is null
   	begin
   	select @msg = 'Missing IN Company', @rcode = 1
   	goto bspexit
   	end

if @loc is null
   	begin
   	select @msg = 'Missing IN Location', @rcode = 1
   	goto bspexit
   	end


select @active=Active, @msg=Description, @locgroup=LocGroup, @wghtopt=WghtOpt,
		@taxcode=TaxCode, @haultaxopt=HaulTaxOpt
from INLM with (nolock) where INCo = @inco and Loc = @loc
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Location', @rcode=1
	goto bspexit
	end
   
if @activeopt = 'Y' and @active = 'N'
	begin
	select @msg = 'Not an active Location', @rcode=1
	goto bspexit
	end


bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicFromLocVal] TO [public]
GO
