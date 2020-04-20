SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLTransVal    Script Date: 8/28/99 9:34:46 AM ******/
   CREATE  proc [dbo].[bspGLTransVal]
   /***************************************************
    *	MODIFIED BY:	MV 01/03/03 - #20246 dbl quote cleanup.
    *
    * validates GL Transaction
    * pass in GL Co#,Month, and Trans#
    * returns Trans description
   */
   	(@glco bCompany = 0, @mth bMonth = null, @gltrans bTrans = 0,
   	 @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Month!', @rcode = 1
   	goto bspexit
   	end
   
   if @gltrans = 0
   	begin
   	select @msg = 'Missing GL Transaction!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bGLDT
   	where GLCo = @glco and Mth = @mth and GLTrans = @gltrans
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Transaction not on file!', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLTransVal] TO [public]
GO
