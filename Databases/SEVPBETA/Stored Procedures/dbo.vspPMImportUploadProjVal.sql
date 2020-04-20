SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportUploadProjVal    Script Date: 06/06/2006 ******/
CREATE proc [dbo].[vspPMImportUploadProjVal]
/*************************************
* Created By:	GF 06/06/2006	- for 6.x
* Modified By:	GF 03/12/2008	- issue #127076 changed state to varchar(4)
*				CHS 11/20/08	-	#130774
*
*
* validates PM Import Upload Project, if exists Job Status must pending, open.
* Returns project, contract info when exists.
*
* Pass:
*	PM Company
*	PM Project
*
* Output:
* Exists Flag
* Job Status
* Job Description
* Liability Template
* PR State
* Lock Phase Flag
* Markup Discount Rate
* Job Warning Flag
* Contract
*
* Success returns:
*	0 and JCJM Description
*
* Error returns:
*	1 and error message
**************************************/
(@pmco bCompany = null, @project bJob = null, @exists bYN = 'Y' output,
 @status tinyint = 0 output, @job_desc bItemDesc = null output, @liabtemp smallint = null output,
 @prstate varchar(4) = null output, @lockphases bYN = 'N' output, @murate bRate = 0 output,
 @jobwarnflag bYN = 'N' output, @contract bContract = null output, @country varchar(60) output, 
 @msg varchar(255) output)

as 
set nocount on

declare @rcode int

select @rcode = 0, @lockphases = 'N', @jobwarnflag = 'N', @exists = 'Y'


select @country = (select DefaultCountry from HQCO with (nolock) 
					left join PMCO with (nolock) on @pmco = PMCO.PMCo
where HQCO.HQCo = isnull(PMCO.PRCo, @pmco))  


if @pmco is null
   	begin
   	select @msg = 'Missing PM Company.', @rcode = 1
   	goto bspexit
   	end

if @project is null
	begin
	select @msg = 'Missing Project.', @rcode=1
   	goto bspexit
	end


------ validate JCJM
select @msg=Description, @job_desc=Description, @status=JobStatus, @contract=Contract,
		@liabtemp=LiabTemplate, @prstate=PRStateCode, @lockphases=LockPhases, @murate=MarkUpDiscRate
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0 
   	begin
	select @status = 0, @exists = 'N'
   	select @msg = 'New Project.'
	goto bspexit
   	end

------ job status must be 0-pending or 1-open
if @status not in (0,1)
	begin
	select @msg = 'Job Status must be (0) - Pending or (1) - Open.', @rcode = 1
	goto bspexit
	end


------ check if cost header data exists for job
if exists(select * from JCCH with (nolock) where JCCo=@pmco and Job=@project)
	select @jobwarnflag = 'Y'




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUploadProjVal] TO [public]
GO
