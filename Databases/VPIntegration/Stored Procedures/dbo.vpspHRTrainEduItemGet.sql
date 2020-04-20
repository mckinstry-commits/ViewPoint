SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspHRTrainEduItemGet]
/************************************************************
* CREATED:     SDE 5/31/2006
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the HR Resource Training\Education based on the HRCo and HRRef
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    HRCo, HRRef        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@HRCo bCompany, @HRRef int,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;

select 
	KeyID, HRCo, HRRef, Seq, TrainCode, Description, Institution, Class, 
	Date, Status, 
	case Status
		When 'A' then 'Absent'
		When 'C' then 'Complete'
		When 'I' then 'In Progress'
		When 'S' then 'Scheduled'
		When 'U' then 'Unscheduled'
		When 'X' then 'Canceled'						
		end as 'StatusDescription',
		
	Grade, CEUCredits, Hours, DegreeYN, DegreeDesc, Cost, 
	ReimbursedYN, Instructor1099YN, VendorGroup, Vendor, OSHAYN, MSHAYN, 
	FirstAidYN, CPRYN, WorkRelatedYN, HistSeq, Notes, UniqueAttchID, Type, 
	ClassSeq, CompleteDate 

from HRET with (nolock)

where HRCo = @HRCo and HRRef = @HRRef
and KeyID = IsNull(@KeyID, KeyID)





GO
GRANT EXECUTE ON  [dbo].[vpspHRTrainEduItemGet] TO [VCSPortal]
GO
