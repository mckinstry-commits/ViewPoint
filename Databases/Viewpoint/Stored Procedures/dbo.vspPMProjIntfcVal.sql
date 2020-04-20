SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************/
CREATE proc [dbo].[vspPMProjIntfcVal]
/***********************************************************
 * Created By:	GF 11/04/2005 6.x
 * Modified By:	GF 12/12/2007 issue #25569 use separate post closed job flags in JCCO enhancement
 *				GF 03/12/2008 - issue #127076 changed state to varchar(4)
*				GP 11/12/2008 - Issue 131042, fixed description return value to PMInterface.
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
 * StatusString	semi-colon deliminated string for status check.
 *
 * OUTPUT PARAMETERS
 * Status		Staus of Job
 * LiabTemp		Liability Template
 * PRState		PR State
 * Contract		Contract for project from JCJM
 * JCCH_Exists	flag to indicate whether any JCCH records have a source status = 'Y' and no interface date.
 * @msg      error message if error occurs otherwise Description of Project
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null,
 @status tinyint output, @liabtemplate smallint output, @prstate varchar(4) output,
 @contract bContract output, @jcch_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @descMsg varchar(255)

select @rcode = 0, @jcch_exists = 'N'

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

---- get job info
select @descMsg=Description, @status=JobStatus, @liabtemplate=LiabTemplate,
		@prstate=PRStateCode, @contract=Contract
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
	begin
	select @msg = 'Project not on file!', @rcode = 1
	goto bspexit
	end

---- validate job status to JCCo post closed job flags
exec @rcode = dbo.vspJCJMClosedStatusVal @pmco, @project, @msg output
if @rcode <> 0 goto bspexit

---- check to see if any JCCH records are ready to interface
if exists(select top 1 1 from JCCH with (nolock) where JCCo=@pmco and Job=@project
			and SourceStatus='Y' and isnull(InterfaceDate,'') = '')
	begin
	select @jcch_exists = 'Y'
	end

-- Issue 131042
if @msg = '' set @msg = @descMsg



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjIntfcVal] TO [public]
GO
