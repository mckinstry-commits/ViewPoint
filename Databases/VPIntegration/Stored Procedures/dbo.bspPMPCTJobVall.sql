SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Proc [dbo].[bspPMPCTJobVall]
   (@jcco bCompany = 0, @job bJob = null, @contract bContract = null output,
    @item bContractItem output, @msg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: TV   05/05/01 !Cinco de Mayo!
    * MODIFIED By : 
    *
    * USAGE:
    * validates JC Job For the PMPCTDet form								
    * and returns contract and Contract Description
    * an error is returned if any of the following occurs
    * no job passed, no job found in JCJM, no contract found in JCCM
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against 
    *   Job    Job to validate
    *
    * OUTPUT PARAMETERS
    *   @contract returns the contract for this job.  
    *   @contractdesc returns the contract desc for this contract                       
    *   @msg      error message if error occurs otherwise Description of Job
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   
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
   
   
   
   select @msg = Description, @contract= Contract, @item = Item 
   from JCJP with (nolock) where JCCo = @jcco and Job = @job 
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file, or no associated contract!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCTJobVall] TO [public]
GO
