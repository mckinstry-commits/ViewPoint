SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspHQReasonCodeVal] 
 /********************************************************
 	Created: RT 08/31/05
 	
 	Usage:
 		Validates Reason Code 
 
 	Pass in
 		@ReasonCode
 
 	returns
 		@rcode, Description
 
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
 else
 begin
	select @errmsg = Description from HQRC where ReasonCode = @reasoncode
 end

 bspexit:
 return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQReasonCodeVal] TO [public]
GO
