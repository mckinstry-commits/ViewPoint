SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[bspGLCOfromHRCO]
   /*******************************************************
   	Created 02/23/01 RM
   
   	this procedure gets the PRCo based on the passed in HRCo
   
   	pass in HRCo
   
   	returns PRCo
   		rcode
   
   *	Modified 6/29/01	
   *	This should return the GL Company assigned to a PRCo in PRCO.
   *	Using PRCo obtained from HRCO to get GLCo from PRCO.
   
   *******************************************************/
   (@hrco bCompany, @glco bCompany = null output, @msg varchar(255) output)
   as
   
   declare @rcode int, @prco bCompany
   select @rcode = 0
   
   if not exists(select HRCo from HRCO with (nolock) where HRCo = @hrco)
   begin
   	select @msg = 'Invalid HR Company',@rcode = 1
   	goto bspexit
   end
   
   select @prco = PRCo from HRCO with (nolock)
   where HRCo = @hrco
   
   --added code
   
   if @prco is null
   	begin
   		select @msg = 'Cannot get PRCo.', @rcode = 1
   		goto bspexit
   	end
   
   select @glco = GLCo from PRCO with (nolock)
   where PRCo = @prco
   
   if @glco is null
   	begin
   		select @msg = 'Cannot get GLCo.', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLCOfromHRCO] TO [public]
GO
