SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMTransmittalDistributionDelete]
/************************************************************
* CREATED:     12/18/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)

* USAGE:
*   Deletes PM Transmittal Distribution
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_Transmittal bDocument,
      @Original_Seq INT,
      @Original_VendorGroup bGroup,
      @Original_SentToFirm bFirm,
      @Original_SentToContact bEmployee,
      @Original_Send bYN,
      @Original_PrefMethod CHAR(1),
      @Original_CC bYN,
      @Original_DateSent bDate,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER

    )
AS 
    SET NOCOUNT ON ;

    DELETE  FROM PMTC
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( Transmittal = @Original_Transmittal )
            AND ( Seq = @Original_Seq )
            AND ( VendorGroup = @Original_VendorGroup )
            AND ( SentToFirm = @Original_SentToFirm )
            AND ( SentToContact = @Original_SentToContact )
            AND ( Send = @Original_Send )
            AND ( PrefMethod = @Original_PrefMethod )
            AND ( CC = @Original_CC )
            AND ( DateSent = @Original_DateSent
                  OR @Original_DateSent IS NULL
                  AND DateSent IS NULL
                ) 
	--AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) 
	--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 


GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalDistributionDelete] TO [VCSPortal]
GO
