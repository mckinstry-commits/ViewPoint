SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspINMOJobVal]
/********************************************************
   	Created By: RM 02/21/02
   	Modified: RM 04/22/03 - Return UseTax flag from JCCO to form. 17939
*				GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*
   
   	Usage: used in Material Order Entry to validate job
   
   
   
   *********************************************************/
(@jcco bCompany,@job bJob, @taxcode bTaxCode = null output,@jobstatus tinyint = null output,
 @lockphases bYN = null output,@usetax bYN = null output,@msg varchar(255) output)
as
set nocount on

declare @rcode int, @postclosedjobs bYN, @postsoftclosedjobs bYN, @contract bContract

select @rcode=0

select @usetax=UseTaxOnMaterial, @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from JCCO with (nolock) where JCCo=@jcco
if @@rowcount=0
   	begin
	select @msg='Invalid JC Company!',@rcode=1
	goto bspexit
   	end

exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @jobstatus output, @lockphases output,
				@taxcode output, @msg=@msg output
if @rcode = 1
   	begin
	goto bspexit
	end


select @jobstatus=JobStatus, @msg=Description
from JCJM with (nolock) where JCCo=@jcco and Job=@job
if @@rowcount=0
   	begin
	select @msg='Invalid Job.',@rcode=1
	goto bspexit
   	end

if @jobstatus = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg='Cannot post to soft-closed job.',@rcode=1
	goto bspexit
	end

if @jobstatus = 3 and @postclosedjobs = 'N'
   	begin
	select @msg='Cannot post to hard-closed job.',@rcode=1
	goto bspexit		
   	end




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOJobVal] TO [public]
GO
