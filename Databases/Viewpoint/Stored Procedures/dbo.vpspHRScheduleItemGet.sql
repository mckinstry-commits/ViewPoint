SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRScheduleItemGet]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    chs 9/14/06
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the HR Resource Schedule based on the HRCo and HRRef
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
SELECT s.KeyID, s.HRCo, s.HRRef, s.Date, s.Description, s.ScheduleCode, 
c.Description as 'ScheduleCodeDescription', s.Notes, s.UniqueAttchID 

FROM HRES s with (nolock)
	left join HRCM c with (nolock) on s.HRCo = c.HRCo and s.ScheduleCode = c.Code and c.Type = 'C'
	
where s.HRCo = @HRCo and s.HRRef = @HRRef
and s.KeyID = IsNull(@KeyID, s.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspHRScheduleItemGet] TO [VCSPortal]
GO
