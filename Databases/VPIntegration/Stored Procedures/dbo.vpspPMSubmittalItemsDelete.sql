SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMSubmittalItemsDelete
/************************************************************
* CREATED:     8/14/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)

* USAGE:
*   Deletes the PM Submittal Header	Item
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_Submittal bDocument,
      @Original_SubmittalType bDocType,
      @Original_Rev TINYINT,
      @Original_Item SMALLINT,
      @Original_Description bItemDesc,
      @Original_Status bStatus,
      @Original_Send bYN,
      @Original_DateReqd bDate,
      @Original_DateRecd bDate,
      @Original_ToArchEng bDate,
      @Original_DueBackArch bDate,
      @Original_RecdBackArch bDate,
      @Original_DateRetd bDate,
      @Original_ActivityDate bDate,
      @Original_CopiesRecd TINYINT,
      @Original_CopiesSent TINYINT,
      @Original_CopiesReqd TINYINT,
      @Original_CopiesRecdArch TINYINT,
      @Original_CopiesSentArch TINYINT,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;

-- note role id 9 = Project Manager

    DELETE  FROM PMSI
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( Submittal = @Original_Submittal )
            AND ( SubmittalType = @Original_SubmittalType )
            AND ( Rev = @Original_Rev )
            AND ( Item = @Original_Item )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                )
            AND ( Send = @Original_Send )
            AND ( DateReqd = @Original_DateReqd
                  OR @Original_DateReqd IS NULL
                  AND DateReqd IS NULL
                )
            AND ( DateRecd = @Original_DateRecd
                  OR @Original_DateRecd IS NULL
                  AND DateRecd IS NULL
                )
            AND ( ToArchEng = @Original_ToArchEng
                  OR @Original_ToArchEng IS NULL
                  AND ToArchEng IS NULL
                )
            AND ( DueBackArch = @Original_DueBackArch
                  OR @Original_DueBackArch IS NULL
                  AND DueBackArch IS NULL
                )
            AND ( RecdBackArch = @Original_RecdBackArch
                  OR @Original_RecdBackArch IS NULL
                  AND RecdBackArch IS NULL
                )
            AND ( DateRetd = @Original_DateRetd
                  OR @Original_DateRetd IS NULL
                  AND DateRetd IS NULL
                )
            AND ( ActivityDate = @Original_ActivityDate
                  OR @Original_ActivityDate IS NULL
                  AND ActivityDate IS NULL
                )
            AND ( CopiesRecd = @Original_CopiesRecd
                  OR @Original_CopiesRecd IS NULL
                  AND CopiesRecd IS NULL
                )
            AND ( CopiesSent = @Original_CopiesSent
                  OR @Original_CopiesSent IS NULL
                  AND CopiesSent IS NULL
                )
            AND ( CopiesReqd = @Original_CopiesReqd
                  OR @Original_CopiesReqd IS NULL
                  AND CopiesReqd IS NULL
                )
            AND ( CopiesRecdArch = @Original_CopiesRecdArch
                  OR @Original_CopiesRecdArch IS NULL
                  AND CopiesRecdArch IS NULL
                )
            AND ( CopiesSentArch = @Original_CopiesSentArch
                  OR @Original_CopiesSentArch IS NULL
                  AND CopiesSentArch IS NULL
                )
--AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL)
--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)

GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalItemsDelete] TO [VCSPortal]
GO
