SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFISentToFirmInsert]
/************************************************************
* CREATED:		7/11/06	CHS
* MODIFIED:		6/12/07	CHS
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* USAGE:
*   Returns the PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  

* Notes:	
*	when PrefMethod = 'E' then 'Email'
*	when PrefMethod = 'T' then 'Email - Text Only'
*	when PrefMethod = 'F' then 'Fax'
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @RFIType bDocType,
      @RFI bDocument,
 	--@RFISeq int,
      @RFISeq VARCHAR(10),
      @VendorGroup bGroup,
      @SentToFirm bFirm,
      @SentToContact bEmployee,
      @DateSent bDate,
      @InformationReq VARCHAR(MAX),
      @DateReqd bDate,
      @Response bNotes,
      @DateRecd bDate,
      @Send bYN,
      @PrefMethod CHAR(1),
      @CC CHAR(1),
      @UniqueAttchID UNIQUEIDENTIFIER
 	
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
		
 	
    SET @RFISeq = ( SELECT  ISNULL(( MAX(RFISeq) + 1 ), 1)
                    FROM    PMRD WITH ( NOLOCK )
                    WHERE   PMCo = @PMCo
                            AND Project = @Project
                            AND RFIType = @RFIType
                            AND RFI = @RFI
                  )
 					
    INSERT  INTO PMRD
            ( PMCo,
              Project,
              RFIType,
              RFI,
              RFISeq,
              VendorGroup,
              SentToFirm,
              SentToContact,
              DateSent,
              InformationReq,
              DateReqd,
              Response,
              DateRecd,
              Send,
              PrefMethod,
              CC,
              UniqueAttchID
 		)
    VALUES  ( @PMCo,
              @Project,
              @RFIType,
              @RFI,
              @RFISeq,
              @VendorGroup,
              @SentToFirm,
              @SentToContact,
              @DateSent,
              @InformationReq,
              @DateReqd,
              @Response,
              @DateRecd,
              @Send,
              @PrefMethod,
              @CC,
              @UniqueAttchID 
 		)

    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMRFISentToFirmGet @PMCo, @Project, @RFIType, @RFI, @KeyID
 		
    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode






GO
GRANT EXECUTE ON  [dbo].[vpspPMRFISentToFirmInsert] TO [VCSPortal]
GO
