SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE  proc [dbo].[vspPMCommonForProjectPhases]
/********************************************************
 * Created By:	GF 11/27/2006
 * Modified By:	GF 12/19/2007 - issue #124407 return JCCO allow posting to closed job flags.
 *               
 *
 * USAGE:
 * Retrieves common info specific for the PM Project Phases form.
 * returns the JCCT descriptions for each PMCO.ShowCostType(1-10)
 * setup in PMCO.
 *
 * INPUT PARAMETERS:
 *	PM Company
 *
 * OUTPUT PARAMETERS:
 * PhaseGroup,

 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @phasegroup bGroup = null output, @showct1_desc bDesc = null output,
 @showct2_desc bDesc = null output, @showct3_desc bDesc = null output, @showct4_desc bDesc = null output,
 @showct5_desc bDesc = null output, @showct6_desc bDesc = null output, @showct7_desc bDesc = null output,
 @showct8_desc bDesc = null output, @showct9_desc bDesc = null output, @showct10_desc bDesc = null output,
 @pmcoexists bYN = 'Y' output, @postclosedjobs bYN = 'N' output, @postsoftclosedjobs bYN = 'N' output)
as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0, @pmcoexists = 'Y', @postclosedjobs = 'N', @postsoftclosedjobs = 'N'

---- check if PM Company is valid
if not exists(select * from PMCO where PMCo=@pmco)
	begin
	select @pmcoexists = 'N'
	goto bspexit
	end


---- get phase group from HQCO for JC company
select @phasegroup = PhaseGroup
from HQCO with (nolock) where HQCo = @pmco

---- get JC Company info
select @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from JCCO with (nolock) where JCCo=@pmco

---- get PMCO.ShowCostType descriptions
select @showct1_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType1

select @showct2_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType2

select @showct3_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType3

select @showct4_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType4

select @showct5_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType5

select @showct6_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType6

select @showct7_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType7

select @showct8_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType8

select @showct9_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType9

select @showct10_desc = a.Description
from JCCT a with (nolock) left join PMCO b with (nolock) on b.PMCo=@pmco
where a.PhaseGroup=@phasegroup and a.CostType=b.ShowCostType10




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonForProjectPhases] TO [public]
GO
