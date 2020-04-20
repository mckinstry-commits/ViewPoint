SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspJCLiabTmplDesc]
/***********************************************************
* CREATED BY:	DANF 04/25/2005 
* MODIFIED By:	CHS 01/31/2008 - issue #124189
*				
* USAGE:
* Used in JC Liability templates to return the a description to the key field.
*
* INPUT PARAMETERS
*   JCCo   			JC Co 
*   LiabTemplate  	Insurance template
*
* OUTPUT PARAMETERS
*   @msg      Description of Template if found.
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@jcco bCompany = 0, @liabtemplate smallint = null, @basisearningscodes bYN output, @msg varchar(60) output)

  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  @liabtemplate is not null
		begin
			select @msg = Description 
			from dbo.JCTH with (nolock)
			where JCCo = @jcco and LiabTemplate = @liabtemplate


			-- return 'N' if no basis earnings codes exist for LiabType
			set @basisearningscodes = 'Y'

			select @basisearningscodes = 'N' 
				where exists(select top 1 1 from JCTL l with (nolock) 
								left join JCTE e with (nolock) 
									on l.JCCo = e.JCCo 
									and l.LiabTemplate = e.LiabTemplate 
									and l.LiabType = e.LiabType
								where l.CalcMethod = 'R' 
										and e.EarnCode is null 
										and l.JCCo = @jcco
										and l.LiabTemplate = @liabtemplate)

		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCLiabTmplDesc] TO [public]
GO
