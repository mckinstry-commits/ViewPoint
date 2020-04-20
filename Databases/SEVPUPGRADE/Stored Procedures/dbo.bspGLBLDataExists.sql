SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBLDataExists    Script Date: 8/28/99 9:34:40 AM ******/
   CREATE  proc [dbo].[bspGLBLDataExists]
   /*************************************
   * Created by: JM 5/3/98
   * Modified by:	MV 01/31/03 - #20246 dbl quote cleanup.
   *
   * Returns whether records exist in GLBL for a Co and GLAcct.
   *
   * Pass:
   *	GLCo
   *	BLAcct
   *
   * Success returns:
   *	0 and whether or not detail exists (0 = false, 1 = true)
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@glco bCompany = null, @glacct bGLAcct = null, 
   	@dataexists tinyint = 0 output, @msg varchar(60) output)
   as 
   set nocount on
   declare @rcode int
   select @rcode = 0
   select @dataexists = 0 --false
   	
   if @glco is null
   	begin
   	select @msg = 'Missing GLCo', @rcode = 1
   	goto bspexit
   	end
   
   if @glacct is null
   
   	begin
   	select @msg = 'Missing GLAcct', @rcode = 1
   	goto bspexit
   	end
   
   /* need to verify jrn is passed; if ok, then run select */
   select * 
   	from bGLBL 
   	where GLCo = @glco and GLAcct = @glacct
   if @@rowcount > 0 select @dataexists = 1 --true
   
   bspexit:
   	if @rcode = 1 
   	select @msg = @msg + ' - can''t determine if records exist for this GLAcct!'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBLDataExists] TO [public]
GO
