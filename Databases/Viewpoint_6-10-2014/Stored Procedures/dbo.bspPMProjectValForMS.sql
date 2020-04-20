SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
CREATE proc [dbo].[bspPMProjectValForMS]
/***********************************************************
 * Created By:	GF 02/22/2002 
 * Modified By:
 * 
 *
 * USAGE:
 * validates Projects from JCJM and returns the description
 * an error is returned if any of the following occurs
 * no job passed, no project found in JCJM. Used in PMMSQuote.
 *
 * INPUT PARAMETERS
 *   PMCo   		PM Co to validate against
 *   Project    	Project to validate
 *   StatusString	Comma deliminated string for status check.
 *
 *
 * OUTPUT PARAMETERS
 *  @status   Staus of Job
 *	@lockedphases
 *	@taxcode
 *	@jobphone
 *	@contact
 *	@pricetemplate
 *	@haultaxopt
 *  @msg      error message if error occurs otherwise Description of Project
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @statusstring varchar(60) = null,
 @status tinyint output, @lockedphases bYN output, @taxcode bTaxCode output,
 @contact bDesc output, @phone bPhone output, @pricetemplate smallint output,
 @haultaxopt tinyint output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @projectmgr int

select @rcode = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing project!', @rcode = 1
	goto bspexit
	end

---- validate project
select @msg=Description, @status=JobStatus, @lockedphases=LockPhases,
   	   @taxcode=TaxCode, @pricetemplate=PriceTemplate, @phone=JobPhone,
   	   @projectmgr=ProjectMgr, @haultaxopt=HaulTaxOpt
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
	begin
	select @msg = 'Project not on file!', @rcode = 1
	goto bspexit
	end

---- Check to see if the status on this project is contained in the string passed in
if charindex(convert(varchar,@status), @statusstring) = 0
	begin
	select @msg = 'Invalid status on project. Status: '
	select @msg = @msg + case when @status=0 then 'Pending !'
		 		when @status=1 then 'Open !'
		 		when @status=2 then 'Soft Closed !'
		 		else 'Closed !' end
	select @rcode = 1
	--select @msg = 'Invalid status on project!', @rcode = 1
	goto bspexit
	end


---- get Project Manager Name
if isnull(@projectmgr,'') <> ''
	begin
	select @contact=Name
	from JCMP with (nolock) where JCCo=@pmco and ProjectMgr=@projectmgr
	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectValForMS] TO [public]
GO
