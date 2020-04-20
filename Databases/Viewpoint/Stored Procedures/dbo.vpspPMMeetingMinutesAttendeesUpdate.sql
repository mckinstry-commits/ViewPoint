SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMMeetingMinutesAttendeesUpdate 
/************************************************************
* CREATED:     2/5/07  CHS
*
* USAGE:
*   Updates the PM Meeting Minutes Attendees
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/

(
	@PMCo bCompany,
	@Project bJob,
	@MeetingType bDocType,
	@Meeting int,
	@MinutesType tinyint,
	@Seq int,
	@VendorGroup bGroup,
	@FirmNumber bFirm,
	@ContactCode bEmployee,
	@PresentYN bYN,
	@UniqueAttchID uniqueidentifier,

	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_MeetingType bDocType,
	@Original_Meeting int,
	@Original_MinutesType tinyint,
	@Original_Seq int,
	@Original_VendorGroup bGroup,
	@Original_FirmNumber bFirm,
	@Original_ContactCode bEmployee,
	@Original_PresentYN bYN,
	@Original_UniqueAttchID uniqueidentifier
)

AS
	SET NOCOUNT ON;
	
UPDATE PMMD 

SET 
	--PMCo = @PMCo,
	--Project = @Project,
	--MeetingType = @MeetingType,
	--Meeting = @Meeting,
	--MinutesType = @MinutesType,
	--Seq = @Seq,
	--VendorGroup = @VendorGroup,
	FirmNumber = @FirmNumber,
	ContactCode = @ContactCode,
	PresentYN = @PresentYN,
	UniqueAttchID = @UniqueAttchID
	
WHERE (PMCo = @Original_PMCo)
	AND (Project = @Original_Project)
	AND (MeetingType = @Original_MeetingType)
	AND (Meeting = @Original_Meeting)
	AND (MinutesType = @Original_MinutesType)
	AND (Seq = @Original_Seq)
	AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)
	AND (FirmNumber = @Original_FirmNumber OR @Original_FirmNumber IS NULL AND FirmNumber IS NULL)
	AND (ContactCode = @Original_ContactCode OR @Original_ContactCode IS NULL AND ContactCode IS NULL)
	AND (PresentYN = @Original_PresentYN OR @Original_PresentYN IS NULL AND PresentYN IS NULL)
	AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL);



GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesAttendeesUpdate] TO [VCSPortal]
GO
