SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesDelete]
/************************************************************
* CREATED:     2/22/06  CHS
*
* USAGE:
*   Deletes PM Meeting Minutes
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@Original_Meeting int,
	@Original_MeetingType nvarchar(50),
	@Original_MinutesType tinyint,
	@Original_PMCo nvarchar(50),
	@Original_Project nvarchar(50),
	@Original_FirmNumber nvarchar(50),
	@Original_Location varchar(30),
	@Original_MeetingDate bDate,
	@Original_MeetingTime smalldatetime,
	@Original_NextDate bDate,
	@Original_NextLocation varchar(30),
	@Original_NextTime smalldatetime,
	@Original_Preparer nvarchar(50),
	@Original_Subject varchar(60),
	@Original_UniqueAttchID uniqueidentifier,
	@Original_VendorGroup nvarchar(50)
)
AS
	SET NOCOUNT ON;
DELETE FROM PMMM 
WHERE (Meeting = @Original_Meeting) 
AND (MeetingType = @Original_MeetingType) 
AND (MinutesType = @Original_MinutesType) 
AND (PMCo = @Original_PMCo) AND (Project = @Original_Project) 
AND (FirmNumber = @Original_FirmNumber OR @Original_FirmNumber IS NULL AND FirmNumber IS NULL) 
AND (Location = @Original_Location OR @Original_Location IS NULL AND Location IS NULL) 
AND (MeetingDate = @Original_MeetingDate) 
AND (MeetingTime = @Original_MeetingTime OR @Original_MeetingTime IS NULL AND MeetingTime IS NULL) 
AND (NextDate = @Original_NextDate OR @Original_NextDate IS NULL AND NextDate IS NULL) 
AND (NextLocation = @Original_NextLocation OR @Original_NextLocation IS NULL AND NextLocation IS NULL) 
AND (NextTime = @Original_NextTime OR @Original_NextTime IS NULL AND NextTime IS NULL) 
AND (Preparer = @Original_Preparer OR @Original_Preparer IS NULL AND Preparer IS NULL) 
AND (Subject = @Original_Subject OR @Original_Subject IS NULL AND Subject IS NULL) 
AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 
AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)

GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesDelete] TO [VCSPortal]
GO
