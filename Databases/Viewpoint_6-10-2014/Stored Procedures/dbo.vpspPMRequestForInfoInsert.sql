SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRequestForInfoInsert]
/***********************************************************
* Created:	08/31/2009	JB		Rewrote SP/cleanup
* Modified:	12/11/2009	MCP		#136783 We were not passing @VenderGroup to vpspPMRequestForInfoGet 
*									causing vpspPMRequestForInfoGet to use @KeyID instead	
*			04/07/2011	GP		Added Reference and Suggestion column
*           06/17/2011  TEJ     Modified the calculation of the next RFI #. Projects can be set
*                                  Individually to key of just Project, or Project and DocType.
*                                  Called the V6 stored proc to handle this.
*			AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*			11/30/2011	JG		B-03889 - Added some validation to required fields for more informative messages.				
*			GF 12/06/2011 TK-10599
*
* Description:	Insert an RFI.
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
      @Submittal VARCHAR(10),
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
      @Reference VARCHAR(10),
      @Suggestion VARCHAR(MAX)
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @nextRFI INT,
            @DocCat VARCHAR(10),
            @msg VARCHAR(255)
            
    ----Verify required default Params
		IF @PMCo IS NULL
		BEGIN
			SELECT @msg = 'Missing PM Company.'
		END
		ELSE IF @Project IS NULL
		BEGIN
			SELECT @msg = 'Missing Project.'
		END
		ELSE IF @RFIType IS NULL
		BEGIN
			SELECT @msg = 'Missing RFI Type.'
		END
		ELSE IF @RFI IS NULL
		BEGIN
			SELECT @msg = 'Missing RFI ID.'
		END
		ELSE IF @RFIDate IS NULL
		BEGIN
			SELECT @msg = 'Missing RFI Date.'
		END
		ELSE IF @RespondFirm IS NULL
		BEGIN
			SELECT @msg = 'Missing To Firm.'
		END
		ELSE IF @RespondContact IS NULL
		BEGIN
			SELECT @msg = 'Missing To Contact.'
		END
		ELSE IF @DateSent IS NULL
		BEGIN
			SELECT @msg = 'Missing Date Sent.'
		END
		
		IF @msg IS NOT NULL
		BEGIN
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
        
    -- Set Values
        SET @DocCat = 'RFI'
        SET @PrefMethod = ( SELECT  PrefMethod
                            FROM    PMPM WITH ( NOLOCK )
                            WHERE   VendorGroup = @VendorGroup
                                    AND FirmNumber = @RespondFirm
                                    AND ContactCode = @RespondContact
                          )

	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Issue Validation
        IF ( @Issue = -1 ) 
            SET @Issue = NULL
	
	--ResponsibleFirm Validation
        IF ( @ResponsibleFirm = -1 ) 
            SET @ResponsibleFirm = NULL
	
	--ResponsiblePerson Validation
        IF ( @ResponsiblePerson = -1 ) 
            SET @ResponsiblePerson = NULL
	
	--ReqFirm Validation
        IF ( @ReqFirm = -1 ) 
            SET @ReqFirm = NULL
	
	--ReqContact Validation
        IF ( @ReqContact = -1 ) 
            SET @ReqContact = NULL
	
	--RFI Validation
        IF ( ISNULL(@RFI, '') = '' )
            OR @RFI = '+'
            OR @RFI = 'n'
            OR @RFI = 'N' 
            BEGIN
		-- 2011/06/06 - TomJ 
		-- Must Calculate the PM DocNumber using the same logic as V6 Whether we key off project and
		-- Sequence number or Project, doc type, and sequence number can be set on a project by project
		-- basis
                SET @msg = NULL
                EXECUTE dbo.vspPMGetNextPMDocNum @PMCo, @Project, @RFIType, '',
                    'RFI', @nextRFI OUTPUT, @msg OUTPUT
                IF ( LEN(@msg) > 0 ) 
                    BEGIN
                        RAISERROR(@msg, 16, 1)
                        GOTO vspExit
                    END		

                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @nextRFI,
                    @msg OUTPUT
                SET @RFI = @msg
            END
        ELSE 
            BEGIN
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @RFI,
                    @msg OUTPUT
                SET @RFI = @msg
            END
	
	--Insert the Request for information record
        INSERT  INTO PMRI
                ( PMCo,
                  Project,
                  RFIType,
                  RFI,
                  Subject,
                  RFIDate,
                  Issue,
                  Status,
                  Submittal,
                  Drawing,
                  Addendum,
                  SpecSec,
                  ScheduleNo,
                  VendorGroup,
                  ResponsibleFirm,
                  ResponsiblePerson,
                  ReqFirm,
                  ReqContact,
                  Notes,
                  UniqueAttchID,
                  Response,
                  DateDue,
                  ImpactDesc,
                  ImpactDays,
                  ImpactCosts,
                  ImpactPrice,
                  RespondFirm,
                  RespondContact,
                  DateSent,
                  DateRecd,
                  PrefMethod,
                  InfoRequested,
                  Reference,
                  Suggestion
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @RFIType,
                  @RFI,
                  @Subject,
                  @RFIDate,
                  @Issue,
                  @Status,
                  @Submittal,
                  @Drawing,
                  @Addendum,
                  @SpecSec,
                  @ScheduleNo,
                  @VendorGroup,
                  @ResponsibleFirm,
                  @ResponsiblePerson,
                  @ReqFirm,
                  @ReqContact,
                  @Notes,
                  @UniqueAttchID,
                  @Response,
                  @DateDue,
                  @ImpactDesc,
                  @ImpactDays,
                  @ImpactCosts,
                  @ImpactPrice,
                  @RespondFirm,
                  @RespondContact,
                  @DateSent,
                  @DateRecd,
                  @PrefMethod,
                  @InfoRequested,
                  @Reference,
                  @Suggestion
		    )
	
	--Get the updated current record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMRequestForInfoGet @PMCo, @Project, @VendorGroup, @KeyID

        vspExit:
    END


GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForInfoInsert] TO [VCSPortal]
GO
