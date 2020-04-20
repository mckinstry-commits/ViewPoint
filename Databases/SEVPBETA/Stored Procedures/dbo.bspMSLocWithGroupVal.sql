SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspMSLocWithGroupVal]
   /***************************************************************************
   * Created By:   GF 02/21/2000
   * Modified By:  TerryLis 1/10/2007  Fixed validation of location 
   *
   * validates Location by Location Group
   *
   * Pass:
   *	Company, Location Group, Location
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   *****************************************************************************/
   (@inco bCompany = null, @locgroup bGroup = null, @loc bLoc = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int, @inlmgroup bGroup
   
   select @rcode = 0
   
   if @inco is null
       begin
       select @msg='Missing Company!', @rcode=1
       goto bspexit
       end
   
   /*
   if @locgroup is null
   	begin
   	select @msg = 'Missing Location Group!', @rcode = 1
   	goto bspexit
   	end
   */
   
   -- if @loc is null goto bspexit
   
   if @locgroup is not null
       begin
       select @validcnt = Count(*) from bINLG where INCo=@inco and LocGroup=@locgroup
       if @validcnt = 0
           begin
           select @msg = 'Invalid Location Group!', @rcode=1
           goto bspexit
           end
       end
   
   select @msg=Description, @inlmgroup=LocGroup from bINLM where INCo=@inco and Loc=@loc
   if @@rowcount= 0
       begin
			select @msg = 'Invalid Location!', @rcode=1
			goto bspexit
       end
   
   if @locgroup is not null and @inlmgroup<>@locgroup
       begin
			select @msg = 'Location not set up for Location Group!', @rcode=1
			goto bspexit
       end
   
   bspexit:
       --if @rcode<>0 select @msg=@msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSLocWithGroupVal] TO [public]
GO
