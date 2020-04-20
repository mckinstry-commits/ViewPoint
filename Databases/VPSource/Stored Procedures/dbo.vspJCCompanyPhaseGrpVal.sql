SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCompanyVal    Script Date: 8/28/99 9:35:01 AM ******/
CREATE   proc [dbo].[vspJCCompanyPhaseGrpVal]
/*************************************
* Created:	CHS 06/10/2009 - issue #132119
* Modified:
*
* validates JC Company number and returns Description from HQCo
*	
* Pass:
*	JC Company number
*
* Success returns:
*	0 and Company name from bJCCO
*
* Error returns:
*	1 and error message
**************************************/
(@thisjcco bCompany = 0, @otherjcco bCompany = 0, @msg varchar(60) output)
as 
set nocount on

declare @rcode int

set @rcode = 0


if @thisjcco = 0
	begin
	select @msg = 'Missing JC Company#', @rcode = 1
	goto bspexit
	end

if exists(select top 1 1 from JCCO where @thisjcco = JCCo)
	begin
	select @msg = Name from HQCO where HQCo = @thisjcco
	end
else
	begin
	select @msg = 'Not a valid JC Company', @rcode = 1
	end


if isnull(@otherjcco,0) = 0
	begin
	goto bspexit
	end


if not exists (select top 1 1 from HQCO t with (nolock) 
		join HQCO o with (nolock) on t.PhaseGroup = o.PhaseGroup
		where t.HQCo = @thisjcco and o.HQCo = @otherjcco)
	begin
	select @msg = 'Phase groups do not match.', @rcode = 1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCompanyPhaseGrpVal] TO [public]
GO
