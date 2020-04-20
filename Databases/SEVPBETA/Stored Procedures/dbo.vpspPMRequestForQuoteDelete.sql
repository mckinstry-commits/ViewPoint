SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMRequestForQuoteDelete
/************************************************************
* CREATED:     1/08/07  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Returns PM RFQ
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
*
************************************************************/
    (
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_PCOType bDocType,
      @Original_PCO bPCO,
      @Original_RFQ bDocument,
      @Original_Description CHAR(60),
      @Original_RFQDate bDate,
      @Original_VendorGroup bGroup,
      @Original_FirmNumber bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_Status bStatus,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER

    )
AS 
    SET NOCOUNT ON ;

    DELETE  PMRQ
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( PCOType = @Original_PCOType )
            AND ( PCO = @Original_PCO )
            AND ( RFQ = @Original_RFQ )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( RFQDate = @Original_RFQDate )
            AND ( VendorGroup = @Original_VendorGroup
                  OR @Original_VendorGroup IS NULL
                  AND VendorGroup IS NULL
                )
            AND ( FirmNumber = @Original_FirmNumber
                  OR @Original_FirmNumber IS NULL
                  AND FirmNumber IS NULL
                )
            AND ( ResponsiblePerson = @Original_ResponsiblePerson
                  OR @Original_ResponsiblePerson IS NULL
                  AND ResponsiblePerson IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                ) 
	
	--AND  (Notes = @Original_Notes OR Notes@Original_Notes IS NULL AND Notes IS NULL) 
	--AND  (UniqueAttchID = @Original_UniqueAttchID OR UniqueAttchID@Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForQuoteDelete] TO [VCSPortal]
GO
