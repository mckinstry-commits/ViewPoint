SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQSMSAVal    Script Date: 8/28/99 9:32:48 AM ******/
   CREATE  proc [dbo].[bspHQSMSAVal]
   	(@smsacode varchar(10) = null, @msg varchar(60) output)
   as
   /***********************************************************
    * CREATED BY: SE   10/2/96
    * MODIFIED By : SE 10/2/96
    *
    * USAGE:
    * validates HQ SMSA Code
    * an error is returned if any of the following occurs
    * no SMSA code passed, or SMSA code doesn't exist in bHQSM
    *
    * INPUT PARAMETERS
    *   SMSACode   SMSA code to valideate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise description of SMSA code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @smsacode is null
   	begin
   	select @msg = 'Missing SMSA code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from HQSM
   	where SMSACode= @smsacode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'SMSA code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQSMSAVal] TO [public]
GO
