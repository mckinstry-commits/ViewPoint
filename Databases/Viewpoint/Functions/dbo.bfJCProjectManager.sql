SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       function [dbo].[bfJCProjectManager]
  (@jcco bGroup, @job bJob)
      returns varchar(30)
   /***********************************************************
    * CREATED BY	: DANF 09/14/05
    * MODIFIED BY	
    *
    * USAGE:
    * Used to return the Project Manager
    *
    * INPUT PARAMETERS
    * 	@jcco bGroup
    * 	@job bJob
 
    *
    * OUTPUT PARAMETERS
    *  @name     Project manager name
    *
    *****************************************************/
      as
      begin
  
 		declare @name varchar(30), @rcode int, @msg varchar(255)
 
 
 		-- get the project manager name
 		select @name = Name
 		from JCMP m with (nolock)
 		join JCJM j with (nolock)
 		on m.JCCo = j.JCCo and m.ProjectMgr = j.ProjectMgr
 		where j.JCCo = @jcco and j.Job = @job
 
 
  	exitfunction:
  			
  	return isnull(@name,'')
     end

GO
GRANT EXECUTE ON  [dbo].[bfJCProjectManager] TO [public]
GO
