SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCustomerVal    Script Date: 8/28/99 9:32:47 AM ******/
   CREATE  proc [dbo].[bspHQCustomerVal]
   /* validates HQ Customer number
    * pass in Customer Group and Customer#
    * returns Company name or error msg if doesn't exist
   */
   	(@custgrp bGroup = null, @customer bCustomer = null, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @custgrp is null
   	begin
   	select @msg = 'Missing Customer Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @customer is null
   	begin
   	select @msg = 'Missing Customer!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Name from bARCM where CustGroup = @custgrp and Customer = @customer
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Customer!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQCustomerVal] TO [public]
GO
