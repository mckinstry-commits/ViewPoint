SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCostCodeVal    Script Date: 8/28/99 9:34:18 AM ******/
   CREATE  proc [dbo].[bspCostCodeVal]
   /******************************************
   * validate Cost Code
   *
   * Pass;
   *	EM group and Cost Code
   *
   * Succuss returns:
   *	0 and description from EMRC
   *
   * Error returns:
   *	1 and error message
   *******************************************/
   	(@emgroup bGroup = null, @costcode bCostCode = null, @msg varchar(60) output)
   as
   	set nocount on 
   	declare @rcode int
   	select @rcode = 0
   
   if @costcode is null
   	begin
   	select @msg = 'Missing Cost Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bEMCC where EMGroup = @emgroup and CostCode = @costcode
   	if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Cost Code', @rcode = 1
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCostCodeVal] TO [public]
GO
