SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCompanyValWithGLCo    Script Date: 8/28/99 9:35:01 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCCompanyValWithGLCo    Script Date: 12/3/97 3:25:03 PM ******/
   CREATE   proc [dbo].[bspJCCompanyValWithGLCo]
   /*************************************
   * CREATED: kf 12/3/97
   * validates JC Company number and returns Description and information from JCCofrom HQCo
   *			TV - 23061 added isnulls
   * Pass:
   *	From JC Company number
   *	To   JC Company number
   *
   * Success returns:
   *	0, Company description, From GLCo and To GLCo from bJCCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@fromjcco bCompany = 0, @tojcco bCompany = 0, 
	@fromglco bCompany output, @toglco bCompany output, 
	@msg varchar(60) output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @fromjcco = 0
   	begin
   	select @msg = 'Missing the from JC Company#', @rcode = 1
   	goto bspexit
   	end

   if @tojcco = 0
   	begin
   	select @msg = 'Missing the to JC Company#', @rcode = 1
   	goto bspexit
   	end
   
   exec @rcode = bspJCCompanyVal @fromjcco, @msg output
   if @rcode <> 0 
		begin
		select @msg = 'Error in the From JC Company. ' + @msg
		goto bspexit
		end
   
   exec @rcode = bspJCCompanyVal @fromjcco, @msg output
   if @rcode <> 0 
		begin
			select @msg = 'Error in the To JC Company. ' + @msg
			goto bspexit
		end
   
   
   select @fromglco = GLCo from dbo.bJCCO with (nolock) where JCCo = @fromjcco
   
   select @toglco = GLCo from dbo.bJCCO with (nolock) where JCCo = @tojcco

   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCompanyValWithGLCo] TO [public]
GO
