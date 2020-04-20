SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRequestForInfoDelete]
/************************************************************
* CREATED:     3/14/06  CHS
* MODIFIED BY: 4/7/2011 GP	Added Reference and Suggestion column
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)

*
* USAGE:
*	Deletes PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_RFIType bDocType,
      @Original_RFI bDocument,
      @Original_Subject CHAR(60),
      @Original_RFIDate bDate,
      @Original_Issue bIssue,
      @Original_Status bStatus,
      @Original_Submittal VARCHAR(10),
      @Original_Drawing VARCHAR(10),
      @Original_Addendum VARCHAR(10),
      @Original_SpecSec VARCHAR(10),
      @Original_ScheduleNo VARCHAR(10),
      @Original_VendorGroup bGroup,
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_ReqFirm bFirm,
      @Original_ReqContact bEmployee,
      @Original_Notes bNotes,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_Response VARCHAR(MAX),
      @Original_DateDue bDate,
      @Original_Reference VARCHAR(10),
      @Original_Suggestion VARCHAR(MAX)
    )
AS 
    SET NOCOUNT ON ;

    DELETE  FROM PMRI
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( RFIType = @Original_RFIType
                  OR @Original_RFIType IS NULL
                  AND RFIType IS NULL
                )
            AND ( RFI = @Original_RFI
                  OR @Original_RFI IS NULL
                  AND RFI IS NULL
                )
            AND ( Subject = @Original_Subject
                  OR @Original_Subject IS NULL
                  AND Subject IS NULL
                )
            AND ( RFIDate = @Original_RFIDate
                  OR @Original_RFIDate IS NULL
                  AND RFIDate IS NULL
                )
            AND ( Issue = @Original_Issue
                  OR @Original_Issue IS NULL
                  AND Issue IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                )
            AND ( Submittal = @Original_Submittal
                  OR @Original_Submittal IS NULL
                  AND Submittal IS NULL
                )
            AND ( Drawing = @Original_Drawing
                  OR @Original_Drawing IS NULL
                  AND Drawing IS NULL
                )
            AND ( Addendum = @Original_Addendum
                  OR @Original_Addendum IS NULL
                  AND Addendum IS NULL
                )
            AND ( SpecSec = @Original_SpecSec
                  OR @Original_SpecSec IS NULL
                  AND SpecSec IS NULL
                )
            AND ( ScheduleNo = @Original_ScheduleNo
                  OR @Original_ScheduleNo IS NULL
                  AND ScheduleNo IS NULL
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
            AND ( ReqFirm = @Original_ReqFirm
                  OR @Original_ReqFirm IS NULL
                  AND ReqFirm IS NULL
                )
            AND ( ReqContact = @Original_ReqContact
                  OR @Original_ReqContact IS NULL
                  AND ReqContact IS NULL
                ) 
--AND(Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) 
--AND(UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 
--AND(Response = @Original_Response OR @Original_Response IS NULL AND Response IS NULL) 
            AND ( DateDue = @Original_DateDue
                  OR @Original_DateDue IS NULL
                  AND DateDue IS NULL
                )
            AND ( Reference = @Original_Reference
                  OR ( @Original_Reference IS NULL
                       AND Reference IS NULL
                     )
                )
            AND ( Suggestion = @Original_Suggestion
                  OR ( @Original_Suggestion IS NULL
                       AND Suggestion IS NULL
                     )
                ) ;




GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForInfoDelete] TO [VCSPortal]
GO
