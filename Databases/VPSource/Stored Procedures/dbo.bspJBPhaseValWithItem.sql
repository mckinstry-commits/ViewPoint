SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBPhaseValWithItem]
   	(@co bCompany, @contract bContract, @PhaseGroup tinyint, @phase bPhase = null,
       @job bJob,@item bContractItem output, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: kb 11/27/00
    * MODIFIED By :
    *
    * USAGE:
    * validates JC Phase from Phase Master.
    * an error is returned if any of the following occurs
    * no phase passed, no phase found in JCPM.
    *
    * INPUT PARAMETERS
    *   PhaseGroup  JC Phase group for this company
    *   Phase       Insurance template to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Template description
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   
   	declare @rcode int
   	select @rcode = 0
   
   if @phase is null
   	begin
   	select @msg = 'Missing Phase', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = p.Description
   	from JCJP p join JCJM j on
       j.JCCo = p.JCCo and j.Job = p.Job
   	where PhaseGroup = @PhaseGroup and Phase = @phase
       and p.Contract = @contract
   
   if @@rowcount = 0
   	begin
   	/*select @msg = 'Phase not setup for a job on this contract.', @rcode = 1
   	goto bspexit*/
       select @msg = Description from JCPM where PhaseGroup = @PhaseGroup and Phase = @phase
       if @@rowcount = 0
           begin
           select @msg = 'Invalid phase', @rcode = 1
           goto bspexit
           end
   	end
   
   if @job is not null
       begin
       select @item = Item from JCJP where JCCo = @co and Job = @job and
         Phase = @phase and PhaseGroup = @PhaseGroup
       end
   else
       begin
       select @item = Item from JCJP where JCCo = @co and Phase = @phase
         and PhaseGroup = @PhaseGroup and Contract = @contract
       if @@rowcount = 0
           begin
           select @job = min(Job) from JCJM where JCCo = @co and Contract = @contract
           if @@rowcount <> 0
               begin
               select @item = Item from JCJP where JCCo = @co and Job = @job and
                 Phase = @phase and PhaseGroup = @PhaseGroup
               end
           end
       end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBPhaseValWithItem] TO [public]
GO
