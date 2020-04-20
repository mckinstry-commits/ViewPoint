SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMTransmittalItemDelete
/************************************************************
* CREATED:     12/18/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Deletes PM Transmittal Items
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
      @Original_DocType bDocType,
      @Original_Document bDocument,
      @Original_DocumentDesc bItemDesc,
      @Original_CopiesSent TINYINT,
      @Original_Status bStatus,
      @Original_Remarks VARCHAR(MAX),
      @Original_Rev TINYINT,
      @Original_UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;

    DELETE  FROM PMTS
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( Transmittal = @Original_Transmittal )
            AND ( Seq = @Original_Seq )
            AND ( DocType = @Original_DocType
                  OR @Original_DocType IS NULL
                  AND DocType IS NULL
                )
            AND ( Document = @Original_Document
                  OR @Original_Document IS NULL
                  AND Document IS NULL
                )
            AND ( DocumentDesc = @Original_DocumentDesc
                  OR @Original_DocumentDesc IS NULL
                  AND DocumentDesc IS NULL
                )
            AND ( CopiesSent = @Original_CopiesSent
                  OR @Original_CopiesSent IS NULL
                  AND CopiesSent IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                ) 
	--AND (Remarks = @Original_Remarks OR @Original_Remarks IS NULL AND Remarks IS NULL) 
            AND ( Rev = @Original_Rev
                  OR @Original_Rev IS NULL
                  AND Rev IS NULL
                ) 
	--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 



GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalItemDelete] TO [VCSPortal]
GO
