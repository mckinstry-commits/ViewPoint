SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUMVal    Script Date: 8/28/99 9:34:55 AM ******/
   CREATE    proc [dbo].[bspHQUMVal]
   /*************************************
   * validates HQ Unit of Measure vs HQUM.UM
   *
   * Pass:
   *	HQ UM
   *
   * Success returns:
   *	0 and Description from bHQUM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@um bUM = null, @msg varchar(256) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
if @um is null or @um = ''
   	begin
   	select @msg = 'Missing Unit of Measure', @rcode = 1
   	goto bspexit
   	end


   
   select @msg = Description from bHQUM with (nolock) where UM = @um
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Unit of Measure', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQUMVal] TO [public]
GO
