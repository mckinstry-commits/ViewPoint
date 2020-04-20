SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspHRScheduleItemUpdate]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Updates an HR Resource Schedule 
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
      @ScheduleCode VARCHAR(10),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_Date bDate,
      @Original_HRCo bCompany,
      @Original_HRRef bHRRef,
      @Original_Description bDesc,
      @Original_ScheduleCode VARCHAR(10),
      @Original_UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT OFF ;
    UPDATE  HRES
    SET     HRCo = @HRCo,
            HRRef = @HRRef,
            Date = @Date,
            Description = @Description,
            ScheduleCode = @ScheduleCode,
            Notes = @Notes,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( Date = @Original_Date )
            AND ( HRCo = @Original_HRCo )
            AND ( HRRef = @Original_HRRef )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( ScheduleCode = @Original_ScheduleCode )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                ) ;
	


GO
GRANT EXECUTE ON  [dbo].[vpspHRScheduleItemUpdate] TO [VCSPortal]
GO
