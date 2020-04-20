SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfValidPhaseDesc] 
	(@jcco bCompany = null, @job bJob = null, @phase bPhase = null, @phasegroup tinyint)
returns varchar(60)
as
begin

/***********************************************************
* CREATED BY: DANF 06/06/2005
* MODIFIED By:	GF 09/27/2006 allow for null phase
*				GF 11/20/2008 use no locks, cleanup
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
*
* USAGE:
* Pass this function a string and a format like '2R-3LN' and it
* return a string formatted to the format specification.
*
*
* INPUT PARAMETERS
*    instring   string to format
*    informat   format mask to format string to
*
* OUTPUT PARAMETERS
*    outstring  instring formatted
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/
-- #142350 - renaming @PhaseGroup
DECLARE @validphasechars int,
		@lockphases bYN,
		@active bYN,
		@desc varchar(255),
		@pphase bPhase,
		@JCJPexists varchar(1),
		@PhaseGroupHQ tinyint

select @JCJPexists='N'

if @jcco is null or @job is null or @phase is null goto bspexit

---- validate JC Company -  get valid portion of phase code
select @validphasechars = ValidPhaseChars
from bJCCO with (nolock) where JCCo = @jcco
if @@rowcount <> 1
	begin
	select @desc = 'Invalid Job Cost Company!'
	goto bspexit
	end

---- get Phase Group
select @PhaseGroupHQ = PhaseGroup
from bHQCO with (nolock) where HQCo = @jcco
if @@rowcount <> 1
	begin
	select @desc = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!'
	goto bspexit
	end

---- Issue 17738
if @PhaseGroupHQ <> @phasegroup
	begin
	select @desc = 'Phase Group ' + isnull(convert(varchar(3), @PhaseGroupHQ),'') + ' for HQ Company ' 
			+ isnull(convert(varchar(3),@jcco),'') + ' does not match Phase Group '
			+ isnull(convert(varchar(3), @phasegroup),'')
	goto bspexit
	end

---- get job info
select @lockphases = LockPhases
from bJCJM where JCCo = @jcco and Job = @job
if @@rowcount <> 1
	begin
	select @desc = 'Job ' + isnull(@job,'') + ' not found!'
	goto bspexit
	end

---- first check Job Phases - exact match
select @desc = Description, @pphase = Phase, @active = ActiveYN
from bJCJP with (nolock)
where JCCo = @jcco and Job = @job and Phase = @phase
if @@rowcount = 1
	begin
	select @JCJPexists = 'Y'
	if @active = 'Y' goto bspexit   -- Phase is on file and active
	select @desc = 'Phase ' + isnull(@phase,'') + ' is inactive!'  -- Phase is on file, but inactive
	goto bspexit
	end


---- check for a valid portion
if isnull(@validphasechars,0) = 0 goto skipvalidportion

---- format valid portion of Phase
select @pphase = substring(@phase,1,@validphasechars) + '%'

---- check valid portion of Phase in Job Phase table
select Top 1 @desc = Description, @pphase = Phase
from bJCJP with (nolock)
where JCCo = @jcco and Job = @job and Phase like @pphase
Group By JCCo, Job, Phase, Item, Description, ProjMinPct



skipvalidportion:
---- full match in Phase Master will override description from partial match in Job Phase
select @desc = isnull(isnull(Description,@desc),''), @pphase = isnull(Phase,@phase)
from bJCPM with (nolock)
where PhaseGroup = @PhaseGroupHQ and Phase = @phase
--- if found we have a description, done
if @@rowcount <> 0 goto bspexit

---- check Phase Master using valid portion
if @validphasechars > 0
	begin
	select @pphase = substring(@phase,1,@validphasechars) + '%'
	select Top 1 @desc = Description, @pphase = Phase
	from bJCPM with (nolock)
	where PhaseGroup = @PhaseGroupHQ and Phase like @pphase
	Group By PhaseGroup, Phase, Description, ProjMinPct
	if @@rowcount = 1
		begin
		goto bspexit
		end
	end

---- we are out of places to check
select @desc = 'Phase ' + isnull(@phase,'') + ' not on file!'




bspexit:
	return(@desc)
	end

GO
GRANT EXECUTE ON  [dbo].[vfValidPhaseDesc] TO [public]
GO
