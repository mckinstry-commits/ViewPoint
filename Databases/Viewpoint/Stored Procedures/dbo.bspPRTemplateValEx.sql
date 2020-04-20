SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRTemplateValEx]
   /************************************************************************
   * CREATED:	mh 8/9/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate a PR Template and check for use in JC Job Master
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany, @template smallint, @inusejc varchar(5) = 'False' output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @jcco bCompany
   
       select @rcode = 0, @inusejc = 'False'
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company!', @rcode = 1
   		goto bspexit
   	end
   	
   	if @template is null
   	begin
   		select @msg = 'Missing PR Template!', @rcode = 1
   		goto bspexit
   	end
   
   	exec @rcode = dbo.bspPRTemplateVal @prco, @template, @msg output
   
   	if @rcode = 0
   	begin
   
   		select @jcco = JCCo from dbo.PRCO with (nolock) where PRCo = @prco
   
   		if @jcco is not null
   		begin
   			if exists(select CraftTemplate 
   					from dbo.JCJM with (nolock) 
   					where JCCo = @prco and CraftTemplate = @template)
   				select @inusejc = 'True'
   		end
   	end
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTemplateValEx] TO [public]
GO
