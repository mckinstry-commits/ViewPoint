SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesItemsDelete]
/************************************************************
* CREATED:     2/22/06  CHS
*
* USAGE:
*   Deletes PM Meeting Minutes Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
(
	@Original_Item int,
	@Original_Meeting int,
	@Original_MeetingType nvarchar(50),
	@Original_MinutesType tinyint,
	@Original_PMCo nvarchar(50),
	@Original_Project nvarchar(50),
	@Original_DueDate bDate,
	@Original_FinDate bDate,
	@Original_InitDate bDate,
	@Original_InitFirm nvarchar(50),
	@Original_Initiator nvarchar(50),
	@Original_Issue nvarchar(50),
	@Original_OriginalItem varchar(10),
	@Original_ResponsibleFirm nvarchar(50),
	@Original_ResponsiblePerson nvarchar(50),
	@Original_Status nvarchar(50),
	@Original_UniqueAttchID uniqueidentifier,
	@Original_VendorGroup nvarchar(50)
)
AS
	SET NOCOUNT ON;
DELETE FROM PMMI 

WHERE (Item = @Original_Item) 
AND (Meeting = @Original_Meeting) 
AND (MeetingType = @Original_MeetingType) 
AND (MinutesType = @Original_MinutesType) 
AND (PMCo = @Original_PMCo) 
AND (Project = @Original_Project) 
AND (DueDate = @Original_DueDate OR @Original_DueDate IS NULL AND DueDate IS NULL) 
AND (FinDate = @Original_FinDate OR @Original_FinDate IS NULL AND FinDate IS NULL) 
AND (InitDate = @Original_InitDate OR @Original_InitDate IS NULL AND InitDate IS NULL) 
AND (InitFirm = @Original_InitFirm OR @Original_InitFirm IS NULL AND InitFirm IS NULL) 
AND (Initiator = @Original_Initiator OR @Original_Initiator IS NULL AND Initiator IS NULL) 
AND (Issue = @Original_Issue OR @Original_Issue IS NULL AND Issue IS NULL) 
AND (OriginalItem = @Original_OriginalItem OR @Original_OriginalItem IS NULL AND OriginalItem IS NULL) 
AND (ResponsibleFirm = @Original_ResponsibleFirm OR @Original_ResponsibleFirm IS NULL AND ResponsibleFirm IS NULL) 
AND (ResponsiblePerson = @Original_ResponsiblePerson OR @Original_ResponsiblePerson IS NULL AND ResponsiblePerson IS NULL) 
AND (Status = @Original_Status OR @Original_Status IS NULL AND Status IS NULL) 
AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 
AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)

GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesItemsDelete] TO [VCSPortal]
GO
