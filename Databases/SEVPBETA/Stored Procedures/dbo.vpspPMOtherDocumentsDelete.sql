SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMOtherDocumentsDelete
/************************************************************
* CREATED:     11/28/06  CHS
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*              2011/11/27 TEJ - Modifying to reflect a change of Description to DocumentDescription
*
* USAGE:
*   Returns PM Other Documents
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, and VendorGroup
*
************************************************************/
    (
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_DocType bDocType,
      @Original_Document bDocument,
	  
      @Original_DocumentDescription bDesc,
      @Original_Location VARCHAR(60),
      @Original_VendorGroup bGroup,
      @Original_RelatedFirm bFirm,
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_Issue bIssue,
      @Original_Status bStatus,
      @Original_DateDue bDate,
      @Original_DateRecd bDate,
      @Original_DateSent bDate,
      @Original_DateDueBack bDate,
      @Original_DateRecdBack bDate,
      @Original_DateRetd bDate,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER

    )
AS 
    SET NOCOUNT ON ;

    DELETE  FROM PMOD
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( DocType = @Original_DocType )
            AND ( Document = @Original_Document )
            AND ( Description = @Original_DocumentDescription )
            AND ( Location = @Original_Location
                  OR @Original_Location IS NULL
                  AND Location IS NULL
                )
            AND ( VendorGroup = @Original_VendorGroup
                  OR @Original_VendorGroup IS NULL
                  AND VendorGroup IS NULL
                )
            AND ( RelatedFirm = @Original_RelatedFirm
                  OR @Original_RelatedFirm IS NULL
                  AND RelatedFirm IS NULL
                )
            AND ( ResponsibleFirm = @Original_ResponsibleFirm
                  OR @Original_ResponsibleFirm IS NULL
                  AND ResponsibleFirm IS NULL
                )
            AND ( ResponsiblePerson = @Original_ResponsiblePerson
                  OR @Original_ResponsiblePerson IS NULL
                  AND ResponsiblePerson IS NULL
                )
            AND ( Issue = @Original_Issue
                  OR @Original_Issue IS NULL
                  AND Issue IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                )
            AND ( DateDue = @Original_DateDue
                  OR @Original_DateDue IS NULL
                  AND DateDue IS NULL
                )
            AND ( DateRecd = @Original_DateRecd
                  OR @Original_DateRecd IS NULL
                  AND DateRecd IS NULL
                )
            AND ( DateSent = @Original_DateSent
                  OR @Original_DateSent IS NULL
                  AND DateSent IS NULL
                )
            AND ( DateDueBack = @Original_DateDueBack
                  OR @Original_DateDueBack IS NULL
                  AND DateDueBack IS NULL
                )
            AND ( DateRecdBack = @Original_DateRecdBack
                  OR @Original_DateRecdBack IS NULL
                  AND DateRecdBack IS NULL
                )
            AND ( DateRetd = @Original_DateRetd
                  OR @Original_DateRetd IS NULL
                  AND DateRetd IS NULL
                )
	--AND (Notes = @Original_Notes OR Notes IS NULL AND Notes is Null)
	--AND (UniqueAttchID = @Original_UniqueAttchID OR UniqueAttchID IS NULL AND UniqueAttchID is Null)

GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsDelete] TO [VCSPortal]
GO
