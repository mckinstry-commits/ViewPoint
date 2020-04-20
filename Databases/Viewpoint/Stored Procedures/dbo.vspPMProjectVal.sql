SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMProjectVal    Script Date: 04/27/2005 ******/
CREATE  proc [dbo].[vspPMProjectVal]
/***********************************************************
* Created By:	GF	07/07/2005
* Modified By:	GF	12/07/2007 - issue #124407 posting to closed jobs
*				GF	03/11/2008 - issue #127076 added country as output
*				GF	03/12/2008 - issue #127076 removed dead output parameters mail, ship addresses
*				GF	03/21/2008 - issue #127??? changed total project to a numeric(14,2)
*				GP	05/11/2009 - issue #132805 added @UseTaxDefault output from JCJM
*				GF	05/26/2009 - issue #24641
*				CHS	05/28/2009 - issue #133735
*				GF 09/14/2009 - issue #135548 - changed to use view for JCJM instead of table.
*
*
* USAGE:
* validates Projects from bJCJM
* and returns the description
* an error is returned if any of the following occurs
* no job passed, no project found in JCJM
*
* INPUT PARAMETERS
* PMCo   		PM Co to validate against
* Project    	Project to validate
* StatusString	Comma deliminated string for status check.
*
*
* OUTPUT PARAMETERS
* @Status			Staus of Job
* @lockedphases	Locked Phase Flag
* @projectmanager	Project Manager
* @taxcode			Tax Code
* @retainagePCT	Retainage percent
* @contract		JC Contract
* @slcompgroup		SL compliance group
* @pocompgroup		PO compliance group
* @ourfirm			Project OurFirm
* @totalproject	Total Project cost from JCCH
* @stddaysdue		Project Document days due
* @rfidaysdue		Project Document RFI days due
* @description		Project Description
* @basetaxon			JCJM Base Tax on Vendor, Job
* @archengfirm			Project architect engineer firm
* @archengcontact		Project architect engineer contact
* @jobstatusmsg		Project Status Message - either null or error message
* @mailcountry		Project Mail Country
* @shipcountry		Project Ship country
* @msg				error message if error occurs otherwise Description of Project
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @statusstring varchar(20) = null,
 @status tinyint output, @lockedphases bYN output, @projectmanager int output,
 @taxcode bTaxCode output, @retainagepct bPct output, @contract bContract output,
 @slcompgroup varchar(10) output, @pocompgroup varchar(10) output, @ourfirm bFirm = NULL OUTPUT,
 @totalproject numeric(14,2) = 0 output, @stddaysdue smallint output, @rfidaysdue smallint output,
 @description bItemDesc output, @begstatus bStatus output, @siregion varchar(6) = null output,
 @basetaxon varchar(1) output, @archengfirm bVendor output, @archengcontact bEmployee output,
 @UseDefaultTax bYN = null output, @autoadditemyn bYN output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @jcode int

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

---- get job information
select @msg=p.Description, @description=p.Description, @status=p.JobStatus, @lockedphases=p.LockPhases,
		@projectmanager=p.ProjectMgr, @basetaxon=p.BaseTaxOn, @taxcode=p.TaxCode,
		@retainagepct = isnull(m.RetainagePCT,0), @contract=p.Contract,
		@slcompgroup=p.SLCompGroup, @pocompgroup=p.POCompGroup, @ourfirm=p.OurFirm,
		@stddaysdue=p.DefaultStdDaysDue, @rfidaysdue=p.DefaultRFIDaysDue,
		@siregion = m.SIRegion, @archengfirm=p.ArchEngFirm, @archengcontact=p.ContactCode,
		@UseDefaultTax=p.UseTaxYN, @autoadditemyn=p.AutoAddItemYN
from dbo.JCJM p with (nolock) join bJCCM m with (nolock) on m.JCCo=p.JCCo and m.Contract=p.Contract
where p.JCCo = @pmco and p.Job = @project
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
		 		when @status=2 then 'Soft-Closed !'
		 		else 'Hard-Closed !' end
	select @rcode = 1
	goto bspexit
	end

---- get the job status message using the JCCo company posting options
---- do not return error code here. depends on the project form being loaded. Front-end
---- exec @jcode = vspJCJMClosedStatusVal @pmco, @project, @jobstatusmsg output

---- if missing project our firm - get from PMCO
if @ourfirm IS null
	begin
  	select @ourfirm=OurFirm from dbo.PMCO with (nolock) where PMCo=@pmco
  	end

---- get beginning status from PMCO
select @begstatus=BeginStatus from dbo.PMCO with (nolock) where PMCo=@pmco

---- initialize document categories
if not exists(select 1 from bPMCT)
	begin
	declare @sql nvarchar(max)
	set @sql = 'exec dbo.vspPMCTInitialize'
	exec (@sql)
	end
	
---- get total cost from bJCCH for Job/Projectc
select @totalproject = isnull(sum(OrigCost),0)
from dbo.JCCH with (nolock) where JCCo = @pmco and Job = @project
if @@rowcount = 0 select @totalproject = 0



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectVal] TO [public]
GO
