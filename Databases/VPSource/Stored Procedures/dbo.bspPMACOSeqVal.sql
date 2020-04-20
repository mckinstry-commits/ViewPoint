SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspPMACOSeqVal]
  /***********************************************************
   * CREATED BY: CJW 12/18/97
   * MODIFIED By: GF 05/08/2000
   *				GF 07/06/2005 - issue #29167 added validation for JCOH using ACOSequence.
   *
   * USAGE:
   *	Validates PMOH.ACOSequence as not duplicating an existing PMOH.ACOSequence
   *	for the same PMOH.PMCo, PMOH.Project, PMOH.ACO.
   *	An error is returned if any of the following occurs
   *	no company passed
   *	no project passed
   *	no ACO passed
   *	matching ACOSequence found in PMOH
   *
   * INPUT PARAMETERS
   *	PMCo
   *	Project
   *	ACO
   *	ACOSequence(validated)
   *
   * OUTPUT PARAMETERS
   *   @msg - error message if error occurs otherwise Description of ACO in PMOH
   *	to establish a rowcount
   * RETURN VALUE
   *   0 - Success
   *   1 - Failure
   *****************************************************/
  (@pmco bCompany = 0, @project bJob = null, @aco bACO = null, @acoseq smallint, @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int, @jcoh_aco bACO
  
  select @rcode = 0
  
  if @pmco is null
  	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end
  
  if @project is null
  	begin
  	select @msg = 'Missing Project!', @rcode = 1
  	goto bspexit
  	end
  
  if @aco is null
  	begin
  	select @msg = 'Missing ACO!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- check PMOH
  select @msg=Description from bPMOH with (nolock)
  where PMCo=@pmco and Project=@project and ACO<>@aco and ACOSequence=@acoseq
  if @@rowcount <> 0
  	begin
  	select @msg = 'Warning! ACO Sequence already on file for Project/ACO Sequence!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- check JCOH
  select @jcoh_aco=ACO from JCOH with (nolock)
  where JCCo=@pmco and Job=@project and ACO<>@aco and ACOSequence=@acoseq
  if @@rowcount <> 0
  	begin
  	select @msg = 'Warning! ACO Sequence already on file in JCOH for ACO: ' + isnull(@jcoh_aco,'') + '!', @rcode = 1
  	goto bspexit
  	end
  
  
  
  
  bspexit:
      if @rcode<>0 select @msg=isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMACOSeqVal] TO [public]
GO
