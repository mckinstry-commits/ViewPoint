SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFIResponderUpdate]
/************************************************************
* CREATED:     7/11/06  CHS
* MODIFIED:		7/12/07	CHS
*				GF 09/03/2010 - issue #141031 change to use date only function
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
* 
* USAGE:
*   Updates the PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @RFIType bDocType,
      @RFI bDocument,
      @Subject VARCHAR(60),
      @RFIDate bDate,
      @Issue bIssue,
      @Status bStatus,
      @Submittal bDocument,
      @Drawing VARCHAR(10),
      @Addendum VARCHAR(10),
      @SpecSec VARCHAR(10),
      @ScheduleNo VARCHAR(10),
      @VendorGroup bGroup,
      @ResponsibleFirm bFirm,
      @ResponsiblePerson bEmployee,
      @ReqFirm bFirm,
      @ReqContact bEmployee,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Response VARCHAR(MAX),
      @DateDue bDate,
      @ImpactDesc bItemDesc,
      @ImpactDays SMALLINT,
      @ImpactCosts bDollar,
      @ImpactPrice bDollar,
      @RespondFirm bFirm,
      @RespondContact bEmployee,
      @DateSent bDate,
      @DateRecd bDate,
      @PrefMethod VARCHAR(1),
      @InfoRequested VARCHAR(MAX),
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_RFIType bDocType,
      @Original_RFI bDocument,
      @Original_Subject VARCHAR(60),
      @Original_RFIDate bDate,
      @Original_Issue bIssue,
      @Original_Status bStatus,
      @Original_Submittal bDocument,
      @Original_Drawing VARCHAR(10),
      @Original_Addendum VARCHAR(10),
      @Original_SpecSec VARCHAR(10),
      @Original_ScheduleNo VARCHAR(10),
      @Original_VendorGroup bGroup,
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_ReqFirm bFirm,
      @Original_ReqContact bEmployee,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_Response VARCHAR(MAX),
      @Original_DateDue bDate,
      @Original_ImpactDesc bItemDesc,
      @Original_ImpactDays SMALLINT,
      @Original_ImpactCosts bDollar,
      @Original_ImpactPrice bDollar,
      @Original_RespondFirm bFirm,
      @Original_RespondContact bEmployee,
      @Original_DateSent bDate,
      @Original_DateRecd bDate,
      @Original_PrefMethod VARCHAR(1),
      @Original_InfoRequested VARCHAR(MAX)

    )
AS 
    SET NOCOUNT ON ;
	
    UPDATE  PMRI
    SET     Response = @Response
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( RFIType = @Original_RFIType )
            AND ( RFI = @Original_RFI ) 



    UPDATE  PMRD
    SET     Response = @Response,
	----#141031
            DateRecd = dbo.vfDateOnly()
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( RFIType = @Original_RFIType )
            AND ( RFI = @Original_RFI )
            AND ( RFISeq = ( SELECT MIN(d.RFISeq)
                             FROM   PMRD d
                             WHERE  d.PMCo = @Original_PMCo
                                    AND d.Project = @Original_Project
                                    AND d.RFIType = @Original_RFIType
                                    AND d.RFI = @Original_RFI
                           ) ) ;




GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIResponderUpdate] TO [VCSPortal]
GO
