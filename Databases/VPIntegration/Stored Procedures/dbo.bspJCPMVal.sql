SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspJCPMVal]
   /***********************************************************
    * CREATED BY: SE   10/11/96
    * MODIFIED By : SE 10/11/96
    *				TV - 23061 added isnulls
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
   (@PhaseGroup tinyint, @phase bPhase = null, @msg varchar(60) output)
   as
   set nocount on
   
   
   
   	declare @rcode int
   	select @rcode = 0
   
   if @phase is null
   	begin
   	select @msg = 'Missing Phase', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from JCPM
   	where PhaseGroup = @PhaseGroup and Phase = @phase
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Phase not setup in Phase Master.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPMVal] TO [public]
GO
