SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFQDistributionUpdate]
/************************************************************
* CREATED:     1/08/07  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Updates RFQ
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PCOType bDocType,
      @PCO bPCO,
      @RFQ bDocument,
      @RFQSeq TINYINT,
      @VendorGroup bGroup,
      @SentToFirm bFirm,
      @SentToContact bEmployee,
      @DateSent bDate,
      @DateReqd bDate,
      @Response VARCHAR(MAX),
      @DateRecd bDate,
      @Send CHAR(1),
      @PrefMethod CHAR(1),
      @CC CHAR(1),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_PCOType bDocType,
      @Original_PCO bPCO,
      @Original_RFQ bDocument,
      @Original_RFQSeq TINYINT,
      @Original_VendorGroup bGroup,
      @Original_SentToFirm bFirm,
      @Original_SentToContact bEmployee,
      @Original_DateSent bDate,
      @Original_DateReqd bDate,
      @Original_Response VARCHAR(MAX),
      @Original_DateRecd bDate,
      @Original_Send CHAR(1),
      @Original_PrefMethod CHAR(1),
      @Original_CC CHAR(1),
      @Original_UniqueAttchID CHAR(1)
    )
AS 
    SET NOCOUNT ON ;

    DECLARE @rcode INT,
        @message VARCHAR(255)
    SELECT  @rcode = 0,
            @message = ''

    IF ( @PrefMethod IS NULL ) 
        BEGIN
            ( SELECT    @PrefMethod = ( SELECT  PMPM.PrefMethod
                                        FROM    PMPM
                                        WHERE   PMPM.VendorGroup = @VendorGroup
                                                AND PMPM.FirmNumber = @SentToFirm
                                                AND PMPM.ContactCode = @SentToContact
                                      )
            )
        END
	
    ELSE 
        IF ( ( @PrefMethod = 'E' )
             AND ( ( SELECT PMPM.EMail
                     FROM   PMPM
                     WHERE  PMPM.VendorGroup = @VendorGroup
                            AND PMPM.FirmNumber = @SentToFirm
                            AND PMPM.ContactCode = @SentToContact
                   ) IS NULL )
           ) 
            BEGIN 
                SELECT  @rcode = 1,
                        @message = 'Invalid Method: no EMail setup for Contact.'
                GOTO bspmessage
            END		
		
        ELSE 
            IF ( ( @PrefMethod = 'T' )
                 AND ( ( SELECT PMPM.EMail
                         FROM   PMPM
                         WHERE  PMPM.VendorGroup = @VendorGroup
                                AND PMPM.FirmNumber = @SentToFirm
                                AND PMPM.ContactCode = @SentToContact
                       ) IS NULL )
               ) 
                BEGIN 
                    SELECT  @rcode = 1,
                            @message = 'Invalid Method: no EMail setup for Contact.'
                    GOTO bspmessage
                END		
	
            ELSE 
                IF ( ( @PrefMethod = 'F' )
                     AND ( ( SELECT PMPM.Fax
                             FROM   PMPM
                             WHERE  PMPM.VendorGroup = @VendorGroup
                                    AND PMPM.FirmNumber = @SentToFirm
                                    AND PMPM.ContactCode = @SentToContact
                           ) IS NULL )
                   ) 
                    BEGIN 
                        SELECT  @rcode = 1,
                                @message = 'Invalid Method: no Fax number setup for Contact.'
                        GOTO bspmessage
                    END	

    UPDATE  PMQD
    SET     --PMCo = @PMCo,
	--Project = @Project,
	--PCOType = @PCOType,
	--PCO = @PCO,
	--RFQ = @RFQ,
	--RFQSeq = @RFQSeq,
            VendorGroup = @VendorGroup,
            SentToFirm = @SentToFirm,
            SentToContact = @SentToContact,
            DateSent = @DateSent,
            DateReqd = @DateReqd,
            Response = @Response,
            DateRecd = @DateRecd,
            Send = @Send,
            PrefMethod = @PrefMethod,
            CC = @CC,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( PCOType = @Original_PCOType )
            AND ( PCO = @Original_PCO )
            AND ( RFQ = @Original_RFQ )
            AND ( RFQSeq = @Original_RFQSeq )
            AND ( VendorGroup = @Original_VendorGroup )
            AND ( SentToFirm = @Original_SentToFirm )
            AND ( SentToContact = @Original_SentToContact )
            AND ( DateSent = @Original_DateSent )
            AND ( DateReqd = @Original_DateReqd
                  OR @Original_DateReqd IS NULL
                  AND DateReqd IS NULL
                )
	--AND (Response = @Original_Response OR @Original_Response IS NULL AND Response IS NULL)
            AND ( DateRecd = @Original_DateRecd
                  OR @Original_DateRecd IS NULL
                  AND DateRecd IS NULL
                )
            AND ( PrefMethod = @Original_PrefMethod
                  OR @Original_PrefMethod IS NULL
                  AND PrefMethod IS NULL
                )
	
	--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)
	--AND (CCList = @Original_CCList OR @Original_CCList IS NULL AND CCList IS NULL)
	
    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vpspPMRFQDistributionUpdate] TO [VCSPortal]
GO
