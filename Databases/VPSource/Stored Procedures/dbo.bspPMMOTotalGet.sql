SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMMOTotalGet]
   /********************************************************
   * Created By:   GF	02/15/2002
   * Modified By:
   *
   *
   * USAGE:
   *   Retrieves the total cost for a Jobs MO. The total for
   *   a material order is the sum of the items in INMI and
   *   the items in PMMF.
   *
   * USED IN
   *   PMMOItems
   *
   * INPUT PARAMETERS:
   *   PMCo
   *	INCo
   *	Project
   *	MO
   *
   * OUTPUT PARAMETERS:
   *	MO Amount
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@pmco bCompany = null, @inco bCompany = null, @project bJob = null, @mo varchar(10) = null,
    @amount bDollar output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @amount = 0
   
   if @pmco is null
       begin
   	select @msg = 'Missing PM Company', @rcode = 1
   	goto bspexit
   	end
   
   if @inco is null
       begin
   	select @msg = 'Missing IN Company', @rcode = 1
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing PM Project', @rcode = 1
   	goto bspexit
   	end
   
   if @mo is null
   	begin
   	select @msg = 'Missing MO ', @rcode = 1
   	goto bspexit
   	end
   
   
   -- get amount from INMI items
   select @amount = sum(i.TotalPrice) 
   from bINMO h with (nolock) 
   join bINMI i with (nolock) on h.INCo=i.INCo and h.MO=i.MO
   where h.INCo=@inco and h.MO=@mo
   
   -- now add in PMMF items
   select @amount=isnull(@amount,0) + isnull(sum(Amount),0) 
   from bPMMF with (nolock) 
   where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo and InterfaceDate is null
   and ((RecordType='O' and ACO is null) or (RecordType='C' and ACO is not null))
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'') 
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMOTotalGet] TO [public]
GO
