SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspAPReasonCodeVal] 
   /********************************************************
   	Created MV 10/13/06
   	
   	Usage:
   		Validates Reason Code and returns description
		for APUnappInvRev
   
   	Pass in
   		@ReasonCode
   
   	returns
		description
   		@rcode
   
   ********************************************************/
   (@reasoncode bReasonCode,@msg varchar(255) output)
   
   AS
   
   declare @rcode int
   
   select @rcode = 0
   
   select @msg = Description from bHQRC where ReasonCode = @reasoncode
	if @@rowcount = 0
   begin
   	select @rcode = 1,@msg = 'Reason Code not setup in HQ Reason Codes.'
   	goto bspexit
   end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPReasonCodeVal] TO [public]
GO
