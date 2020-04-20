SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCMPostVal    Script Date: 8/28/99 9:35:00 AM ******/
CREATE   proc [dbo].[bspJCCMPostVal]
/***********************************************************
    * CREATED BY: JM   4/16/97
    * MODIFIED By : JM 8/5/98 - Added Department and GLTransAcct outputs.
    *				TV - 23061 added isnulls
	*				GF 12/12/2007 - issue #25569 separate post closed jobs flags in JCCO enhancement
	*				GF 05/05/2010 - issue #139178 added validation to not allow for pending status.
	*
    * USAGE:
    *	Validates JC Contract when posting to batch
    * 	An error is returned if any of the following occurs:
    *
    * 	No contract passed
    *	No contract found in JCCM
    *   	If JCCO.PostClosedJobs='N' and Job status is 2 or 3
    *
    * INPUT PARAMETERS
    *   JCCo   	JC Co to validate against
    *   Contract	Contract to validate
    *
    * OUTPUT PARAMETERS
    *   @status   		Status of job (Pending, Open, SoftClosed, Closed)
    *   @dept     		Department
    *   @gltransacct	GLTransAcct
    *   @msg      		error message if error occurs otherwise Description of Job
    *
    * RETURN VALUES
    *   0         Success
    *   1         Failure
    *****************************************************/
(@jcco bCompany = null, @contract bContract = null, @status tinyint output,
 @dept bDept output, @gltransacct bGLAcct output, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1)

select @rcode = 0

if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

if @contract is null
   	begin
   	select @msg = 'Missing Contract!', @rcode = 1
   	goto bspexit
   	end

select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from JCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
   	begin
   	select @msg = 'JC Company invalid!', @rcode = 1
   	goto bspexit
   	end
   
select @msg = Description, @status=ContractStatus, @dept=Department
from JCCM with (nolock)
where JCCo = @jcco and Contract = @contract
if @@rowcount = 0
   	begin
   	select @msg = 'Contract not on file!', @rcode = 1
   	goto bspexit
   	end

select @gltransacct = OpenRevAcct
from JCDM with (nolock)
where JCCo = @jcco and Department = @dept

----#139178
if @status = 0
	begin
	select @msg = 'Contract is Pending!', @rcode = 1
	goto bspexit
	end
----#139178

if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @msg = 'Contract Soft-Closed!', @rcode = 1
	goto bspexit
	end

if @status = 3 and @postclosedjobs = 'N'
	begin
	select @msg='Contract Hard-Closed!', @rcode=1
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCMPostVal] TO [public]
GO
