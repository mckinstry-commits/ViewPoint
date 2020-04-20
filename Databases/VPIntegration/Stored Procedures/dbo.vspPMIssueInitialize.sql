SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMIssueInitialize    Script Date: 8/28/99 9:35:14 AM ******/
CREATE proc [dbo].[vspPMIssueInitialize]
/*************************************
 * Created By:	GF 02/05/2007
 * Modified By:	GF 09/03/2010 - issue #141031 change to use date only function
 *
 * Pass this a Project and some issue info and it will initialize an ISSUE
 *
 * Pass:
 *       PMCO          PM Company this RFI is in
 *       Project       Project for the RFI
 *       OurFirm	      Our Firm that initiator comes from
 *       Initiator     Valid Contact form OurFirm
 *       Description   Description to initialize
 *       DateInitiated The Date initiated
 * Returns:
 *      NewIssue          New issue number that was initialized
 *      MSG if Error
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *  
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @ourfirm bFirm = null, @initiator bEmployee = null,
 @description bItemDesc, @dateinitiated bDate, @newissue bIssue = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @vendorgroup bGroup, @issue bIssue

select @rcode = 0

if @pmco is null or @project is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end

if isnull(@ourfirm,0) = 0 select @ourfirm = null
if isnull(@initiator,0) = 0 select @initiator = null

select @vendorgroup=h.VendorGroup
from HQCO h with (nolock) join PMCO p with (nolock) on h.HQCo=p.APCo
where p.PMCo=@pmco

-- -- -- get next project issue from PMIM
begin transaction
select @issue=isnull(Max(Issue),0) + 1 
from PMIM with (nolock) where PMCo=@pmco and Project=@project
if isnull(@issue,0) = 0 select @issue = 1
-- -- -- insert into PMIM
insert PMIM(PMCo, Project, Issue, VendorGroup, FirmNumber, Initiator, Description, DateInitiated, Status)
select @pmco, @project, @issue, @vendorgroup, @ourfirm, @initiator, substring(@description,1,30), isnull(@dateinitiated,dbo.vfDateOnly()), 0
if @@rowcount = 0
	begin
  	select @msg = 'Nothing inserted!', @rcode=1
  	rollback
  	goto bspexit
  	end




select @newissue=@issue
commit transaction




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMIssueInitialize] TO [public]
GO
