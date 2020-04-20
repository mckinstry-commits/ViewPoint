SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCACOSeqVal    Script Date: 8/28/99 9:32:56 AM ******/
   CREATE proc [dbo].[bspJCACOSeqVal]
   /***********************************************************
    * CREATED BY: JM 4/11/97
    * MODIFIED By: GF 07/23/98
    *				TV - 23061 added isnulls
    *				GF 07/06/2005 - issue #29167 added validation for PMOH using ACOSequence.
    *
    *
    * USAGE:
    *   Validates JCOH.ACOSequence as not duplicating an existing 
    * 	JCOH.ACOSequence for same JCOH.JCCo, JCOH.Job, JCOH.ACO, and
    *	JCOH.ApprovalDate 	
    *   An error is returned if any of the following occurs
    * 	no Company passed
    *	no Job passed
    *	no ACO passed
    *	no ApprovalDate passed
    *	no ACOSequence passed
    *	matching ACOSequence found in JCOH
    *
    * INPUT PARAMETERS
    *	JCCo
    *	Job
    *	ACO
    *	ApprovalDate
    *	ACOSequence (validated)
    *
    * OUTPUT PARAMETERS
    *   @msg - error message if error occurs otherwise Description of ACO in JCOH
    *	to establish a rowcount
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/ 
   (@jcco bCompany = 0, @job bJob = null, @aco bACO = null, @apprdate bDate, 
    @acoseq smallint, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @pmoh_aco bACO
   
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
   
   if @aco is null
   
   	begin
   	select @msg = 'Missing ACO!', @rcode = 1
   	goto bspexit
   	end
   
   if @apprdate is null
   	begin
   	select @msg = 'Missing Approval Date!', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- check JCOH
   select @msg=Description from JCOH with (nolock)
   where JCCo=@jcco and Job=@job and ACO<>@aco and ACOSequence=@acoseq
   if @@rowcount <> 0
   	begin
   	select @msg = 'Warning! ACO Sequence already on file for Job/ACO Sequence!', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- check PMOH
   select @pmoh_aco=ACO from PMOH with (nolock)
   where PMCo=@jcco and Project=@job and ACO<>@aco and ACOSequence=@acoseq
   if @@rowcount <> 0
   	begin
   	select @msg = 'Warning! ACO Sequence already on file in PMOH for ACO: ' + isnull(@pmoh_aco,'') + '!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- -- -- select @msg = Description
   -- -- -- 	from JCOH
   -- -- -- 	where JCCo = @jcco and 
   -- -- -- 		Job = @job and 
   -- -- -- 		ACO <> @aco and		
   -- -- -- /*		ApprovalDate = @apprdate and 	*/
   -- -- -- 		ACOSequence = @acoseq
   -- -- -- 
   -- -- -- if @@rowcount <> 0
   -- -- -- 	begin
   -- -- -- /*	select @msg = 'Warning! ACO Sequence already on file for this Job/ACO/Approval Date!', @rcode = 1 */
   -- -- -- 	select @msg = 'Warning! ACO Seq already on file for Job/ACO Seq!', @rcode = 1 
   -- -- -- 	goto bspexit
   -- -- -- 	end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCACOSeqVal] TO [public]
GO
