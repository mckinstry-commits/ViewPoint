SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRTemplateExistsVal]
   /************************************************************************
   * CREATED:  mh 7/26/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate a PR Template and return a Yes/No 
   *	Template does or does not exist.     
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany = 0, @template smallint, @templtexists bYN output, @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0, @templtexists = 'N'
   
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
   
   	select @msg = Description from dbo.PRTM with (nolock) where PRCo = @prco and Template=@template
   	if @@rowcount = 0
   		select @templtexists = 'N'
   	else
   		select @templtexists = 'Y'
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTemplateExistsVal] TO [public]
GO
