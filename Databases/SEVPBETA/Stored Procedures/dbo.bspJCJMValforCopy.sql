SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspJCJMValforCopy]
/***********************************************************
* CREATED BY: TV 05/28/01
* MODIFIED By : TV - 23061 added isnulls
*				CHS 11/20/08 - #130774 - added country output
*
* USAGE:
* validates JC Job
* if Job Exists an error is returned.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @ARCo
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @jobout bJob output, @country varchar(60) output, @msg varchar(255) output)
    as
    set nocount on  
   
    declare @rcode int

	select @country = (select DefaultCountry from HQCO with (nolock) 
						left join JCCO with (nolock) on @jcco = JCCO.JCCo and @jcco = JCCO.PRCo
						left join JCJM with (nolock) on @jcco = JCJM.JCCo and @job = JCJM.Job

	where HQCO.HQCo = isnull(JCCO.PRCo, JCJM.JCCo))   

    if @jcco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @job is null
    	begin
    	select @msg = 'Missing Job!', @rcode = 1
    	goto bspexit
    	end
   
    if exists (select * from bJCJM with (nolock) where JCCo = @jcco and Job = @job)
    	begin
    	select @msg = 'Job currently exists in the Job Master. Cannot complete Copy.', @rcode = 1
   	goto bspexit
    	end
   

   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMValforCopy] TO [public]
GO
