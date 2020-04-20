SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesInsert]
/************************************************************
* CREATED:		2/22/06	CHS
* MODIFIED:		6/12/07	CHS
* MODIFIED:		6/26/07	CHS
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts PM Meeting Minutes
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @MeetingType bDocType,
      @MeetingDate bDate,
	--@Meeting int,
      @Meeting VARCHAR(10),
      @MinutesType TINYINT,
      @MeetingTime SMALLDATETIME,
      @Location VARCHAR(30),
      @Subject VARCHAR(60),
      @VendorGroup bGroup,
      @FirmNumber bFirm,
      @Preparer bEmployee,
      @NextDate bDate,
      @NextTime SMALLDATETIME,
      @NextLocation VARCHAR(30),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
	
    )
AS 
    SET NOCOUNT ON ;


--if @Meeting is NULL or @Meeting = -1
    IF ( ISNULL(@Meeting, '') = '' )
        OR @Meeting = '+'
        OR @Meeting = 'n'
        OR @Meeting = 'N' 
        BEGIN
            SET @Meeting = ( SELECT ISNULL(( MAX(Meeting) + 1 ), 1)
                             FROM   PMMM WITH ( NOLOCK )
                             WHERE  PMCo = @PMCo
                                    AND Project = @Project
                                    AND MinutesType = @MinutesType
                                    AND MeetingType = @MeetingType
                           )
        END

	
    IF @Preparer = -1 
        SET @Preparer = NULL 

    INSERT  INTO PMMM
            ( PMCo,
              Project,
              MeetingType,
              MeetingDate,
              Meeting,
              MinutesType,
              MeetingTime,
              Location,
              Subject,
              VendorGroup,
              FirmNumber,
              Preparer,
              NextDate,
              NextTime,
              NextLocation,
              Notes,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @MeetingType,
              @MeetingDate,
              @Meeting,
              @MinutesType,
              @MeetingTime,
              @Location,
              @Subject,
              @VendorGroup,
              @FirmNumber,
              @Preparer,
              @NextDate,
              @NextTime,
              @NextLocation,
              @Notes,
              @UniqueAttchID
            ) ;


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMMeetingMinutesGet @PMCo, @Project, @VendorGroup, @KeyID



GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesInsert] TO [VCSPortal]
GO
