SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRFQDistributionInsert]
/************************************************************
* CREATED:		1/08/07		CHS
* Modified:		6/05/07		chs
*				GF 09/03/2010 - issue #141031 change to use date only function
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts PM RFQ
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
	--@RFQSeq tinyint,
      @RFQSeq VARCHAR(3),
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
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;

    DECLARE @rcode INT,
        @msg VARCHAR(255),
        @message VARCHAR(255)

    SELECT  @rcode = 0,
            @message = ''

----#141031
    IF ( @DateSent IS NULL ) 
        SET @DateSent = dbo.vfDateOnly()

    IF ( ISNULL(@RFQSeq, '') = '' )
        OR @RFQSeq = '+'
        OR @RFQSeq = 'n'
        OR @RFQSeq = 'N' 
        BEGIN
            SET @RFQSeq = ( SELECT  ISNULL(( MAX(RFQSeq) + 1 ), 1)
                            FROM    PMQD WITH ( NOLOCK )
                            WHERE   PMCo = @PMCo
                                    AND Project = @Project
                                    AND VendorGroup = @VendorGroup
                                    AND PCOType = @PCOType
                                    AND PCO = @PCO
                                    AND RFQ = @RFQ
                          ) 
        END
						
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

    INSERT  INTO PMQD
            ( PMCo,
              Project,
              PCOType,
              PCO,
              RFQ,
              RFQSeq,
              VendorGroup,
              SentToFirm,
              SentToContact,
              DateSent,
              DateReqd,
              Response,
              DateRecd,
              PrefMethod,
              Send,
              CC,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @PCOType,
              @PCO,
              @RFQ,
              @RFQSeq,
              @VendorGroup,
              @SentToFirm,
              @SentToContact,
              @DateSent,
              @DateReqd,
              @Response,
              @DateRecd,
              @PrefMethod,
              @Send,
              @CC,
              @UniqueAttchID
            ) ;

    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMRFQDistributionGet @PMCo, @Project, @VendorGroup, @PCOType,
        @PCO, @RFQ, @KeyID


    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vpspPMRFQDistributionInsert] TO [VCSPortal]
GO
