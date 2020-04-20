SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLClosedMthSubVal    Script Date: 8/28/99 9:34:42 AM ******/
   CREATE  procedure [dbo].[bspGLClosedMthSubVal]
   /******************************************************
   *	MODIFIED BY: MV 01/31/03 - #20246 dbl quote cleanup.
   *				 MV 04/28/06 - #27762 change err msg mth to 'mm/yy'
   *				 kb 7/13/6 - #121843 put @rcode = 1 back in there
   *				 MV 07/24/06 - #27762 change month in err message to mm + 1
   * validates that a month has been closed in subledgers in GL
   *
   * pass in GL Co#, and Month
   * returns 0 if successfull, 1 and error msg if error
   *******************************************************/
   
   	@glco bCompany, @mth bMonth, @msg varchar(60) output
   as 
   set nocount on
   declare @lastmthsubclsd bMonth, @rcode int,@month int, @year int
   	
   select @rcode = 0, @month = 0,@year = 0
   	
   /* check GL Company - get info */
   select @lastmthsubclsd = LastMthSubClsd from bGLCO where GLCo = @glco
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   /* check if Month is open */
   
   if @mth > @lastmthsubclsd
   	begin
	select @month = convert(int,month(@lastmthsubclsd))
	select @year = convert(varchar(4),year(@lastmthsubclsd))
	select @msg = 'Month must be before ' + convert(varchar(2),case @month when 12 then 1 else (@month + 1) end) + '/'
	select @msg = @msg + case @month when 12 then RIGHT(convert(varchar(4),(@year + 1)),2)
	 else RIGHT(convert(varchar(4),@year), 2) end
   	--select @msg = 'Month must be before ' + convert(varchar(2),@month) + 
	--'/' + RIGHT(convert(varchar(4),year(@lastmthsubclsd)),2)

		--convert(varchar(12),@lastmthsubclsd,1), @rcode=1
select @rcode = 1
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLClosedMthSubVal] TO [public]
GO
