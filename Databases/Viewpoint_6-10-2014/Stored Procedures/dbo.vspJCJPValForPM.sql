SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************************/
CREATE  proc [dbo].[vspJCJPValForPM]
/***********************************************************
 * CREATED BY:	GF 01/19/2002
 * MODIFIED By: TV - 23061 added isnulls
 *				GF 07/25/2005 - changed for 6.x added additional parameters
 *
 *
 *
 * USAGE:
 * validates PM Phase against JCJP for the PM Cost Types form.  
 * an error is returned if any of the following occurs
 * no job passed, no phase passed.
 * 
 * This just validates the phase and phase information
 * and valid partial phase.
 *
 * INPUT PARAMETERS
 *   JCCo   JC Co to validate against 
 *   Job    Job to validate in JCJP
 *   Phase  Phase to validate
 *
 * OUTPUT PARAMETERS
 * @pphase			valid portion of phase (may not match passed phase)
 * @phasetota		total from phase from JCCH
 * @item			phase contract item
 * @item_desc		contract item description
 * @item_um			contract item UM
 * @item_units		contract item original units
 * @item_unitprice	contract item unit price
 * @item_amount		contract item original amount
 * @msg      error message if error occurs otherwise Description of Phase
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/ 
(@jcco bCompany = 0, @job bJob = null, @phase bPhase = null,
 @pphase bPhase = null output, @phasetotal bDollar = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validphasechars int, @phasegroup bGroup, @inputmask varchar(30),
		@contract bContract, @item bContractItem

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

-- get Phase Group
select @phasegroup = PhaseGroup from HQCO where HQCo = @jcco
if @@rowcount <> 1
	begin
	select @msg = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
	goto bspexit
	end

-- -- -- get phase total
select @phasetotal = isnull(sum(OrigCost),0) 
from JCCH (nolock) where JCCo=@jcco and Job=@job and Phase=@phase

-- validate JC Company -  get valid portion of phase code
select @validphasechars = ValidPhaseChars from JCCO where JCCo=@jcco
if @@rowcount <> 1
	begin
	select @msg = 'Invalid Job Cost Company!', @rcode = 1
	goto bspexit
	end

-- -- -- get contract from JCJM
select @contract=Contract
from JCJM with (nolock) where JCCo=@jcco and Job=@job
if @@rowcount = 0
	begin
	select @msg = 'Job not set up in Job Master.', @rcode = 1
	goto bspexit
	end

-- first check Job Phases - exact match
select @msg = Description, @pphase=Phase, @item=Item
from JCJP where JCCo = @jcco and Job = @job and Phase = @phase
if @@rowcount = 0
	begin
  	select @msg = 'Phase not set up in Job Phases', @rcode = 1
  	goto bspexit
  	end

-- -- -- -- -- -- get phase contract item info from JCCI
-- -- -- select @item_desc=Description, @item_um=UM, @item_units=OrigContractUnits,
-- -- -- 		@item_unitprice=OrigUnitPrice, @item_amount=OrigContractAmt
-- -- -- from JCCI with (nolock) where JCCo=@jcco and Contract=@contract and Item=@item


-- check for a valid portion
if isnull(@validphasechars,0) = 0 goto skipvalidportion

-- get the format for datatype 'bPhase'
select @inputmask = InputMask from DDDTShared where Datatype = 'bPhase'
if @@rowcount = 0
	begin
	select @msg = 'Missing (bPhase) datatype in DDDTShared!', @rcode = 1    -- should always exist
	goto bspexit
	end

-- format valid portion of Phase
select @pphase = substring(@phase,1,@validphasechars) + '%'

-- check valid portion of Phase in Job Phase table
select TOP 1 @pphase = Phase
from JCJP where JCCo = @jcco and Job = @job and Phase like @pphase
Group By JCCo, Job, Phase

skipvalidportion:
-- full match in Phase Master will override description from partial match in Job Phase
select @pphase = isnull(Phase,@phase)
from JCPM where PhaseGroup = @phasegroup and Phase = @phase




bspexit:
	if @rcode<>0 select @msg=@msg
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJPValForPM] TO [public]
GO
