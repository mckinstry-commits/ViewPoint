SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLMonthVal    Script Date: 8/28/99 9:34:44 AM ******/
   CREATE   procedure [dbo].[bspGLMonthVal]
   /******************************************************
   * Created: ??
   * Last Modified: MV 01/31/03 - #20246 dbl quote cleanup.
   *				 GF 04/29/2005 - issue #26594 - beginning/ending month not in correct format.
   *
   *
   *
   * Validates a month for GL posting - must be after
   * last mth closed in GL and before or equal to last
   * mth closed in subledgers + max open mths
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
   
   /* check if Month is open */
   select @beginmth = dateadd(month, 1, @lastmthglclsd)
   select @endmth = dateadd(month, @maxopen, @lastmthsubclsd)
   
   if @mth < @beginmth or @mth > @endmth
   	begin
   	select @msg = 'Month must be between ' + isnull(substring(convert(varchar(8),@beginmth,1),1,3),'')
           + isnull(substring(convert(varchar(8), @beginmth, 1),7,2),'') + ' and '
           + isnull(substring(convert(varchar(8),@endmth,1),1,3),'') + isnull(substring(convert(varchar(8), @endmth, 1),7,2),'')
   	-- -- -- select @msg = 'Month must be between ' + convert(varchar(12),@beginmth,1) + ' and ' + convert(varchar(12), @endmth, 1)
   	select @rcode = 1
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLMonthVal] TO [public]
GO
