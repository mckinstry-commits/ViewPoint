SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspJCCommonInfoForProj]
/********************************************************
* Created By:	Dan 03/04/2009 - ISSUE #132118
* Modified By:	CHS 03/19/2009 - issue #129898
*				GF 02/09/2010 - issue #136995 projection time stamp notes
*
*
* USAGE:
* Retrieves common info from JCCO for use in JC Cost Projections
*
* INPUT PARAMETERS:
* JC Company
*
* OUTPUT PARAMETERS:
* GLCo,
* ProjMethod,
* ProjMinPct,
* ProjPercent,
* ProjOverUnder,
* ProjRemain, 
* Phasegroup,
* Projection Active Phases
* Projection Reamin UC Option
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@jcco bCompany=0, @glco bCompany = null  output, @projmethod char(1) = null output,
 @projminpct  bPct = null output, @projpercent bYN = null output, @projoverunder bYN = null output,
 @projremain bYN = null output, @projunit bYN = null output, @projhour bYN = null output,
 @projcost bYN = null output, @projunitcost bYN = null output, @phasegroup bGroup = null output,
 @projinactivephases bYN = null output, @projremainucopt char(1) = 'E' output, @projresdetopt bYN = 'N' output,
 @prco bCompany = null output, @projtimestamp char(1) = 'Y' output, @errmsg varchar(255) = null output)

as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0, @errmsg = null, @projhour = 'N', @projcost = 'N', @projunitcost = 'N',
		@projinactivephases = 'N', @projremainucopt = 'E', @projtimestamp = 'Y'

---- get company info
select @glco = GLCo, @projmethod = ProjMethod, @projminpct = ProjMinPct,
		@projpercent = ProjPercent, @projoverunder = ProjOverUnder,
		@projremain = ProjRemain, @projinactivephases = ProjInactivePhases,
		@projremainucopt = ProjRemainUCOpt, @projresdetopt = ProjResDetOpt,
		@prco = PRCo, @projtimestamp=ProjNoteTimeStamp
from dbo.bJCCO with (nolock) where JCCo = @jcco
if @@rowcount <> 1
	begin
	select @errmsg = 'JC Company ' + convert(varchar(3), @jcco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- get phase group from HQCO for JC company.
select @phasegroup = PhaseGroup
from dbo.bHQCO with (nolock) where HQCo = @jcco
if @@rowcount <> 1
	begin
	select @errmsg = 'Error in retrieving group information from Head Quarters!', @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCommonInfoForProj] TO [public]
GO
