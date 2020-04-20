SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCRateTemplateDesc]
  /***********************************************************
   * CREATED BY: DANF 02/15/07
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Rate Template Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   JCCo   			JC Co 
   *   Template 		Template
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Rate Template if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@jcco bCompany = 0, @ratetemplate smallint = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  isnull(@ratetemplate,'') <> ''
		begin
		  select @msg = Description 
		  from dbo.JCRT with (nolock)
		  where JCCo = @jcco and RateTemplate = @ratetemplate
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCRateTemplateDesc] TO [public]
GO
