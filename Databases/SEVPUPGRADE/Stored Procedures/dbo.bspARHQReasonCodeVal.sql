SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARHQReasonCodeVal    Script Date 03/09/01 9:34:50 AM ******/
   CREATE  proc [dbo].[bspARHQReasonCodeVal]
   /*************************************
   * validates HQ Reason Codes
   *
   * Pass:
   *	HQ Reason Code to be validated
   *
   * Success returns:
   *	0 and Reason Code Description from bHQRC
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@reasoncode bReasonCode = null, @msg varchar(30) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @reasoncode is null
   	begin
   	select @msg = 'Missing HQ Reason Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from HQRC where ReasonCode = @reasoncode
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HQ ReasonCode', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARHQReasonCodeVal] TO [public]
GO
