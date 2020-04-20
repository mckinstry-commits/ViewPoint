SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspPMSubmittalHeaderDelete
/************************************************************
* CREATED:     7/24/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)

* USAGE:
*   Deletes the PM Submittal Header	
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
      @Original_SubmittalDescription bItemDesc,
      @Original_PhaseGroup bGroup,
      @Original_Phase bPhase,
      @Original_Issue bIssue,
      @Original_Status bStatus,
      @Original_VendorGroup bGroup,
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_SubFirm bFirm,
      @Original_SubContact bEmployee,
      @Original_ArchEngFirm bFirm,
      @Original_ArchEngContact bEmployee,
      @Original_DateReqd bDate,
      @Original_DateRecd bDate,
      @Original_ToArchEng bDate,
      @Original_DueBackArch bDate,
      @Original_DateRetd bDate,
      @Original_ActivityDate bDate,
      @Original_CopiesRecd TINYINT,
      @Original_CopiesSent TINYINT,
      @Original_Notes VARCHAR(MAX),
      @Original_CopiesReqd TINYINT,
      @Original_CopiesRecdArch TINYINT,
      @Original_CopiesSentArch TINYINT,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_SpecNumber VARCHAR(20),
      @Original_RecdBackArch bDate
	
	
    )
AS 
    SET NOCOUNT ON ;

-- note role id 9 = Project Manager

    DELETE  FROM PMSM
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( Submittal = @Original_Submittal )
            AND ( SubmittalType = @Original_SubmittalType )
            AND ( Rev = @Original_Rev )
            AND ( Description = @Original_SubmittalDescription
                  OR @Original_SubmittalDescription IS NULL
                  AND Description IS NULL
                )
            AND ( PhaseGroup = @Original_PhaseGroup
                  OR @Original_PhaseGroup IS NULL
                  AND PhaseGroup IS NULL
                )
            AND ( Phase = @Original_Phase
                  OR @Original_Phase IS NULL
                  AND Phase IS NULL
                )
            AND ( Issue = @Original_Issue
                  OR @Original_Issue IS NULL
                  AND Issue IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                )
            AND ( VendorGroup = @Original_VendorGroup
                  OR @Original_VendorGroup IS NULL
                  AND VendorGroup IS NULL
                )
            AND ( ResponsibleFirm = @Original_ResponsibleFirm
                  OR @Original_ResponsibleFirm IS NULL
                  AND ResponsibleFirm IS NULL
                )
            AND ( ResponsiblePerson = @Original_ResponsiblePerson
                  OR @Original_ResponsiblePerson IS NULL
                  AND ResponsiblePerson IS NULL
                )
            AND ( SubFirm = @Original_SubFirm
                  OR @Original_SubFirm IS NULL
                  AND SubFirm IS NULL
                )
            AND ( SubContact = @Original_SubContact
                  OR @Original_SubContact IS NULL
                  AND SubContact IS NULL
                )
            AND ( ArchEngFirm = @Original_ArchEngFirm
                  OR @Original_ArchEngFirm IS NULL
                  AND ArchEngFirm IS NULL
                )
            AND ( ArchEngContact = @Original_ArchEngContact
                  OR @Original_ArchEngContact IS NULL
                  AND ArchEngContact IS NULL
                )
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
--AND(Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL)
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
--AND(UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)
            AND ( SpecNumber = @Original_SpecNumber
                  OR @Original_SpecNumber IS NULL
                  AND SpecNumber IS NULL
                )
            AND ( RecdBackArch = @Original_RecdBackArch
                  OR @Original_RecdBackArch IS NULL
                  AND RecdBackArch IS NULL
                )


GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalHeaderDelete] TO [VCSPortal]
GO
