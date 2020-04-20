SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE procedure [dbo].[bspPMSubmitRevDefaults]
/*******************************************************************************
    * Created By:	GF 04/13/2000
    * Modified By:	GF 10/11/2001 - Get contact from JCJM for ArchEngFirm issue #14840
    *				GF 02/25/2002 - Changed @submittaldesc from bDesc to bItemDesc
    *				GF 03/28/2002 - Added spec number to revision defaults.
    *				GF 10/23/2002 - #19046 - when status final use BeginStatus from PMCO.
    *				GF 05/24/2004 - #24166 - added activity date to output params
    *
    *
    * Generates defaults from a submittal revision.
    *
    *
    * Pass In
    *   PM Company, Project, DocType, Submittal, Revision
    *
    * RETURN PARAMS
    *   Submittal Description
    *   Phase
    *   Status
    *   Responsible Person
    *   Issue
    *   Sub Firm
    *   Sub Contact
    *   ArchEng Contact
    *   ArchEng Firm
    *   Copies Required
    *   SpecNumber
    *   ActivityDate
    *   msg           Error Message, or Success message
    *
    * Returns
    *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
    *
 ********************************************************************************/
(@pmco bCompany = null, @project bJob = null, @doctype bDocType = null,
 @submittal bDocument = null, @rev_in int = null, 
 @submittaldesc bItemDesc output, @phase bPhase output,
 @status bStatus output, @resperson bEmployee output, @issue bIssue output,
 @subfirm bVendor output, @subcontact bEmployee output, @archengcontact bEmployee output,
 @archengfirm bVendor output, @copiesreqd tinyint output, @specnumber varchar(20) output,
 @activitydate bDate output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @revision int, @beginstatus bStatus, @codetype varchar(1)

select @rcode=0, @issue = 0, @msg = ''
   
if @pmco is null or @project is null or @doctype is null or @submittal is null
	goto bspexit



-- -- -- get architect/engineer from JCJM
select @archengfirm=ArchEngFirm, @archengcontact=ContactCode
from JCJM with (nolock) where JCCo=@pmco and Job=@project

-- -- -- get begin status, will be used if status for revision being used as
-- -- -- a default has a final status.
select @beginstatus=BeginStatus from PMCO with (nolock) where PMCo=@pmco
if isnull(@beginstatus,'') = ''
	begin
	select @beginstatus = min(Status) from PMSC with (nolock) where CodeType='B'
	end

-- -- -- get description for revision if not null
if @rev_in is not null
	begin
	select @msg=Description from PMSM with (nolock)
	where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@submittal and Rev=@rev_in
	end

-- -- -- get max revision from PMSM
select @revision=isnull(max(Rev),0) from PMSM with (nolock) 
where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@submittal
if @@rowcount = 0 goto bspexit

-- -- -- get submittal information
select @submittaldesc=Description, @phase=Phase, @status=Status, @resperson=ResponsiblePerson,
   		@issue=Issue, @subfirm=SubFirm, @subcontact=SubContact, @archengcontact=ArchEngContact,
   		@archengfirm=ArchEngFirm, @copiesreqd=CopiesReqd, @specnumber=SpecNumber, 
   		@activitydate=ActivityDate -- -- -- , @msg=Description
from PMSM with (nolock) 
where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@submittal and Rev=@revision
if @@rowcount = 0 goto bspexit



-- -- -- get current status
if isnull(@beginstatus, '') <> '' and isnull(@status, '') <> ''
	begin
	select @codetype = CodeType from PMSC with (nolock) where Status=@status
	if @@rowcount = 0 or @codetype = 'F' select @status = @beginstatus
	end






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSubmitRevDefaults] TO [public]
GO
