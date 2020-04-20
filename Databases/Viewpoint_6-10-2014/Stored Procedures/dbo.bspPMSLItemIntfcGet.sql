SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE proc [dbo].[bspPMSLItemIntfcGet]
/***********************************************************
* Created By:	GF 03/02/2005
* Modified By:	GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*
*
* USAGE:
* Called from PMSLItems interfaced grid to return PMSL information
* to display in the PM SL Items form.
*
*
* INPUT PARAMETERS
* SLCo, SL, SLItem
*
* OUTPUT PARAMETERS
* ACO, ACOItem, SubCo, IntefaceDate
* msg     error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@slco bCompany = 0, @sl VARCHAR(30) = null, @slitem bItem = null,
@aco bACO output, @acoitem bACOItem output, @jobdesc bItemDesc output,
@acodesc bItemDesc output, @addondesc bItemDesc output, @phasedesc bItemDesc output,
@msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @addon tinyint, @phase bPhase, @pmco bCompany, @project bJob, @phasegroup bGroup

select @rcode = 0
   
-- -- -- get SLIT information
select @addon=Addon, @phasegroup=PhaseGroup, @phase=Phase, @pmco=JCCo, @project=Job
from dbo.bSLIT with (nolock)
where SLCo=@slco and SL=@sl and SLItem=@slitem
   
-- -- -- get maximum PMSL data for this PMCo,Project,SLCo,SL, and Item
select @aco=max(ACO)
from dbo.bPMSL with (nolock)
where SLCo=@slco and SL=@sl and SLItem=@slitem and InterfaceDate is not null
if @@rowcount <> 0
   	begin
   	select @acoitem=max(ACOItem)
   	from bPMSL with (nolock)
   	where SLCo=@slco and SL=@sl and SLItem=@slitem and InterfaceDate is not null and ACO=@aco
   	end
-- -- -- get ACO descripiton
if isnull(@aco,'') <> ''
   	begin
   	select @acodesc = Description
   	from bPMOH with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco
   	end
   
-- -- -- get job description
select @jobdesc = Description
from dbo.bJCJM with (nolock) where JCCo=@pmco and Job=@project
-- -- -- get addon description
select @addondesc = Description
from dbo.bSLAD with (nolock) where SLCo=@slco and Addon=@addon
-- -- -- get phase description
select @phasedesc = Description
from dbo.bJCJP with (nolock) where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
if @@rowcount = 0
   	begin
   	select @phasedesc = Description
   	from dbo.bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
   	end



bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLItemIntfcGet] TO [public]
GO
