SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [dbo].[vfJCPhaseDesc] 
	(@JCCo TINYINT = NULL,
	 @Phase bPhase = NULL)
returns varchar(60)
as
begin

/***********************************************************
* CREATED BY:	GF 10/08/2012 TK-18333
* MODIFIED By:	
*
*
* USAGE:
* Pass this function a JCCo, PhaseGroup, and Phase code
* and it will return the phase description form JCPM
* for an exact match or valid part phase.
*
*
* INPUT PARAMETERS
* @JCCo			JC Company
* @Phase		JC Phase
*
* OUTPUT PARAMETERS
* outstring		Description from phase master
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

DECLARE @validphasechars INT,
		@desc varchar(255),
		@pphase bPhase,
		@PhaseGroup TINYINT

if @JCCo IS NULL OR @Phase IS NULL GOTO vspexit

---- validate JC Company -  get valid portion of phase code
select @validphasechars = ValidPhaseChars
from dbo.bJCCO WITH (NOLOCK)
WHERE JCCo = @JCCo
if @@rowcount <> 1
	BEGIN
	SET @desc = 'Invalid Job Cost Company!'
	GOTO vspexit
	END

---- get Phase Group
select @PhaseGroup = PhaseGroup
from dbo.bHQCO with (nolock) where HQCo = @JCCo
if @@rowcount <> 1
	begin
	select @desc = 'Phase Group for HQ Company ' + dbo.vfToString(@JCCo) + ' not found!'
	goto vspexit
	end


---- first check Phase Master - exact match
select @desc = Description
from dbo.bJCPM WITH (NOLOCK)
where PhaseGroup = @PhaseGroup
	AND Phase = @Phase
if @@rowcount = 1 GOTO vspexit

---- format valid portion of Phase
if isnull(@validphasechars,0) > 0
	BEGIN
	SELECT @pphase = substring(@Phase, 1, @validphasechars) + '%'
	select Top 1 @desc = Description
	from dbo.bJCPM WITH (NOLOCK)
	where PhaseGroup = @PhaseGroup
		AND Phase like @pphase
	Group By PhaseGroup, Phase, Description
	if @@rowcount = 1
		begin
		goto vspexit
		end
	END

---- we are out of places to check
SET @desc = 'Phase ' + dbo.vfToString(@Phase) + ' not on file!'




vspexit:
	return(@desc)
	end

GO
GRANT EXECUTE ON  [dbo].[vfJCPhaseDesc] TO [public]
GO
