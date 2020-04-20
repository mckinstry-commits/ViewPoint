SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRAccJCJobVal]
/************************************************************************
* CREATED:	mh 5/6/2005    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*   Validate Job entered in HR Accidents against JCJM.  Returned LockPhases
*	flag.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany = nully, @jcco bCompany = null, @job bJob = null, @lockphases bYN output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int, @jobout bJob

    select @rcode = 0


	select @lockphases = LockPhases, @msg = j.Description 
	from JCJM j
	where j.JCCo = @jcco 
	and j.Job = @job 

  	if @@rowcount = 0
  	begin
  		select @msg = 'Job not on file!', @rcode = 1
  		goto bspexit
  	end

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAccJCJobVal] TO [public]
GO
