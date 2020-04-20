SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspCMGetCMCOGLCo]
   /************************************************************************
   * CREATED:  mh 10/4/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Get the GLCo set up in CMCO for a given CM Company
   *    
   *           
   * Notes about Stored Procedure
   * 
   *	Issue 25601
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@cmco bCompany = null, @glco bCompany = null output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @cmco is null 
   	begin
   		select @msg = 'Missing CM Company', @rcode = 1
   		goto bspexit
   	end
   
   	select @glco = GLCo
   	from dbo.CMCO with (nolock) where CMCo = @cmco
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMGetCMCOGLCo] TO [public]
GO
