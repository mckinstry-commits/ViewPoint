SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE proc [dbo].[bspJCJRVal]
   /***********************************************************
    * CREATED BY:	MV   05/20/03
    * MODIFIED By: TV - 23061 added isnulls
    *				MV - 10/21/04 - #25703 - use 'if exists'
    *				GF - 11/04/2004 - issue #26021 added seq to input params for validating reviewer exists
    *
    * USAGE:
    * validates JCJR Reviewer
    * 
    * an error is returned if any of the following occurs
    * no job passed, no job found in JCJM, no reviewer found,
    * duplicate reviewer 
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against 
    *   Job    Job to validate
    *	 Reviewer JCJR Reveiwer
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Job
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@jcco bCompany = 0, @job bJob = null, @reviewer varchar(3) = null, @seq int = null,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
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
   
   if @reviewer is null
   	begin
   	select @msg = 'Missing Reviewer!', @rcode = 1
   	goto bspexit
   	end
   
   --validate JCCO
   if not exists (select 1 from bJCCO where JCCo = @jcco)
       begin
       select @msg = 'JCCo is Invalid ', @rcode = 1
       goto bspexit
   	end
   
   --validate Job
   if not exists (select 1 from bJCJM where JCCo = @jcco and Job = @job)
       begin
       select @msg = 'Job is Invalid ', @rcode = 1
       goto bspexit
   	end
   
   -- Validate Reviewer
   select @msg= Name from bHQRV where Reviewer=@reviewer
   if @@rowcount = 0
       begin
       select @msg = 'Reviewer is Invalid ', @rcode = 1
       goto bspexit
   	end
   
   -- Check for duplicate Reviewer
   if exists(select 1 from JCJR where JCCo=@jcco and Job=@job and Reviewer=@reviewer and Seq<>@seq)
   	begin
   	select @msg = 'Duplicate Reviewer', @rcode = 1
       goto bspexit
   	end
   
   
   
   
bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJRVal] TO [public]
GO
