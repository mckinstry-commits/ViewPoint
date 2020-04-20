SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMRequestForInfoUpdate]
/***********************************************************
* Created:     8/31/09		JB		Rewrote SP/cleanup
* Modified:		4/7/2011	GP		Added Reference and Suggestion column, also fixed call to vpspPMRequestForInfoGet
*										by passing VendorGroup parameter.
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
*
* Description:	Update an RFI.
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@RFIType bDocType,
	@RFI bDocument,
	@Subject VARCHAR(60),
	@RFIDate bDate,
	@Issue bIssue,
	@Status bStatus,
	@Submittal bDocument,
	@Drawing VARCHAR(10),
	@Addendum VARCHAR(10),
	@SpecSec VARCHAR(10),
	@ScheduleNo VARCHAR(10),
	@VendorGroup bGroup,
	@ResponsibleFirm bFirm,
	@ResponsiblePerson bEmployee,
	@ReqFirm bFirm,
	@ReqContact bEmployee,
	@Notes VARCHAR(MAX),
	@UniqueAttchID UNIQUEIDENTIFIER,
	@Response VARCHAR(MAX),
	@DateDue bDate,
	@ImpactDesc bItemDesc,
	@ImpactDays SMALLINT,
	@ImpactCosts bDollar,
	@ImpactPrice bDollar,
	@RespondFirm bFirm,
	@RespondContact bEmployee,
	@DateSent bDate,
	@DateRecd bDate,
	@PrefMethod VARCHAR(1),
	@InfoRequested VARCHAR(MAX),
	@Reference varchar(10),
	@Suggestion varchar(max),
	@KeyID BIGINT,
	
	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_RFIType bDocType,
	@Original_RFI bDocument,
	@Original_Subject VARCHAR(60),
	@Original_RFIDate bDate,
	@Original_Issue bIssue,
	@Original_Status bStatus,
	@Original_Submittal bDocument,
	@Original_Drawing VARCHAR(10),
	@Original_Addendum VARCHAR(10),
	@Original_SpecSec VARCHAR(10),
	@Original_ScheduleNo VARCHAR(10),
	@Original_VendorGroup bGroup,
	@Original_ResponsibleFirm bFirm,
	@Original_ResponsiblePerson bEmployee,
	@Original_ReqFirm bFirm,
	@Original_ReqContact bEmployee,
	@Original_Notes VARCHAR(MAX),
	@Original_UniqueAttchID UNIQUEIDENTIFIER,
	@Original_Response VARCHAR(MAX),
	@Original_DateDue bDate,
	@Original_ImpactDesc bItemDesc,
	@Original_ImpactDays SMALLINT,
	@Original_ImpactCosts bDollar,
	@Original_ImpactPrice bDollar,
	@Original_RespondFirm bFirm,
	@Original_RespondContact bEmployee,
	@Original_DateSent bDate,
	@Original_DateRecd bDate,
	@Original_PrefMethod VARCHAR(1),
	@Original_InfoRequested VARCHAR(MAX),
	@Original_Reference varchar(10),
	@Original_Suggestion varchar(max),
	@Original_KeyID BIGINT
	)

AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @DocCat VARCHAR(10), @msg VARCHAR(255)
	SET @DocCat = 'RFI'
	
	
	--Status Code Validation
	IF ([dbo].vpfPMValidateStatusCode(@Status, @DocCat)) = 0
	BEGIN
		SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '') + ' is not valid for Document Category: ' + ISNULL(@DocCat, '') + '.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
	--Issue Validation
	IF (@Issue = -1) SET @Issue = NULL
	
	--ResponsibleFirm Validation
	IF (@ResponsibleFirm = -1) SET @ResponsibleFirm = NULL
	
	--ResponsiblePerson Validation
	IF (@ResponsiblePerson = -1) SET @ResponsiblePerson = NULL
	
	--ReqFirm Validation
	IF (@ReqFirm = -1) SET @ReqFirm = NULL
	
	--ReqContact Validation
	IF (@ReqContact = -1) SET @ReqContact = NULL
	
	--Submittal Validation
	IF @Submittal <> @Original_Submittal
	BEGIN
		SET @msg = NULL
		EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @Submittal, @msg OUTPUT
		SET @Submittal = @msg
	END

	--Update the Request for info entry
	UPDATE PMRI
	SET
		Subject = @Subject,
		RFIDate = @RFIDate,
		Issue = @Issue,
		Status = @Status,
		Submittal = @Submittal,
		Drawing = @Drawing,
		Addendum = @Addendum,
		SpecSec = @SpecSec,
		ScheduleNo = @ScheduleNo,
		VendorGroup = @VendorGroup,
		ResponsibleFirm = @ResponsibleFirm,
		ResponsiblePerson = @ResponsiblePerson,
		ReqFirm = @ReqFirm,
		ReqContact = @ReqContact,
		Notes = @Notes,
		UniqueAttchID = @UniqueAttchID,
		Response = @Response,
		DateDue = @DateDue,
		ImpactDesc = @ImpactDesc,
		ImpactDays = @ImpactDays,
		ImpactCosts = @ImpactCosts,
		ImpactPrice = @ImpactPrice,
		RespondFirm = @RespondFirm,
		RespondContact = @RespondContact,
		DateSent = @DateSent,
		DateRecd = @DateRecd,
		PrefMethod = @PrefMethod,
		InfoRequested = @InfoRequested,
		Reference = @Reference,
		Suggestion = @Suggestion

	WHERE PMCo = @Original_PMCo
		AND Project = @Original_Project
		AND RFIType = @Original_RFIType
		AND RFI = @Original_RFI

	EXECUTE vpspPMRequestForInfoGet @PMCo, @Project, @VendorGroup, @KeyID

	vspExit:
END



GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForInfoUpdate] TO [VCSPortal]
GO
