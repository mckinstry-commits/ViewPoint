SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsDistributionInsert]
/************************************************************
* CREATED:		11/28/06	CHS
* MODIFIED:		6/12/07		CHS
				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)	
				
* USAGE:
*   Inserts PM Other Documents Distribution
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
	--@Seq int,
      @Seq VARCHAR(10),
      @VendorGroup bGroup,
      @SentToFirm bFirm,
      @SentToContact bEmployee,
      @Send bYN,
      @PrefMethod CHAR(1),
      @CC bYN,
      @DateSent bDate,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
	
    )
AS 
    SET NOCOUNT ON ;

    DECLARE @rcode INT,
        @message VARCHAR(255)
    SELECT  @rcode = 0,
            @message = ''

--if @SentToFirm = -1 set @SentToFirm = NULL
--if @SentToContact = -1 set @SentToContact = NULL

    SET @Seq = ( SELECT ISNULL(( MAX(Seq) + 1 ), 1)
                 FROM   PMOC WITH ( NOLOCK )
                 WHERE  PMCo = @PMCo
                        AND Project = @Project
                        AND DocType = @DocType
                        AND Document = @Document
               )
					

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
	

    INSERT  INTO PMOC
            ( PMCo,
              Project,
              DocType,
              Document,
              Seq,
              VendorGroup,
              SentToFirm,
              SentToContact,
              Send,
              PrefMethod,
              CC,
              DateSent,
              Notes,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @DocType,
              @Document,
              @Seq,
              @VendorGroup,
              @SentToFirm,
              @SentToContact,
              @Send,
              @PrefMethod,
              @CC,
              @DateSent,
              @Notes,
              @UniqueAttchID
            )


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMOtherDocumentsDistributionGet @PMCo, @Project, @VendorGroup,
        @DocType, @Document, @KeyID
	
    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsDistributionInsert] TO [VCSPortal]
GO
