SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRW2ItemVal    Script Date: 8/28/99 9:35:42 AM ******/
   CREATE  procedure [dbo].[bspPRW2ItemVal]
   /******************************************************
    * CREATED BY: EN 11/20/98
    * MODIFIED By : EN 11/20/98
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *	Validates that Item is set up for the specified TaxYear in bPRWI.
    *
    * Input params:
    *	@TaxYear	Tax Year
    *	@Item		Item code
    *
    * Output params:
    *	@msg		Code description or error message
    *
    * Return code:
    *	0 = success, 1 = failure
   *******************************************************/
   
   	@TaxYear char(4), @Item tinyint, @msg varchar(60) output
   as 
   set nocount on
   declare @rcode int
   	
   select @rcode = 0
   
   select @msg = Description from bPRWI where TaxYear = @TaxYear and Item = @Item
   if @@rowcount = 0
   	begin
   	 select @msg = 'Invalid item!', @rcode = 1
   	 goto bspexit
   	end
   
    bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRW2ItemVal] TO [public]
GO
