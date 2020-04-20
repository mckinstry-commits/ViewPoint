SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspHQReasonCodeVal] 
   /********************************************************
   	Created RM 03/02/01
   	
   	Usage:
   		Validates Reason Code
   
   	Pass in
   		@ReasonCode
   
   	returns
   		@rcode
   
   ********************************************************/
   (@reasoncode bReasonCode,@errmsg varchar(255) output)
   
   AS
   
   declare @rcode int
   
   select @rcode = 0
   
   if not exists(select * from bHQRC where ReasonCode = @reasoncode)
   begin
   	select @rcode = 1,@errmsg = 'Reason Code not setup in HQ Reason Codes.'
   	goto bspexit
   end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQReasonCodeVal] TO [public]
GO
