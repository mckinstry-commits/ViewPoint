SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE proc [dbo].[vspPMPOMOItemDescDefault]
/***********************************************************
* Created By:	GF 07/25/2009 - issue #129667
* Modified By:
*
*
* USAGE:
* Gets the default PO/MO item description for PM based on the
* MatlPhaseDesc flag from the PM Company table.
*
* When Y - always use the phase description.
*
* When N - use the following hierarchy:
*	1. If PMMF.Description exists, came from import. Use
*   2. Use change order item description if PO/MO Item created from CO detail.
*   3. Use contract item description if PO/MO Item created from original detail.
*   4. Use phase description if neither of the first two conditions are met.
*
* INPUT PARAMETERS
* pmco, project, phasegroup, phase, pcotype, pco, pcoitem, aco, acoitem, pmmf sequence
*
* OUTPUT PARAMETERS
*   msg     description, or error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
@pcotype bDocType = null, @pco bPCO = null, @pcoitem bPCOItem = null, @aco bACO = null,
@acoitem bACOItem = null, @pmmf_seq int = null, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @defaultdesc varchar(60), @contract bContract, @item bContractItem,
   		@validphasechars int, @inputmask varchar(30), @pphase bPhase, @usephasedesc bYN
 
select @rcode = 0, @defaultdesc = null, @validphasechars = null, @usephasedesc = 'Y'

---- get UsePhaseDesc from PMCO
select @usephasedesc=MatlPhaseDesc
from dbo.PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0 select @usephasedesc = 'Y'

---- validate JC Company -  get valid portion of phase code
select @validphasechars=ValidPhaseChars
from dbo.JCCO with (nolock) where JCCo=@pmco
   
---- get the format for datatype 'bPhase'
select @inputmask=InputMask from DDDTShared with (nolock) where Datatype='bPhase'
   
---- format valid portion of Phase
if @validphasechars not in (0,Null)
	begin
	select @pphase = substring(@phase,1,@validphasechars) + '%'
	end

set @defaultdesc = null

---- get default PO/MO Item description, use phase description if specified
if @usephasedesc='Y'
      begin
      -- get JCJP full phase description
      select @defaultdesc=Description from dbo.JCJP with (nolock) 
      where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
      if @@rowcount = 0
         begin
         -- get JCPM full phase description
         select @defaultdesc=Description from dbo.JCPM with (nolock) 
         where PhaseGroup=@phasegroup and Phase=@phase
         if @@rowcount = 0
            begin
            if @validphasechars not in (0,Null)
               begin
               -- check valid portion of Phase in JCJP
               select Top 1 @defaultdesc=Description from dbo.JCJP with (nolock) 
               where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase like @pphase
               Group By JCCo,Job,Phase,Description
               if @@rowcount = 0
                  begin
                  -- check valid portion of Phase in JCPM
                  select @defaultdesc=Description from dbo.JCPM with (nolock) 
                  where PhaseGroup=@phasegroup and Phase like @pphase
                  if @@rowcount=0
                     begin
    	              select @defaultdesc='Description not found', @rcode = 1
                     goto bspexit
                     end
    	           end
               end
            else
               begin
               -- no valid portion of phase
               select @defaultdesc='Description not found', @rcode = 1
               goto bspexit
               end
            end
         end
   
      select @rcode = 0
      goto bspexit
      end
   
   
select @defaultdesc = null

---- get change order item description
if @pco is not null and @pcoitem is not null
      begin
      select @defaultdesc=Description from dbo.PMOI with (nolock) 
      where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
      end

if @aco is not null and @acoitem is not null
      begin
      select @defaultdesc=Description from dbo.PMOI with (nolock) 
      where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
      end

select @contract=Contract, @item=Item
from dbo.JCJP with (nolock)
where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase

if @pco is null and @aco is null
      begin
      select @defaultdesc=Description
      from dbo.JCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@item
      end


if @defaultdesc is null
      begin
      select @defaultdesc=Description
      from dbo.JCJP with (nolock) where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
      if @@rowcount = 0
         begin
         select @defaultdesc=Description
         from dbo.JCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
         if @@rowcount = 0
            begin
            select @defaultdesc='Description not found', @rcode =1
            goto bspexit
            end
         end
      end




select @rcode = 0



bspexit:
	select @msg=@defaultdesc
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOMOItemDescDefault] TO [public]
GO
