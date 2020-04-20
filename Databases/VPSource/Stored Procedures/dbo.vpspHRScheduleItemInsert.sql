SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspHRScheduleItemInsert]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    
*
* USAGE:
*   Inserts a new HR Resource Schedule 
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*            
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@HRCo bCompany,
	@HRRef bHRRef,
	@Date bDate,
	@Description bDesc,
	@ScheduleCode varchar(10),
	@Notes bNotes,
	@UniqueAttchID uniqueidentifier
)
AS
	SET NOCOUNT OFF;
INSERT INTO HRES(HRCo, HRRef, Date, Description, ScheduleCode, Notes, UniqueAttchID) 
VALUES (@HRCo, @HRRef, @Date, @Description, @ScheduleCode, @Notes, @UniqueAttchID);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspHRScheduleItemGet @HRCo, @HRRef, @KeyID
	


GO
GRANT EXECUTE ON  [dbo].[vpspHRScheduleItemInsert] TO [VCSPortal]
GO
