SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspJCRateTemplateMove]
   /************************************************************
    * CREATED BY: 	 DANF 02/19/07
    * MODIFIED By :	
    *
    * USAGE:
    * Replaces all old rates in JC Rate Template
    *
    * INPUT PARAMETERS
    *   @jcco      JC Co
    *   @template  Rate Template
    *
    * OUTPUT PARAMETERS
    *   @msg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@jcco bCompany, @template smallint, @msg varchar(255) output
   as
   set nocount on
   
   declare @rcode int
  
   select 	@rcode = 0
   
   select @msg = 'An error has occurred'
   
   if not exists(select top 1 1 from dbo.bJCCO with (nolock) where JCCo=@jcco)
       begin
       select @msg = isnull(@msg,'') + ' Invalid JC Company!'
       select @rcode = 1
       end
   
   if not exists(select top 1 1 from dbo.bJCRT with (nolock) where  JCCo = @jcco and RateTemplate=@template )
       begin
       select @msg = isnull(@msg,'') +  ' The combination of Company - ' + convert(varchar(30),@jcco) + ' and Rate Template - ' + convert(varchar(4),@template) + ' Does not exist!'
       select @rcode = 1
       end
   
   if @rcode <> 0
   begin
   	goto bspexit
   end
   
   /* copy old to new rates in bPRCI */
   update dbo.bJCRD
   set OldRate = NewRate
   where JCCo = @jcco and RateTemplate = @template
   
  
   
   bspexit:
   	select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCRateTemplateMove] TO [public]
GO
