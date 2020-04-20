SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspHRScheduleItemDelete]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    
*
* USAGE:
*   Deletes a HR Resource Schedule 
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
	@Original_Date bDate,
	@Original_HRCo bCompany,
	@Original_HRRef bHRRef,
	@Original_Description bDesc,
	@Original_ScheduleCode varchar(10),
	@Original_UniqueAttchID uniqueidentifier
)
AS
	SET NOCOUNT OFF;
DELETE FROM HRES WHERE (Date = @Original_Date) AND (HRCo = @Original_HRCo) AND (HRRef = @Original_HRRef) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) AND (ScheduleCode = @Original_ScheduleCode) AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)



GO
GRANT EXECUTE ON  [dbo].[vpspHRScheduleItemDelete] TO [VCSPortal]
GO
