SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRGLCoVal    Script Date: 8/28/99 9:35:32 AM ******/
   CREATE  procedure [dbo].[bspPRGLCoVal]
   /******************************************************
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *
   * validates that the GLCo and makes sure the month is 
   * open for its subledgers
   *
   * pass in GL Co#, and Month
   * returns 0 if successfull, 1 and error msg if error
   *******************************************************/
   
   	@glco bCompany, @mth bMonth, @msg varchar(60) output
   as 
   set nocount on
   declare @lastmthsubclsd bMonth, @lastmthglclsd bMonth,
   	 @maxopen tinyint, @beginmth bMonth, @endmth bMonth,
   	 @rcode int
   	
   select @rcode = 0
   	
   /* check GL Company - get info */
   select @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd,
   	@maxopen = MaxOpen from bGLCO where @glco = GLCo
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid GL Company!', @rcode = 1
   	goto bspexit
   	end
   /*set ending month to last mth closed in subledgers + max # of open mths */
   select @endmth = dateadd(month, @maxopen, @lastmthsubclsd)
   
   
   select @beginmth = dateadd(month, 1, @lastmthsubclsd)
   	if @mth < @beginmth or @mth > @endmth
   		begin
   		select @msg = 'Month must be between ' + convert(varchar(12),@beginmth,1) + ' and ' + 
   			convert(varchar(12), @endmth,1) + ' for this GLCo.'
   		select @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRGLCoVal] TO [public]
GO
