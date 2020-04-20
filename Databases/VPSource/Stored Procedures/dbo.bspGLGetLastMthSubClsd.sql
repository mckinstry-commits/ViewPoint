SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLGetLastMthSubClsd]
   /******************************************************
   * Created: GR 09/29/00
   * Modified:
   * Gets month has been closed in subledgers in GL
   *
   * pass in JC Company
   * returns 0 if successfull, 1 and error msg if error
   *******************************************************/
   
   	@co bCompany, @lastmthsubclsd bMonth output, @msg varchar(60) output
   as
   set nocount on
   declare @glco bCompany, @rcode int
   
   select @rcode = 0
   
   --get GL Company
   select @glco=GLCo from bJCCO where JCCo=@co
   if @@rowcount = 0
       begin
       select @msg = 'Nat a valid JC Company!', @rcode=1
       goto bspexit
       end
   
   --get lastmthsunclsd
   select @lastmthsubclsd = LastMthSubClsd from bGLCO where GLCo = @glco
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
       if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspGLGetLastMthSubClsd]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLGetLastMthSubClsd] TO [public]
GO
