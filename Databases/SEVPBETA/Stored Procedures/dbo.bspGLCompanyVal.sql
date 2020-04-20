SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLCompanyVal    Script Date: 8/28/99 9:34:42 AM ******/
   CREATE  proc [dbo].[bspGLCompanyVal]
   /*************************************
   *	MODIFIED BY:	MV 01/31/03 - #20246 dbl quote cleanup.
   * validates GL Company number
   *
   * Pass:
   *	GL Company number
   *
   * Success returns:
   *	0 and Company name from bHQCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@glco bCompany = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @glco is null
   	begin
   	select @msg = 'Missing GL Company#', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from GLCO where @glco = GLCo)
   	begin
   	select @msg = Name from bHQCO where HQCo = @glco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid GL company ', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLCompanyVal] TO [public]
GO
