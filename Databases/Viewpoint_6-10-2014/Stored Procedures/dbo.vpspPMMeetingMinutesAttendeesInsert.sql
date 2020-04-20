SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesAttendeesInsert]
/************************************************************
* CREATED:		2/5/07		CHS
* MODIFIED:		6/12/07		CHS
* MODIFIED:		11/19/07	CHS  
*
* USAGE:
*   Inserts the PM Meeting Minutes Attendees
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
	--@Seq int,
	@Seq varchar(10),
	@VendorGroup bGroup,
	@FirmNumber bFirm,
	@ContactCode bEmployee,
	@PresentYN bYN,
	@UniqueAttchID uniqueidentifier

)

AS
	SET NOCOUNT ON;
	
Set @Seq = (Select IsNull((Max(Seq)+1),1) from PMMD with (nolock) 
				where PMCo = @PMCo 
				and Project = @Project 
				and MinutesType = @MinutesType
				and Meeting = @Meeting
				and MeetingType = @MeetingType)
	
INSERT INTO PMMD(PMCo, Project, MeetingType, Meeting, MinutesType, Seq, 
	VendorGroup, FirmNumber, ContactCode, PresentYN, UniqueAttchID) 

VALUES (@PMCo, @Project, @MeetingType, @Meeting, @MinutesType, @Seq, 
	@VendorGroup, @FirmNumber, @ContactCode, @PresentYN, @UniqueAttchID);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMMeetingMinutesAttendeesGet @PMCo, @Project, @MeetingType, 
	@Meeting, @MinutesType, @VendorGroup, @FirmNumber, @ContactCode, @KeyID


GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesAttendeesInsert] TO [VCSPortal]
GO
