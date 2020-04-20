SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCGLCoGet    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE    proc [dbo].[bspJCGLCoGet]
   /********************************************************
   * CREATED BY: 	SE 5/7/97
   * MODIFIED BY: TV - 23061 added isnulls
   *
   * USAGE:
   * 	Retrieves the GLCompany from JobCost
   *
   * INPUT PARAMETERS:
   *	JC Company number
   *
   * OUTPUT PARAMETERS:
   *	GLCo
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@jcco bCompany, @glco bCompany output, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   Select @msg = ''
   
   
   select @glco = GLCo from bJCCO with (nolock) where JCCo = @jcco
   if @@rowcount = 1 
      select @rcode=0
   else
      select @msg = 'JC company does not exist.', @rcode=1, @glco=0
   
   if @glco is Null 
      select @msg = 'JC Company is not setup for Job Cost company ' + isnull(convert(varchar(3),@jcco),'') , @rcode=1, @glco=0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCGLCoGet] TO [public]
GO
