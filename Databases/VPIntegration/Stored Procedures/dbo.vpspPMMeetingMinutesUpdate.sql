SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesUpdate]
/************************************************************
* CREATED:		2/22/06  CHS
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Deletes PM Meeting Minutes
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo NVARCHAR(50),
      @Project NVARCHAR(50),
      @MeetingType NVARCHAR(50),
      @MeetingDate bDate,
      @Meeting INT,
      @MinutesType TINYINT,
      @MeetingTime SMALLDATETIME,
      @Location VARCHAR(30),
      @Subject VARCHAR(60),
      @VendorGroup NVARCHAR(50),
      @FirmNumber NVARCHAR(50),
      @Preparer NVARCHAR(50),
      @NextDate bDate,
      @NextTime SMALLDATETIME,
      @NextLocation VARCHAR(30),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_Meeting INT,
      @Original_MeetingType NVARCHAR(50),
      @Original_MinutesType TINYINT,
      @Original_PMCo NVARCHAR(50),
      @Original_Project NVARCHAR(50),
      @Original_FirmNumber NVARCHAR(50),
      @Original_Location VARCHAR(30),
      @Original_MeetingDate bDate,
      @Original_MeetingTime SMALLDATETIME,
      @Original_NextDate bDate,
      @Original_NextLocation VARCHAR(30),
      @Original_NextTime SMALLDATETIME,
      @Original_Preparer NVARCHAR(50),
      @Original_Subject VARCHAR(60),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VendorGroup NVARCHAR(50),
      @Original_Notes VARCHAR(MAX)
    )
AS 
    SET NOCOUNT ON ;
    UPDATE  PMMM
    SET     --PMCo = @PMCo, Project = @Project, MeetingType = @MeetingType, Meeting = @Meeting, MinutesType = @MinutesType, 
            MeetingDate = @MeetingDate,
            MeetingTime = @MeetingTime,
            Location = @Location,
            Subject = @Subject,
            VendorGroup = @VendorGroup,
            FirmNumber = @FirmNumber,
            Preparer = @Preparer,
            NextDate = @NextDate,
            NextTime = @NextTime,
            NextLocation = @NextLocation,
            Notes = @Notes,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( Meeting = @Original_Meeting )
            AND ( MeetingType = @Original_MeetingType )
            AND ( MinutesType = @Original_MinutesType )
            AND ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( FirmNumber = @Original_FirmNumber
                  OR @Original_FirmNumber IS NULL
                  AND FirmNumber IS NULL
                )
            AND ( Location = @Original_Location
                  OR @Original_Location IS NULL
                  AND Location IS NULL
                )
            AND ( MeetingDate = @Original_MeetingDate )
            AND ( MeetingTime = @Original_MeetingTime
                  OR @Original_MeetingTime IS NULL
                  AND MeetingTime IS NULL
                )
            AND ( NextDate = @Original_NextDate
                  OR @Original_NextDate IS NULL
                  AND NextDate IS NULL
                )
            AND ( NextLocation = @Original_NextLocation
                  OR @Original_NextLocation IS NULL
                  AND NextLocation IS NULL
                )
            AND ( NextTime = @Original_NextTime
                  OR @Original_NextTime IS NULL
                  AND NextTime IS NULL
                )
            AND ( Preparer = @Original_Preparer
                  OR @Original_Preparer IS NULL
                  AND Preparer IS NULL
                )
            AND ( Subject = @Original_Subject
                  OR @Original_Subject IS NULL
                  AND Subject IS NULL
                )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                )
            AND ( VendorGroup = @Original_VendorGroup
                  OR @Original_VendorGroup IS NULL
                  AND VendorGroup IS NULL
                ) ;


GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesUpdate] TO [VCSPortal]
GO
