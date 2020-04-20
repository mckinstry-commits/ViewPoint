SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEFTRouteIDVal    Script Date: 8/28/99 9:33:57 AM ******/
   CREATE   Procedure [dbo].[bspEFTRouteIDVal]
   /***********************************************************
    * CREATED BY: EN 12/07/00
    *	Modified by:	MAV 04/11/03 - #20931 - test for other stuff.
	*					MV 11/11/08 - #129234 - validate only for US
	*					EN 2/23/2011 #143236 - look up country using company # rather than passing country into proc
    *
    * USAGE:
    * Validates AP EFT Routing ID.  It must be exactly 9 digits long
    * and numeric.
    *
    * INPUT PARAMETERS
	*	@co			Company #
    *   @routeid	EFT Routing ID
    *
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of Company
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   	(@co bCompany = null, @routeid char(34) = null, @msg varchar(60) = null output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   
	IF (SELECT DefaultCountry FROM dbo.HQCO WHERE HQCo = @co) = 'US'
	BEGIN
	   if len(@routeid) <> 9 or isnumeric(@routeid) = 0
   		begin
   		select @msg = 'Routing ID must be 9 digits, numeric.', @rcode = 1
   		goto bspexit
   		end
	   
	   if charindex(',', @routeid) <> 0 or
   		charindex('-',@routeid) <> 0 or
   		charindex('.',@routeid) <> 0 or
   		charindex('+',@routeid) <> 0 
   		begin
   		select @msg = 'Routing ID must be 9 digits, numeric.', @rcode = 1
   		goto bspexit
   		end
	END
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEFTRouteIDVal] TO [public]
GO
