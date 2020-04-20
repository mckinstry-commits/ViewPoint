SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLJrnlVal    Script Date: 8/28/99 9:34:44 AM ******/
   CREATE proc [dbo].[bspGLJrnlValForGLJE]
   /*******************************************************
    * Created By:	GF 01/03/2002 - issue #19599 
    * Modified By:
    *
    * validates GL Journal
    * pass in GL Co# and Journal
    * returns Journal description
   ********************************************************/
   (@glco bCompany = 0, @jrnl bJrnl = null, @toco bCompany = 0, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @rev bYN
   
   select @rcode = 0
   
   if isnull(@glco,0) = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@jrnl,'') = ''
   	begin
   	select @msg = 'Missing Journal!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@toco,0) = 0
   	begin
   	select @msg = 'Missing To Company!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate journal
   select @msg = Description, @rev=Rev
   from bGLJR with (nolock) where GLCo = @glco and Jrnl = @jrnl
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Journal ' + @jrnl + ' not on file for GLCo # ' + convert(varchar(5),@glco) + ' !', @rcode = 1
   	goto bspexit
   	end
   
   -- done if company = to company
   if @glco = @toco goto bspexit
   
   -- if auto reversal is true for from company journal, GL company must equal To company
   if @rev = 'Y'
   	begin
   	select @msg = 'GL Journal: ' + @jrnl + ' is a auto-reversal journal. GL Company and To Company must be the same.', @rcode = 1
   	goto bspexit
   	end
   
   -- now check the To Company journal reversal flag, GL company must equal To company
   select @rev=Rev from bGLJR with (nolock) where GLCo=@toco and Jrnl=@jrnl
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Journal ' + @jrnl + ' not on file for To Co # ' + convert(varchar(5),@toco) + ' !', @rcode = 1
   	goto bspexit
   	end
   if @rev = 'Y'
   	begin
   	select @msg = 'GL Journal: ' + @jrnl + ' is a auto-reversal journal. GL Company and To Company must be the same.', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLJrnlValForGLJE] TO [public]
GO
