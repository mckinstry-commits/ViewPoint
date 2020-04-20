SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARJCCompanyValWithInfo    Script Date: 11/01/01 14:00 PM******/
CREATE proc [dbo].[bspARJCCompanyValWithInfo]
/*************************************
   * CREATED:	TJL - 11/01/01\
   * Modified By:	GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
   *
   *
   * validates JC Company number and returns Description and information from JCCo from HQCo
   *
   * Pass:
   *	JC Company number
   *
   * Success returns:
   *	0, Company name, PostClosedJobsFlag  from bJCCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
(@jcco bCompany = 0, @postclosedjobs bYN output, @glrevoveride bYN output,
 @glcostoveride bYN output, @glco bCompany output, @postsoftclosedjobs bYN output,
 @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @jcco = 0
	begin
   	select @msg = 'Missing JC Company#', @rcode = 1
   	goto bspexit
   	end

exec @rcode = bspJCCompanyVal @jcco, @msg output
if @rcode <> 0 goto bspexit

select @glrevoveride = GLRevOveride, @postclosedjobs = PostClosedJobs, @glcostoveride = GLCostOveride,
		@glco = GLCo, @postsoftclosedjobs = PostSoftClosedJobs
from bJCCO where JCCo = @jcco


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARJCCompanyValWithInfo] TO [public]
GO
