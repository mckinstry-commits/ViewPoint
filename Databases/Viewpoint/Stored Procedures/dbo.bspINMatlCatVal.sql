SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINMatlCatVal]
   /*************************************
   * Created By: GR 11/6/99
   * Modified By: RM 12/23/02 Cleanup Double Quotes
   *
   * validates Category
   *
   * Pass:
   *	INCO, Category
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@inco bCompany = null, @category varchar(10) = null, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @matlgroup bGroup
   	select @rcode = 0
   
   if @inco is null
       begin
       select @msg='Missing IN Company', @rcode=1
       goto bspexit
       end
   
   if @category is null goto bspexit
   
   select @matlgroup=MatlGroup from bHQCO where HQCo=@inco
   
   if @matlgroup is not null
       begin
       select @msg=Description from bHQMC where MatlGroup=@matlgroup and Category=@category
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Category', @rcode = 1
   		end
       end
   
   bspexit:
    --   if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMatlCatVal] TO [public]
GO
