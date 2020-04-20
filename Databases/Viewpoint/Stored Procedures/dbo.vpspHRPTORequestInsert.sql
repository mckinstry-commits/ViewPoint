SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRPTORequestInsert]
/************************************************************
* CREATED:		03/20/08  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts the HR PTO Rquests
*	
* CALLED FROM:
*	ViewpointCS Portal  
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
      @Seq TINYINT,
      @Hours NUMERIC(10, 2),
      @Status CHAR(1),
      @Source CHAR(10),
      @RequesterComment VARCHAR(255),
      @ApproverComment VARCHAR(255),
      @Approver VARCHAR(128)
    )
AS 
    SET NOCOUNT ON ;

    SELECT  @Seq = ISNULL(( MAX(Seq) + 1 ), 0)
    FROM    HRES
    WHERE   HRCo = @HRCo
            AND HRRef = @HRRef
    SELECT  @Source = 'HRPTOReqVC',
            @Status = 'N'

    INSERT  INTO HRES
            ( HRCo,
              HRRef,
              Date,
              Description,
              ScheduleCode,
              Notes,
              UniqueAttchID,
              Seq,
              Hours,
              Status,
              Source,
              RequesterComment,
              ApproverComment,
              Approver
            )
    VALUES  ( @HRCo,
              @HRRef,
              @Date,
              @Description,
              @ScheduleCode,
              @Notes,
              @UniqueAttchID,
              @Seq,
              @Hours,
              @Status,
              @Source,
              @RequesterComment,
              @ApproverComment,
              @Approver
            )


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspHRPTORequestGet @HRCo, @HRRef, @KeyID
GO
GRANT EXECUTE ON  [dbo].[vpspHRPTORequestInsert] TO [VCSPortal]
GO
