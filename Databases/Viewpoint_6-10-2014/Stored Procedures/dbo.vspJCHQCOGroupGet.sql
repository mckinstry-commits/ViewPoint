SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 8/28/99 9:34:50 AM ******/
CREATE  proc [dbo].[vspJCHQCOGroupGet]
/*************************************
  * validates HQ VendorGroup, MatlGroup, PhaseGroup, or CustGroup
* Modified By:	GF 12/21/2007 - issue #25569 return JCCO Post Closed Job flags
*
  *
  * Pass:
  *	HQ Group to be validated
  *
  * Success returns:
  *	0 and Group Description from bHQGP
  *
  * Error returns:
  *	1 and error message
  **************************************/
(@co bCompany, @matlgroup bGroup output, @phasegroup bGroup output, 
 @vendorgroup bGroup output, @customergroup bGroup output, @emgroup bGroup output, 
 @taxgroup bGroup output, @postclosedjobs bYN = 'N' output, @postsoftclosedjobs bYN = 'N' output,
 @msg varchar(60) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

if @co is null
  	begin
  	select @msg = 'Missing HQ Company', @rcode = 1
  	goto bspexit
  	end

---- get JCCo info
select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
from dbo.JCCO with (nolock) where JCCo=@co
if @@rowcount = 0
	begin
	select @msg = 'JC Company ' + convert(varchar(3), @co) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- get HQCo info
select @matlgroup =MatlGroup, @phasegroup =PhaseGroup, @vendorgroup =VendorGroup,
		@customergroup =CustGroup , @emgroup =EMGroup, @taxgroup =TaxGroup
from dbo.HQCO with (nolock) where HQCo = @co 
if @@rowcount = 0
	begin
	select @msg = 'Error getting group info', @rcode = 1
	end


bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCHQCOGroupGet] TO [public]
GO
