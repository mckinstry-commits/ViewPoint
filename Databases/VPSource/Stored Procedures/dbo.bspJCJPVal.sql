SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCJPVal    Script Date: 8/28/99 9:32:58 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCJPVal    Script Date: 2/12/97 3:25:05 PM ******/
   CREATE   proc [dbo].[bspJCJPVal]
   
   	(@jcco bCompany = 0, @job bJob = null, @phase bPhase = null, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: LM   01/21/97
    * MODIFIED By : LM   01/21/97
    *				TV - 23061 added isnulls
    * USAGE:
    * validates JC Phase against JCJP for the JC Projections form.  
    * an error is returned if any of the following occurs
    * no job passed, no phase passed.
    * 
    * This just validates the phase and returns a description
    *
    * 
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against 
    *   Job    Job to validate in JCJP
    *   Phase  Phase to validate 
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Phase
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   
   declare @rcode int, @numrows int
   
   select @rcode = 0
   
   
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
   
   if @phase is null
   	begin
   	select @msg = 'Missing phase!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* Check Job Phases */
   select @msg = Description 
   	from JCJP
   	where JCCo = @jcco and Job = @job and Phase = @phase
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Phase not set up in Job Phases', @rcode = 1
   	end
         
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJPVal] TO [public]
GO
