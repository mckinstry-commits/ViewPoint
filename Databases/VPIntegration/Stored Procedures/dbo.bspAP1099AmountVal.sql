SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspAP1099AmountVal]
   /*************************************
   *Created by MV 03/18/03
   *Modified by 
   *			
   *
   * Usage:
   *	validates 1099 Amount
   *
   * Input params:
   *	@V1099Amt	1099 Amount to be validated
   *
   *Output params:
   *	@msg		error text
   *
   * Return code:
   *	0 = success, 1= failure
   *
   **************************************/
   	(@V1099amt bDollar = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @V1099amt is null
   	begin
   	select @msg = 'Missing 1099 Amount.', @rcode = 1
   	goto bspexit
   	end
   
   
   if @V1099amt < 0 or isnumeric(@V1099amt) = 0
   	begin
   	select @msg = 'Not a valid 1099 Amount.', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAP1099AmountVal] TO [public]
GO
