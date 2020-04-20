SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQFreqVal    Script Date: 8/28/99 9:34:50 AM ******/
   CREATE  procedure [dbo].[bspHQFreqVal]
   /*************************************
   * validates HQ Frequency Codes
   *
   * Pass:
   *	HQ Frequency Code to be validated
   *
   * Success returns:
   *	0 and Description from bHQFC
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@freq bFreq = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @freq is null
   	begin
   	select @msg = 'Missing Frequency code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bHQFC where Frequency = @freq
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Frequency code.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQFreqVal] TO [public]
GO
