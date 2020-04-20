SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBLaborCatgyVal]
   /*************************************
   * created : 05/17/00 bc
   *
   * Pass:
   *
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@jbco bCompany, @lbrcatgy varchar(10), @msg varchar(255) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @lbrcatgy is null
   	begin
   	select @msg = 'Missing labor category', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from JBLC
   where JBCo = @jbco and LaborCategory = @lbrcatgy
   
   if @@rowcount = 0
     begin
     select @msg = 'Not a valid labor category', @rcode = 1
     end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBLaborCatgyVal] TO [public]
GO
