SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRFISentToFirmDelete]
/************************************************************
* CREATED:     3/14/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
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
      @Original_RFISeq INT,
      @Original_VendorGroup bGroup,
      @Original_SentToFirm bFirm,
      @Original_SentToContact bEmployee,
      @Original_DateSent bDate,
      @Original_InformationReq VARCHAR(MAX),
      @Original_DateReqd bDate,
      @Original_Response VARCHAR(MAX),
      @Original_DateRecd bDate,
      @Original_Send bYN,
      @Original_PrefMethod CHAR(1),
      @Original_CC bYN,
      @Original_UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;

    DELETE  FROM PMRD
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( RFIType = @Original_RFIType )
            AND ( RFI = @Original_RFI )
            AND ( RFISeq = @Original_RFISeq )
            AND ( VendorGroup = @Original_VendorGroup )
            AND ( SentToFirm = @Original_SentToFirm )
            AND ( SentToContact = @Original_SentToContact )
            AND ( DateSent = @Original_DateSent )
	--AND(InformationReq = @Original_InformationReq OR @Original_InformationReq IS NULL AND InformationReq IS NULL)
            AND ( DateReqd = @Original_DateReqd
                  OR @Original_DateReqd IS NULL
                  AND DateReqd IS NULL
                )
	--AND(Response = @Original_Response OR @Original_Response IS NULL AND Response IS NULL)
            AND ( DateRecd = @Original_DateRecd
                  OR @Original_DateRecd IS NULL
                  AND DateRecd IS NULL
                )
            AND ( Send = @Original_Send )
            AND ( PrefMethod = @Original_PrefMethod )
            AND ( CC = @Original_CC )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                )

GO
GRANT EXECUTE ON  [dbo].[vpspPMRFISentToFirmDelete] TO [VCSPortal]
GO
