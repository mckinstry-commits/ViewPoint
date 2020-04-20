SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************/
CREATE     procedure [dbo].[bspINLocValForMSHaul]
/*************************************
   * Created By:  GF 01/07/2001
   * Modified By:
   *				RM 12/23/02 Cleanup Double Quotes
 *					GF 02/08/2006 - issue #120169 use @inco material group for validation
 *
   *
   * validates IN Locations for MSHaulEntryLines
   *
   * Pass:
   *  INCo        - Inventory Company
   *  Location    - Location to be Validated
   *  MatlGroup   - Material group
   *  Material    - Material
   *
   * Success returns:
   *  Description of Location
   *
   * Error returns:
   *	1 and error message
   **************************************/
  (@inco bCompany = null, @loc bLoc, @activeopt bYN, @matlgroup bGroup = null,
   @material bMatl = null, @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int, @validcnt int, @active bYN, @tomatlgroup bGroup
  
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
  
  select @active=Active, @msg = Description
  from bINLM where INCo = @inco and Loc = @loc
  if @@rowcount = 0
       begin
       select @msg='Not a valid Location', @rcode=1
       goto bspexit
       end
  
  if @activeopt = 'Y' and @active = 'N'
       begin
       select @msg = 'Not an active Location', @rcode=1
       goto bspexit
       end

-- -- -- get IN company material group
select @tomatlgroup=MatlGroup
from bHQCO with (nolock) where HQCo=@inco


-- -- -- validate material to IN materials
if @tomatlgroup is not null and @material is not null
	begin
	select @validcnt=count(*) from bINMT
	where INCo=@inco and Loc=@loc and MatlGroup=@tomatlgroup and Material=@material
	if @validcnt = 0
		begin
		select @msg = 'Material is not set up for the IN To Location', @rcode = 1
		goto bspexit
		end
	end




bspexit:
	--if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocValForMSHaul] TO [public]
GO
