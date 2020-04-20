SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLGetLastMthGLClsd]
   /******************************************************
   * Created: bc 04/25/01
   * Modified:
   * Gets month has been closed in GL
   *
   * pass in JC Company
   * returns 0 if successfull, 1 and error msg if error
   *******************************************************/
   
   	@co bCompany, @lastmthclsd bMonth output, @msg varchar(60) output
   as
   set nocount on
   declare @glco bCompany, @rcode int
   
   select @rcode = 0
   
   --get lastmthsunclsd
   select @lastmthclsd = LastMthGLClsd
   from bGLCO
   where GLCo = @co
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
       if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspGLGetLastMthGLClsd]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLGetLastMthGLClsd] TO [public]
GO
