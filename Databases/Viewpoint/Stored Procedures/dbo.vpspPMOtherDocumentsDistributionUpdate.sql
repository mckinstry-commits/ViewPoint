SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsDistributionUpdate]
/************************************************************
* CREATED:     11/28/06  CHS
				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Updates PM Other Documents Distribution
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @DocType bDocType,
      @Document bDocument,
      @Seq INT,
      @VendorGroup bGroup,
      @SentToFirm bFirm,
      @SentToContact bEmployee,
      @Send bYN,
      @PrefMethod CHAR(1),
      @CC bYN,
      @DateSent bDate,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_DocType bDocType,
      @Original_Document bDocument,
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

    UPDATE  PMOC
    SET     --PMCo = @PMCo,
	--Project = @Project,
	--DocType = @DocType, 
	--Document = @Document, 
	--Seq = @Seq,
            VendorGroup = @VendorGroup,
            SentToFirm = @SentToFirm,
            SentToContact = @SentToContact,
            Send = @Send,
            PrefMethod = @PrefMethod,
            CC = @CC,
            DateSent = @DateSent,
            Notes = @Notes,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( DocType = @Original_DocType )
            AND ( Document = @Original_Document )
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


    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsDistributionUpdate] TO [VCSPortal]
GO
