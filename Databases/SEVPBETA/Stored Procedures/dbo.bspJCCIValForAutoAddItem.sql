SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspJCCIValForAutoAddItem]
/***********************************************************
* CREATED BY:	GF 08/08/2002 - Issue #17355 AutoAddItemYN flag enhancement
* MODIFIED By:	TV - 23061 added isnulls
*				CHS 06/16/2009 - issue #132119 - auto add item
*
* USAGE:
* validates JC contract item
* an error is returned if any of the following occurs
* no contract passed, no item passed, no item found in JCCI.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   Contract  Contract to validate against
*   Item      Contract item to validate
*	 Job		Job to validate for auto add item.
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Contract Item
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = null, @contract bContract = null, @item bContractItem = null,
@job bJob = null, @phasegroup bGroup = null, @phase bPhase = null, @msg varchar(255) output)

   as
   set nocount on
   
   declare @rcode int, @autoadditemyn bYN, @validcnt int
   
   select @rcode = 0, @validcnt = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @contract is null
   	begin
   	select @msg = 'Missing Contract!', @rcode = 1
   	goto bspexit
   	end
   
   if @item is null
   	begin
   	select @msg = 'Missing Contract item!', @rcode = 1
   	goto bspexit
   	end
   
   select @autoadditemyn=AutoAddItemYN
   from bJCJM where JCCo=@jcco and Job=@job
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate contract item - if AutoAddItemYN = 'N' then required
   if isnull(@autoadditemyn,'N') = 'N'
   	begin
   	select @msg = Description 
   	from bJCCI where JCCo = @jcco and Contract = @contract and Item = @item
   	if @@rowcount = 0
   		begin
   		select @msg = 'Contract Item not on file!', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end
   
   -- validate contract item - if AutoAddItemYN = 'Y' then check JCCH.SourceStatus
   if isnull(@autoadditemyn,'N') = 'Y'
   	begin
   	select @msg = Description
   	from bJCCI with (nolock) where JCCo = @jcco and Contract = @contract and Item = @item
   	if @@rowcount <> 0 goto bspexit
   	-- missing contract item - check SourceStatus for phase cost types in JCCH
--   	select @validcnt = count(*)
--   	from bJCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and SourceStatus in ('J','I')
--   	if @validcnt <> 0
--   		begin
--   		select @msg = 'Invalid contract item - some phase cost types have source status of (J) or (I).', @rcode = 1
--   		goto bspexit
--   		end
   	end
   
   select @msg = 'New contract item'
   
   
   
   bspexit:
       if @rcode<>0 select @msg=@msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCIValForAutoAddItem] TO [public]
GO
