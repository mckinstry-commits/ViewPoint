SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMPunchListUpdate]
/************************************************************
* CREATED:     3/29/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
* USAGE:
*   Updates PM Punch List
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PunchList bDocument,
      @Description VARCHAR(255),
      @PunchListDate bDate,
      @PrintOption CHAR(1),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_PunchList bDocument,
      @Original_Description VARCHAR(255),
      @Original_PunchListDate bDate,
      @Original_PrintOption CHAR(1),
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER

    )
AS 
    SET NOCOUNT ON ;
	
    UPDATE  dbo.PMPU
    SET     --PMCo = @PMCo, Project = @Project, PunchList = @PunchList, 
            Description = @Description,
            PrintOption = @PrintOption,
            PunchListDate = @PunchListDate,
            Notes = @Notes,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( PunchList = @Original_PunchList )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( PunchListDate = @Original_PunchListDate
                  OR @Original_PunchListDate IS NULL
                  AND PunchListDate IS NULL
                )
            AND ( PrintOption = @Original_PrintOption
                  OR @Original_PrintOption IS NULL
                  AND PrintOption IS NULL
                )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                ) 

    SELECT  PMCo,
            Project,
            PunchList,
            Description,
            PrintOption,
            PunchListDate,
            Notes,
            UniqueAttchID
    FROM    dbo.PMPU WITH ( NOLOCK )
    WHERE   ( PMCo = @PMCo )
            AND ( Project = @Project )
            AND ( PunchList = @PunchList )




GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListUpdate] TO [VCSPortal]
GO
