SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[vpspHRTCGet]
/************************************************************
* CREATED:     RWH 5/10/06
* MODIFIED:		6/7/07	CHS 
*
* USAGE:
*   Returns the HR Traiing Classes
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    HRCo     
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@HRCo bCompany,
	@KeyID int = Null)
AS

SET NOCOUNT ON;

SELECT KeyID, HRCo, TrainCode, Type, ClassSeq, ClassDesc, Instructor, Institution, Address, City, 
	State, Contact, Phone, EMail, Room, Hours, Status, CEUCredits, VendorGroup, Vendor, 
	StartDate, ClassTime, EndDate, TimeDesc, MaxAttend, Instructor1099YN, OSHAYN, MSHAYN, 
	FirstAidYN, CPRYN, ReimbursedYN, WorkRelatedYN, Notes, UniqueAttchID

FROM HRTC 

where HRCo = @HRCo 
and KeyID = IsNull(@KeyID, KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspHRTCGet] TO [VCSPortal]
GO
