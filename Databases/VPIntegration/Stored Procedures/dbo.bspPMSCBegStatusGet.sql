SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPMSCBegStatusGet    Script Date: 8/28/99 9:35:19 AM ******/
   CREATE proc [dbo].[bspPMSCBegStatusGet]
   /*************************************
   * Created By:	GF 08/14/2003
   * Modified By:
   *
   *
   * Gets a default beginning status from PMSC for PM Company
   *
   * Pass:
   * PM Company
   *
   * Returns:
   * StatusCode
   *
   * Success returns:
   *	0
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@pmco bCompany = null, @beginstatus bStatus = null output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- get beginning status from bPMCo - if no status in PMCO find first with StatusType = 'B'
   select @beginstatus = BeginStatus from bPMCO with (nolock) where PMCo=@pmco and BeginStatus is not null
   if @@rowcount = 0
   	begin
   	select @beginstatus = Status from bPMSC with (nolock) where CodeType = 'B'
   	if @@rowcount = 0
   		begin
   		select @msg = 'Missing Beginning Status!', @rcode = 1
   		goto bspexit
   		end
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSCBegStatusGet] TO [public]
GO
