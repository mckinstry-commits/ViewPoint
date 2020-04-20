SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJCProjectinMinProjPct]
(@jcco bCompany = null, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null)
returns numeric(6,4)
/***********************************************************
* CREATED BY	: DANF
* MODIFIED BY	
*
* USAGE:
* 	Returns Minimun Projection Percent
*
* INPUT PARAMETERS:
*	Job Cost Company, Job, Phase Group, Phase
*
* OUTPUT PARAMETERS:
*	Min Projection Percent
*	
*
*****************************************************/
as
begin

declare @minpct bPct

	select @minpct = isnull(ProjMinPct,0)
	from JCJP with (nolock) 
	where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
	if @minpct = 0
		begin
		select @minpct = isnull(ProjMinPct,0) 
		from JCJM with (nolock)
		where JCCo=@jcco and Job=@job
		if @minpct = 0
			begin
			select @minpct = isnull(ProjMinPct,0) 
			from JCCO with (nolock)
			where JCCo=@jcco
			end
		end
exitfunction:
  			
return @minpct
end

GO
GRANT EXECUTE ON  [dbo].[vfJCProjectinMinProjPct] TO [public]
GO
