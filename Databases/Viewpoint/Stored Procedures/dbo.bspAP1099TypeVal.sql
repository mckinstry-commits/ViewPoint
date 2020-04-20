SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAP1099TypeVal    Script Date: 8/28/99 9:32:30 AM ******/
   CREATE procedure [dbo].[bspAP1099TypeVal]
   /*************************************
   *Created by GG 06/13/97
   *Modified by GG 03/31/97
   *			MV 10/18/02 - 18878 quoted identifier cleanup
   *				CHS	05/30/2012	- B-08928 make 1099 changes to Australia
   *
   * Usage:
   *	validates 1099 types
   *
   * Input params:
   *	@V1099type	1099 Type to be validated
   *
   *Output params:
   *	@msg		Description from bAPTT or error text
   *
   * Return code:
   *	0 = success, 1= failure
   *
   **************************************/
   	(@V1099type varchar(10) = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @V1099type is null
   	begin
   	select @msg = 'Missing Type.', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Description from APTT where V1099Type = @V1099type
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Type.', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAP1099TypeVal] TO [public]
GO
