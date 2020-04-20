SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspJCPMValForPM]  
/***********************************************************  
* Created By:	GF 05/13/2003  
* Modified By:	TV - 23061 added isnulls  
*				GF 12/03/2009 - issue #136815 added valid part phase validation to JCPM
*
*  
* USAGE:  
* validates JC Phase from Phase Master. Returns description from  
* either JCPM or JCJP depending whethere Job is passed and/or  
* phase exists in JCJP.  
* an error is returned if any of the following occurs  
* no phase passed, no phase found in JCPM.  
*  
* Currently used only in PM Project Addons  
*  
* INPUT PARAMETERS  
* JCCo JC Company  
* Job  JC Job  
* PhaseGroup  JC Phase group for this company  
* Phase       Insurance template to validate  
*  
* OUTPUT PARAMETERS  
*   @msg      error message if error occurs otherwise Description of Template description  
* RETURN VALUE  
*   0         success  
*   1         Failure  
*****************************************************/   
(@jcco bCompany = null, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,   
 @msg varchar(255) output)  
as  
set nocount on  
  
declare @rcode int, @phasedesc bItemDesc, @validphasechars int, @inputmask varchar(30), @pphase bPhase
   
select @rcode = 0, @msg='', @pphase = null
  
if @phasegroup is null  
 begin  
 select @msg = 'Missing Phase Group', @rcode = 1  
 goto bspexit  
 end  
  
if @phase is null  
 begin  
 select @msg = 'Missing Phase', @rcode = 1  
 goto bspexit  
 end  
  
  
---- validate phase to phase master  
select @msg = Description  
from dbo.JCPM with (nolock) where PhaseGroup = @phasegroup and Phase = @phase  
if @@rowcount = 0  
	begin  
	select @validphasechars = ValidPhaseChars from dbo.bJCCO with (nolock) where JCCo=@jcco  
	if @@rowcount = 0  
		begin  
		select @msg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1  
		goto bspexit  
		end
		
	if @validphasechars = 0  
		begin  
		select @msg = 'Phase not setup in Phase Master.', @rcode = 1  
		goto bspexit  
		end  

	/* get the mask for bPhase */  
	select @inputmask=InputMask from DDDTShared where Datatype = 'bPhase'  

	/* format validportion of phase */  
	select @pphase=substring(@phase,1,@validphasechars) + '%'  

	select TOP 1 @msg = Description  
	from dbo.JCPM with (nolock)
	where PhaseGroup = @phasegroup and Phase like @pphase  
	Group By PhaseGroup, Phase, Description  
	if @@rowcount = 0  
		begin  
		select @msg = 'Phase not setup in Phase Master.', @rcode = 1  
		goto bspexit  
		end  
	end  

if isnull(@job,'') <> '' and isnull(@jcco,'') <> ''  
	begin  
	select @phasedesc=Description  
	from dbo.JCJP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase  
	if @@rowcount <> 0 select @msg = @phasedesc  
	end  
 
 
 
 
bspexit:  
	return @rcode  
GO
GRANT EXECUTE ON  [dbo].[bspJCPMValForPM] TO [public]
GO
