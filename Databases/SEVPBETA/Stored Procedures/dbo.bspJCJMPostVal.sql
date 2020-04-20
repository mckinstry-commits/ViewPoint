SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCJMPostVal    Script Date: 12/6/2004 1:04:16 PM ******/
CREATE   proc [dbo].[bspJCJMPostVal]
/***********************************************************
* CREATED BY: 	SE   11/10/96
* MODIFIED By:	kb 12/9/98
*				GR 10/14/99 - added check for pending job
*				RT 08/20/03 - Issue #21582, return Address2 field from JCJM.
*				TV - 23061 added isnulls
*				GF 12/12/2007 - issue #25569 separate post closed jobs flags.
*				GF 03/11/2008 - issue #127076 added country as output parameter
*				GP 05/11/2009 - issue 132805 added @UseDefaultTax output parameter
*
*
*
* USAGE:
* validates JC Job
* an error is returned if any of the following occurs
* no job is passed, no job found in JCCM.
*   -If jCCO.PostCLosedJobs='N' and Job status is 2 or 3
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @contract returns the contract for this job.
*   @status   Status of job, Open, SoftClose,Close
*   @lockphases  weather or not lockphases flag is set
*   @taxcode  tax code for job
*   @address  Shipping address of the job
*   @city     Shipping City of job
*   @state    state of address of job
*   @zip      zip code
*   @address2 Shipping address line 2
*	 @country  Shipping Country of job
*
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @contract bContract = null output,
 @status tinyint =null output, @lockphases bYN = null output,
 @taxcode bTaxCode = null output, @address varchar(60)=null output,
 @city varchar(30)=null output, @state varchar(4) = null output, @zip bZip=null output,
 @pocompgroup varchar(10)=null output, @slcompgroup varchar(10)=null output, 
 @address2 varchar(60)=null output, @country char(2) = null output,
 @UseDefaultTax bYN=null output, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @postclosed varchar(1), @postsoftclosed varchar(1)

select @rcode = 0, @contract=''

if @jcco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end

select @postclosed=PostClosedJobs, @postsoftclosed=PostSoftClosedJobs
from bJCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
	begin
	select @msg = 'JC Company invalid!', @rcode = 1
	goto bspexit
	end

if @job is null
	begin
	select @msg = 'Missing Job!', @rcode = 1
	goto bspexit
	end

select @msg = Description, @contract=Contract, @status=JobStatus, @lockphases=LockPhases, @taxcode=TaxCode,
    	@address=ShipAddress, @city=ShipCity, @state=ShipState, @zip=ShipZip, @pocompgroup = POCompGroup,
    	@slcompgroup = SLCompGroup, @address2=ShipAddress2, @country=ShipCountry, @UseDefaultTax = UseTaxYN
from JCJM with (nolock) where JCCo = @jcco and Job = @job
if @@rowcount = 0
    	begin
    	select @msg = 'Job not on file!', @rcode = 1
    	goto bspexit
    	end
if @status=0
	begin
	select @msg='Job Status cannot be Pending!', @rcode=1
	goto bspexit
	end
if @status = 2 and @postsoftclosed = 'N'
	begin
	select @msg = 'Job is soft-closed.', @rcode = 1
	goto bspexit
	end
if @status = 3 and @postclosed = 'N'
	begin
	select @msg='Job is hard-closed!', @rcode=1
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMPostVal] TO [public]
GO
