SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************/
 CREATE  proc [dbo].[bspPMProjIntfcVal]
 /***********************************************************
   * Created By:    GF 03/22/2000
   * Modified By:	GF 03/12/2008 - issue #127076 changed state to varchar(4)
   *
   * USAGE:
   * validates Projects from bJCJM
   * and returns the description
   * an error is returned if any of the following occurs
   * no job passed, no project found in JCJM
   *
   * INPUT PARAMETERS
   *   PMCo   		PM Co to validate against
   *   Project    	Project to validate
   *   StatusString	semi-colon deliminated string for status check.
   *
   * OUTPUT PARAMETERS
   *   @Status   Staus of Job
   *   @LiabTemp Liability Template
   *   @PRState  PR State
   *   @msg      error message if error occurs otherwise Description of Project
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
 (@pmco bCompany = 0, @project bJob = null, @StatusString varchar(60) = null,
  @Status tinyint output, @liabtemplate smallint output, @prstate varchar(4) output,
  @msg varchar(255) output)
 as
 set nocount on
 
 declare @rcode int
 
 select @rcode = 0
 
 if @pmco is null
    	begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
 
 if @project is null
    	begin
    	select @msg = 'Missing project!', @rcode = 1
    	goto bspexit
    	end
 
 -- -- -- get job info
 select @msg=Description, @Status=JobStatus, @liabtemplate=LiabTemplate, @prstate=PRStateCode
 from JCJM where JCCo=@pmco and Job=@project
 if @@rowcount = 0
 	begin
 	select @msg = 'Project not on file!', @rcode = 1
 	goto bspexit
 	end
 
 -- -- -- Check to see if the status on this project is contained in the string passed in
 if charindex(convert(varchar,@Status), @StatusString) = 0
 	begin
 	select @msg = 'Invalid status on project!', @rcode = 1
 	goto bspexit
 	end
 
 
 
 
 
 bspexit:
 	if @rcode<>0 select @msg = isnull(@msg,'')
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjIntfcVal] TO [public]
GO
