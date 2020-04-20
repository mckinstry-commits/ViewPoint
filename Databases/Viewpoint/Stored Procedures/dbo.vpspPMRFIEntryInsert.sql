SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFIEntryInsert]
/************************************************************
* CREATED:		2006/06/13 CHS
* MODIFIED:		2007/06/06 chs
* MODIFIED:		2007/07/12 CHS
* MODIFIED:		2007/12/13 CHS
*				2010/09/03 GF  - issue #141031 change to use date only function
*               2011/07/12 TEJ - Fixed the numbering for the stored procedure to pull the number for
*                                the RFI using the logic for the passed in project
*				GF 12/06/2011 TK-10599
*
* USAGE:
*   Inserts PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@RFIType bDocType,
	@RFI bDocument = null,
	@Subject VARCHAR(60),
	@RFIDate bDate,
	@DateDue bDate,
	@ReqFirm bFirm,
	@ReqContact bEmployee,
	@Notes bNotes,
	@RFITypeDescription  varchar(60),
	@UniqueAttchID uniqueidentifier,
	@Issue bIssue = null,
	@Status bStatus,
	@Submittal varchar(10),
	@Drawing varchar(10),
	@Addendum varchar(10),
	@SpecSec varchar(10),
	@ScheduleNo varchar(10),
	@VendorGroup bGroup,
	@ResponsibleFirm bFirm = null,
	@ResponsiblePerson bEmployee = null,
	@Response bNotes,
	@PrefMethod varchar(1) = 'E',
	@ImpactDesc bItemDesc = null,
	@ImpactDays smallint = null,
	@ImpactCosts bDollar = null,
	@ImpactPrice bDollar = null,
	@RespondFirm bFirm = null,
	@RespondContact bEmployee = null,
	@DateSent bDate = null,
	@DateRecd bDate = null,
	@InfoRequested bNotes = null

)

AS
BEGIN
	SET NOCOUNT ON;
	
	declare @DefaultRFIDaysDue int
	declare @rcode int, @nextRFI int, @msg varchar(255)
	set @rcode = 0

	set @DefaultRFIDaysDue = (select DefaultRFIDaysDue from PMJCProjects where JCCo = @PMCo and Job = @Project)
	set @DateDue = DATEADD(DD, @DefaultRFIDaysDue, dbo.vfDateOnly())

	----#141031
	set @RFIDate = dbo.vfDateOnly()
	set @PrefMethod = 'E'

	-- 2011/06/06 - TomJ 
	-- Must Calculate the PM DocNumber using the same logic as V6 Whether we key off project and
	-- Sequence number or Project, doc type, and sequence number can be set on a project by project
	-- basis
	SET @msg = NULL
	EXECUTE dbo.vspPMGetNextPMDocNum @PMCo, @Project, @RFIType, '', 'RFI', @nextRFI OUTPUT, @msg OUTPUT
	IF (LEN(@msg) > 0)
	BEGIN
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END					

	set @msg = null
	exec @rcode = dbo.vpspFormatDatatypeField 'bDocument', @nextRFI, @msg output
	set @RFI = @msg



	if @Issue = -1
		begin 
		set @Issue = null
		end

	if @ResponsibleFirm = -1
		begin 
		set @ResponsibleFirm = null
		end

	if @ResponsiblePerson = -1
		begin 
		set @ResponsiblePerson = null
		end
			
	INSERT INTO PMRI(PMCo, Project, RFIType, RFI, Subject, RFIDate, Issue, Status, Submittal, 
	Drawing, Addendum, SpecSec, ScheduleNo, VendorGroup, ResponsibleFirm, ResponsiblePerson, 
	ReqFirm, ReqContact, Notes, UniqueAttchID, Response, PrefMethod, ImpactDays,
	ImpactCosts, ImpactPrice, RespondFirm, RespondContact, DateSent, DateRecd, InfoRequested,
	DateDue) 

	VALUES (@PMCo, @Project, @RFIType, @RFI, @Subject, @RFIDate, @Issue, @Status, @Submittal, 
	@Drawing, @Addendum, @SpecSec, @ScheduleNo, @VendorGroup, @ResponsibleFirm, @ResponsiblePerson, 
	@ReqFirm, @ReqContact, @Notes, @UniqueAttchID, @Response, @PrefMethod, 	@ImpactDays,
	@ImpactCosts, @ImpactPrice, @RespondFirm, @RespondContact, @DateSent, @DateRecd, @InfoRequested,
	@DateDue);

	DECLARE @KeyID int
	SET @KeyID = SCOPE_IDENTITY()
	execute vpspPMRFIEntryGet @PMCo, @Project, @ReqFirm, @ReqContact, @KeyID

	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIEntryInsert] TO [VCSPortal]
GO
