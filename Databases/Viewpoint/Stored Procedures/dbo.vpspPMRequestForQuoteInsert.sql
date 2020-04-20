SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspPMRequestForQuoteInsert]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				DAN SO 11/14/2011 - D-03599 - allow DateDue field
*				GF 12/06/2011 TK-10599
* 
* Description:	Insert a request for quote.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PCOType bDocType,
      @PCO bPCO,
      @RFQ bDocument,
      @Description VARCHAR(60),
      @RFQDate bDate,
      @DateDue bDate,		-- D-03599
      @VendorGroup bGroup,
      @FirmNumber bFirm,
      @ResponsiblePerson bEmployee,
      @Status bStatus,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER

    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'RFQ'

	--Status Code Validation
        IF @Status = '-1' 
            SET @Status = NULL
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Firm Validation
        IF @FirmNumber = -1 
            SET @FirmNumber = NULL
	
	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL

	--RFQ Validation
        IF ( ISNULL(@RFQ, '') = '' )
            OR @RFQ = '+'
            OR @RFQ = 'n'
            OR @RFQ = 'N' 
            BEGIN
                SET @RFQ = ( SELECT ISNULL(MAX(RFQ), 0) + 1
                             FROM   PMRQ
                             WHERE  PMCo = @PMCo
                                    AND Project = @Project
                                    AND PCOType = @PCOType
                                    AND PCO = @PCO
                           )	
            END
        SET @msg = NULL
        EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @RFQ, @msg OUTPUT
        SET @RFQ = @msg

	--Insert the RFQ
        INSERT  INTO PMRQ
                ( PMCo,
                  Project,
                  PCOType,
                  PCO,
                  RFQ,
                  Description,
                  RFQDate,
                  DateDue,		-- D-03599
                  VendorGroup,
                  FirmNumber,
                  ResponsiblePerson,
                  Status,
                  Notes,
                  UniqueAttchID
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @PCOType,
                  @PCO,
                  @RFQ,
                  @Description,
                  @RFQDate,
                  @DateDue,		-- D-03599
                  @VendorGroup,
                  @FirmNumber,
                  @ResponsiblePerson,
                  @Status,
                  @Notes,
                  @UniqueAttchID
		    )

	--Get the updated current record.
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMRequestForQuoteGet @PMCo, @Project, @VendorGroup, @KeyID
	
        vspExit:
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForQuoteInsert] TO [VCSPortal]
GO
