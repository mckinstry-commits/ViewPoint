SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINLocGroupVal]
   /***************************************************************************
   * Created By: GR 11/04/99
   *				RM 12/23/02 Cleanup Double Quotes
   *
   * validates Location Group
   *
   * Pass:
   *	Material, Material Group, Unit of Measure
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   *****************************************************************************/
   	(@inco bCompany = null, @locgroup bGroup = null, @msg varchar(255) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @inco is null
       begin
       select @msg='Missing Company', @rcode=1
       goto bspexit
       end
   
   if @locgroup is null
   	begin
   	select @msg = 'Missing Location Group', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=Description from bINLG where INCo=@inco and LocGroup=@locgroup
   	if @@rowcount = 0
   		begin
   		select @msg = 'Location Group not set up in Location Group Master', @rcode = 1
   		end
   
   bspexit:
      -- if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocGroupVal] TO [public]
GO
